import SwiftUI

public struct MainTabView: View {
    public init() {}

    public var body: some View {
        TabView {
            LiveCoachDashboardView()
                .tabItem {
                    Label("Canlı AI Koç", systemImage: "shield.lefthalf.filled")
                }

            AnalyticsDashboardView()
                .tabItem {
                    Label("Maç & Süre Analizi", systemImage: "chart.xyaxis.line")
                }

            MyDeckBuilderView()
                .tabItem {
                    Label("Destem", systemImage: "rectangle.grid.2x2.fill")
                }
        }
        .tint(.cyan)
    }
}
