import SwiftUI

// ============================================================================
// CLASH ROYALE NATIVE iOS - MATCH DURATION (SECONDS) & TELEMETRY ANALYTICS VIEW
// ============================================================================

public struct AnalyticsDashboardView: View {
    @EnvironmentObject var analytics: MatchAnalyticsStore

    public init() {}

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 14) {
                    // 1. KPI SUMMARY GRID (WIN RATE, AVG SECONDS, FASTEST WIN, LONGEST MATCH)
                    kpiSummaryGrid

                    // 2. PHASE & DURATION (SECONDS) BREAKDOWN
                    phaseDurationCard

                    // 3. ARCHETYPE WIN-RATE & AVG DURATION MATRIX
                    archetypeMatrixCard

                    // 4. RECORDED MATCH HISTORY (WITH EXACT SECONDS & TURNING POINT)
                    matchHistorySection
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
            }
            .background(Color(red: 0.04, green: 0.06, blue: 0.12).ignoresSafeArea())
            .navigationTitle("📊 Maç & Süre Analizi")
        }
    }

    private var kpiSummaryGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
            kpiBox(
                title: "KAZANMA ORANI",
                value: "%\(analytics.winRatePercent)",
                subtitle: "Toplam \(analytics.matches.count) Maç",
                color: .green
            )
            kpiBox(
                title: "ORT. MAÇ SÜRESİ",
                value: "\(analytics.averageDurationSeconds) sn",
                subtitle: String(format: "%02d:%02d Dakika", analytics.averageDurationSeconds / 60, analytics.averageDurationSeconds % 60),
                color: .yellow
            )
            kpiBox(
                title: "EN HIZLI GALİBİYET",
                value: "\(analytics.fastestWinSeconds) sn",
                subtitle: "1x Normal Süre Bitişi",
                color: .cyan
            )
            kpiBox(
                title: "EN UZUN MAÇ",
                value: "\(analytics.longestMatchSeconds) sn",
                subtitle: "Uzatma / 3x İksir Fazı",
                color: .purple
            )
        }
    }

    private func kpiBox(title: String, value: String, subtitle: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption2.bold())
                .foregroundStyle(.secondary)
            Text(value)
                .font(.system(size: 24, weight: .black, design: .monospaced))
                .foregroundStyle(color)
            Text(subtitle)
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.8))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Color(red: 0.08, green: 0.12, blue: 0.22))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var phaseDurationCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("⏱️ Maç Süresi (Saniye) & İksir Fazı Dağılımı")
                .font(.headline)

            ForEach(analytics.phaseDurationBreakdown) { phase in
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(phase.titleTr)
                            .font(.caption.bold())
                        Spacer()
                        Text("%\(phase.winRatePercent) Kazanma (\(phase.wins)G/\(phase.losses)M)")
                            .font(.caption.bold())
                            .foregroundStyle(.green)
                    }
                    ProgressView(value: Double(phase.winRatePercent), total: 100.0)
                        .tint(.cyan)
                    HStack {
                        Text("\(phase.matchCount) Maç")
                        Spacer()
                        Text("Ort. Süre: \(phase.avgDurationSeconds) saniye")
                            .fontWeight(.semibold)
                            .foregroundStyle(.yellow)
                    }
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                }
                .padding(9)
                .background(Color.white.opacity(0.05))
                .clipShape(RoundedRectangle(cornerRadius: 9))
            }
        }
        .padding(12)
        .background(Color(red: 0.08, green: 0.12, blue: 0.22))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    private var archetypeMatrixCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("🏆 Rakip Arketiplere Göre Süre & Performans")
                .font(.headline)

            ForEach(analytics.archetypePerformanceMatrix) { item in
                HStack {
                    Text(item.archetype)
                        .font(.subheadline.bold())
                        .frame(width: 95, alignment: .leading)
                    Text("%\(item.winRatePercent) WR")
                        .font(.caption.bold())
                        .foregroundStyle(.green)
                    Spacer()
                    Text("Ort: \(item.avgDurationSeconds) sn")
                        .font(.caption.monospaced().bold())
                        .foregroundStyle(.yellow)
                    Text("(+\(String(format: "%.1f", item.avgNetTrade))💧)")
                        .font(.caption.bold())
                        .foregroundStyle(.cyan)
                }
                .padding(.vertical, 6)
                Divider().background(Color.white.opacity(0.1))
            }
        }
        .padding(12)
        .background(Color(red: 0.08, green: 0.12, blue: 0.22))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    private var matchHistorySection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("📜 Saniye Bazlı Maç Geçmişi")
                .font(.headline)

            ForEach(analytics.matches) { match in
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text(match.result == .win ? "🏆 GALİBİYET (\(match.myCrowns)-\(match.oppCrowns))" : "❌ MAĞLUBİYET (\(match.myCrowns)-\(match.oppCrowns))")
                            .font(.subheadline.weight(.black))
                            .foregroundStyle(match.result == .win ? .green : .red)
                        Spacer()
                        Text("⏱️ \(match.durationFormatted)")
                            .font(.caption.monospaced().bold())
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(Color.yellow.opacity(0.2))
                            .foregroundStyle(.yellow)
                            .clipShape(Capsule())
                    }

                    Text("Rakip: \(match.opponentDeckName) [\(match.opponentArchetype)]")
                        .font(.caption.bold())
                        .foregroundStyle(.white)

                    Text("Faz: \(match.endPhaseTitleTr) • Net Takas: +\(match.netTradeScore)💧 • Sızıntı: \(String(format: "%.1f", match.myLeakSeconds))sn")
                        .font(.caption2)
                        .foregroundStyle(.secondary)

                    Text("🔍 \(match.keyTurningPointTr)")
                        .font(.caption)
                        .foregroundStyle(.cyan)
                        .padding(8)
                        .background(Color.cyan.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .padding(12)
                .background(Color(red: 0.08, green: 0.12, blue: 0.22))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
    }
}
