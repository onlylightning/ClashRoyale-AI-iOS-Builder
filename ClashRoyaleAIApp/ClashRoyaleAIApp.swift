import SwiftUI

// ============================================================================
// CLASH ROYALE NATIVE iOS APP ENTRY POINT
// Listens to ReplayKit Broadcast Extension Darwin IPC events in real time
// ============================================================================

@main
struct ClashRoyaleAIApp: App {
    @StateObject private var engine = CRAIEngine.shared
    @StateObject private var analytics = MatchAnalyticsStore.shared
    @StateObject private var pipController = PiPOverlayController.shared
    @StateObject private var voiceCoach = VoiceCoachManager.shared

    init() {
        setupReplayKitIPCListener()
    }

    var body: some Scene {
        WindowGroup {
            MainTabView()
                .environmentObject(engine)
                .environmentObject(analytics)
                .environmentObject(pipController)
                .environmentObject(voiceCoach)
                .preferredColorScheme(.dark)
        }
    }

    private func setupReplayKitIPCListener() {
        ReplayKitIPCBridge.shared.startObservingInMainApp { payload in
            let engine = CRAIEngine.shared

            // 1. Sync match clock seconds if OCR detected timer on Clash Royale screen
            if let clockSec = payload.detectedMatchClockSeconds, clockSec > engine.elapsedSeconds {
                engine.elapsedSeconds = clockSec
            }

            // 2. Sync player elixir bar if read from bottom purple bar
            if let myElixir = payload.detectedMyElixirBar {
                engine.playerElixir = myElixir
            }

            // 3. Opponent played a card detected by YOLOv8 CoreML model
            if let oppCardId = payload.detectedOpponentCardId,
               let card = CRDatabase.shared.cardById[oppCardId] {
                let bestCounter = engine.registerOpponentCardPlayed(oppCardId)
                VoiceCoachManager.shared.announceOpponentCard(
                    card: card,
                    bestCounter: bestCounter,
                    engine: engine
                )
            }

            // 4. Player played a card
            if let myCardId = payload.detectedMyCardId {
                engine.registerMyCardPlayed(myCardId)
            }

            // 5. Refresh Picture-in-Picture floating HUD over Clash Royale
            PiPOverlayController.shared.enqueueRenderedHUDFrame()
        }
    }
}
