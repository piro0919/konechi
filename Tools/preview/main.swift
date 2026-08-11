// 絵をメニューバーの実寸で確かめる。
//
// 拡大して良く見えても実寸で潰れることが多い。明るい帯と暗い帯の両方に置いて、
// 背景の明暗どちらでも沈まないかも同時に見る。
import AppKit

let paths = Array(CommandLine.arguments.dropFirst())
guard !paths.isEmpty else {
    print("使い方: ./preview.sh <png> [<png>…]")
    exit(1)
}

let actual: CGFloat = 21  // メニューバーでの実寸
let sizes: [CGFloat] = [actual, actual * 2, 96]
let rowHeight: CGFloat = 120
let width: CGFloat = 620
let height = rowHeight * CGFloat(paths.count) + 20
let scale: CGFloat = 3

let sheet = NSImage(size: NSSize(width: width * scale, height: height * scale))
sheet.lockFocus()
NSGraphicsContext.current!.cgContext.scaleBy(x: scale, y: scale)

// 上半分を暗く、下半分を明るくして、同じ絵を両方の背景で見る
NSColor(calibratedWhite: 0.12, alpha: 1).setFill()
NSBezierPath(rect: NSRect(x: 0, y: 0, width: width, height: height)).fill()
NSColor(calibratedWhite: 0.93, alpha: 1).setFill()
NSBezierPath(rect: NSRect(x: 0, y: 0, width: width, height: height / 2)).fill()

let labelAttributes: [NSAttributedString.Key: Any] = [
    .font: NSFont.monospacedSystemFont(ofSize: 10, weight: .regular),
    .foregroundColor: NSColor.gray,
]

for (index, path) in paths.enumerated() {
    guard let image = NSImage(contentsOfFile: path) else {
        print("読めません: \(path)")
        continue
    }
    let y = height - 10 - rowHeight * CGFloat(index + 1)
    let ratio = image.size.width / image.size.height

    var x: CGFloat = 24
    for size in sizes {
        image.draw(
            in: NSRect(x: x, y: y + rowHeight / 2 - size / 2, width: size * ratio, height: size))
        x += size * ratio + 28
    }

    let name = (path as NSString).lastPathComponent
    let ratioText = String(format: "%.2f", ratio)
    ("\(name)  実寸\(Int(actual))pt / 2倍 / 96pt  横縦比 \(ratioText)" as NSString)
        .draw(at: NSPoint(x: 24, y: y + 6), withAttributes: labelAttributes)
}

sheet.unlockFocus()

let output = "docs/preview.png"
let rep = NSBitmapImageRep(data: sheet.tiffRepresentation!)!
try! rep.representation(using: .png, properties: [:])!
    .write(to: URL(fileURLWithPath: output))
print("\(output) を作りました")
