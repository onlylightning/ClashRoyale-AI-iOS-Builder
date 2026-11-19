import SwiftUI

// ============================================================================
// CLASH ROYALE NATIVE iOS - MY 8-CARD DECK & META PRESET SELECTOR
// ============================================================================

public struct MyDeckBuilderView: View {
    @EnvironmentObject var engine: CRAIEngine

    public init() {}

    private var myCards: [CRCard] {
        engine.myDeckCardIds.compactMap { CRDatabase.shared.cardById[$0] }
    }

    private var avgElixir: Double {
        guard !myCards.isEmpty else { return 0 }
        let sum = myCards.reduce(0) { $0 + $1.elixir }
        return Double(sum) / Double(myCards.count)
    }

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {

                    // 1. CURRENT 8-CARD DECK
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("🃏 Aktif Destem (8 Kart)")
                                .font(.headline)
                            Spacer()
                            Text(String(format: "Ort. İksir: %.1f💧", avgElixir))
                                .font(.caption.bold())
                                .foregroundStyle(.cyan)
                        }

                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 8) {
                            ForEach(myCards) { card in
                                VStack(spacing: 3) {
                                    Text("\(card.elixir)💧")
                                        .font(.caption2.bold())
                                        .foregroundStyle(.cyan)
                                    Text(card.nameTr)
                                        .font(.caption.bold())
                                        .lineLimit(1)
                                        .minimumScaleFactor(0.75)
                                }
                                .padding(9)
                                .frame(maxWidth: .infinity)
                                .background(Color.cyan.opacity(0.18))
                                .clipShape(RoundedRectangle(cornerRadius: 9))
                            }
                        }
                    }
                    .padding(12)
                    .background(Color(red: 0.08, green: 0.12, blue: 0.22))
                    .clipShape(RoundedRectangle(cornerRadius: 14))

                    // 2. PRESET META DECKS
                    VStack(alignment: .leading, spacing: 8) {
                        Text("⚡ Hazır Meta Destelerinden Tek Dokunuşla Seç")
                            .font(.headline)

                        ForEach(CRDatabase.shared.metaDecks) { deck in
                            Button {
                                engine.setMyDeck(deck.cards)
                            } label: {
                                HStack {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(deck.name)
                                            .font(.subheadline.bold())
                                            .foregroundStyle(.white)
                                        Text("\(deck.archetype) • \(String(format: "%.1f", deck.avgElixir))💧")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                    Spacer()
                                    Text("Seç")
                                        .font(.caption.bold())
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 5)
                                        .background(Color.cyan.opacity(0.25))
                                        .foregroundStyle(.cyan)
                                        .clipShape(Capsule())
                                }
                                .padding(10)
                                .background(Color.white.opacity(0.05))
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                            }
                        }
                    }
                    .padding(12)
                    .background(Color(red: 0.08, green: 0.12, blue: 0.22))
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
            }
            .background(Color(red: 0.04, green: 0.06, blue: 0.12).ignoresSafeArea())
            .navigationTitle("🃏 Destem")
        }
    }
}
