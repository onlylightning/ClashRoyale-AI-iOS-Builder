import Foundation

// ============================================================================
// CLASH ROYALE NATIVE iOS - CARD, COUNTER PLACEMENT & META DECK DATABASE
// ============================================================================

public enum CRCardType: String, Codable, CaseIterable {
    case troop = "Birlik"
    case building = "Bina"
    case spell = "Büyü"
}

public enum CRCardRole: String, Codable, CaseIterable {
    case winCondition = "Kule Yıkıcı (Atak)"
    case tank = "Ağır Tank"
    case miniTank = "Mini Tank"
    case antiAir = "Hava & Menzilli Destek"
    case swarm = "Sürü"
    case building = "Savunma Binası"
    case smallSpell = "Küçük Büyü"
    case bigSpell = "Büyük Büyü"
    case cycle = "Döngü (1-2 İksir)"
}

public enum ArenaPlacementZone: String, Codable {
    case center4_3 = "Merkez 4-3 Kare (İki Kule Vurur)"
    case center3_2 = "Yüksek Merkez 3-2 Kare (Uzak Çekme)"
    case kingActivation = "Kral Kulesi Ön Çaprazı (Kral Aktivasyonu)"
    case onTop = "Birliğin Tam Üzeri (Çevreleyerek)"
    case towerFront = "Prenses Kulesi Önü (Tampon)"
    case kiteOpposite = "Ters Koridora Uçurtma (Kite Karesi)"
    case bridgeBlock = "Köprü Ağzı Bloklama"
    case backSafe = "Kule Dış Yanı (Büyüden Uzak Açı)"
    case oppositeBridgePunish = "Ters Köprü Anında Cezalandırma!"

    public var gridCoordinate: (x: Int, y: Int) {
        switch self {
        case .center4_3: return (9, 21)
        case .center3_2: return (10, 22)
        case .kingActivation: return (9, 26)
        case .onTop: return (13, 22)
        case .towerFront: return (14, 24)
        case .kiteOpposite: return (8, 20)
        case .bridgeBlock: return (14, 18)
        case .backSafe: return (16, 25)
        case .oppositeBridgePunish: return (3, 17)
        }
    }
}

public struct CounterMoveRule: Codable, Hashable {
    public let counterCardId: String
    public let placement: ArenaPlacementZone
    public let tacticalTipTr: String

    public init(counterCardId: String, placement: ArenaPlacementZone, tacticalTipTr: String) {
        self.counterCardId = counterCardId
        self.placement = placement
        self.tacticalTipTr = tacticalTipTr
    }
}

public struct CRCard: Identifiable, Codable, Hashable {
    public let id: String
    public let nameTr: String
    public let nameEn: String
    public let elixir: Int
    public let type: CRCardType
    public let role: CRCardRole
    public let evoCycles: Int?
    public let crownTowerDamage: Int
    public let counters: [CounterMoveRule]
}

public struct CRMetaDeck: Identifiable, Codable, Hashable {
    public let id: String
    public let name: String
    public let archetype: String
    public let avgElixir: Double
    public let dangerPhase: String
    public let cards: [String]
    public let signatureCards: [String]
    public let howToBeatTr: String
}

public final class CRDatabase {
    public static let shared = CRDatabase()

    public let allCards: [CRCard]
    public let cardById: [String: CRCard]
    public let metaDecks: [CRMetaDeck]

