import Foundation
import Vision
import CoreML
import CoreVideo
import CoreImage

// ============================================================================
// CLASH ROYALE NATIVE iOS - COREML (YOLOv8) & VISION OCR FRAME ANALYZER
// Runs on Apple Neural Engine inside ReplayKit Broadcast Extension
// ============================================================================

public final class CRVisionDetector {
    public static let shared = CRVisionDetector()

    private var coreMLModel: VNCoreMLModel?
    /// Tracks last detection timestamp per cardId to debounce repeated detections of the same walking troop
    private var lastCardDetectionTime: [String: TimeInterval] = [:]
    private let cardDebounceSeconds: TimeInterval = 3.6
    private var lastOCRTime: TimeInterval = 0

    private init() {
        loadCompiledCoreMLModelIfPresent()
    }

    public func resetMatchSession() {
        lastCardDetectionTime.removeAll()
        lastOCRTime = 0
    }

    /// Loads `ClashRoyaleCards.mlmodelc` from the extension bundle if trained/bundled
    private func loadCompiledCoreMLModelIfPresent() {
        guard let modelURL = Bundle.main.url(forResource: "ClashRoyaleCards", withExtension: "mlmodelc") else {
            return
        }
        do {
            let config = MLModelConfiguration()
            config.computeUnits = .cpuAndNeuralEngine
            let mlModel = try MLModel(contentsOf: modelURL, configuration: config)
            self.coreMLModel = try VNCoreMLModel(for: mlModel)
        } catch {
            print("[CRVisionDetector] CoreML model load info: \(error.localizedDescription)")
        }
    }

    /// Analyzes a live iPhone Clash Royale screen frame from ReplayKit
    public func analyzeClashRoyaleFrame(pixelBuffer: CVPixelBuffer, timestamp: TimeInterval) -> VisionFramePayload? {
        var detectedOppCard: String? = nil
        var detectedMyCard: String? = nil
        var detectedConfidence: Double = 0.0
        var detectedClockSeconds: Int? = nil
        var isMatchOver = false

        // 1. Scan Bottom Player Elixir Bar from Pixel Buffer (Fast O(1) ROI Scan)
        let myElixir = scanPlayerElixirBar(pixelBuffer: pixelBuffer)

        // 2. Run CoreML YOLOv8 Card & Troop Detector on Arena ROI
        if let vnModel = coreMLModel {
            let request = VNCoreMLRequest(model: vnModel) { [weak self] req, _ in
                guard let self = self,
                      let results = req.results as? [VNRecognizedObjectObservation] else { return }

                for obs in results where obs.confidence >= 0.72 {
                    guard let topLabel = obs.labels.first else { continue }
                    let cardId = topLabel.identifier
                    guard CRDatabase.shared.cardById[cardId] != nil else { continue }

                    // Check debounce window
                    if let lastSeen = self.lastCardDetectionTime[cardId],
                       timestamp - lastSeen < self.cardDebounceSeconds {
                        continue
                    }

                    self.lastCardDetectionTime[cardId] = timestamp
                    detectedConfidence = Double(obs.confidence)

                    // Vision normalized coordinates: origin (0,0) is bottom-left.
                    // Top half of arena (midY > 0.50) belongs to Opponent; bottom half (0.20..0.50) belongs to Player.
                    let midY = obs.boundingBox.midY
                    if midY >= 0.48 {
                        detectedOppCard = cardId
                    } else if midY >= 0.18 {
                        detectedMyCard = cardId
                    }
                    break
                }
            }
            request.imageCropAndScaleOption = .scaleFill
            let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .up, options: [:])
            try? handler.perform([request])
        }

        // 3. Run Vision OCR on Top-Right Match Clock every 1.0 second to track exact match seconds
        if timestamp - lastOCRTime >= 1.0 {
            lastOCRTime = timestamp
            let ocrResult = recognizeMatchClockAndEndState(pixelBuffer: pixelBuffer)
            detectedClockSeconds = ocrResult.elapsedSeconds
            isMatchOver = ocrResult.isMatchOver
        }

