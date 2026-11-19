import Foundation
import AVKit
import AVFoundation
import UIKit
import CoreVideo
import CoreMedia

// ============================================================================
// CLASH ROYALE NATIVE iOS - PICTURE-IN-PICTURE (PiP) IN-GAME OVERLAY HUD
// Renders Live Opponent Elixir, 4-Card Hand Cycle, Meta Deck & Counter Move
// into a floating PiP window ON TOP of Clash Royale without Jailbreak!
// ============================================================================

public final class PiPOverlayController: NSObject, ObservableObject, AVPictureInPictureControllerDelegate, AVPictureInPictureSampleBufferPlaybackDelegate {
    public static let shared = PiPOverlayController()

    @Published public var isPiPActive: Bool = false
    public let displayLayer = AVSampleBufferDisplayLayer()

    private var pipController: AVPictureInPictureController?
    private var renderTimer: Timer?

    private override init() {
        super.init()
        configureBackgroundAudioSession()
        setupSampleBufferPiP()
    }

    private func configureBackgroundAudioSession() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .spokenAudio, options: [.mixWithOthers, .duckOthers])
            try session.setActive(true)
        } catch {
            print("[PiPOverlayController] AudioSession error: \(error.localizedDescription)")
        }
    }

    public func setupSampleBufferPiP() {
        guard AVPictureInPictureController.isPictureInPictureSupported() else { return }

        let contentSource = AVPictureInPictureController.ContentSource(
            sampleBufferDisplayLayer: displayLayer,
            playbackDelegate: self
        )
        let controller = AVPictureInPictureController(contentSource: contentSource)
        controller.delegate = self
        if #available(iOS 14.2, *) {
            controller.canStartPictureInPictureAutomaticallyFromInline = true
        }
        self.pipController = controller

        // Push fresh HUD frames into the PiP buffer at 4 FPS
        renderTimer?.invalidate()
        renderTimer = Timer.scheduledTimer(withTimeInterval: 0.25, repeats: true) { [weak self] _ in
            self?.enqueueRenderedHUDFrame()
        }
        enqueueRenderedHUDFrame()
    }

    public func togglePiP() {
        guard let pip = pipController else { return }
        if pip.isPictureInPictureActive {
            pip.stopPictureInPicture()
        } else {
            pip.startPictureInPicture()
        }
    }

    // MARK: - Render Live Tactical HUD Frame into CMSampleBuffer
    public func enqueueRenderedHUDFrame() {
        let engine = CRAIEngine.shared
        let width = 520
        let height = 280

        let renderer = UIGraphicsImageRenderer(size: CGSize(width: width, height: height))
        let image = renderer.image { ctx in
            let cg = ctx.cgContext

            // 1. Dark Esports HUD Background
            UIColor(red: 0.05, green: 0.08, blue: 0.16, alpha: 1.0).setFill()
            cg.fill(CGRect(x: 0, y: 0, width: width, height: height))

            // Top Header Strip: Opponent Elixir + Match Clock + Phase
            UIColor(red: 0.10, green: 0.15, blue: 0.28, alpha: 1.0).setFill()
            cg.fill(CGRect(x: 0, y: 0, width: width, height: 48))

            let mins = engine.elapsedSeconds / 60
            let secs = engine.elapsedSeconds % 60
            let headerText = String(
                format: "RAKİP İKSİR: %.1f💧  |  SEN: %.1f💧  |  %02d:%02d (%dx)",
                engine.opponentElixir, engine.playerElixir, mins, secs, engine.currentPhaseMultiplier
            )
            let headerAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 16, weight: .black),
                .foregroundColor: UIColor.white
            ]
            headerText.draw(at: CGPoint(x: 14, y: 14), withAttributes: headerAttrs)

            // 2. Active Counter Move & Positive Elixir Trade Box
            UIColor(red: 0.08, green: 0.24, blue: 0.20, alpha: 1.0).setFill()
            cg.fill(CGRect(x: 12, y: 58, width: width - 24, height: 68))

            var counterLine1 = "🛡️ AI KOÇ: Rakip hamlesi bekleniyor..."
            var counterLine2 = "Clash Royale'e geçin, ReplayKit ekranı otomatik okur."
            if let threat = engine.lastOpponentCard, let best = engine.recommendedCounters.first {
                let sign = best.netElixirTrade >= 0 ? "+\(best.netElixirTrade)" : "\(best.netElixirTrade)"
                counterLine1 = "🔴 \(threat.nameTr) ➔ 🟢 \(best.counterCard.nameTr) İLE SAVUN (\(sign)💧)"
                counterLine2 = "📍 \(best.placement.rawValue)"
            }

            counterLine1.draw(
                at: CGPoint(x: 22, y: 66),
                withAttributes: [
                    .font: UIFont.systemFont(ofSize: 16, weight: .heavy),
                    .foregroundColor: UIColor(red: 0.20, green: 0.95, blue: 0.65, alpha: 1.0)
                ]
            )
            counterLine2.draw(
                at: CGPoint(x: 22, y: 92),
                withAttributes: [
                    .font: UIFont.systemFont(ofSize: 13.5, weight: .bold),
                    .foregroundColor: UIColor.white
                ]
            )

            // 3. Opponent's Current 4-Card Hand + Evolution Alert
            let handNames = engine.opponentHandSlots.map { slot -> String in
                guard let c = slot.card else { return "❓" }
                return slot.isEvolutionReady ? "🟣\(c.nameTr)(EVO!)" : "\(c.nameTr)(\(c.elixir))"
            }.joined(separator: "  •  ")

            "🔄 RAKİBİN ELİNDEKİ 4 KART:".draw(
                at: CGPoint(x: 14, y: 138),
                withAttributes: [
                    .font: UIFont.systemFont(ofSize: 12.5, weight: .heavy),
                    .foregroundColor: UIColor(red: 0.98, green: 0.45, blue: 0.52, alpha: 1.0)
                ]
            )
            handNames.draw(
                at: CGPoint(x: 14, y: 158),
                withAttributes: [
                    .font: UIFont.systemFont(ofSize: 15, weight: .bold),
                    .foregroundColor: UIColor.white
                ]
            )

            // 4. Detected Meta Deck & Unrevealed Surprise Cards
            var deckLine = "🎯 DESTE TAHMİNİ: İlk 2 kart bekleniyor..."
            var surpriseLine = ""
            if let topPred = engine.deckPredictions.first {
                deckLine = "🎯 %\(topPred.confidencePercent) \(topPred.deck.name)"
                let surprises = topPred.unrevealedCards.prefix(4).map { $0.nameTr }.joined(separator: ", ")
                if !surprises.isEmpty {
                    surpriseLine = "⚠️ Gizli Tehditler: \(surprises)"
                }
            }

            deckLine.draw(
                at: CGPoint(x: 14, y: 196),
                withAttributes: [
                    .font: UIFont.systemFont(ofSize: 14, weight: .heavy),
                    .foregroundColor: UIColor(red: 0.98, green: 0.75, blue: 0.15, alpha: 1.0)
                ]
            )
            surpriseLine.draw(
                at: CGPoint(x: 14, y: 218),
                withAttributes: [
                    .font: UIFont.systemFont(ofSize: 13, weight: .semibold),
                    .foregroundColor: UIColor(red: 0.85, green: 0.90, blue: 0.98, alpha: 1.0)
                ]
            )

            // 5. Critical Punish / Evo Alert Footer
            if let alert = engine.tacticalAlerts.first {
                alert.titleTr.draw(
                    at: CGPoint(x: 14, y: 248),
                    withAttributes: [
                        .font: UIFont.systemFont(ofSize: 13.5, weight: .black),
                        .foregroundColor: UIColor(red: 0.95, green: 0.55, blue: 0.98, alpha: 1.0)
                    ]
                )
            }
        }

        guard let sampleBuffer = makeSampleBuffer(from: image) else { return }
        if displayLayer.status == .failed {
            displayLayer.flush()
        }
        displayLayer.enqueue(sampleBuffer)
    }

    private func makeSampleBuffer(from image: UIImage) -> CMSampleBuffer? {
        guard let cgImage = image.cgImage else { return nil }
        let width = cgImage.width
        let height = cgImage.height

        var pixelBuffer: CVPixelBuffer?
        let attrs: [CFString: Any] = [
            kCVPixelBufferCGImageCompatibilityKey: true,
            kCVPixelBufferCGBitmapContextCompatibilityKey: true,
            kCVPixelBufferIOSurfacePropertiesKey: [:]
        ]
        guard CVPixelBufferCreate(
            kCFAllocatorDefault, width, height,
            kCVPixelFormatType_32ARGB, attrs as CFDictionary, &pixelBuffer
        ) == kCVReturnSuccess, let pxBuffer = pixelBuffer else {
            return nil
        }

        CVPixelBufferLockBaseAddress(pxBuffer, [])
        if let context = CGContext(
            data: CVPixelBufferGetBaseAddress(pxBuffer),
            width: width, height: height,
            bitsPerComponent: 8,
            bytesPerRow: CVPixelBufferGetBytesPerRow(pxBuffer),
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue
        ) {
            context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
        }
        CVPixelBufferUnlockBaseAddress(pxBuffer, [])

        var formatDesc: CMVideoFormatDescription?
        guard CMVideoFormatDescriptionCreateForImageBuffer(
            allocator: kCFAllocatorDefault,
            imageBuffer: pxBuffer,
            formatDescriptionOut: &formatDesc
        ) == noErr, let desc = formatDesc else {
            return nil
        }

        var timing = CMSampleTimingInfo(
            duration: CMTime(value: 1, timescale: 4),
            presentationTimeStamp: CMClockGetTime(CMClockGetHostTimeClock()),
            decodeTimeStamp: .invalid
        )

        var sampleBuffer: CMSampleBuffer?
        CMSampleBufferCreateForImageBuffer(
            allocator: kCFAllocatorDefault,
            imageBuffer: pxBuffer,
            dataReady: true,
            makeDataReadyCallback: nil,
            refcon: nil,
            formatDescription: desc,
            sampleTiming: &timing,
            sampleBufferOut: &sampleBuffer
        )
        return sampleBuffer
    }

    // MARK: - AVPictureInPictureControllerDelegate & PlaybackDelegate
    public func pictureInPictureControllerDidStartPictureInPicture(_ pictureInPictureController: AVPictureInPictureController) {
        isPiPActive = true
    }

    public func pictureInPictureControllerDidStopPictureInPicture(_ pictureInPictureController: AVPictureInPictureController) {
        isPiPActive = false
    }

    public func pictureInPictureController(_ pictureInPictureController: AVPictureInPictureController, setPlaying playing: Bool) {}

    public func pictureInPictureControllerTimeRangeForPlayback(_ pictureInPictureController: AVPictureInPictureController) -> CMTimeRange {
        return CMTimeRange(start: .negativeInfinity, duration: .positiveInfinity)
    }

    public func pictureInPictureControllerIsPlaybackPaused(_ pictureInPictureController: AVPictureInPictureController) -> Bool {
        return false
    }

    public func pictureInPictureController(_ pictureInPictureController: AVPictureInPictureController, didTransitionToRenderSize newRenderSize: CMVideoDimensions) {}

    public func pictureInPictureController(_ pictureInPictureController: AVPictureInPictureController, skipByInterval skipInterval: CMTime, completion completionHandler: @escaping () -> Void) {
        completionHandler()
    }
}
