import SwiftUI
import ReplayKit
import AVKit

// ============================================================================
// CLASH ROYALE NATIVE iOS - LIVE COACH & REPLAYKIT / PiP LAUNCHER VIEW
// ============================================================================

/// Wraps Apple's official `RPSystemBroadcastPickerView` so the user starts ReplayKit with 1 tap
struct ReplayKitBroadcastPickerRepresentable: UIViewRepresentable {
    let extensionBundleId = "com.clashroyale.aicoach.BroadcastExtension"

    func makeUIView(context: Context) -> RPSystemBroadcastPickerView {
        let picker = RPSystemBroadcastPickerView(frame: CGRect(x: 0, y: 0, width: 54, height: 54))
        picker.preferredExtension = extensionBundleId
        picker.showsMicrophoneButton = false
        return picker
    }

    func updateUIView(_ uiView: RPSystemBroadcastPickerView, context: Context) {}
}

/// Hosts the `AVSampleBufferDisplayLayer` required by `AVPictureInPictureController`
struct PiPLayerHostView: UIViewRepresentable {
    let displayLayer: AVSampleBufferDisplayLayer

    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: .zero)
        displayLayer.frame = CGRect(x: 0, y: 0, width: 260, height: 140)
        displayLayer.videoGravity = .resizeAspect
        view.layer.addSublayer(displayLayer)
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        displayLayer.frame = uiView.bounds
    }
}

public struct LiveCoachDashboardView: View {
    @EnvironmentObject var engine: CRAIEngine
    @EnvironmentObject var analytics: MatchAnalyticsStore
    @EnvironmentObject var pipController: PiPOverlayController
    @EnvironmentObject var voiceCoach: VoiceCoachManager

    @State private var showSaveMatchSheet = false
    @State private var selectedSaveResult: MatchResultType = .win
    @State private var saveMyCrowns: Int = 2
    @State private var saveOppCrowns: Int = 1

