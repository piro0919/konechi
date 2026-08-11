// 判定ロジックを端末から確かめるための小さな実行ファイル。
// Sources/Link.swift をアプリと共有しているので、ここで見える結果がメニューバーの表示と一致する。
//
//   ./probe.sh          いまの主経路と通信量
//   ./probe.sh en0 en9  指定したデバイスの種別だけを引く
import Foundation

let devices = Array(CommandLine.arguments.dropFirst())

func formatted(_ bytesPerSecond: Double) -> String {
    let units = ["B/s", "KB/s", "MB/s", "GB/s"]
    var value = bytesPerSecond
    var unit = 0
    while value >= 1024, unit < units.count - 1 {
        value /= 1024
        unit += 1
    }
    return String(format: "%.1f %@", value, units[unit])
}

if devices.isEmpty {
    let status = LinkProbe.current()
    print("接続:       \(status.kind.label)\(status.isTunneled ? "（VPN 経由）" : "")")
    print("サービス:   \(status.serviceName)")
    print("デバイス:   \(status.device)")
    print("IP:         \(status.ipAddress)")
    print("ルーター:   \(status.router)")
    print("リンク速度: \(status.linkSpeed ?? "-")")

    // 通信量は差分でしか出せないので、1秒あけて2回読む
    if let first = LinkProbe.byteCount(of: status.device) {
        Thread.sleep(forTimeInterval: 1)
        if let second = LinkProbe.byteCount(of: status.device) {
            let down = Double(second.received &- first.received)
            let up = Double(second.sent &- first.sent)
            print("通信量:     下り \(formatted(down)) / 上り \(formatted(up))")
        }
    }

    if let underlying = LinkProbe.underlyingPhysical() {
        print("物理経路:   \(underlying.kind.label) / \(underlying.serviceName) / \(underlying.device)")
    }
} else {
    for device in devices {
        let described = LinkProbe.describe(device: device)
        let speed = LinkProbe.linkSpeed(of: device).map { " / \($0)" } ?? ""
        print("\(device): \(described.kind.label) / \(described.serviceName)\(speed)")
    }
}
