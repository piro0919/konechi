import AppKit

// メニューバーに出す絵を決める。
//
// キャラの絵は Resources に `konechi-<状態>.png` の名前で置く（命名は chappie v1 に倣った）。
// 絵がまだ無い状態でも動くよう、見つからなければ SF Symbols の記号で代用する。
// 絵が揃えば、この代用は自動的に使われなくなる。

enum Icon {
    /// メニューバーでの実寸。高さをこれに合わせる
    static let height: CGFloat = 22

    static func image(for kind: LinkKind, tunneled: Bool) -> NSImage? {
        // 記号を選んでいるときは絵を探しに行かない
        let base = Settings.iconStyle == .symbol ? symbol(for: kind) : artwork(for: kind) ?? symbol(for: kind)
        guard let base else { return nil }
        return tunneled ? withLockBadge(base) : base
    }

    // MARK: - キャラの絵

    private static func artwork(for kind: LinkKind) -> NSImage? {
        guard
            let url = Bundle.main.url(forResource: "konechi-\(name(of: kind))", withExtension: "png"),
            let image = NSImage(contentsOf: url)
        else { return nil }

        // 元の高解像度の中身を保ったまま、表示する大きさだけを指定する。
        // 指定した大きさの画像へ描き直すと Retina で引き伸ばされて粗くなる
        image.size = NSSize(width: height * (image.size.width / image.size.height), height: height)
        // キャラはカラーなので、単色化させない
        image.isTemplate = false
        return image
    }

    private static func name(of kind: LinkKind) -> String {
        switch kind {
        case .wired: return "wired"
        case .wifi: return "wifi"
        case .none: return "offline"
        case .other: return "default"
        }
    }

    // MARK: - 絵が無いときの代用

    private static func symbol(for kind: LinkKind) -> NSImage? {
        for candidate in kind.symbolCandidates {
            if let image = NSImage(systemSymbolName: candidate, accessibilityDescription: kind.label) {
                image.isTemplate = true
                return image
            }
        }
        return nil
    }

    // MARK: - VPN の鍵バッジ

    /// 右下に鍵を重ねる。重なりが読めるよう、重ねる前に周囲をくり抜く。
    /// 鍵の絵があればそれを使い、無ければ記号で代用する
    private static func withLockBadge(_ base: NSImage) -> NSImage {
        let badge = Settings.iconStyle == .symbol ? lockSymbol() : lockArtwork() ?? lockSymbol()
        guard let lock = badge else { return base }
        return compose(base: base, badge: lock)
    }

    /// 鍵の絵。高さは土台の半分に揃える
    private static func lockArtwork() -> NSImage? {
        guard
            let url = Bundle.main.url(forResource: "konechi-lock", withExtension: "png"),
            let image = NSImage(contentsOf: url)
        else { return nil }

        let badgeHeight = height * 0.5
        image.size = NSSize(
            width: badgeHeight * (image.size.width / image.size.height), height: badgeHeight)
        image.isTemplate = false
        return image
    }

    private static func lockSymbol() -> NSImage? {
        NSImage(systemSymbolName: "lock.fill", accessibilityDescription: "VPN")?
            .withSymbolConfiguration(.init(pointSize: height * 0.5, weight: .bold))
    }

    private static func compose(base: NSImage, badge lock: NSImage) -> NSImage {
        let size = NSSize(width: base.size.width + height * 0.16, height: base.size.height)
        let out = NSImage(size: size)

        out.lockFocus()
        let context = NSGraphicsContext.current!.cgContext

        base.draw(at: .zero, from: .zero, operation: .sourceOver, fraction: 1)

        let badge = NSRect(
            x: size.width - lock.size.width, y: 0,
            width: lock.size.width, height: lock.size.height)

        context.setBlendMode(.destinationOut)
        NSColor.black.set()
        NSBezierPath(ovalIn: badge.insetBy(dx: -height * 0.06, dy: -height * 0.06)).fill()
        context.setBlendMode(.normal)

        lock.draw(at: badge.origin, from: .zero, operation: .sourceOver, fraction: 1)
        out.unlockFocus()

        // 土台がキャラの絵（カラー）ならそのまま、記号なら単色のまま扱う
        out.isTemplate = base.isTemplate
        return out
    }
}
