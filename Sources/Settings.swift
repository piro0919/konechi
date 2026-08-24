import Foundation
import ServiceManagement

// 設定の保存と読み出し。
//
// 数が少ないので UserDefaults に直接置く。ログイン時の起動だけは OS 側が持つ状態なので、
// こちらでは持たず ServiceManagement に問い合わせる。二重に持つと必ずずれる。

enum ThroughputUnit: String, CaseIterable {
    /// MB/s のようなバイト表記。ファイルの大きさと同じ尺度
    case bytes
    /// Mbps のようなビット表記。回線の速度と同じ尺度
    case bits

    var label: String {
        switch self {
        case .bytes: return L.unitBytes
        case .bits: return L.unitBits
        }
    }

    func formatted(_ bytesPerSecond: Double) -> String {
        switch self {
        case .bytes:
            // ファイルの大きさと同じ尺度なので 1024 で刻む
            return scaled(bytesPerSecond, by: 1024, units: ["B/s", "KB/s", "MB/s", "GB/s"])
        case .bits:
            // 回線の速度と同じ尺度。こちらは 1000 で刻む。1Mbps は 10^6 bps であって
            // 2^20 bps ではないので、1024 で割ると回線の公称値と食い違う
            return scaled(bytesPerSecond * 8, by: 1000, units: ["bps", "Kbps", "Mbps", "Gbps"])
        }
    }

    private func scaled(_ value: Double, by step: Double, units: [String]) -> String {
        var value = value
        var index = 0
        while value >= step, index < units.count - 1 {
            value /= step
            index += 1
        }
        return String(format: "%.1f %@", value, units[index])
    }
}

/// メニューバーに出すアイコンの見た目
enum IconStyle: String, CaseIterable {
    /// キャラクターの絵
    case character
    /// macOS 標準の記号。他のメニューバー項目と揃えたい人向け
    case symbol

    var label: String {
        switch self {
        case .character: return L.styleCharacter
        case .symbol: return L.styleSymbol
        }
    }
}

/// メニューに出す情報の行
enum InfoRow: String, CaseIterable {
    case kind, service, device, ip, router, speed, down, up

    var label: String {
        switch self {
        case .kind: return L.connection
        case .service: return L.service
        case .device: return L.device
        case .ip: return L.ipAddress
        case .router: return L.router
        case .speed: return L.linkSpeed
        case .down: return L.down
        case .up: return L.up
        }
    }

    /// 接続はこのアプリの本体なので隠せない
    var isFixed: Bool { self == .kind }

    /// 毎秒動く値。開いた時点で決まる値とは区切り線で分ける
    var isLive: Bool { self == .down || self == .up }
}

enum Settings {
    private static let unitKey = "throughputUnit"
    private static let hiddenRowsKey = "hiddenInfoRows"
    private static let languageKey = "language"
    private static let iconStyleKey = "iconStyle"

    // MARK: - アイコンの見た目

    static var iconStyle: IconStyle {
        get {
            UserDefaults.standard.string(forKey: iconStyleKey)
                .flatMap(IconStyle.init(rawValue:)) ?? .character
        }
        set {
            UserDefaults.standard.set(newValue.rawValue, forKey: iconStyleKey)
            NotificationCenter.default.post(name: .settingsChanged, object: nil)
        }
    }

    // MARK: - 言語

    /// 既定は「システムに従う」。実際にどちらを使うかは Language.resolved が決める
    static var language: Language {
        get {
            UserDefaults.standard.string(forKey: languageKey)
                .flatMap(Language.init(rawValue:)) ?? .system
        }
        set {
            UserDefaults.standard.set(newValue.rawValue, forKey: languageKey)
            NotificationCenter.default.post(name: .settingsChanged, object: nil)
        }
    }

    // MARK: - メニューに出す項目

    /// 隠している行。既定は「全部出す」なので、保存するのは隠したものだけにする。
    /// 出すものを保存すると、後から行が増えたときに既存の利用者へ出なくなる
    static var hiddenRows: Set<InfoRow> {
        get {
            let saved = UserDefaults.standard.stringArray(forKey: hiddenRowsKey) ?? []
            return Set(saved.compactMap(InfoRow.init(rawValue:)).filter { !$0.isFixed })
        }
        set {
            UserDefaults.standard.set(
                newValue.filter { !$0.isFixed }.map(\.rawValue), forKey: hiddenRowsKey)
            NotificationCenter.default.post(name: .settingsChanged, object: nil)
        }
    }

    static func isVisible(_ row: InfoRow) -> Bool {
        !hiddenRows.contains(row)
    }

    static func setVisible(_ row: InfoRow, _ visible: Bool) {
        var rows = hiddenRows
        if visible { rows.remove(row) } else { rows.insert(row) }
        hiddenRows = rows
    }

    static var throughputUnit: ThroughputUnit {
        get {
            UserDefaults.standard.string(forKey: unitKey)
                .flatMap(ThroughputUnit.init(rawValue:)) ?? .bytes
        }
        set {
            UserDefaults.standard.set(newValue.rawValue, forKey: unitKey)
            NotificationCenter.default.post(name: .settingsChanged, object: nil)
        }
    }

    // MARK: - ログイン時の起動

    /// 状態は OS 側が持っているので、こちらでは覚えず毎回問い合わせる
    static var launchesAtLogin: Bool {
        SMAppService.mainApp.status == .enabled
    }

    /// 切り替えに失敗したら理由を返す。成功なら nil
    static func setLaunchesAtLogin(_ enabled: Bool) -> String? {
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
            return nil
        } catch {
            return error.localizedDescription
        }
    }
}

extension Notification.Name {
    static let settingsChanged = Notification.Name("konechi.settingsChanged")
}
