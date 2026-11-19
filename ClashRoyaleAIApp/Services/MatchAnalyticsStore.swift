import Foundation

// ============================================================================
// CLASH ROYALE NATIVE iOS - PERSISTENT MATCH DURATION (SECONDS) & TELEMETRY STORE
// ============================================================================

public final class MatchAnalyticsStore: ObservableObject {
    public static let shared = MatchAnalyticsStore()

    @Published public var matches: [MatchRecord] = []
    private let fileURL: URL

    private init() {
        if let containerURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: SharedConfig.appGroupIdentifier) {
            self.fileURL = containerURL.appendingPathComponent("cr_matches_telemetry_v1.json")
        } else {
            let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            self.fileURL = docs.appendingPathComponent("cr_matches_telemetry_v1.json")
        }
        loadMatches()
    }

    public func loadMatches() {
        if let data = try? Data(contentsOf: fileURL),
           let decoded = try? JSONDecoder().decode([MatchRecord].self, from: data),
           !decoded.isEmpty {
            self.matches = decoded
        } else {
            self.matches = Self.buildSampleSeedMatches()
            saveMatches()
        }
    }

    public func saveMatches() {
        guard let data = try? JSONEncoder().encode(matches) else { return }
        try? data.write(to: fileURL, options: .atomic)
    }

    public func recordCompletedMatch(from engine: CRAIEngine, result: MatchResultType, myCrowns: Int, oppCrowns: Int) {
        let durationSec = max(15, engine.elapsedSeconds > 0 ? engine.elapsedSeconds : 165)
        let topPred = engine.deckPredictions.first
        let oppDeckName = topPred?.deck.name ?? "Karma Meta Destesi"
        let oppArchetype = topPred?.deck.archetype ?? "Control"
        let oppCards = !engine.opponentKnownDeckIds.isEmpty
            ? engine.opponentKnownDeckIds
            : (topPred?.deck.cards ?? ["hog_rider", "fireball", "the_log", "cannon"])

        let netTrade = engine.actionLog.reduce(0) { $0 + $1.tradeDelta }
        let critSec = max(20, durationSec - 26)
        let phaseName = critSec >= 240 ? "3x Final Uzatma" : (critSec >= 120 ? "2x Çift İksir" : "1x Normal Süre")

        let turningPoint = result == .win
            ? "\(critSec). saniyede (\(phaseName)) \(oppDeckName) karşısında +\(max(3, netTrade)) iksir pozitif takas yakalayıp \(durationSec). saniyede maçı kazandın."
            : "\(critSec). saniyede (\(phaseName)) iksir farkı açıldığında rakip ters koridor cezalandırması yaptı. Savunma binasını 4-3 kareye 2 sn erken kurarak bu kaybı önleyebilirsin."

        let record = MatchRecord(
            id: UUID(),
            playedAt: Date(),
            result: result,
            myCrowns: myCrowns,
            oppCrowns: oppCrowns,
            durationSeconds: durationSec,
            opponentDeckName: oppDeckName,
            opponentArchetype: oppArchetype,
            opponentCardIds: oppCards,
            myDeckCardIds: engine.myDeckCardIds,
            myTotalElixirSpent: max(20, engine.playerTotalElixirSpent),
            oppTotalElixirSpent: max(20, engine.opponentTotalElixirSpent),
            myLeakSeconds: engine.playerLeakSeconds,
            oppLeakSeconds: engine.opponentLeakSeconds,
            netTradeScore: netTrade,
            keyTurningPointTr: turningPoint,
            timeline: engine.telemetryTimeline,
            actionLog: engine.actionLog
        )

        matches.insert(record, at: 0)
        saveMatches()
    }

    public func deleteMatch(id: UUID) {
        matches.removeAll { $0.id == id }
        saveMatches()
    }

    // MARK: - Computed Deep Analytics Metrics
    public var winRatePercent: Int {
        guard !matches.isEmpty else { return 0 }
        let wins = matches.filter { $0.result == .win }.count
        return Int((Double(wins) / Double(matches.count) * 100.0).rounded())
    }

    public var averageDurationSeconds: Int {
        guard !matches.isEmpty else { return 0 }
        let total = matches.reduce(0) { $0 + $1.durationSeconds }
        return total / matches.count
    }

    public var fastestWinSeconds: Int {
        matches.filter { $0.result == .win }.map { $0.durationSeconds }.min() ?? 0
    }

    public var longestMatchSeconds: Int {
        matches.map { $0.durationSeconds }.max() ?? 0
    }

    public var averageNetElixirTrade: Double {
        guard !matches.isEmpty else { return 0 }
        let sum = matches.reduce(0) { $0 + $1.netTradeScore }
        return (Double(sum) / Double(matches.count) * 10).rounded() / 10.0
    }

    public var phaseDurationBreakdown: [PhaseDurationStats] {
        let buckets: [(id: String, title: String, minSec: Int, maxSec: Int)] = [
            ("1x", "1x Erken Bitiş (0 - 120 sn)", 0, 120),
            ("2x_reg", "2x Son Dakika (121 - 180 sn)", 121, 180),
            ("2x_ot", "2x Uzatma / Ani Ölüm (181 - 240 sn)", 181, 240),
            ("3x_ot", "3x Final Uzatma (241 - 300 sn)", 241, 305)
        ]

        return buckets.map { b in
            let group = matches.filter { $0.durationSeconds >= b.minSec && $0.durationSeconds <= b.maxSec }
            let wins = group.filter { $0.result == .win }.count
            let avgSec = group.isEmpty ? 0 : group.reduce(0) { $0 + $1.durationSeconds } / group.count
            let wr = group.isEmpty ? 0 : Int((Double(wins) / Double(group.count) * 100.0).rounded())
            return PhaseDurationStats(
                id: b.id,
                titleTr: b.title,
                matchCount: group.count,
                wins: wins,
                losses: group.count - wins,
                winRatePercent: wr,
                avgDurationSeconds: avgSec
            )
        }
    }

    public var archetypePerformanceMatrix: [ArchetypePerformanceStats] {
        let archetypes = ["Cycle", "Bait", "Beatdown", "Bridge Spam", "Siege", "Control"]
        return archetypes.compactMap { arch in
            let group = matches.filter { $0.opponentArchetype == arch }
            guard !group.isEmpty else { return nil }
            let wins = group.filter { $0.result == .win }.count
            let wr = Int((Double(wins) / Double(group.count) * 100.0).rounded())
            let avgSec = group.reduce(0) { $0 + $1.durationSeconds } / group.count
            let avgTrade = Double(group.reduce(0) { $0 + $1.netTradeScore }) / Double(group.count)
            return ArchetypePerformanceStats(
                archetype: arch,
                matchCount: group.count,
                winRatePercent: wr,
                avgDurationSeconds: avgSec,
                avgNetTrade: (avgTrade * 10).rounded() / 10.0
            )
        }
    }

    private static func buildSampleSeedMatches() -> [MatchRecord] {
        return [
            MatchRecord(
                id: UUID(),
                playedAt: Date().addingTimeInterval(-1800),
                result: .win,
                myCrowns: 2,
                oppCrowns: 0,
                durationSeconds: 164,
                opponentDeckName: "Klasik Log Bait (Fıçı + Prenses + Roket)",
                opponentArchetype: "Bait",
                opponentCardIds: ["goblin_barrel", "princess", "knight", "goblin_gang", "inferno_tower", "ice_spirit", "rocket", "the_log"],
                myDeckCardIds: ["hog_rider", "musketeer", "cannon", "ice_golem", "skeletons", "ice_spirit", "fireball", "the_log"],
                myTotalElixirSpent: 78,
                oppTotalElixirSpent: 74,
                myLeakSeconds: 1.1,
                oppLeakSeconds: 7.8,
                netTradeScore: 9,
                keyTurningPointTr: "138. saniyede (2x İksir) rakip Roket (6💧) attığı an ters köprüden Domuz Binicisi ile cezalandırıp 164. saniyede kazandın.",
                timeline: [
                    SecondTelemetryPoint(second: 0, myElixir: 6, oppElixir: 6, phaseMultiplier: 1),
                    SecondTelemetryPoint(second: 60, myElixir: 7.5, oppElixir: 5.0, phaseMultiplier: 1),
                    SecondTelemetryPoint(second: 120, myElixir: 8.2, oppElixir: 4.5, phaseMultiplier: 2),
                    SecondTelemetryPoint(second: 164, myElixir: 6.4, oppElixir: 1.8, phaseMultiplier: 2)
                ],
                actionLog: []
            ),
            MatchRecord(
                id: UUID(),
                playedAt: Date().addingTimeInterval(-5400),
                result: .win,
                myCrowns: 1,
                oppCrowns: 0,
                durationSeconds: 218,
                opponentDeckName: "P.E.K.K.A Bridge Spam",
                opponentArchetype: "Bridge Spam",
                opponentCardIds: ["pekka", "battle_ram", "bandit", "royal_ghost", "electro_wizard", "magic_archer", "fireball", "zap"],
                myDeckCardIds: ["hog_rider", "musketeer", "cannon", "ice_golem", "skeletons", "ice_spirit", "fireball", "the_log"],
                myTotalElixirSpent: 112,
                oppTotalElixirSpent: 109,
                myLeakSeconds: 1.8,
                oppLeakSeconds: 6.4,
                netTradeScore: 12,
                keyTurningPointTr: "194. saniyede (2x Uzatma) P.E.K.K.A'yı Buz Golemi ile ters koridora uçurtma (Kite) yapıp +5 iksir kazandın ve 218. saniyede Ani Ölüm'de bitirdin.",
                timeline: [
                    SecondTelemetryPoint(second: 0, myElixir: 6, oppElixir: 6, phaseMultiplier: 1),
                    SecondTelemetryPoint(second: 120, myElixir: 6.5, oppElixir: 6.0, phaseMultiplier: 2),
                    SecondTelemetryPoint(second: 180, myElixir: 8.0, oppElixir: 4.2, phaseMultiplier: 2),
                    SecondTelemetryPoint(second: 218, myElixir: 7.2, oppElixir: 2.0, phaseMultiplier: 2)
                ],
                actionLog: []
            ),
            MatchRecord(
                id: UUID(),
                playedAt: Date().addingTimeInterval(-9000),
                result: .win,
                myCrowns: 3,
                oppCrowns: 1,
                durationSeconds: 112,
                opponentDeckName: "Golem + Gece Cadısı Beatdown",
                opponentArchetype: "Beatdown",
                opponentCardIds: ["golem", "night_witch", "lumberjack", "baby_dragon", "electro_dragon", "tornado", "lightning", "barbarian_barrel"],
                myDeckCardIds: ["hog_rider", "musketeer", "cannon", "ice_golem", "skeletons", "ice_spirit", "fireball", "the_log"],
                myTotalElixirSpent: 52,
                oppTotalElixirSpent: 48,
                myLeakSeconds: 0.0,
                oppLeakSeconds: 5.3,
                netTradeScore: 11,
                keyTurningPointTr: "42. saniyede (1x İksir) rakip arkadan 8 iksirlik Golem açtığı an ters koridordan saldırıp 112. saniyede 3 Taç ile bitirdin.",
                timeline: [
                    SecondTelemetryPoint(second: 0, myElixir: 6, oppElixir: 6, phaseMultiplier: 1),
                    SecondTelemetryPoint(second: 45, myElixir: 8.5, oppElixir: 1.5, phaseMultiplier: 1),
                    SecondTelemetryPoint(second: 112, myElixir: 7.0, oppElixir: 2.2, phaseMultiplier: 1)
                ],
                actionLog: []
            )
        ]
    }
}