        if detectedOppCard != nil || detectedMyCard != nil || detectedClockSeconds != nil || isMatchOver {
            return VisionFramePayload(
                timestamp: timestamp,
                detectedOpponentCardId: detectedOppCard,
                detectedMyCardId: detectedMyCard,
                detectedMyElixirBar: myElixir,
                detectedMatchClockSeconds: detectedClockSeconds,
                detectedMultiplierPhase: nil,
                isMatchOver: isMatchOver,
                confidence: max(0.85, detectedConfidence)
            )
        }

        return nil
    }

    // MARK: - Vision OCR for Top-Right Match Timer ("02:45" -> Elapsed Seconds)
    private func recognizeMatchClockAndEndState(pixelBuffer: CVPixelBuffer) -> (elapsedSeconds: Int?, isMatchOver: Bool) {
        var elapsedSec: Int? = nil
        var matchEnded = false

        let textReq = VNRecognizeTextRequest { req, _ in
            guard let observations = req.results as? [VNRecognizedTextObservation] else { return }
            for obs in observations {
                guard let candidate = obs.topCandidates(1).first?.string.lowercased() else { continue }

                if candidate.contains("kazanan") || candidate.contains("winner") || candidate.contains("tamam") || candidate.contains("ok") {
                    matchEnded = true
                }

                // Parse MM:SS timer format (e.g. "2:45" or "01:12")
                let pattern = #"(\d{1,2}):(\d{2})"#
                if let regex = try? NSRegularExpression(pattern: pattern),
                   let match = regex.firstMatch(in: candidate, range: NSRange(candidate.startIndex..., in: candidate)),
                   let minRange = Range(match.range(at: 1), in: candidate),
                   let secRange = Range(match.range(at: 2), in: candidate),
                   let mins = Int(candidate[minRange]),
                   let secs = Int(candidate[secRange]),
                   mins <= 3 && secs < 60 {
                    let remaining = mins * 60 + secs
                    // Standard regulation is 180s (3:00)
                    elapsedSec = max(0, 180 - remaining)
                }
            }
        }
        textReq.recognitionLevel = .fast
        textReq.usesLanguageCorrection = false
        // Top-right corner ROI where Clash Royale displays the battle clock
        textReq.regionOfInterest = CGRect(x: 0.72, y: 0.85, width: 0.26, height: 0.12)

        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .up, options: [:])
        try? handler.perform([textReq])

        return (elapsedSec, matchEnded)
    }

    // MARK: - Bottom Purple Elixir Bar Pixel Scanner (10 Segments)
    private func scanPlayerElixirBar(pixelBuffer: CVPixelBuffer) -> Double? {
        CVPixelBufferLockBaseAddress(pixelBuffer, .readOnly)
        defer { CVPixelBufferUnlockBaseAddress(pixelBuffer, .readOnly) }

        let width = CVPixelBufferGetWidth(pixelBuffer)
        let height = CVPixelBufferGetHeight(pixelBuffer)
        let bytesPerRow = CVPixelBufferGetBytesPerRow(pixelBuffer)
        guard width > 100, height > 100,
              let baseAddress = CVPixelBufferGetBaseAddress(pixelBuffer) else {
            return nil
        }

        let buffer = baseAddress.assumingMemoryBound(to: UInt8.self)
        let barY = Int(Double(height) * 0.945)
        let startX = Int(Double(width) * 0.26)
        let endX = Int(Double(width) * 0.95)
        let barW = max(10, endX - startX)
        let segW = barW / 10

        var filledSegments = 0
        for s in 0..<10 {
            let sampleX = min(width - 1, startX + s * segW + (segW / 2))
            let offset = barY * bytesPerRow + sampleX * 4
            let b = Int(buffer[offset])
            let g = Int(buffer[offset + 1])
            let r = Int(buffer[offset + 2])

            // Clash Royale purple elixir RGB signature
            if r > 135 && b > 140 && r > g + 30 && b > g + 30 {
                filledSegments = s + 1
            }
        }

        return Double(filledSegments)
    }
}