    private init() {
        let cards: [CRCard] = [
            // WIN CONDITIONS & TANKS
            CRCard(
                id: "hog_rider", nameTr: "Domuz Binicisi", nameEn: "Hog Rider", elixir: 4,
                type: .troop, role: .winCondition, evoCycles: nil, crownTowerDamage: 0,
                counters: [
                    CounterMoveRule(counterCardId: "cannon", placement: .center4_3, tacticalTipTr: "Top'u 4-3 merkez karesine bırak: Domuz 0 vuruş yapar (+1 İksir Kazanç)."),
                    CounterMoveRule(counterCardId: "tornado", placement: .kingActivation, tacticalTipTr: "Kasırga ile Kral Kulesine çek: 0 hasar + Kral Kulesi aktif (+1 İksir)."),
                    CounterMoveRule(counterCardId: "tesla", placement: .center4_3, tacticalTipTr: "Merkez 4-3 kareye Tesla koy, Domuz kuleye dokunamaz."),
                    CounterMoveRule(counterCardId: "mini_pekka", placement: .towerFront, tacticalTipTr: "Kule önüne erken bırak: 0 vuruş + güçlü karşı saldırı."),
                    CounterMoveRule(counterCardId: "skeletons", placement: .towerFront, tacticalTipTr: "Buz Ruhu ile birlikte (+2 İksir) veya tek başına (+3 İksir) savun.")
                ]
            ),
            CRCard(
                id: "goblin_barrel", nameTr: "Goblin Fıçısı", nameEn: "Goblin Barrel", elixir: 3,
                type: .spell, role: .winCondition, evoCycles: 2, crownTowerDamage: 0,
                counters: [
                    CounterMoveRule(counterCardId: "the_log", placement: .towerFront, tacticalTipTr: "Fıçı inmeden 0.5 sn önce Tomruk yuvarla: 0 hasar (+1 İksir Kazanç)."),
                    CounterMoveRule(counterCardId: "barbarian_barrel", placement: .towerFront, tacticalTipTr: "Kule dibine Barbar Varili yuvarla (+1 İksir Kazanç)."),
                    CounterMoveRule(counterCardId: "arrows", placement: .towerFront, tacticalTipTr: "Oklar ile garantili temizle (3-3 eşit takas)."),
                    CounterMoveRule(counterCardId: "valkyrie", placement: .towerFront, tacticalTipTr: "Fıçı düşmeden hemen önce kule arkasına koy, dönüşle 3 goblini tekte keser.")
                ]
            ),
            CRCard(
                id: "mega_knight", nameTr: "Mega Şövalye", nameEn: "Mega Knight", elixir: 7,
                type: .troop, role: .tank, evoCycles: 1, crownTowerDamage: 0,
                counters: [
                    CounterMoveRule(counterCardId: "knight", placement: .center4_3, tacticalTipTr: "Merkez 4-3 kareye Şövalye bırak: Her iki kule vurur (+4 İksir Kazanç!)."),
                    CounterMoveRule(counterCardId: "valkyrie", placement: .center4_3, tacticalTipTr: "Merkeze çek, Valkür tek başına +3 İksir Kazanç ile durdurur."),
                    CounterMoveRule(counterCardId: "mini_pekka", placement: .onTop, tacticalTipTr: "Zıplamasını engellemek için tam dibine bırak (+3 İksir Kazanç)."),
                    CounterMoveRule(counterCardId: "inferno_tower", placement: .center4_3, tacticalTipTr: "Merkez 4-3 Cehennem Kulesi saniyeler içinde eritir (+2 İksir)."),
                    CounterMoveRule(counterCardId: "ice_golem", placement: .kiteOpposite, tacticalTipTr: "Ters koridora uçurtma (Kite) yap, Silahşör uzaktan kessin (+5 İksir!).")
                ]
            ),
            CRCard(
                id: "pekka", nameTr: "P.E.K.K.A", nameEn: "P.E.K.K.A", elixir: 7,
                type: .troop, role: .tank, evoCycles: 1, crownTowerDamage: 0,
                counters: [
                    CounterMoveRule(counterCardId: "skeletons", placement: .center4_3, tacticalTipTr: "Merkeze 3 İskelet bırakarak oyala (+6 İksir!)."),
                    CounterMoveRule(counterCardId: "guards", placement: .center4_3, tacticalTipTr: "Kalkanlı Korumalar P.E.K.K.A'yı 6 vuruş oyalar (+4 İksir Kazanç)."),
                    CounterMoveRule(counterCardId: "inferno_tower", placement: .center4_3, tacticalTipTr: "4-3 kareye Cehennem Kulesi kur, Çarpma'ya karşı önüne İskelet koy (+2 İksir)."),
                    CounterMoveRule(counterCardId: "ice_golem", placement: .kiteOpposite, tacticalTipTr: "Ters koridora uçurtma (Kite) yap (+5 İksir).")
                ]
            ),
            CRCard(
                id: "golem", nameTr: "Golem", nameEn: "Golem", elixir: 8,
                type: .troop, role: .winCondition, evoCycles: nil, crownTowerDamage: 0,
                counters: [
                    CounterMoveRule(counterCardId: "inferno_tower", placement: .center4_3, tacticalTipTr: "Rakip Golem'i arkadan attığı an TERS KORİDORDAN cezalandır! Köprüde Cehennem Kulesi kur."),
                    CounterMoveRule(counterCardId: "cannon", placement: .center3_2, tacticalTipTr: "Golem'i 3-2 kareye çek, arkadaki Gece Cadısı'nı Alev Topu/Valkür ile ayır.")
                ]
            ),
            CRCard(
                id: "lava_hound", nameTr: "Lav Tazısı", nameEn: "Lava Hound", elixir: 7,
                type: .troop, role: .winCondition, evoCycles: nil, crownTowerDamage: 0,
                counters: [
                    CounterMoveRule(counterCardId: "inferno_tower", placement: .center4_3, tacticalTipTr: "Lav Tazısı arkadan atıldığı an TERS KORİDORDAN saldır ki arkasına Balon koyamasın!"),
                    CounterMoveRule(counterCardId: "tesla", placement: .center4_3, tacticalTipTr: "Merkeze Tesla kur, Köpekçikler patlayınca Oklar/Alev Topu hazır tut.")
                ]
            ),
            CRCard(
                id: "balloon", nameTr: "Balon", nameEn: "Balloon", elixir: 5,
                type: .troop, role: .winCondition, evoCycles: nil, crownTowerDamage: 0,
                counters: [
                    CounterMoveRule(counterCardId: "tesla", placement: .center3_2, tacticalTipTr: "Merkeze Tesla koy: Balon kuleye ulaşamadan düşer (+1 İksir)."),
                    CounterMoveRule(counterCardId: "musketeer", placement: .backSafe, tacticalTipTr: "Kule dış yanına Silahşör + Buz Ruhu koy: 0 kule hasarı (+1 İksir)."),
                    CounterMoveRule(counterCardId: "bats", placement: .onTop, tacticalTipTr: "Yarasalar +3 İksir Kazanç ile Balon'u hızla eritir."),
                    CounterMoveRule(counterCardId: "hunter", placement: .onTop, tacticalTipTr: "Tam altına Avcı bırak: 2 yakın atışta Balon'u patlatır (+1 İksir).")
                ]
            ),
            CRCard(
                id: "x_bow", nameTr: "X-Yayı", nameEn: "X-Bow", elixir: 6,
                type: .building, role: .winCondition, evoCycles: nil, crownTowerDamage: 0,
                counters: [
                    CounterMoveRule(counterCardId: "earthquake", placement: .bridgeBlock, tacticalTipTr: "Şövalye/Buz Golemi ile tankla + Deprem at (+2 İksir Kazanç!)."),
                    CounterMoveRule(counterCardId: "royal_giant", placement: .bridgeBlock, tacticalTipTr: "Karşısına Kraliyet Devi bas: X-Yayı'nı tanklayıp yok eder."),
                    CounterMoveRule(counterCardId: "rocket", placement: .bridgeBlock, tacticalTipTr: "X-Yayı'na doğrudan Roket at (6-6 eşit takas).")
                ]
            ),
            CRCard(
                id: "royal_giant", nameTr: "Kraliyet Devi", nameEn: "Royal Giant", elixir: 6,
                type: .troop, role: .winCondition, evoCycles: 1, crownTowerDamage: 0,
                counters: [
                    CounterMoveRule(counterCardId: "inferno_tower", placement: .center3_2, tacticalTipTr: "3-2 merkez karesine Cehennem Kulesi kur, Balıkçı'ya karşı önüne İskelet koy."),
                    CounterMoveRule(counterCardId: "cannon", placement: .center3_2, tacticalTipTr: "Top + İskeletler kombosuyla +2 İksir Kazanç al."),
                    CounterMoveRule(counterCardId: "mini_pekka", placement: .onTop, tacticalTipTr: "Köprüde hemen üstüne Mini P.E.K.K.A bırak (+2 İksir).")
                ]
            ),
            CRCard(
                id: "graveyard", nameTr: "Mezarlık", nameEn: "Graveyard", elixir: 5,
                type: .spell, role: .winCondition, evoCycles: nil, crownTowerDamage: 0,
                counters: [
                    CounterMoveRule(counterCardId: "poison", placement: .towerFront, tacticalTipTr: "Mezarlığın tam üstüne Zehir bırak: Tüm iskeletler doğduğu an ölür (+1 İksir)."),
                    CounterMoveRule(counterCardId: "valkyrie", placement: .towerFront, tacticalTipTr: "Kule kenarına Valkür bırak (+1 İksir)."),
                    CounterMoveRule(counterCardId: "guards", placement: .towerFront, tacticalTipTr: "Zehir'e dayanıklı Korumalar ile Mezarlığı tut (+2 İksir).")
                ]
            ),
            CRCard(
                id: "miner", nameTr: "Madenci", nameEn: "Miner", elixir: 3,
                type: .troop, role: .winCondition, evoCycles: nil, crownTowerDamage: 0,
                counters: [
                    CounterMoveRule(counterCardId: "knight", placement: .towerFront, tacticalTipTr: "Çıkacağı noktaya Şövalye koy, Duvar Yıkıcılar geliyorsa Tomruk hazırla."),
                    CounterMoveRule(counterCardId: "skeletons", placement: .towerFront, tacticalTipTr: "+2 İksir Kazanç ile Madenci'yi yakala.")
                ]
            ),
            CRCard(
                id: "wall_breakers", nameTr: "Duvar Yıkıcılar", nameEn: "Wall Breakers", elixir: 2,
                type: .troop, role: .winCondition, evoCycles: 2, crownTowerDamage: 0,
                counters: [
                    CounterMoveRule(counterCardId: "the_log", placement: .towerFront, tacticalTipTr: "Tomruk ile ikisini birden temizle."),
                    CounterMoveRule(counterCardId: "skeletons", placement: .center4_3, tacticalTipTr: "Ortaya İskeletler koyarak+1 İksir Kazanç al.")
                ]
            ),
            CRCard(
                id: "sparky", nameTr: "Kıvılcım", nameEn: "Sparky", elixir: 6,
                type: .troop, role: .tank, evoCycles: nil, crownTowerDamage: 0,
                counters: [
                    CounterMoveRule(counterCardId: "electro_wizard", placement: .onTop, tacticalTipTr: "Elektro Büyücü şarjını sürekli sıfırlar (+2 İksir)."),
                    CounterMoveRule(counterCardId: "skeletons", placement: .onTop, tacticalTipTr: "Tam üstüne 3 İskelet dağıt (Surround): Şarjını 1 iksire boşa harcar (+5 İksir!)."),
                    CounterMoveRule(counterCardId: "rocket", placement: .backSafe, tacticalTipTr: "Kule yanından geçerken Kule + Kıvılcım'a Roket at.")
                ]
            ),
            CRCard(
                id: "goblin_giant", nameTr: "Goblin Devi", nameEn: "Goblin Giant", elixir: 6,
                type: .troop, role: .winCondition, evoCycles: 1, crownTowerDamage: 0,
                counters: [
                    CounterMoveRule(counterCardId: "cannon", placement: .center4_3, tacticalTipTr: "4-3 merkez karesine Top koy (+3 İksir)."),
                    CounterMoveRule(counterCardId: "inferno_tower", placement: .center4_3, tacticalTipTr: "Merkeze Cehennem Kulesi koy.")
                ]
            ),
            CRCard(
                id: "battle_ram", nameTr: "Koçbaşı", nameEn: "Battle Ram", elixir: 4,
                type: .troop, role: .winCondition, evoCycles: 2, crownTowerDamage: 0,
                counters: [
                    CounterMoveRule(counterCardId: "the_log", placement: .towerFront, tacticalTipTr: "Koçbaşı şarjını Tomruk ile kır (+2 İksir)."),
                    CounterMoveRule(counterCardId: "cannon", placement: .center4_3, tacticalTipTr: "Top ile merkeze çek (+1 İksir).")
                ]
            ),
            CRCard(
                id: "royal_hogs", nameTr: "Kraliyet Domuzları", nameEn: "Royal Hogs", elixir: 5,
                type: .troop, role: .winCondition, evoCycles: nil, crownTowerDamage: 0,
                counters: [
                    CounterMoveRule(counterCardId: "fireball", placement: .towerFront, tacticalTipTr: "Alev Topu ile +1 İksir Kazanç al."),
                    CounterMoveRule(counterCardId: "valkyrie", placement: .center4_3, tacticalTipTr: "Üstlerine Valkür bırak (+1 İksir)."),
                    CounterMoveRule(counterCardId: "bomb_tower", placement: .center4_3, tacticalTipTr: "Bomba Kulesi 4 domuzu aynı anda eritir (+1 İksir).")
                ]
            ),
            CRCard(
                id: "goblin_drill", nameTr: "Goblin Köstebeği", nameEn: "Goblin Drill", elixir: 4,
                type: .building, role: .winCondition, evoCycles: 2, crownTowerDamage: 0,
                counters: [
                    CounterMoveRule(counterCardId: "valkyrie", placement: .towerFront, tacticalTipTr: "Çıktığı noktaya Valkür koy: 0 kule hasarı."),
                    CounterMoveRule(counterCardId: "dark_prince", placement: .towerFront, tacticalTipTr: "Kara Prens alan hasarıyla tüm goblinleri temizler.")
                ]
            ),
            CRCard(
                id: "mortar", nameTr: "Havan", nameEn: "Mortar", elixir: 4,
                type: .building, role: .winCondition, evoCycles: 2, crownTowerDamage: 0,
                counters: [
                    CounterMoveRule(counterCardId: "earthquake", placement: .bridgeBlock, tacticalTipTr: "Deprem ile +1 İksir Kazanç sağlayarak Havan'ı yık."),
                    CounterMoveRule(counterCardId: "knight", placement: .center3_2, tacticalTipTr: "Merkezden Şövalye ile Havan atışlarını tankla.")
                ]
            ),
            CRCard(
                id: "elixir_golem", nameTr: "İksir Golemi", nameEn: "Elixir Golem", elixir: 3,
                type: .troop, role: .winCondition, evoCycles: nil, crownTowerDamage: 0,
                counters: [
                    CounterMoveRule(counterCardId: "valkyrie", placement: .onTop, tacticalTipTr: "Destek birliklerinin arasına Valkür + Alev Topu at: +4 bedava iksir kazanırsın!"),
                    CounterMoveRule(counterCardId: "bomb_tower", placement: .center4_3, tacticalTipTr: "Bomba Kulesi tüm damlacıkları eritir.")
                ]
            ),
            CRCard(
                id: "giant", nameTr: "Dev", nameEn: "Giant", elixir: 5,
                type: .troop, role: .winCondition, evoCycles: nil, crownTowerDamage: 0,
                counters: [
                    CounterMoveRule(counterCardId: "cannon", placement: .center4_3, tacticalTipTr: "4-3 merkez karesine Top koy (+2 İksir)."),
                    CounterMoveRule(counterCardId: "mini_pekka", placement: .onTop, tacticalTipTr: "Mini P.E.K.K.A ile hızla kes (+1 İksir).")
                ]
            ),

            // MINI TANKS & SUPPORT
            CRCard(
                id: "knight", nameTr: "Şövalye", nameEn: "Knight", elixir: 3,
                type: .troop, role: .miniTank, evoCycles: 2, crownTowerDamage: 0,
                counters: [
                    CounterMoveRule(counterCardId: "skeletons", placement: .center4_3, tacticalTipTr: "Ortaya İskeletler ile çek: İki kule vurur (+2 İksir Kazanç)."),
                    CounterMoveRule(counterCardId: "bats", placement: .onTop, tacticalTipTr: "Yarasalar ile bedava temizle (+1 İksir).")
                ]
            ),
            CRCard(
                id: "valkyrie", nameTr: "Valkür", nameEn: "Valkyrie", elixir: 4,
                type: .troop, role: .miniTank, evoCycles: 2, crownTowerDamage: 0,
                counters: [
                    CounterMoveRule(counterCardId: "knight", placement: .center4_3, tacticalTipTr: "Kendi sahanda Şövalye ile +1 İksir Kazanç sağla."),
                    CounterMoveRule(counterCardId: "bats", placement: .onTop, tacticalTipTr: "Hava birimiyle sıfır hasarla kes (+2 İksir).")
                ]
            ),
            CRCard(
                id: "mini_pekka", nameTr: "Mini P.E.K.K.A", nameEn: "Mini P.E.K.K.A", elixir: 4,
                type: .troop, role: .miniTank, evoCycles: nil, crownTowerDamage: 0,
                counters: [
                    CounterMoveRule(counterCardId: "skeletons", placement: .center4_3, tacticalTipTr: "Merkeze 3 İskelet bırak (+3 İksir Kazanç!)."),
                    CounterMoveRule(counterCardId: "guards", placement: .center4_3, tacticalTipTr: "Korumalar ile ortaya çek (+1 İksir).")
                ]
            ),
            CRCard(
                id: "ice_golem", nameTr: "Buz Golemi", nameEn: "Ice Golem", elixir: 2,
                type: .troop, role: .miniTank, evoCycles: nil, crownTowerDamage: 0,
                counters: [
                    CounterMoveRule(counterCardId: "cannon", placement: .center4_3, tacticalTipTr: "Arkadan Domuz Binicisi geliyorsa bina ile ikisini de merkeze çek.")
                ]
            ),
            CRCard(
                id: "bandit", nameTr: "Haydut", nameEn: "Bandit", elixir: 3,
                type: .troop, role: .miniTank, evoCycles: nil, crownTowerDamage: 0,
                counters: [
                    CounterMoveRule(counterCardId: "skeletons", placement: .onTop, tacticalTipTr: "Atılma menziline girmeden tam dibine İskeletler bırak (+2 İksir)."),
                    CounterMoveRule(counterCardId: "knight", placement: .center4_3, tacticalTipTr: "Şövalye ile atılmasını durdur.")
                ]
            ),
            CRCard(
                id: "royal_ghost", nameTr: "Kraliyet Hayaleti", nameEn: "Royal Ghost", elixir: 3,
                type: .troop, role: .miniTank, evoCycles: nil, crownTowerDamage: 0,
                counters: [
                    CounterMoveRule(counterCardId: "knight", placement: .center4_3, tacticalTipTr: "Görünür yapmak için önüne Şövalye koy."),
                    CounterMoveRule(counterCardId: "ice_golem", placement: .center4_3, tacticalTipTr: "Buz Golemi ile tankla (+1 İksir).")
                ]
            ),
            CRCard(
                id: "lumberjack", nameTr: "Oduncu", nameEn: "Lumberjack", elixir: 4,
                type: .troop, role: .miniTank, evoCycles: nil, crownTowerDamage: 0,
                counters: [
                    CounterMoveRule(counterCardId: "knight", placement: .center4_3, tacticalTipTr: "Arkadan Balon gelebilir! Oduncu'yu merkeze çek ki Öfke kule önüne düşmesin (+1 İksir)."),
                    CounterMoveRule(counterCardId: "ice_golem", placement: .kiteOpposite, tacticalTipTr: "Ters koridora uçurtma yap (+2 İksir).")
                ]
            ),
            CRCard(
                id: "fisherman", nameTr: "Balıkçı", nameEn: "Fisherman", elixir: 3,
                type: .troop, role: .miniTank, evoCycles: nil, crownTowerDamage: 0,
                counters: [
                    CounterMoveRule(counterCardId: "skeletons", placement: .center4_3, tacticalTipTr: "Kancasını 1 iksirlik İskeletler'e harcat (+2 İksir).")
                ]
            ),
            CRCard(
                id: "mighty_miner", nameTr: "Güçlü Madenci", nameEn: "Mighty Miner", elixir: 4,
                type: .troop, role: .miniTank, evoCycles: nil, crownTowerDamage: 0,
                counters: [
                    CounterMoveRule(counterCardId: "electro_spirit", placement: .onTop, tacticalTipTr: "Elektro Ruh / Çarpma ile matkabını sıfırla."),
                    CounterMoveRule(counterCardId: "skeletons", placement: .center4_3, tacticalTipTr: "Ortaya İskeletler ile çek (+3 İksir).")
                ]
            ),
            CRCard(
                id: "dark_prince", nameTr: "Kara Prens", nameEn: "Dark Prince", elixir: 4,
                type: .troop, role: .miniTank, evoCycles: nil, crownTowerDamage: 0,
                counters: [
                    CounterMoveRule(counterCardId: "knight", placement: .center4_3, tacticalTipTr: "Şövalye ile kendi sahanda karşıla (+1 İksir).")
                ]
            ),
            CRCard(
                id: "royal_recruits", nameTr: "Kraliyet Muhafızları", nameEn: "Royal Recruits", elixir: 7,
                type: .troop, role: .swarm, evoCycles: 1, crownTowerDamage: 0,
                counters: [
                    CounterMoveRule(counterCardId: "bomb_tower", placement: .center4_3, tacticalTipTr: "Tam ortaya Bomba Kulesi kur (+3 İksir)."),
                    CounterMoveRule(counterCardId: "valkyrie", placement: .center4_3, tacticalTipTr: "Merkeze Valkür bırakarak iki koridoru ortaya topla (+3 İksir).")
                ]
            ),
            CRCard(
                id: "battle_healer", nameTr: "Savaş Şifacısı", nameEn: "Battle Healer", elixir: 4,
                type: .troop, role: .miniTank, evoCycles: nil, crownTowerDamage: 0,
                counters: [
                    CounterMoveRule(counterCardId: "mini_pekka", placement: .onTop, tacticalTipTr: "Yüksek tekil hasarla can basamadan kes.")
                ]
            ),

            // ANTI-AIR & RANGED
            CRCard(
                id: "musketeer", nameTr: "Silahşör", nameEn: "Musketeer", elixir: 4,
                type: .troop, role: .antiAir, evoCycles: 2, crownTowerDamage: 0,
                counters: [
                    CounterMoveRule(counterCardId: "skeletons", placement: .onTop, tacticalTipTr: "Köprüyü geçince üstüne İskeletler bırak (+3 İksir)."),
                    CounterMoveRule(counterCardId: "fireball", placement: .backSafe, tacticalTipTr: "Kule yanından geçerken Alev Topu at.")
                ]
            ),
            CRCard(
                id: "firecracker", nameTr: "Havai Fişekçi", nameEn: "Firecracker", elixir: 3,
                type: .troop, role: .antiAir, evoCycles: 2, crownTowerDamage: 0,
                counters: [
                    CounterMoveRule(counterCardId: "skeletons", placement: .kingActivation, tacticalTipTr: "Kral Kulesi önüne 1 iksirlik birim koyarak BEDAVA Kral Kulesi aç!"),
                    CounterMoveRule(counterCardId: "arrows", placement: .backSafe, tacticalTipTr: "Oklar ile tekte temizle (3-3 eşit takas).")
                ]
            ),
            CRCard(
                id: "princess", nameTr: "Prenses", nameEn: "Princess", elixir: 3,
                type: .troop, role: .antiAir, evoCycles: nil, crownTowerDamage: 0,
                counters: [
                    CounterMoveRule(counterCardId: "the_log", placement: .bridgeBlock, tacticalTipTr: "Tomruk ile +1 İksir Kazanç (Fıçı varsa dikkat!)."),
                    CounterMoveRule(counterCardId: "skeletons", placement: .bridgeBlock, tacticalTipTr: "Köprü ağzında birimle yakala (+2 İksir).")
                ]
            ),
            CRCard(
                id: "magic_archer", nameTr: "Büyülü Okçu", nameEn: "Magic Archer", elixir: 4,
                type: .troop, role: .antiAir, evoCycles: nil, crownTowerDamage: 0,
                counters: [
                    CounterMoveRule(counterCardId: "fireball", placement: .bridgeBlock, tacticalTipTr: "Kuleye hizalama yapmasına izin verme, Alev Topu at.")
                ]
            ),
            CRCard(
                id: "electro_wizard", nameTr: "Elektro Büyücü", nameEn: "Electro Wizard", elixir: 4,
                type: .troop, role: .antiAir, evoCycles: nil, crownTowerDamage: 0,
                counters: [
                    CounterMoveRule(counterCardId: "skeletons", placement: .onTop, tacticalTipTr: "Kendi sahana geçince üstüne İskeletler veya Şövalye bırak (+3 İksir).")
                ]
            ),
            CRCard(
                id: "ice_wizard", nameTr: "Buz Büyücüsü", nameEn: "Ice Wizard", elixir: 3,
                type: .troop, role: .antiAir, evoCycles: 2, crownTowerDamage: 0,
                counters: [
                    CounterMoveRule(counterCardId: "fireball", placement: .backSafe, tacticalTipTr: "Alev Topu ile tekte öldür.")
                ]
            ),
            CRCard(
                id: "archers", nameTr: "Okçular", nameEn: "Archers", elixir: 3,
                type: .troop, role: .antiAir, evoCycles: 2, crownTowerDamage: 0,
                counters: [
                    CounterMoveRule(counterCardId: "arrows", placement: .backSafe, tacticalTipTr: "Oklar ile tekte temizle."),
                    CounterMoveRule(counterCardId: "the_log", placement: .towerFront, tacticalTipTr: "Kendi sahanda Tomruk ile +1 İksir Kazanç.")
                ]
            ),
            CRCard(
                id: "baby_dragon", nameTr: "Yavru Ejderha", nameEn: "Baby Dragon", elixir: 4,
                type: .troop, role: .antiAir, evoCycles: nil, crownTowerDamage: 0,
                counters: [
                    CounterMoveRule(counterCardId: "musketeer", placement: .backSafe, tacticalTipTr: "Silahşör veya Tesla ile indir.")
                ]
            ),
            CRCard(
                id: "mega_minion", nameTr: "Mega Dalkavuk", nameEn: "Mega Minion", elixir: 3,
                type: .troop, role: .antiAir, evoCycles: nil, crownTowerDamage: 0,
                counters: [
                    CounterMoveRule(counterCardId: "ice_spirit", placement: .center4_3, tacticalTipTr: "Buz Ruhu ile ortaya çek (+2 İksir).")
                ]
            ),
            CRCard(
                id: "night_witch", nameTr: "Gece Cadısı", nameEn: "Night Witch", elixir: 4,
                type: .troop, role: .antiAir, evoCycles: nil, crownTowerDamage: 0,
                counters: [
                    CounterMoveRule(counterCardId: "poison", placement: .onTop, tacticalTipTr: "Golem arkasındaysa Zehir ile hem Cadı'yı hem Yarasaları erit.")
                ]
            ),
            CRCard(
                id: "hunter", nameTr: "Avcı", nameEn: "Hunter", elixir: 4,
                type: .troop, role: .antiAir, evoCycles: nil, crownTowerDamage: 0,
                counters: [
                    CounterMoveRule(counterCardId: "skeletons", placement: .onTop, tacticalTipTr: "Saçmalarını 1 iksirlik İskeletler'e harcat (+3 İksir).")
                ]
            ),
            CRCard(
                id: "bowler", nameTr: "Atıcı", nameEn: "Bowler", elixir: 5,
                type: .troop, role: .antiAir, evoCycles: nil, crownTowerDamage: 0,
                counters: [
                    CounterMoveRule(counterCardId: "bats", placement: .onTop, tacticalTipTr: "Havaya vuramaz! Yarasalar ile +3 İksir Kazanç.")
                ]
            ),
            CRCard(
                id: "electro_dragon", nameTr: "Elektro Ejderha", nameEn: "Electro Dragon", elixir: 5,
                type: .troop, role: .antiAir, evoCycles: 1, crownTowerDamage: 0,
                counters: [
                    CounterMoveRule(counterCardId: "lightning", placement: .onTop, tacticalTipTr: "Yıldırım ile destek yığınını anında sil.")
                ]
            ),
            CRCard(
                id: "flying_machine", nameTr: "Uçan Makine", nameEn: "Flying Machine", elixir: 4,
                type: .troop, role: .antiAir, evoCycles: nil, crownTowerDamage: 0,
                counters: [
                    CounterMoveRule(counterCardId: "fireball", placement: .center4_3, tacticalTipTr: "Alev Topu ile tekte düşür.")
                ]
            ),
            CRCard(
                id: "zappies", nameTr: "Şok Birlikleri", nameEn: "Zappies", elixir: 4,
                type: .troop, role: .antiAir, evoCycles: nil, crownTowerDamage: 0,
                counters: [
                    CounterMoveRule(counterCardId: "fireball", placement: .backSafe, tacticalTipTr: "Alev Topu ile üçünü birden sil.")
                ]
            ),

            // CYCLE & SWARM
            CRCard(
                id: "skeletons", nameTr: "İskeletler", nameEn: "Skeletons", elixir: 1,
                type: .troop, role: .cycle, evoCycles: 2, crownTowerDamage: 0,
                counters: [
                    CounterMoveRule(counterCardId: "the_log", placement: .towerFront, tacticalTipTr: "Evrimli İskeletler çoğalmaya başlarsa Tomruk/Ruh at.")
                ]
            ),
            CRCard(
                id: "ice_spirit", nameTr: "Buz Ruhu", nameEn: "Ice Spirit", elixir: 1,
                type: .troop, role: .cycle, evoCycles: 2, crownTowerDamage: 0,
                counters: [
                    CounterMoveRule(counterCardId: "skeletons", placement: .towerFront, tacticalTipTr: "1 iksirlik birimle emdir.")
                ]
            ),
            CRCard(
                id: "electro_spirit", nameTr: "Elektro Ruh", nameEn: "Electro Spirit", elixir: 1,
                type: .troop, role: .cycle, evoCycles: nil, crownTowerDamage: 0,
                counters: [
                    CounterMoveRule(counterCardId: "skeletons", placement: .kingActivation, tacticalTipTr: "Kule önüne 1 birim koyarak zincirleme şokla Kral Kulesini aç!")
                ]
            ),
            CRCard(
                id: "goblin_gang", nameTr: "Goblin Çetesi", nameEn: "Goblin Gang", elixir: 3,
                type: .troop, role: .swarm, evoCycles: nil, crownTowerDamage: 0,
                counters: [
                    CounterMoveRule(counterCardId: "the_log", placement: .towerFront, tacticalTipTr: "Tomruk ile +1 İksir Kazanç."),
                    CounterMoveRule(counterCardId: "ice_spirit", placement: .center4_3, tacticalTipTr: "Buz Ruhu ile dondurup kuleye kestir (+2 İksir).")
                ]
            ),
            CRCard(
                id: "guards", nameTr: "Korumalar", nameEn: "Guards", elixir: 3,
                type: .troop, role: .swarm, evoCycles: nil, crownTowerDamage: 0,
                counters: [
                    CounterMoveRule(counterCardId: "arrows", placement: .towerFront, tacticalTipTr: "Oklar kalkanlarını kırıp tekte öldürür.")
                ]
            ),
            CRCard(
                id: "bats", nameTr: "Yarasalar", nameEn: "Bats", elixir: 2,
                type: .troop, role: .swarm, evoCycles: 2, crownTowerDamage: 0,
                counters: [
                    CounterMoveRule(counterCardId: "ice_spirit", placement: .center4_3, tacticalTipTr: "1 iksirlik Buz/Elektro Ruh tüm Yarasaları siler (+1 İksir)."),
                    CounterMoveRule(counterCardId: "zap", placement: .onTop, tacticalTipTr: "Çarpma ile anında temizle.")
                ]
            ),
            CRCard(
                id: "spear_goblins", nameTr: "Mızraklı Goblinler", nameEn: "Spear Goblins", elixir: 2,
                type: .troop, role: .swarm, evoCycles: nil, crownTowerDamage: 0,
                counters: [
                    CounterMoveRule(counterCardId: "skeletons", placement: .center4_3, tacticalTipTr: "+1 İksir Kazanç ile ortada karşıla.")
                ]
            ),

            // BUILDINGS
            CRCard(
                id: "cannon", nameTr: "Top", nameEn: "Cannon", elixir: 3,
                type: .building, role: .building, evoCycles: 2, crownTowerDamage: 0,
                counters: [
                    CounterMoveRule(counterCardId: "earthquake", placement: .center4_3, tacticalTipTr: "Domuz koşarken Top'un üstüne Deprem at.")
                ]
            ),
            CRCard(
                id: "tesla", nameTr: "Tesla", nameEn: "Tesla", elixir: 4,
                type: .building, role: .building, evoCycles: 2, crownTowerDamage: 0,
                counters: [
                    CounterMoveRule(counterCardId: "earthquake", placement: .center4_3, tacticalTipTr: "Deprem yer altındaki Tesla'ya bile tam hasar vurur (+1 İksir).")
                ]
            ),
            CRCard(
                id: "inferno_tower", nameTr: "Cehennem Kulesi", nameEn: "Inferno Tower", elixir: 5,
                type: .building, role: .building, evoCycles: nil, crownTowerDamage: 0,
                counters: [
                    CounterMoveRule(counterCardId: "zap", placement: .center4_3, tacticalTipTr: "Işını 2.5 sn ısındıktan sonra Çarpma ile sıfırla.")
                ]
            ),
            CRCard(
                id: "tombstone", nameTr: "Mezar Taşı", nameEn: "Tombstone", elixir: 3,
                type: .building, role: .building, evoCycles: nil, crownTowerDamage: 0,
                counters: [
                    CounterMoveRule(counterCardId: "the_log", placement: .center4_3, tacticalTipTr: "Kırılırken Tomruk yuvarlayarak çıkan 4 iskeleti de ez.")
                ]
            ),
            CRCard(
                id: "goblin_cage", nameTr: "Goblin Kafesi", nameEn: "Goblin Cage", elixir: 4,
                type: .building, role: .building, evoCycles: 1, crownTowerDamage: 0,
                counters: [
                    CounterMoveRule(counterCardId: "earthquake", placement: .center4_3, tacticalTipTr: "Deprem ile kırıp çıkan Kavgacıyı kendi sahanda kes.")
                ]
            ),
            CRCard(
                id: "bomb_tower", nameTr: "Bomba Kulesi", nameEn: "Bomb Tower", elixir: 4,
                type: .building, role: .building, evoCycles: nil, crownTowerDamage: 0,
                counters: [
                    CounterMoveRule(counterCardId: "bats", placement: .bridgeBlock, tacticalTipTr: "Havaya vuramaz! Hava birimiyle nehrin üstünden yık.")
                ]
            ),

            // SPELLS (WITH EXACT CROWN TOWER DAMAGE)
            CRCard(
                id: "the_log", nameTr: "Tomruk", nameEn: "The Log", elixir: 2,
                type: .spell, role: .smallSpell, evoCycles: nil, crownTowerDamage: 58,
                counters: [
                    CounterMoveRule(counterCardId: "goblin_barrel", placement: .oppositeBridgePunish, tacticalTipTr: "RAKİP TOMRUK HARCADI! Goblin Fıçısı veya Sürü ile şimdi saldır!")
                ]
            ),
            CRCard(
                id: "zap", nameTr: "Çarpma", nameEn: "Zap", elixir: 2,
                type: .spell, role: .smallSpell, evoCycles: 2, crownTowerDamage: 58,
                counters: [
                    CounterMoveRule(counterCardId: "bats", placement: .oppositeBridgePunish, tacticalTipTr: "Rakip Çarpma harcadı! Yarasalar ve Kıvılcım artık güvende.")
                ]
            ),
            CRCard(
                id: "arrows", nameTr: "Oklar", nameEn: "Arrows", elixir: 3,
                type: .spell, role: .smallSpell, evoCycles: nil, crownTowerDamage: 111,
                counters: [
                    CounterMoveRule(counterCardId: "firecracker", placement: .backSafe, tacticalTipTr: "Rakip Oklar harcadı! Havai Fişekçi ve Okçular artık güvende.")
                ]
            ),
            CRCard(
                id: "tornado", nameTr: "Kasırga", nameEn: "Tornado", elixir: 3,
                type: .spell, role: .smallSpell, evoCycles: nil, crownTowerDamage: 51,
                counters: [
                    CounterMoveRule(counterCardId: "hog_rider", placement: .oppositeBridgePunish, tacticalTipTr: "Rakip Kasırga harcadı! Domuz Binicisi şimdi kuleye yapışır!")
                ]
            ),
            CRCard(
                id: "barbarian_barrel", nameTr: "Barbar Varili", nameEn: "Barbarian Barrel", elixir: 2,
                type: .spell, role: .smallSpell, evoCycles: nil, crownTowerDamage: 0,
                counters: [
                    CounterMoveRule(counterCardId: "skeletons", placement: .towerFront, tacticalTipTr: "Çıkan Barbar'ı kendi sahanda oyala.")
                ]
            ),
            CRCard(
                id: "rage", nameTr: "Öfke", nameEn: "Rage", elixir: 2,
                type: .spell, role: .smallSpell, evoCycles: nil, crownTowerDamage: 58,
                counters: []
            ),
            CRCard(
                id: "earthquake", nameTr: "Deprem", nameEn: "Earthquake", elixir: 3,
                type: .spell, role: .bigSpell, evoCycles: nil, crownTowerDamage: 183,
                counters: [
                    CounterMoveRule(counterCardId: "cannon", placement: .center3_2, tacticalTipTr: "Rakibin elinde Deprem var! Binanı kuleyle aynı anda vurulmayacak 3-2 kareye kur!")
                ]
            ),
            CRCard(
                id: "fireball", nameTr: "Alev Topu", nameEn: "Fireball", elixir: 4,
                type: .spell, role: .bigSpell, evoCycles: nil, crownTowerDamage: 207,
                counters: [
                    CounterMoveRule(counterCardId: "musketeer", placement: .backSafe, tacticalTipTr: "Rakip Alev Topu harcadı! Menzilli destek birimlerini güvenle basabilirsin.")
                ]
            ),
            CRCard(
                id: "poison", nameTr: "Zehir", nameEn: "Poison", elixir: 4,
                type: .spell, role: .bigSpell, evoCycles: nil, crownTowerDamage: 224,
                counters: [
                    CounterMoveRule(counterCardId: "graveyard", placement: .oppositeBridgePunish, tacticalTipTr: "Rakip Zehir harcadı! Mezarlık veya sürü kartların için açık pencere!")
                ]
            ),
            CRCard(
                id: "freeze", nameTr: "Dondurma", nameEn: "Freeze", elixir: 4,
                type: .spell, role: .bigSpell, evoCycles: nil, crownTowerDamage: 35,
                counters: [
                    CounterMoveRule(counterCardId: "musketeer", placement: .backSafe, tacticalTipTr: "Rakibin destesinde Dondurma var! Savunmada iki birimi ASLA aynı anda yan yana atma.")
                ]
            ),
            CRCard(
                id: "lightning", nameTr: "Yıldırım", nameEn: "Lightning", elixir: 6,
                type: .spell, role: .bigSpell, evoCycles: nil, crownTowerDamage: 318,
                counters: [
                    CounterMoveRule(counterCardId: "knight", placement: .towerFront, tacticalTipTr: "Kulen düşük candaysa kule yanına yüksek canlı birim koyarak Yıldırım Paratoneri yap!")
                ]
            ),
            CRCard(
                id: "rocket", nameTr: "Roket", nameEn: "Rocket", elixir: 6,
                type: .spell, role: .bigSpell, evoCycles: nil, crownTowerDamage: 370,
                counters: [
                    CounterMoveRule(counterCardId: "hog_rider", placement: .oppositeBridgePunish, tacticalTipTr: "Rakip 6 iksirlik Roket attı! İksiri sıfırlandı, anında köprüden cezalandır!")
                ]
            )
        ]

        self.allCards = cards
        var dict: [String: CRCard] = [:]
        for c in cards { dict[c.id] = c }
        self.cardById = dict

        self.metaDecks = [
            CRMetaDeck(
                id: "hog_2_6",
                name: "2.6 Domuz Döngüsü (Classic 2.6 Hog Cycle)",
                archetype: "Cycle",
                avgElixir: 2.6,
                dangerPhase: "1x & 2x Hızlı Döngü",
                cards: ["hog_rider", "musketeer", "cannon", "ice_golem", "skeletons", "ice_spirit", "fireball", "the_log"],
                signatureCards: ["hog_rider", "ice_golem", "musketeer", "cannon"],
                howToBeatTr: "Top'u Deprem/Alev Topu ile kır veya iki koridordan aynı anda baskı kurarak Silahşör + Top savunmasını aş. Uzatmada Alev Topu + Tomruk döngüsüne gireceği için kule canını 800 altına düşürme!"
            ),
            CRMetaDeck(
                id: "log_bait_classic",
                name: "Klasik Log Bait (Fıçı + Prenses + Roket)",
                archetype: "Bait",
                avgElixir: 3.3,
                dangerPhase: "1x Yemleme & 3x Roket Döngüsü",
                cards: ["goblin_barrel", "princess", "knight", "goblin_gang", "inferno_tower", "ice_spirit", "rocket", "the_log"],
                signatureCards: ["goblin_barrel", "princess", "inferno_tower", "goblin_gang"],
                howToBeatTr: "TOMRUK'U ASLA PRENSES VEYA ÇETE'YE HARCAMA! Tomruk sadece Goblin Fıçısı içindir. Kule arkası 4+ iksirlik kart atma yoksa Kule + Birime Roket yersin!"
            ),
            CRMetaDeck(
                id: "hog_eq_firecracker",
                name: "Domuz + Deprem + Havai Fişekçi (Hog EQ)",
                archetype: "Cycle",
                avgElixir: 2.8,
                dangerPhase: "2x İksir Çift Domuz Döngüsü",
                cards: ["hog_rider", "firecracker", "earthquake", "tesla", "mighty_miner", "skeletons", "ice_spirit", "the_log"],
                signatureCards: ["hog_rider", "firecracker", "earthquake", "mighty_miner"],
                howToBeatTr: "İlk fırsatta Havai Fişekçi'nin şarapneliyle KRAL KULESİNİ AKTİF ET! Binanı her zaman yüksek (3-2) kareye kur ki rakip Deprem ile hem binanı hem Prenses Kuleni aynı anda vuramasın."
            ),
            CRMetaDeck(
                id: "pekka_bridge_spam",
                name: "P.E.K.K.A Bridge Spam (Köprü Baskısı)",
                archetype: "Bridge Spam",
                avgElixir: 3.9,
                dangerPhase: "Çift Koridor Cezalandırma",
                cards: ["pekka", "battle_ram", "bandit", "royal_ghost", "electro_wizard", "magic_archer", "fireball", "zap"],
                signatureCards: ["pekka", "battle_ram", "bandit", "royal_ghost"],
                howToBeatTr: "İksirini asla 3'ün altına düşürme! İksir kaybettiğin an köprüden Haydut / Koçbaşı / Hayalet basacaktır. P.E.K.K.A'yı ortadaki İskeletler/Buz Golemi ile oyala."
            ),
            CRMetaDeck(
                id: "lavaloon",
                name: "LavaLoon (Lav Tazısı + Balon)",
                archetype: "Beatdown",
                avgElixir: 4.1,
                dangerPhase: "2x İksir Hava Ordusu",
                cards: ["lava_hound", "balloon", "tombstone", "mega_minion", "valkyrie", "guards", "fireball", "zap"],
                signatureCards: ["lava_hound", "balloon", "tombstone"],
                howToBeatTr: "Rakip kule arkasına 7 iksirlik Lav Tazısı bıraktığı an TERS KORİDORDAN 4-5 iksirlik hızlı saldırı yap! Böylece Lav Tazısı arkasına Balon koyacak iksiri kalmaz."
            ),
            CRMetaDeck(
                id: "golem_beatdown",
                name: "Golem + Gece Cadısı + Oduncu Beatdown",
                archetype: "Beatdown",
                avgElixir: 4.3,
                dangerPhase: "2x & 3x İksir Tek Hamlede 3 Taç",
                cards: ["golem", "night_witch", "lumberjack", "baby_dragon", "electro_dragon", "tornado", "lightning", "barbarian_barrel"],
                signatureCards: ["golem", "night_witch", "lumberjack"],
                howToBeatTr: "1x İksirde Golem atarsa ters koridordan kulesini yık! Savunmada Golem'i bina ile uzağa çek, Gece Cadısı ve Elektro Ejderha'yı büyük büyü veya Valkür ile Golem'den ayırıp kes."
            ),
            CRMetaDeck(
                id: "xbow_3_0",
                name: "3.0 X-Yayı Kuşatma (X-Bow 3.0 Cycle)",
                archetype: "Siege",
                avgElixir: 3.0,
                dangerPhase: "Tek Kilitlenme + Tesla Savunması",
                cards: ["x_bow", "tesla", "knight", "archers", "skeletons", "electro_spirit", "fireball", "the_log"],
                signatureCards: ["x_bow", "tesla", "archers"],
                howToBeatTr: "Ana tankını asla kule arkasına boşa harcama! Rakip X-Yayı kurduğu an hemen aynı koridorda önüne tankını koy ve X-Yayı'na Deprem/Alev Topu/Roket at."
            ),
            CRMetaDeck(
                id: "splashyard",
                name: "Splashyard (Mezarlık + Zehir + Kasırga)",
                archetype: "Control",
                avgElixir: 3.6,
                dangerPhase: "2x & 3x Savunmadan Karşı Mezarlık",
                cards: ["graveyard", "poison", "tornado", "ice_wizard", "baby_dragon", "knight", "tombstone", "barbarian_barrel"],
                signatureCards: ["graveyard", "ice_wizard", "baby_dragon", "tombstone"],
                howToBeatTr: "Savunma yaptığı birimlerin köprüyü geçip Mezarlık için tanklamasına izin verme! Köprüde tankı bloke et ve Mezarlık üstüne Zehir / Valkür / Korumalar bırak."
            ),
            CRMetaDeck(
                id: "rg_fisherman",
                name: "Kraliyet Devi + Balıkçı + Avcı",
                archetype: "Control",
                avgElixir: 3.3,
                dangerPhase: "1x & 2x Köprü Baskısı",
                cards: ["royal_giant", "fisherman", "hunter", "royal_ghost", "skeletons", "electro_spirit", "fireball", "the_log"],
                signatureCards: ["royal_giant", "fisherman", "hunter"],
                howToBeatTr: "Mini P.E.K.K.A veya Şövalye ile Kraliyet Devi'ni keserken Balıkçı'nın onları çekmemesi için araya 1 iksirlik İskeletler koy!"
            ),
            CRMetaDeck(
                id: "miner_wb_poison",
                name: "Madenci + Duvar Yıkıcılar + Zehir",
                archetype: "Cycle",
                avgElixir: 2.9,
                dangerPhase: "Sürekli Çift Koridor Hasarı",
                cards: ["miner", "wall_breakers", "poison", "knight", "bats", "spear_goblins", "bomb_tower", "the_log"],
                signatureCards: ["miner", "wall_breakers", "bomb_tower"],
                howToBeatTr: "Küçük büyünü Duvar Yıkıcılar'a sakla, Madenci'yi birimle yakala. Kule arkasına Zehir değeri verecek birim atma!"
            ),
            CRMetaDeck(
                id: "goblin_giant_sparky",
                name: "Goblin Devi + Kıvılcım + Öfke",
                archetype: "Beatdown",
                avgElixir: 3.9,
                dangerPhase: "Köprüden Öfkeli Kıvılcım",
                cards: ["goblin_giant", "sparky", "mini_pekka", "dark_prince", "electro_wizard", "bats", "zap", "rage"],
                signatureCards: ["goblin_giant", "sparky", "rage"],
                howToBeatTr: "Kıvılcım'ın şarjını boşa harcatmak için tam üstüne İskeletler / Korumalar (Surround) bırak veya Elektro Büyücü / Roket kullan."
            ),
            CRMetaDeck(
                id: "mk_zap_bait",
                name: "Mega Şövalye + Çarpma Yemleme (MK Zap Bait)",
                archetype: "Bait",
                avgElixir: 3.5,
                dangerPhase: "Savunma Mega Şövalyesi + Karşı Sürü",
                cards: ["mega_knight", "miner", "goblin_gang", "bats", "spear_goblins", "wall_breakers", "inferno_tower", "zap"],
                signatureCards: ["mega_knight", "bats", "spear_goblins", "goblin_gang"],
                howToBeatTr: "Köprüde birliklerini üst üste yığma! Mega Şövalye'yi Şövalye/Valkür veya Buz Golemi uçurtmasıyla merkeze çekip +4 iksir avantajı al."
            ),
            CRMetaDeck(
                id: "lumberloon_freeze",
                name: "Oduncu + Balon + Dondurma (LumberLoon Freeze)",
                archetype: "Bridge Spam",
                avgElixir: 3.9,
                dangerPhase: "Sürpriz Köprü Oduncu+Balon+Dondurma",
                cards: ["lumberjack", "balloon", "freeze", "bowler", "electro_dragon", "baby_dragon", "tornado", "barbarian_barrel"],
                signatureCards: ["lumberjack", "balloon", "freeze", "bowler"],
                howToBeatTr: "Rakibin elinde 4 iksirlik DONDURMA var! Balon savunmasında asla Bina + Hava birimini yan yana koyma; önce binayla çek, Dondurma atıldıktan sonra Silahşör bırak!"
            ),
            CRMetaDeck(
                id: "recruits_royal_hogs",
                name: "Kraliyet Muhafızları + Kraliyet Domuzları",
                archetype: "Bridge Spam",
                avgElixir: 4.1,
                dangerPhase: "2x İksir Çift Koridor Bölünmüş Saldırı",
                cards: ["royal_recruits", "royal_hogs", "flying_machine", "zappies", "goblin_cage", "barbarian_barrel", "fireball", "arrows"],
                signatureCards: ["royal_recruits", "royal_hogs", "flying_machine", "zappies"],
                howToBeatTr: "Alev Topu'nu Uçan Makine veya Kraliyet Domuzları için sakla! Tam merkeze Bomba Kulesi veya Valkür koyarak her iki koridordaki Muhafızları ortaya topla."
            )
        ]
    }
}
