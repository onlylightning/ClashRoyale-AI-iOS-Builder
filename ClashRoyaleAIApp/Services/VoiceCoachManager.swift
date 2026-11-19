import Foundation
import AVFoundation

// ============================================================================
// CLASH ROYALE NATIVE iOS - TURKISH BACKGROUND VOICE COACH (AVSpeechSynthesizer)
// Speaks real-time counter moves, deck predictions & Evolution warnings into
// AirPods / iPhone speakers while playing Clash Royale
// ============================================================================

public final class VoiceCoachManager: ObservableObject {
    public static let shared = VoiceCoachManager()

    @Published public var isVoiceCoachEnabled: Bool = true
    private let synthesizer = AVSpeechSynthesizer()
    private var lastSpokenText: String = ""
    private var lastSpokenTimestamp: TimeInterval = 0

    private init() {}

    public func speak(_ text: String, urgent: Bool = false) {
        guard isVoiceCoachEnabled, !text.isEmpty else { return }
        let now = Date().timeIntervalSince1970
        if !urgent && text == lastSpokenText && now - lastSpokenTimestamp < 3.0 {
            return
        }

        if urgent && synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }

        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "tr-TR")
        utterance.rate = 0.54 // Fast, clear esports coaching pace
        utterance.pitchMultiplier = 1.0
        utterance.volume = 1.0

        lastSpokenText = text
        lastSpokenTimestamp = now
        synthesizer.speak(utterance)
    }

    public func announceOpponentCard(card: CRCard, bestCounter: CounterRecommendation?, engine: CRAIEngine) {
        guard isVoiceCoachEnabled else { return }
        let oppElixirInt = Int(engine.opponentElixir.rounded())
        var message = "Rakip \(card.nameTr), \(oppElixirInt) iksiri kaldı. "

        if let best = bestCounter {
            let tradeText = best.netElixirTrade > 0 ? "artı \(best.netElixirTrade) iksir kazanç" : "eşit takas"
            message += "\(best.counterCard.nameTr) ile \(best.placement.rawValue) savun, \(tradeText). "
        }

        if let alert = engine.tacticalAlerts.first {
            if alert.severity == "PUNISH" {
                message += "Rakibin iksiri bitti, ters koridordan şimdi saldır!"
            } else if alert.severity == "EVO" {
                message += "Dikkat, rakibin elinde Evrimli kart hazır!"
            }
        } else if engine.opponentKnownDeckIds.count == 3, let topDeck = engine.deckPredictions.first, topDeck.confidencePercent >= 80 {
            message += "Deste tespit edildi: Yüzde \(topDeck.confidencePercent) \(topDeck.deck.name)."
        }

        speak(message, urgent: true)
    }
}
