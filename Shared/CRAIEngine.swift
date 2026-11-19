import Foundation
import Combine

// ============================================================================
// CLASH ROYALE NATIVE iOS - CORE AI STRATEGY ENGINE
// Live Elixir Physics | 8-Card FIFO Cycle & Evolution | Meta Deck Predictor |
// Positive Elixir Trade Counter Engine | Punish Window & Spell Lethal Detector
// ============================================================================

public struct CycleCardSlot: Identifiable, Hashable {
    public let id: Int
    public let card: CRCard?
    public let isConfirmed: Bool
    public let isPredictedFromMeta: Bool
    public let cardsUntilInHand: Int // 0 = currently in opponent's hand; 1..4 = in queue
    public let isEvolutionReady: Bool
    public let evolutionProgressText: String?
}

public struct DeckPredictionMatch: Identifiable, Hashable {
    public var id: String { deck.id }
    public let deck: CRMetaDeck
    public let confidencePercent: Int
    public let matchedCardIds: [String]
    public let unrevealedCards: [CRCard]
}

public struct CounterRecommendation: Identifiable, Hashable {
    public var id: String { counterCard.id }
    public let counterCard: CRCard
    public let placement: ArenaPlacementZone
    public let tipTr: String
    public let netElixirTrade: Int
    public let isInMyDeck: Bool
    public let isInMyCurrentHand: Bool
}

public struct TacticalAlertBanner: Identifiable, Hashable {
    public let id = UUID()
    public let severity: String // "CRITICAL", "EVO", "PUNISH", "INFO"
    public let titleTr: String
    public let detailTr: String
}

public final class CRAIEngine: ObservableObject {
    public static let shared = CRAIEngine()

    // MARK: - Published Real-Time State for SwiftUI & PiP Overlay
    @Published public var isRunning: Bool = false
    @Published public var elapsedSeconds: Int = 0
    @Published public var opponentElixir: Double = 6.0
    @Published public var playerElixir: Double = 6.0
    @Published public var opponentLeakSeconds: Double = 0.0
    @Published public var playerLeakSeconds: Double = 0.0

    @Published public var myDeckCardIds: [String] = [
        "hog_rider", "musketeer", "cannon", "ice_golem",
        "skeletons", "ice_spirit", "fireball", "the_log"
    ]
    @Published public var myHandCardIds: [String] = ["hog_rider", "musketeer", "cannon", "ice_golem"]
    @Published public var myQueueCardIds: [String] = ["skeletons", "ice_spirit", "fireball", "the_log"]

    @Published public var opponentKnownDeckIds: [String] = []
    @Published public var opponentRecentQueueIds: [String] = [] // Max 4 FIFO
    @Published public var opponentPlayCounts: [String: Int] = [:]

    @Published public var lastOpponentCard: CRCard? = nil
    @Published public var opponentHandSlots: [CycleCardSlot] = []
    @Published public var opponentQueueSlots: [CycleCardSlot] = []
    @Published public var deckPredictions: [DeckPredictionMatch] = []
    @Published public var recommendedCounters: [CounterRecommendation] = []
    @Published public var tacticalAlerts: [TacticalAlertBanner] = []
    @Published public var opponentTowerHP: Int = 3052

    @Published public var actionLog: [MatchActionEvent] = []
    @Published public var telemetryTimeline: [SecondTelemetryPoint] = []

    public var opponentTotalElixirSpent: Int = 0
    public var playerTotalElixirSpent: Int = 0

    private var timer: Timer?
    private var lastTickTimestamp: TimeInterval = 0
    private var exactElapsed: Double = 0
    private var lastRecordedWholeSecond: Int = -1

    public init() {
        rebuildCycleAndPredictions()
    }

