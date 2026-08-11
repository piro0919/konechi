// メニューバーに出す記号を検討するための画像を作る。
// 実寸（15pt）と拡大を並べて描くので、小さくしたときに形が潰れるかをその場で判断できる。
//
//   ./mockup.sh        docs/symbols.png と docs/badge.png を作り直して開く
import AppKit

// MARK: - 描画の部品

/// 記号を白一色の画像として取り出す。メニューバーでの見え方に寄せるため。
func white(_ name: String, _ pt: CGFloat) -> NSImage? {
    guard
        let base = NSImage(systemSymbolName: name, accessibilityDescription: nil)?
            .withSymbolConfiguration(.init(pointSize: pt, weight: .regular))
    else { return nil }

    let out = NSImage(size: base.size)
    out.lockFocus()
    base.draw(at: .zero, from: .zero, operation: .sourceOver, fraction: 1)
    NSColor.white.set()
    NSRect(origin: .zero, size: base.size).fill(using: .sourceAtop)
    out.unlockFocus()
    return out
}

/// 土台の右下に小さな記号を重ねる。重なりが読めるよう、重ねる前に周囲をくり抜く。
func badged(base: String, badge: String, pt: CGFloat) -> NSImage? {
    guard let body = white(base, pt), let mark = white(badge, pt * 0.52) else { return nil }

    let size = NSSize(
        width: body.size.width + pt * 0.18,
        height: max(body.size.height, mark.size.height * 1.4))
    let out = NSImage(size: size)
    out.lockFocus()
    let ctx = NSGraphicsContext.current!.cgContext

    body.draw(
        at: NSPoint(x: 0, y: (size.height - body.size.height) / 2), from: .zero,
        operation: .sourceOver, fraction: 1)

    let markRect = NSRect(
        x: size.width - mark.size.width, y: 0,
        width: mark.size.width, height: mark.size.height)

    ctx.setBlendMode(.destinationOut)
    NSColor.white.set()
    NSBezierPath(ovalIn: markRect.insetBy(dx: -pt * 0.07, dy: -pt * 0.07)).fill()
    ctx.setBlendMode(.normal)

    mark.draw(at: markRect.origin, from: .zero, operation: .sourceOver, fraction: 1)

    out.unlockFocus()
    return out
}

/// 1行ぶんの見本。実寸と拡大の2つを同じ作り方で描くため、大きさを引数に取る。
struct Row {
    let label: String
    let make: (CGFloat) -> NSImage?
}

func writeSheet(_ rows: [Row], to path: String, labelX: CGFloat) {
    let scale: CGFloat = 3
    let rowHeight: CGFloat = 52
    let width: CGFloat = labelX + 400
    let height = rowHeight * CGFloat(rows.count) + 20

    let sheet = NSImage(size: NSSize(width: width * scale, height: height * scale))
    sheet.lockFocus()
    NSGraphicsContext.current!.cgContext.scaleBy(x: scale, y: scale)

    NSColor(calibratedWhite: 0.10, alpha: 1).setFill()
    NSBezierPath(rect: NSRect(x: 0, y: 0, width: width, height: height)).fill()

    let attributes: [NSAttributedString.Key: Any] = [
        .font: NSFont.systemFont(ofSize: 11),
        .foregroundColor: NSColor(calibratedWhite: 0.75, alpha: 1),
    ]

    for (index, row) in rows.enumerated() {
        let y = height - 10 - rowHeight * CGFloat(index + 1)

        if let actual = row.make(15) {  // メニューバーと同じ大きさ
            actual.draw(
                at: NSPoint(x: 24, y: y + rowHeight / 2 - actual.size.height / 2), from: .zero,
                operation: .sourceOver, fraction: 1)
        }
        if let zoomed = row.make(36) {  // 形を確かめる用
            zoomed.draw(
                at: NSPoint(x: 110, y: y + rowHeight / 2 - zoomed.size.height / 2), from: .zero,
                operation: .sourceOver, fraction: 1)
        }
        (row.label as NSString).draw(
            at: NSPoint(x: labelX, y: y + rowHeight / 2 - 7), withAttributes: attributes)
    }

    sheet.unlockFocus()

    let rep = NSBitmapImageRep(data: sheet.tiffRepresentation!)!
    try! rep.representation(using: .png, properties: [:])!
        .write(to: URL(fileURLWithPath: path))
}

// MARK: - 見本の中身

/// 単体の記号を並べた一覧
let symbolRows: [Row] = [
    "cable.connector.horizontal", "cable.connector", "powerplug", "poweroutlet.type.b",
    "cable.coaxial", "link", "network", "point.3.connected.trianglepath.dotted",
    "wifi", "wifi.slash", "network.slash", "antenna.radiowaves.left.and.right",
].map { name in Row(label: name) { white(name, $0) } }

/// VPN のときに右下へ鍵を足す案
let badgeRows: [Row] = [
    Row(label: "有線 + 鍵（合成）") { badged(base: "cable.connector.horizontal", badge: "lock.fill", pt: $0) },
    Row(label: "Wi-Fi + 鍵（合成）") { badged(base: "wifi", badge: "lock.fill", pt: $0) },
    Row(label: "network.badge.shield.half.filled（既製・実寸で潰れる）") {
        white("network.badge.shield.half.filled", $0)
    },
    Row(label: "有線（比較・鍵なし）") { white("cable.connector.horizontal", $0) },
]

let outputDirectory = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "docs"
writeSheet(symbolRows, to: "\(outputDirectory)/symbols.png", labelX: 190)
writeSheet(badgeRows, to: "\(outputDirectory)/badge.png", labelX: 230)
print("\(outputDirectory)/symbols.png と \(outputDirectory)/badge.png を作りました")
