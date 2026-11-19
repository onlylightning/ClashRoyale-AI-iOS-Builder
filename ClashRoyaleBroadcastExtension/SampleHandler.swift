import ReplayKit
import CoreVideo
import Vision

// ============================================================================
// CLASH ROYALE NATIVE iOS - REPLAYKIT BROADCAST UPLOAD EXTENSION
// Captures live Clash Royale screen frames at 10 FPS in the background and
// pushes detected opponent cards, match seconds & elixir via Darwin IPC
// ============================================================================

public final class SampleHandler: RPBroadcastSampleHandler {

    private var lastProcessedTimestamp: TimeInterval = 0
    /// 10 FPS frame throttling keeps memory under iOS Broadcast Extension 50MB limit
    private let minimumFrameInterval: TimeInterval = 0.10

    public override func broadcastStarted(withSetupInfo setupInfo: [String : NSObject]?) {
        ReplayKitIPCBridge.shared.setBroadcastActive(true)
        CRVisionDetector.shared.resetMatchSession()
    }

    public override func broadcastPaused() {
        ReplayKitIPCBridge.shared.setBroadcastActive(false)
    }

    public override func broadcastResumed() {
        ReplayKitIPCBridge.shared.setBroadcastActive(true)
    }

    public override func broadcastFinished() {
        ReplayKitIPCBridge.shared.setBroadcastActive(false)
    }

    public override func processSampleBuffer(_ sampleBuffer: CMSampleBuffer, with sampleBufferType: RPSampleBufferType) {
        guard sampleBufferType == .video else { return }

        let now = Date().timeIntervalSince1970
        guard now - lastProcessedTimestamp >= minimumFrameInterval else { return }
        lastProcessedTimestamp = now

        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }

        autoreleasepool {
            if let payload = CRVisionDetector.shared.analyzeClashRoyaleFrame(pixelBuffer: pixelBuffer, timestamp: now) {
                ReplayKitIPCBridge.shared.publishVisionPayload(payload)
            }
        }
    }
}
