import Foundation

// ============================================================================
// CLASH ROYALE NATIVE iOS - SECOND-BY-SECOND MATCH TELEMETRY & ANALYTICS MODELS
// ============================================================================

public enum MatchResultType: String, Codable, CaseIterable {
    case win = "WIN"
    case loss = "LOSS"

    public var titleTr: String {
        switch self {
        case .win: return "Galibiyet"
        case .loss: return "Mağlubiyet"
        }
    }
}

public struct SecondTelemetryPoint: Codable, Identifiable, Hashable {
    public var id: Int { second }
    public let second: Int
    public let myElixir: Double
    public let oppElixir: Double
    public let diff: Double
    public let phaseMultiplier: Int

    public init(second: Int, myElixir: Double, oppElixir: Double, phaseMultiplier: Int) {
        self.second = second
        self.myElixir = myElixir
        self.oppElixir = oppElixir
        self.diff = myElixir - oppElixir
        self.phaseMultiplier = phaseMultiplier
    }
}

public struct MatchActionEvent: Codable, Identifiable, Hashable {
    public let id: UUID
    public let timestampSec: Int
    public let actor: String // "opp" or "me"
    public let cardId: String
    public let cardNameTr: String
    public let elixirCost: Int
    public let oppElixirAfter: Double
    public let myElixirAfter: Double
    public let tradeDelta: Int
    public let tacticalNote: String

    public var formattedTime: String {
        let mins = timestampSec / 60
        let secs = timestampSec % 60
        return String(format: "%02d:%02d (%d. sn)", mins, secs, timestampSec)
    }

    public init(
        id: UUID = UUID(),
        timestampSec: Int,
        actor: String,
        cardId: String,
        cardNameTr: String,
        elixirCost: Int,
        oppElixirAfter: Double,
        myElixirAfter: Double,
        tradeDelta: Int,
        tacticalNote: String
    ) {
        self.id = id
        self.timestampSec = timestampSec
        self.actor = actor
        self.cardId = cardId
        self.cardNameTr = cardNameTr
        self.elixirCost = elixirCost
        self.oppElixirAfter = oppElixirAfter
        self.myElixirAfter = myElixirAfter
        self.tradeDelta = tradeDelta
        self.tacticalNote = tacticalNote
    }
}

public struct MatchRecord: Codable, Identifiable, Hashable {
    public let id: UUID
    public let playedAt: Date
    public let result: MatchResultType
    public let myCrowns: Int
    public let oppCrowns: Int
    /// Exact match duration in seconds (e.g. 112 sn, 164 sn, 218 sn, 284 sn)
    public let durationSeconds: Int
    public let opponentDeckName: String
    public let opponentArchetype: String
    public let opponentCardIds: [String]
    public let myDeckCardIds: [String]
    public let myTotalElixirSpent: Int
    public let oppTotalElixirSpent: Int
    public let myLeakSeconds: Double
    public let oppLeakSeconds: Double
    public let netTradeScore: Int
    public let keyTurningPointTr: String
    public let timeline: [SecondTelemetryPoint]
    public let actionLog: [MatchActionEvent]

    public var durationFormatted: String {
        let mins = durationSeconds / 60
        let secs = durationSeconds % 60
        return String(format: "%02d:%02d (%d sn)", mins, secs, durationSeconds)
    }

    public var endPhaseTitleTr: String {
        if durationSeconds <= 120 {
            return "1x Normal Süre (0-120 sn)"
        } else if durationSeconds <= 180 {
            return "2x Son Dakika (121-180 sn)"
        } else if durationSeconds <= 240 {
            return "2x Uzatma / Ani Ölüm (181-240 sn)"
        } else if durationSeconds < 300 {
            return "3x Final Uzatma (241-299 sn)"
        } else {
            return "Tiebreaker / Kule Erime (300 sn)"
        }
    }
}

public struct PhaseDurationStats: Identifiable {
    public let id: String
    public let titleTr: String
    public let matchCount: Int
    public let wins: Int
    public let losses: Int
    public let winRatePercent: Int
    public let avgDurationSeconds: Int
}

public struct ArchetypePerformanceStats: Identifiable {
    public var id: String { archetype }
    public let archetype: String
    public let matchCount: Int
    public let winRatePercent: Int
    public let avgDurationSeconds: Int
    public let avgNetTrade: Double
}
