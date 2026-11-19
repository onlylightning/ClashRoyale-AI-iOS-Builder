import Foundation
import CoreFoundation

// ============================================================================
// SHARED CONFIGURATION & DARWIN IPC BRIDGE
// Connects ReplayKit Broadcast Extension -> Main iOS App (PiP + Voice Coach)
// ============================================================================

public enum SharedConfig {
    /// Xcode Signing & Capabilities -> App Groups identifier
    public static let appGroupIdentifier = "group.com.clashroyale.aicoach"

    /// Darwin system-wide notifications for <5ms IPC between ReplayKit Extension and Main App
    public static let darwinFrameEventNotification = "com.clashroyale.aicoach.frameEvent"
    public static let darwinMatchLifecycleNotification = "com.clashroyale.aicoach.matchLifecycle"

    /// Shared UserDefaults keys
    public static let latestVisionPayloadKey = "cr_latest_vision_payload_v1"
    public static let broadcastActiveKey = "cr_broadcast_active_v1"
}

/// Real-time frame detection payload emitted by ReplayKit Broadcast Upload Extension
public struct VisionFramePayload: Codable {
    public let timestamp: TimeInterval
    public let detectedOpponentCardId: String?
    public let detectedMyCardId: String?
    public let detectedMyElixirBar: Double?
    public let detectedMatchClockSeconds: Int?
    public let detectedMultiplierPhase: Int? // 1, 2, or 3
    public let isMatchOver: Bool
    public let confidence: Double

    public init(
        timestamp: TimeInterval = Date().timeIntervalSince1970,
        detectedOpponentCardId: String? = nil,
        detectedMyCardId: String? = nil,
        detectedMyElixirBar: Double? = nil,
        detectedMatchClockSeconds: Int? = nil,
        detectedMultiplierPhase: Int? = nil,
        isMatchOver: Bool = false,
        confidence: Double = 0.95
    ) {
        self.timestamp = timestamp
        self.detectedOpponentCardId = detectedOpponentCardId
        self.detectedMyCardId = detectedMyCardId
        self.detectedMyElixirBar = detectedMyElixirBar
        self.detectedMatchClockSeconds = detectedMatchClockSeconds
        self.detectedMultiplierPhase = detectedMultiplierPhase
        self.isMatchOver = isMatchOver
        self.confidence = confidence
    }
}

/// Cross-process IPC Bus using App Group UserDefaults + Darwin Notification Center
public final class ReplayKitIPCBridge {
    public static let shared = ReplayKitIPCBridge()
    private let sharedDefaults: UserDefaults?
    private var onPayloadCallback: ((VisionFramePayload) -> Void)?

    private init() {
        self.sharedDefaults = UserDefaults(suiteName: SharedConfig.appGroupIdentifier)
    }

    public func setBroadcastActive(_ active: Bool) {
        sharedDefaults?.set(active, forKey: SharedConfig.broadcastActiveKey)
        sharedDefaults?.synchronize()
        postDarwinNotification(name: SharedConfig.darwinMatchLifecycleNotification)
    }

    public var isBroadcastActive: Bool {
        sharedDefaults?.bool(forKey: SharedConfig.broadcastActiveKey) ?? false
    }

    /// Called by ReplayKit Broadcast Upload Extension when a card or clock event is detected on Clash Royale screen
    public func publishVisionPayload(_ payload: VisionFramePayload) {
        guard let data = try? JSONEncoder().encode(payload) else { return }
        sharedDefaults?.set(data, forKey: SharedConfig.latestVisionPayloadKey)
        sharedDefaults?.synchronize()
        postDarwinNotification(name: SharedConfig.darwinFrameEventNotification)
    }

    /// Called by Main iOS App to read the latest frame detection from ReplayKit
    public func readLatestPayload() -> VisionFramePayload? {
        guard let data = sharedDefaults?.data(forKey: SharedConfig.latestVisionPayloadKey),
              let payload = try? JSONDecoder().decode(VisionFramePayload.self, from: data) else {
            return nil
        }
        return payload
    }

    /// Starts listening for real-time Darwin notifications from ReplayKit Extension
    public func startObservingInMainApp(onReceive: @escaping (VisionFramePayload) -> Void) {
        self.onPayloadCallback = onReceive
        let center = CFNotificationCenterGetDarwinNotifyCenter()
        let observer = UnsafeRawPointer(Unmanaged.passUnretained(self).toOpaque())

        CFNotificationCenterAddObserver(
            center,
            observer,
            { (_, observerPtr, _, _, _) in
                guard let observerPtr = observerPtr else { return }
                let bridge = Unmanaged<ReplayKitIPCBridge>.fromOpaque(observerPtr).takeUnretainedValue()
                if let payload = bridge.readLatestPayload() {
                    DispatchQueue.main.async {
                        bridge.onPayloadCallback?(payload)
                    }
                }
            },
            SharedConfig.darwinFrameEventNotification as CFString,
            nil,
            .deliverImmediately
        )
    }

    private func postDarwinNotification(name: String) {
        let center = CFNotificationCenterGetDarwinNotifyCenter()
        CFNotificationCenterPostNotification(
            center,
            CFNotificationName(name as CFString),
            nil,
            nil,
            true
        )
    }
}
