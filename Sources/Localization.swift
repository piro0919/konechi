import Foundation

// 表示文字列。
//
// .lproj は使わず Swift の表に置く。ビルドを自前の shell で組んでいて、
// 文字列だけのために資源の仕組みを足すと build.sh が重くなるため。
// 言語は2つしかないので、この形のほうが追いやすい。

enum Language: String, CaseIterable {
    case system, ja, en

    /// 実際に使う言語。既定は英語で、環境が日本語のときだけ日本語にする
    static var resolved: Language {
        switch Settings.language {
        case .ja: return .ja
        case .en: return .en
        case .system:
            let preferred = Locale.preferredLanguages.first ?? "en"
            return preferred.hasPrefix("ja") ? .ja : .en
        }
    }

    var label: String {
        switch self {
        case .system: return L.t("システムに従う", "Follow system")
        case .ja: return "日本語"
        case .en: return "English"
        }
    }
}

enum L {
    static func t(_ ja: String, _ en: String) -> String {
        Language.resolved == .ja ? ja : en
    }

    // 接続の種類
    static var wired: String { t("有線", "Wired") }
    static var wifi: String { "Wi-Fi" }
    static var other: String { t("その他", "Other") }
    static var offline: String { t("未接続", "Offline") }

    // メニュー
    static var connection: String { t("接続", "Connection") }
    static var service: String { t("サービス", "Service") }
    static var device: String { t("デバイス", "Device") }
    static var ipAddress: String { t("IP アドレス", "IP address") }
    static var router: String { t("ルーター", "Router") }
    static var linkSpeed: String { t("リンク速度", "Link speed") }
    static var down: String { t("下り", "Down") }
    static var up: String { t("上り", "Up") }
    static var viaVPN: String { t("（VPN 経由）", " (via VPN)") }
    static var measuring: String { t("測定中…", "measuring…") }
    static var settings: String { t("設定…", "Settings…") }
    static var quit: String { t("終了", "Quit") }

    // 設定画面
    static var settingsTitle: String { t("Konechi の設定", "Konechi Settings") }
    static var launchAtLogin: String { t("ログイン時に起動する", "Launch at login") }
    static var throughputUnit: String { t("通信量の単位", "Throughput unit") }
    static var unitBytes: String { t("バイト（MB/s）", "Bytes (MB/s)") }
    static var unitBits: String { t("ビット（Mbps）", "Bits (Mbps)") }
    static var visibleRows: String { t("メニューに出す項目", "Rows shown in the menu") }
    static var language: String { t("言語", "Language") }
    static var checkForUpdates: String { t("更新を確認", "Check for updates") }
    static var iconStyle: String { t("アイコン", "Icon") }
    static var styleCharacter: String { t("コネち", "Konechi") }
    static var styleSymbol: String { t("記号", "Symbol") }
    static func launchToggleFailed(_ reason: String) -> String {
        t("切り替えられませんでした: \(reason)", "Could not change it: \(reason)")
    }
}