    // MARK: - Match Lifecycle
    public func startMatch() {
        if !isRunning {
            isRunning = true
            lastTickTimestamp = Date().timeIntervalSince1970
            timer?.invalidate()
            timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
                self?.tick()
            }
        }
    }

    public func stopMatch() {
        isRunning = false
        timer?.invalidate()
        timer = nil
    }

    public func resetMatch() {
        stopMatch()
        elapsedSeconds = 0
        exactElapsed = 0
        lastRecordedWholeSecond = -1
        opponentElixir = 6.0
        playerElixir = 6.0
        opponentLeakSeconds = 0.0
        playerLeakSeconds = 0.0
        opponentTotalElixirSpent = 0
        playerTotalElixirSpent = 0
        opponentKnownDeckIds = []
        opponentRecentQueueIds = []
        opponentPlayCounts = [:]
        lastOpponentCard = nil
        actionLog = []
        telemetryTimeline = []
        opponentTowerHP = 3052
        rebuildCycleAndPredictions()
    }

    public func setMyDeck(_ cardIds: [String]) {
        guard cardIds.count == 8 else { return }
        myDeckCardIds = cardIds
        myHandCardIds = Array(cardIds.prefix(4))
        myQueueCardIds = Array(cardIds.suffix(4))
        rebuildCycleAndPredictions()
    }

    // MARK: - Elixir Generation Physics (1x = 2.8s, 2x = 1.4s, 3x = 0.933s)
    public var currentPhaseMultiplier: Int {
        if elapsedSeconds < 120 { return 1 }
        if elapsedSeconds < 240 { return 2 }
        return 3
    }

    public var currentElixirRatePerSecond: Double {
        switch currentPhaseMultiplier {
        case 1: return 1.0 / 2.8
        case 2: return 1.0 / 1.4
        default: return 3.0 / 2.8
        }
    }

    private func tick() {
        guard isRunning else { return }
        let now = Date().timeIntervalSince1970
        let dt = max(0, min(0.5, now - lastTickTimestamp))
        lastTickTimestamp = now

        exactElapsed += dt
        elapsedSeconds = Int(exactElapsed)

        let gain = dt * currentElixirRatePerSecond

        if opponentElixir >= 10.0 {
            opponentElixir = 10.0
            opponentLeakSeconds += dt
        } else {
            opponentElixir = min(10.0, opponentElixir + gain)
        }

        if playerElixir >= 10.0 {
            playerElixir = 10.0
            playerLeakSeconds += dt
        } else {
            playerElixir = min(10.0, playerElixir + gain)
        }

        if elapsedSeconds > lastRecordedWholeSecond {
            lastRecordedWholeSecond = elapsedSeconds
            telemetryTimeline.append(
                SecondTelemetryPoint(
                    second: elapsedSeconds,
                    myElixir: playerElixir,
                    oppElixir: opponentElixir,
                    phaseMultiplier: currentPhaseMultiplier
                )
            )
            rebuildAlerts()
        }

        if elapsedSeconds >= 300 {
            stopMatch()
        }
    }

    // MARK: - Opponent & Player Card Play Handlers (From ReplayKit Vision or Manual Tap)
    @discardableResult
    public func registerOpponentCardPlayed(_ cardId: String) -> CounterRecommendation? {
        guard let card = CRDatabase.shared.cardById[cardId] else { return nil }
        if !isRunning { startMatch() }

        opponentElixir = max(0.0, opponentElixir - Double(card.elixir))
        opponentTotalElixirSpent += card.elixir
        lastOpponentCard = card

        if !opponentKnownDeckIds.contains(cardId) && opponentKnownDeckIds.count < 8 {
            opponentKnownDeckIds.append(cardId)
        }

        // Update FIFO 4-Card Waiting Queue
        opponentRecentQueueIds.removeAll { $0 == cardId }
        opponentRecentQueueIds.append(cardId)
        if opponentRecentQueueIds.count > 4 {
            opponentRecentQueueIds.removeFirst()
        }

        opponentPlayCounts[cardId, default: 0] += 1

        rebuildCycleAndPredictions()

        let bestCounter = recommendedCounters.first
        let note = bestCounter != nil
            ? "Öneri: \(bestCounter!.counterCard.nameTr) (\(bestCounter!.placement.rawValue)) [+\(bestCounter!.netElixirTrade)💧]"
            : "Rakip hamlesi"

        actionLog.insert(
            MatchActionEvent(
                timestampSec: elapsedSeconds,
                actor: "opp",
                cardId: card.id,
                cardNameTr: card.nameTr,
                elixirCost: card.elixir,
                oppElixirAfter: opponentElixir,
                myElixirAfter: playerElixir,
                tradeDelta: bestCounter?.netElixirTrade ?? 0,
                tacticalNote: note
            ),
            at: 0
        )

        return bestCounter
    }

    public func registerMyCardPlayed(_ cardId: String) {
        guard let card = CRDatabase.shared.cardById[cardId] else { return }
        if !isRunning { startMatch() }

        playerElixir = max(0.0, playerElixir - Double(card.elixir))
        playerTotalElixirSpent += card.elixir

        if let handIdx = myHandCardIds.firstIndex(of: cardId), !myQueueCardIds.isEmpty {
            let nextCard = myQueueCardIds.removeFirst()
            myHandCardIds[handIdx] = nextCard
            myQueueCardIds.append(cardId)
        }

        let tradeDelta = (lastOpponentCard?.elixir ?? card.elixir) - card.elixir
        actionLog.insert(
            MatchActionEvent(
                timestampSec: elapsedSeconds,
                actor: "me",
                cardId: card.id,
                cardNameTr: card.nameTr,
                elixirCost: card.elixir,
                oppElixirAfter: opponentElixir,
                myElixirAfter: playerElixir,
                tradeDelta: tradeDelta,
                tacticalNote: "Savunma / Karşı Hamle"
            ),
            at: 0
        )

        rebuildCycleAndPredictions()
    }

    // MARK: - 8-Card Cycle Reconstruction, Meta Deck Predictor & Counter Matrix
    private func rebuildCycleAndPredictions() {
        // 1. Meta Deck Matcher
        deckPredictions = computeMetaDeckPredictions()

        // 2. Reconstruct Opponent's 4 In-Hand Cards & 4 Queue Cards
        let confirmedInHandIds = opponentKnownDeckIds.filter { !opponentRecentQueueIds.contains($0) }
        var predictedPool: [String] = []
        if let topDeck = deckPredictions.first, topDeck.confidencePercent >= 25 {
            predictedPool = topDeck.deck.cards.filter { !opponentKnownDeckIds.contains($0) }
        }

        var handSlots: [CycleCardSlot] = []
        for idx in 0..<4 {
            if idx < confirmedInHandIds.count {
                let cId = confirmedInHandIds[idx]
                handSlots.append(makeSlot(slotId: idx, cardId: cId, confirmed: true, predicted: false, dist: 0))
            } else if !predictedPool.isEmpty {
                let predId = predictedPool.removeFirst()
                handSlots.append(makeSlot(slotId: idx, cardId: predId, confirmed: false, predicted: true, dist: 0))
            } else {
                handSlots.append(
                    CycleCardSlot(
                        id: idx, card: nil, isConfirmed: false, isPredictedFromMeta: false,
                        cardsUntilInHand: 0, isEvolutionReady: false, evolutionProgressText: nil
                    )
                )
            }
        }
        self.opponentHandSlots = handSlots

        var queueSlots: [CycleCardSlot] = []
        for dist in 1...4 {
            let idxFromEnd = 4 - dist
            let qIndex = opponentRecentQueueIds.count - 1 - idxFromEnd
            if qIndex >= 0 && qIndex < opponentRecentQueueIds.count {
                let cId = opponentRecentQueueIds[qIndex]
                queueSlots.append(makeSlot(slotId: 10 + dist, cardId: cId, confirmed: true, predicted: false, dist: dist))
            } else {
                queueSlots.append(
                    CycleCardSlot(
                        id: 10 + dist, card: nil, isConfirmed: false, isPredictedFromMeta: false,
                        cardsUntilInHand: dist, isEvolutionReady: false, evolutionProgressText: nil
                    )
                )
            }
        }
        self.opponentQueueSlots = queueSlots

        // 3. Recompute Counter Recommendations for Last Opponent Card
        computeCounterRecommendations()

        // 4. Recompute Punish & Evolution Alerts
        rebuildAlerts()
    }

    private func makeSlot(slotId: Int, cardId: String, confirmed: Bool, predicted: Bool, dist: Int) -> CycleCardSlot {
        let card = CRDatabase.shared.cardById[cardId]
        let plays = opponentPlayCounts[cardId, default: 0]
        var evoReady = false
        var evoText: String? = nil

        if let evoCycles = card?.evoCycles {
            let mod = plays % (evoCycles + 1)
            evoReady = (mod == evoCycles)
            evoText = "\(mod)/\(evoCycles)"
        }

        return CycleCardSlot(
            id: slotId,
            card: card,
            isConfirmed: confirmed,
            isPredictedFromMeta: predicted,
            cardsUntilInHand: dist,
            isEvolutionReady: evoReady,
            evolutionProgressText: evoText
        )
    }

    private func computeMetaDeckPredictions() -> [DeckPredictionMatch] {
        guard !opponentKnownDeckIds.isEmpty else { return [] }
        let seenCount = opponentKnownDeckIds.count

        var matches: [DeckPredictionMatch] = []
        for deck in CRDatabase.shared.metaDecks {
            let matchedIds = opponentKnownDeckIds.filter { deck.cards.contains($0) }
            guard !matchedIds.isEmpty else { continue }

            let sigMatches = matchedIds.filter { deck.signatureCards.contains($0) }.count
            let mismatchCount = seenCount - matchedIds.count

            let precision = Double(matchedIds.count) / Double(seenCount)
            let coverage = Double(matchedIds.count) / 8.0
            var score = (precision * 62.0) + (coverage * 28.0) + (Double(sigMatches) * 11.0) - (Double(mismatchCount) * 14.0)

            if seenCount == 1 && sigMatches == 1 {
                score = max(score, 65.0)
            }
            if matchedIds.count >= 3 && mismatchCount == 0 {
                score = max(score, 89.0 + Double(matchedIds.count - 3) * 2.5)
            }

            let confidence = max(10, min(99, Int(score.rounded())))
            let unrevealed = deck.cards
                .filter { !opponentKnownDeckIds.contains($0) }
                .compactMap { CRDatabase.shared.cardById[$0] }

            matches.append(
                DeckPredictionMatch(
                    deck: deck,
                    confidencePercent: confidence,
                    matchedCardIds: matchedIds,
                    unrevealedCards: unrevealed
                )
            )
        }

        return matches
            .filter { $0.confidencePercent >= 25 }
            .sorted { $0.confidencePercent > $1.confidencePercent }
    }

    private func computeCounterRecommendations() {
        guard let threat = lastOpponentCard else {
            recommendedCounters = []
            return
        }

        var list: [CounterRecommendation] = []
        for rule in threat.counters {
            guard let counterCard = CRDatabase.shared.cardById[rule.counterCardId] else { continue }
            let netTrade = threat.elixir - counterCard.elixir
            let inMyDeck = myDeckCardIds.contains(counterCard.id)
            let inMyHand = myHandCardIds.contains(counterCard.id)

            list.append(
                CounterRecommendation(
                    counterCard: counterCard,
                    placement: rule.placement,
                    tipTr: rule.tacticalTipTr,
                    netElixirTrade: netTrade,
                    isInMyDeck: inMyDeck,
                    isInMyCurrentHand: inMyHand
                )
            )
        }

        recommendedCounters = list.sorted { a, b in
            if a.isInMyCurrentHand != b.isInMyCurrentHand { return a.isInMyCurrentHand }
            if a.isInMyDeck != b.isInMyDeck { return a.isInMyDeck }
            return a.netElixirTrade > b.netElixirTrade
        }
    }

    private func rebuildAlerts() {
        var alerts: [TacticalAlertBanner] = []
        let diff = playerElixir - opponentElixir

        // 1. Heavy Investment Punish Window
        if let last = lastOpponentCard, last.elixir >= 6, opponentElixir <= 3.5 {
            alerts.append(
                TacticalAlertBanner(
                    severity: "PUNISH",
                    titleTr: "🔥 TERS KORİDOR CEZALANDIRMA! Rakip \(last.nameTr) (\(last.elixir)💧) Attı!",
                    detailTr: "Rakibin sadece \(String(format: "%.1f", opponentElixir)) iksiri kaldı. Hemen ters köprüden saldır!"
                )
            )
        }

        // 2. Evolution Ready in Opponent's Hand
        for slot in opponentHandSlots where slot.isEvolutionReady {
            if let c = slot.card {
                alerts.append(
                    TacticalAlertBanner(
                        severity: "EVO",
                        titleTr: "🟣 EVRİM UYARISI: Rakibin Elinde EVRİMLİ \(c.nameTr.uppercased()) Hazır!",
                        detailTr: "Rakibin bir sonraki \(c.nameTr) atışı EVRİMLİ olacak. Ana savunma kartını elinde tut!"
                    )
                )
            }
        }

        // 3. Out-of-Cycle Building / Small Spell Window
        let recentlyUsed = opponentRecentQueueIds.suffix(2).compactMap { CRDatabase.shared.cardById[$0] }
        for used in recentlyUsed where used.role == .building || used.id == "the_log" || used.id == "tornado" {
            alerts.append(
                TacticalAlertBanner(
                    severity: "CRITICAL",
                    titleTr: "🎯 DÖNGÜ AÇIĞI: Rakibin Elinde \(used.nameTr) YOK!",
                    detailTr: "\(used.nameTr) tekrar eline dönene kadar 3-4 kart atması şart. Şimdi atak kartınla saldır!"
                )
            )
        }

        // 4. Big Elixir Lead
        if diff >= 3.0 && playerElixir >= 5.0 {
            alerts.append(
                TacticalAlertBanner(
                    severity: "INFO",
                    titleTr: "⚡ +\(String(format: "%.1f", diff)) İKSİR ÖNDESİN!",
                    detailTr: "Rakip iksir dolduramadan baskı kurma zamanı."
                )
            )
        }

        self.tacticalAlerts = alerts
    }
}
