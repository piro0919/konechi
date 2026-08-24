import Foundation

/// 画面を出さずに、計算だけを確かめる。`./Konechi --selftest` で走る。
/// 触れるのは値の計算だけで、ネットワークにも設定にも触らない。
enum SelfTest {

    private static var failures = 0

    static func run() -> Int32 {
        failures = 0

        // 累計カウンタから毎秒の通信量を出す
        do {
            check(Throughput.perSecond(previous: 0, now: 2048, seconds: 2) == 1024,
                  "差を秒数で割る")
            check(Throughput.perSecond(previous: 1000, now: 1000, seconds: 1) == 0,
                  "動きが無ければ 0")

            // 線を挿し直すとカウンタは 0 から数え直す。そのまま引くと
            // UInt64 が回り込んで、あり得ない速度が出る
            check(Throughput.perSecond(previous: 1_000_000, now: 100, seconds: 1) == 0,
                  "カウンタが戻ったら測らない")
            check(Throughput.perSecond(previous: 0, now: 1024, seconds: 0) == 0,
                  "秒数が 0 なら測らない")
            check(Throughput.perSecond(previous: 0, now: 1024, seconds: -1) == 0,
                  "秒数が負なら測らない")
        }

        // 単位の付け方
        do {
            check(ThroughputUnit.bytes.formatted(0) == "0.0 B/s", "0 はそのまま B/s")
            check(ThroughputUnit.bytes.formatted(512) == "512.0 B/s", "1024 未満は繰り上げない")
            check(ThroughputUnit.bytes.formatted(1024) == "1.0 KB/s", "1024 で KB/s になる")
            check(ThroughputUnit.bytes.formatted(1024 * 1024) == "1.0 MB/s", "MB/s まで上がる")
            check(ThroughputUnit.bytes.formatted(1024 * 1024 * 1024) == "1.0 GB/s",
                  "GB/s まで上がる")

            // 一番大きい単位で頭打ちにする。これ以上の桁は出さない
            check(ThroughputUnit.bytes.formatted(1024.0 * 1024 * 1024 * 1024).hasSuffix("GB/s"),
                  "GB/s より上には行かない")

            // ビット表記は 8 倍してから、1000 刻みで上げる。回線の速度は
            // 1Mbps = 10^6 bps なので、ここを 1024 にすると公称値と食い違う
            check(ThroughputUnit.bits.formatted(0) == "0.0 bps", "0 はそのまま bps")
            check(ThroughputUnit.bits.formatted(125) == "1.0 Kbps", "125 B/s は 1.0 Kbps")
            check(ThroughputUnit.bits.formatted(125_000) == "1.0 Mbps", "125 KB/s は 1.0 Mbps")
            check(ThroughputUnit.bits.formatted(124) == "992.0 bps", "1000 未満は繰り上げない")
            check(ThroughputUnit.bits.formatted(125_000_000) == "1.0 Gbps", "Gbps まで上がる")
            check(ThroughputUnit.bits.formatted(1_250_000_000).hasSuffix("Gbps"),
                  "Gbps より上には行かない")
        }

        // メニューに出す行の性質
        do {
            check(InfoRow.kind.isFixed, "接続の行は隠せない")
            check(InfoRow.allCases.filter(\.isFixed).count == 1, "隠せない行はひとつだけ")
            check(InfoRow.down.isLive && InfoRow.up.isLive, "通信量の行は毎秒動く")
            check(InfoRow.allCases.filter(\.isLive).count == 2, "毎秒動く行は上りと下りだけ")
        }

        print(failures == 0 ? "全部通りました" : "\(failures) 件こけました")
        return failures == 0 ? 0 : 1
    }

    private static func check(_ condition: Bool, _ what: String) {
        if condition {
            print("  ok   \(what)")
        } else {
            print("  NG   \(what)")
            failures += 1
        }
    }
}