    public init() {}

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 14) {

                    // 1. REPLAYKIT & PICTURE-IN-PICTURE (PiP) CONTROL CARD
                    replayKitAndPiPCard

                    // 2. CRITICAL PUNISH / EVOLUTION ALERTS
                    if !engine.tacticalAlerts.isEmpty {
                        alertsSection
                    }

                    // 3. LIVE ELIXIR COUNTER & LEAK RADAR
                    elixirGaugeCard

                    // 4. INSTANT COUNTER MOVE & POSITIVE ELIXIR TRADE
                    counterMoveCard

                    // 5. OPPONENT 8-CARD CYCLE & EVOLUTION TRACKER
                    opponentCycleCard

                    // 6. AI META DECK PREDICTOR
                    metaDeckPredictionCard

                    // 7. MANUAL QUICK TAP GRID (FOR TESTING OR HYBRID USE)
                    quickCardTapGrid
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
            }
            .background(Color(red: 0.04, green: 0.06, blue: 0.12).ignoresSafeArea())
            .navigationTitle("👑 Clash Royale AI Koç")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(engine.isRunning ? "Sıfırla" : "Başlat") {
                        if engine.isRunning {
                            engine.resetMatch()
                        } else {
                            engine.startMatch()
                        }
                    }
                    .fontWeight(.bold)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("🏁 Maçı Kaydet") {
                        showSaveMatchSheet = true
                    }
                    .fontWeight(.bold)
                    .foregroundStyle(.yellow)
                }
            }
            .sheet(isPresented: $showSaveMatchSheet) {
                saveMatchSheetView
            }
        }
    }

    // MARK: - 1. ReplayKit & PiP Overlay Control Card
    private var replayKitAndPiPCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                ReplayKitBroadcastPickerRepresentable()
                    .frame(width: 48, height: 48)
                    .background(Color.red.opacity(0.2))
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: 3) {
                    Text("1. ReplayKit Canlı Ekran Analizi")
                        .font(.headline)
                        .foregroundStyle(.white)
                    Text("Soldaki kayıt butonuna basıp Clash Royale'e geçin. AI ekranı arka planda okur.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }

            HStack(spacing: 10) {
                Button {
                    pipController.togglePiP()
                } label: {
                    Label(
                        pipController.isPiPActive ? "PiP Açık" : "Oyun Üstü PiP Aç",
                        systemImage: "pip.enter"
                    )
                    .font(.subheadline.bold())
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 9)
                    .background(Color.cyan.opacity(0.22))
                    .foregroundStyle(.cyan)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }

                Button {
                    voiceCoach.isVoiceCoachEnabled.toggle()
                } label: {
                    Label(
                        voiceCoach.isVoiceCoachEnabled ? "Sesli Koç: AÇIK" : "Sesli Koç: KAPALI",
                        systemImage: voiceCoach.isVoiceCoachEnabled ? "speaker.wave.3.fill" : "speaker.slash.fill"
                    )
                    .font(.subheadline.bold())
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 9)
                    .background(voiceCoach.isVoiceCoachEnabled ? Color.green.opacity(0.22) : Color.gray.opacity(0.2))
                    .foregroundStyle(voiceCoach.isVoiceCoachEnabled ? .green : .gray)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
            }

            // Hidden/Inline PiP Host Layer (Required by AVPictureInPictureController)
            PiPLayerHostView(displayLayer: pipController.displayLayer)
                .frame(height: 1)
                .opacity(0.01)
        }
        .padding(12)
        .background(Color(red: 0.09, green: 0.14, blue: 0.25))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    // MARK: - 2. Critical Alerts
    private var alertsSection: some View {
        VStack(spacing: 8) {
            ForEach(engine.tacticalAlerts.prefix(2)) { alert in
                VStack(alignment: .leading, spacing: 3) {
                    Text(alert.titleTr)
                        .font(.subheadline.weight(.black))
                        .foregroundStyle(.white)
                    Text(alert.detailTr)
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.85))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(10)
                .background(alert.severity == "EVO" ? Color.purple.opacity(0.75) : Color.red.opacity(0.75))
                .clipShape(RoundedRectangle(cornerRadius: 11))
            }
        }
    }

    // MARK: - 3. Live Elixir Counter
    private var elixirGaugeCard: some View {
        VStack(spacing: 10) {
            HStack {
                Text("💧 Canlı İksir Sayacı")
                    .font(.headline)
                Spacer()
                Text(String(format: "%02d:%02d (%d. sn) • %dx", engine.elapsedSeconds / 60, engine.elapsedSeconds % 60, engine.elapsedSeconds, engine.currentPhaseMultiplier))
                    .font(.caption.monospaced().bold())
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color.yellow.opacity(0.2))
                    .foregroundStyle(.yellow)
                    .clipShape(Capsule())
            }

            HStack {
                VStack(alignment: .leading) {
                    Text("🔴 RAKİP İKSİR")
                        .font(.caption.bold())
                        .foregroundStyle(.pink)
                    Text(String(format: "%.1f", engine.opponentElixir))
                        .font(.system(size: 28, weight: .black, design: .monospaced))
                        .foregroundStyle(.pink)
                    Text(String(format: "Sızıntı: %.1f sn", engine.opponentLeakSeconds))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                VStack(alignment: .center) {
                    let diff = engine.playerElixir - engine.opponentElixir
                    Text("NET AVANTAJ")
                        .font(.caption2.bold())
                        .foregroundStyle(.secondary)
                    Text(String(format: "%@%.1f💧", diff >= 0 ? "+" : "", diff))
                        .font(.title3.weight(.black))
                        .foregroundStyle(diff >= 1.5 ? .green : (diff <= -1.5 ? .red : .white))
                }
                Spacer()
                VStack(alignment: .trailing) {
                    Text("🔵 SENİN İKSİRİN")
                        .font(.caption.bold())
                        .foregroundStyle(.cyan)
                    Text(String(format: "%.1f", engine.playerElixir))
                        .font(.system(size: 28, weight: .black, design: .monospaced))
                        .foregroundStyle(.cyan)
                    Text(String(format: "Sızıntı: %.1f sn", engine.playerLeakSeconds))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(12)
        .background(Color(red: 0.08, green: 0.12, blue: 0.22))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    // MARK: - 4. Counter Move Recommendation
    private var counterMoveCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("🛡️ Anlık Hamle Önerisi (Pozitif İksir Takası)")
                .font(.headline)

            if let threat = engine.lastOpponentCard, let primary = engine.recommendedCounters.first {
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("🔴 \(threat.nameTr) (\(threat.elixir)💧)")
                            .font(.subheadline.bold())
                            .foregroundStyle(.pink)
                        Image(systemName: "arrow.right")
                        Text("🟢 \(primary.counterCard.nameTr) (\(primary.counterCard.elixir)💧)")
                            .font(.subheadline.bold())
                            .foregroundStyle(.green)
                        Spacer()
                        Text(primary.netElixirTrade >= 0 ? "+\(primary.netElixirTrade)💧 Kazanç" : "\(primary.netElixirTrade)💧")
                            .font(.caption.bold())
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(Color.green.opacity(0.25))
                            .foregroundStyle(.green)
                            .clipShape(Capsule())
                    }

                    Text("📍 \(primary.placement.rawValue) [Kare \(primary.placement.gridCoordinate.x):\(primary.placement.gridCoordinate.y)]")
                        .font(.caption.bold())
                        .foregroundStyle(.cyan)

                    Text(primary.tipTr)
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.9))
                }
                .padding(10)
                .background(Color.green.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 10))
            } else {
                Text("Rakip kart attığı anda en düşük iksirli savunma hamlesi ve tam yerleştirme karesi burada görünür.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Color(red: 0.08, green: 0.12, blue: 0.22))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    // MARK: - 5. Opponent 8-Card Cycle & Evolution Tracker
    private var opponentCycleCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("🔄 Rakip Kart Döngüsü & Evrim")
                    .font(.headline)
                Spacer()
                Text("\(engine.opponentKnownDeckIds.count)/8 Biliniyor")
                    .font(.caption.bold())
                    .foregroundStyle(.secondary)
            }

            Text("⚠️ ŞU AN RAKİBİN ELİNDEKİ 4 KART:")
                .font(.caption.bold())
                .foregroundStyle(.pink)

            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 8) {
                ForEach(engine.opponentHandSlots) { slot in
                    VStack(spacing: 4) {
                        if let c = slot.card {
                            HStack {
                                Text("\(c.elixir)💧")
                                    .font(.caption2.bold())
                                    .foregroundStyle(.purple)
                                Spacer()
                                if slot.isEvolutionReady {
                                    Text("EVO!")
                                        .font(.system(size: 9, weight: .black))
                                        .padding(2)
                                        .background(Color.purple)
                                        .foregroundStyle(.white)
                                        .clipShape(RoundedRectangle(cornerRadius: 3))
                                } else if slot.isPredictedFromMeta {
                                    Text("TAHMİN")
                                        .font(.system(size: 8, weight: .bold))
                                        .foregroundStyle(.yellow)
                                }
                            }
                            Text(c.nameTr)
                                .font(.caption.bold())
                                .lineLimit(1)
                                .minimumScaleFactor(0.75)
                        } else {
                            Text("❓")
                                .font(.title3)
                            Text("Gizli")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(8)
                    .frame(maxWidth: .infinity, minHeight: 58)
                    .background(slot.isEvolutionReady ? Color.purple.opacity(0.35) : Color.red.opacity(0.16))
                    .clipShape(RoundedRectangle(cornerRadius: 9))
                    .onTapGesture {
                        if let c = slot.card {
                            let best = engine.registerOpponentCardPlayed(c.id)
                            voiceCoach.announceOpponentCard(card: c, bestCounter: best, engine: engine)
                        }
                    }
                }
            }

            Text("⏳ DÖNGÜ SIRASI (+1 ➔ +4 Kart Sonra):")
                .font(.caption.bold())
                .foregroundStyle(.secondary)
                .padding(.top, 4)

            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 8) {
                ForEach(engine.opponentQueueSlots) { slot in
                    VStack(spacing: 3) {
                        Text("+\(slot.cardsUntilInHand) Kart")
                            .font(.caption2.bold())
                            .foregroundStyle(.secondary)
                        Text(slot.card?.nameTr ?? "⏳")
                            .font(.caption.bold())
                            .lineLimit(1)
                            .minimumScaleFactor(0.75)
                    }
                    .padding(7)
                    .frame(maxWidth: .infinity)
                    .background(Color.white.opacity(0.05))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }
        }
        .padding(12)
        .background(Color(red: 0.08, green: 0.12, blue: 0.22))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    // MARK: - 6. Meta Deck Predictor
    private var metaDeckPredictionCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("🎯 AI Deste Tahmini (Meta Deck Matcher)")
                .font(.headline)

            if let top = engine.deckPredictions.first {
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text(top.deck.name)
                            .font(.subheadline.bold())
                            .foregroundStyle(.yellow)
                        Spacer()
                        Text("%\(top.confidencePercent) Eşleşme")
                            .font(.caption.bold())
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(Color.green.opacity(0.25))
                            .foregroundStyle(.green)
                            .clipShape(Capsule())
                    }

                    if !top.unrevealedCards.isEmpty {
                        let surpriseNames = top.unrevealedCards.map { $0.nameTr }.joined(separator: ", ")
                        Text("⚠️ Henüz Atmadığı Sürpriz Kartlar: \(surpriseNames)")
                            .font(.caption.bold())
                            .foregroundStyle(.orange)
                    }

                    Text("🛡️ Nasıl Yenilir: \(top.deck.howToBeatTr)")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.9))
                }
                .padding(10)
                .background(Color.white.opacity(0.05))
                .clipShape(RoundedRectangle(cornerRadius: 10))
            } else {
                Text("Rakip ilk 2 kartını attığı anda popüler Meta Destesi ve kalan gizli kartları tespit edilir.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Color(red: 0.08, green: 0.12, blue: 0.22))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    // MARK: - 7. Quick Tap Card Grid
    private var quickCardTapGrid: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("⚡ Hızlı Rakip Kart Girişi (Dokunarak Test Et)")
                .font(.headline)

            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 7) {
                ForEach(CRDatabase.shared.allCards) { card in
                    Button {
                        let best = engine.registerOpponentCardPlayed(card.id)
                        voiceCoach.announceOpponentCard(card: card, bestCounter: best, engine: engine)
                        pipController.enqueueRenderedHUDFrame()
                    } label: {
                        VStack(spacing: 2) {
                            Text("\(card.elixir)💧")
                                .font(.caption2.bold())
                                .foregroundStyle(.purple)
                            Text(card.nameTr)
                                .font(.caption.bold())
                                .foregroundStyle(.white)
                                .lineLimit(1)
                                .minimumScaleFactor(0.7)
                        }
                        .padding(7)
                        .frame(maxWidth: .infinity)
                        .background(Color.white.opacity(0.07))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                }
            }
        }
        .padding(12)
        .background(Color(red: 0.08, green: 0.12, blue: 0.22))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    // MARK: - Save Match Sheet
    private var saveMatchSheetView: some View {
        NavigationStack {
            Form {
                Section("Maç Sonucu & Süresi") {
                    Picker("Sonuç", selection: $selectedSaveResult) {
                        Text("🏆 Galibiyet").tag(MatchResultType.win)
                        Text("❌ Mağlubiyet").tag(MatchResultType.loss)
                    }
                    HStack {
                        Text("Maç Süresi (Saniye)")
                        Spacer()
                        Text("\(max(15, engine.elapsedSeconds)) sn")
                            .fontWeight(.bold)
                            .foregroundStyle(.yellow)
                    }
                    Stepper("Senin Taç: \(saveMyCrowns)", value: $saveMyCrowns, in: 0...3)
                    Stepper("Rakip Taç: \(saveOppCrowns)", value: $saveOppCrowns, in: 0...3)
                }
            }
            .navigationTitle("🏁 Maçı Analize Kaydet")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("İptal") { showSaveMatchSheet = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Kaydet") {
                        analytics.recordCompletedMatch(
                            from: engine,
                            result: selectedSaveResult,
                            myCrowns: saveMyCrowns,
                            oppCrowns: saveOppCrowns
                        )
                        engine.resetMatch()
                        showSaveMatchSheet = false
                    }
                    .fontWeight(.bold)
                }
            }
        }
    }
}
