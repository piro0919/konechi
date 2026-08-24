import AppKit
import Network

// メニューバーの常駐。
//
// SwiftUI の MenuBarExtra ではなく AppKit で組んでいる。メニューの中身は OS 側のメニューとして
// 描かれるため、SwiftUI からは開閉の通知が取れない。通信量は開いている間だけ測る仕様なので、
// 開閉を知る必要がある。

@main
enum Konechi {
    static func main() {
        // 画面を出さずに計算だけ確かめる口。直したあとはこれを通す
        if CommandLine.arguments.contains("--selftest") {
            exit(SelfTest.run())
        }
        let app = NSApplication.shared
        let delegate = AppDelegate()
        app.delegate = delegate
        // Dock とアプリ切替に出さず、メニューバーだけに常駐する
        app.setActivationPolicy(.accessory)
        app.run()
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {
    private var statusItem: NSStatusItem!
    private let menu = NSMenu()

    private var status = LinkStatus()
    private let pathMonitor = NWPathMonitor()
    private let monitorQueue = DispatchQueue(label: "konechi.monitor")
    private var linkTimer: Timer?

    /// メニューを開いている間だけ動く。通信量は差分でしか出せないため
    private var throughputTimer: Timer?
    private var lastSample: (count: ByteCount, at: Date)?

    private var settingsWindow = SettingsWindowController()
    /// 画面を作り直すかの判断に使う。文字列は組み立て時に焼き込まれるため
    private var builtLanguage = Language.resolved

    private let infoItems = Dictionary(
        uniqueKeysWithValues: InfoRow.allCases.map { ($0, NSMenuItem()) })

    func applicationDidFinishLaunching(_ notification: Notification) {
        buildMenu()

        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusItem.menu = menu

        refresh()

        // 経路が変わった直後は構成データベースへの反映が僅かに遅れるため、変化の直後にもう一度読む
        pathMonitor.pathUpdateHandler = { [weak self] _ in
            DispatchQueue.main.async {
                self?.refresh()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) { self?.refresh() }
            }
        }
        pathMonitor.start(queue: monitorQueue)

        // 単位を変えたら、開いている表示にすぐ反映する
        NotificationCenter.default.addObserver(
            forName: .settingsChanged, object: nil, queue: .main
        ) { [weak self] _ in
            guard let self else { return }
            if self.builtLanguage != Language.resolved {
                self.builtLanguage = Language.resolved
                let wasVisible = self.settingsWindow.window?.isVisible ?? false
                self.settingsWindow.close()
                self.settingsWindow = SettingsWindowController()
                if wasVisible { self.settingsWindow.show() }
            }
            self.buildMenu()
            self.refresh()
        }

        // 取りこぼしの保険
        linkTimer = Timer.scheduledTimer(withTimeInterval: 5, repeats: true) { [weak self] _ in
            self?.refresh()
        }

        // 更新の確認は起動時に1回だけ。見つかったときだけ画面が出る
        Updater.shared.checkQuietly()

        // メニューを押さずに設定画面を出すための入口。見た目を確かめるときに使う
        if CommandLine.arguments.contains("--settings") {
            openSettings()
        }
    }

    // MARK: - メニュー

    /// 出す項目は設定で変えられるので、変わるたびに組み直す
    private func buildMenu() {
        menu.delegate = self
        menu.removeAllItems()

        let visible = InfoRow.allCases.filter(Settings.isVisible)
        let settled = visible.filter { !$0.isLive }
        let live = visible.filter(\.isLive)

        for row in settled {
            let item = infoItems[row]!
            item.isEnabled = false
            menu.addItem(item)
        }

        // 開いた時点で決まっている値と、毎秒動く値を分ける。片方しか無いときは線を引かない
        if !settled.isEmpty, !live.isEmpty { menu.addItem(.separator()) }

        for row in live {
            let item = infoItems[row]!
            item.isEnabled = false
            menu.addItem(item)
        }

        if !visible.isEmpty { menu.addItem(.separator()) }

        let settings = NSMenuItem(
            title: L.settings, action: #selector(openSettings), keyEquivalent: ",")
        settings.target = self
        menu.addItem(settings)
        menu.addItem(
            withTitle: L.quit, action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
    }

    /// メニューが開いた。通信量の計測を始める
    func menuWillOpen(_ menu: NSMenu) {
        refresh()
        lastSample = LinkProbe.byteCount(of: status.device).map { ($0, Date()) }
        setInfo(.down, "\(L.down): \(L.measuring)")
        setInfo(.up, "\(L.up): \(L.measuring)")

        throughputTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            self?.updateThroughput()
        }
        // メニューを開いている間、通常の実行ループは止まるので明示的に登録する
        RunLoop.current.add(throughputTimer!, forMode: .common)
    }

    /// メニューが閉じた。計測を止める
    func menuDidClose(_ menu: NSMenu) {
        throughputTimer?.invalidate()
        throughputTimer = nil
        lastSample = nil
    }

    // MARK: - 表示の更新

    private func refresh() {
        status = LinkProbe.current()

        // 見た目を確かめるための入口。実際にその状態を作らずにアイコンを差し替えられる。
        //   --state wired|wifi|offline|other   接続の種類を決め打ちする
        //   --vpn                              VPN 中として鍵バッジを出す
        if let index = CommandLine.arguments.firstIndex(of: "--state"),
            CommandLine.arguments.indices.contains(index + 1)
        {
            switch CommandLine.arguments[index + 1] {
            case "wired": status.kind = .wired
            case "wifi": status.kind = .wifi
            case "offline": status.kind = .none
            case "other": status.kind = .other
            default: break
            }
        }
        if CommandLine.arguments.contains("--vpn") {
            status.isTunneled = true
        }

        statusItem.button?.image = Icon.image(for: status.kind, tunneled: status.isTunneled)
        statusItem.button?.toolTip = status.kind.label

        setInfo(.kind, "\(L.connection): \(status.kind.label)" + (status.isTunneled ? L.viaVPN : ""))
        // サービス名だけ環境によって長さが大きく変わり、メニュー全体の幅を決めてしまう。
        // 上限を超えたら省略し、全体は説明の吹き出しで読めるようにする
        setInfo(.service, "\(L.service): \(shortened(status.serviceName))")
        infoItems[.service]!.toolTip =
            status.serviceName.count > Self.serviceNameLimit ? status.serviceName : nil
        setInfo(.device, "\(L.device): \(status.device)")
        setInfo(.ip, "\(L.ipAddress): \(status.ipAddress)")
        setInfo(.router, "\(L.router): \(status.router)")
        setInfo(.speed, "\(L.linkSpeed): \(status.linkSpeed ?? "-")")
    }

    private func updateThroughput() {
        guard
            let previous = lastSample,
            let now = LinkProbe.byteCount(of: status.device)
        else { return }

        let seconds = Date().timeIntervalSince(previous.at)
        guard seconds > 0 else { return }

        let down = Throughput.perSecond(
            previous: previous.count.received, now: now.received, seconds: seconds)
        let up = Throughput.perSecond(
            previous: previous.count.sent, now: now.sent, seconds: seconds)

        setInfo(.down, "\(L.down): \(rate(down))")
        setInfo(.up, "\(L.up): \(rate(up))")
        lastSample = (now, Date())
    }

    /// メニューの幅が環境によって暴れないよう、サービス名の長さに上限を置く。
    /// 実在の名前（USB 10/100/1000 LAN、Lenovo USB-C to LAN）はどちらも19文字なので、
    /// これは「これ以上広がらない」ための歯止めで、普段の幅は変えない
    private static let serviceNameLimit = 20

    /// 情報の行は一段小さい文字で出す。文字数を削らずに幅が縮み、操作の行とも区別が付く
    private func setInfo(_ row: InfoRow, _ text: String) {
        infoItems[row]!.attributedTitle = NSAttributedString(
            string: text,
            attributes: [
                .font: NSFont.menuFont(ofSize: 12),
                .foregroundColor: NSColor.secondaryLabelColor,
            ])
    }

    private func shortened(_ name: String) -> String {
        guard name.count > Self.serviceNameLimit else { return name }
        return name.prefix(Self.serviceNameLimit - 1) + "…"
    }

    private func rate(_ bytesPerSecond: Double) -> String {
        Settings.throughputUnit.formatted(bytesPerSecond)
    }

    @objc private func openSettings() {
        settingsWindow.show()
    }
}
