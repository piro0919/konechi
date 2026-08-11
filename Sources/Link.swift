import Foundation
import SystemConfiguration

// MARK: - 接続の種類

enum LinkKind {
    case wired
    case wifi
    case other
    case none

    var label: String {
        switch self {
        case .wired: return L.wired
        case .wifi: return L.wifi
        case .other: return L.other
        case .none: return L.offline
        }
    }

    /// 記号が古い OS に無い場合に備えて候補を順に試す
    var symbolCandidates: [String] {
        switch self {
        case .wired: return ["cable.connector.horizontal", "cable.connector", "network"]
        case .wifi: return ["wifi"]
        case .other: return ["globe", "network"]
        case .none: return ["network.slash", "wifi.slash", "xmark.circle"]
        }
    }
}

struct LinkStatus {
    var kind: LinkKind = .none
    /// システム環境設定に出る名前（例: USB 10/100/1000 LAN）
    var serviceName: String = "-"
    /// BSD 名（例: en9）
    var device: String = "-"
    var ipAddress: String = "-"
    var router: String = "-"
    /// この線が何で繋がっているか（例: 1000baseT）。取れないときは nil
    var linkSpeed: String?
    /// VPN のトンネルを通っているか。kind は下の物理経路を指す
    var isTunneled = false
}

/// 送受信の累計バイト数。差分を取って通信量にする
struct ByteCount {
    var received: UInt64 = 0
    var sent: UInt64 = 0
}

// MARK: - 状態の取得

enum LinkProbe {
    /// デフォルト経路が向いているインターフェースを構成データベースから読む
    static func current() -> LinkStatus {
        var status = LinkStatus()

        guard
            let store = SCDynamicStoreCreate(nil, "konechi" as CFString, nil, nil),
            let global = SCDynamicStoreCopyValue(store, "State:/Network/Global/IPv4" as CFString)
                as? [String: Any],
            let device = global["PrimaryInterface"] as? String
        else {
            return status
        }

        status.device = device
        status.router = global["Router"] as? String ?? "-"
        status.ipAddress = ipv4Address(of: device) ?? "-"

        let described = describe(device: device)
        status.kind = described.kind
        status.serviceName = described.serviceName

        // 主経路が VPN のトンネルなどで有線でも Wi-Fi でもないときは、
        // その下で実際に使われている物理経路まで辿る。
        // 「有線か Wi-Fi か」を失わずに、トンネルであることを別に持つため。
        if described.kind == .other, let underlying = underlyingPhysical() {
            status.isTunneled = true
            status.kind = underlying.kind
            status.serviceName = underlying.serviceName
        }

        status.linkSpeed = linkSpeed(of: status.isTunneled ? (underlyingPhysical()?.device ?? device) : device)

        return status
    }

    /// ネットワークサービスの優先順に見て、IPv4 アドレスを持つ最初の物理経路を返す。
    /// VPN のトンネルが主経路になっているときに、その下を知るために使う。
    static func underlyingPhysical() -> (kind: LinkKind, serviceName: String, device: String)? {
        guard
            let store = SCDynamicStoreCreate(nil, "konechi" as CFString, nil, nil),
            let setup = SCDynamicStoreCopyValue(store, "Setup:/Network/Global/IPv4" as CFString)
                as? [String: Any],
            let order = setup["ServiceOrder"] as? [String]
        else { return nil }

        for serviceID in order {
            let key = "State:/Network/Service/\(serviceID)/IPv4" as CFString
            guard
                let state = SCDynamicStoreCopyValue(store, key) as? [String: Any],
                let name = state["InterfaceName"] as? String
            else { continue }

            let described = describe(device: name)
            if described.kind == .wired || described.kind == .wifi {
                return (described.kind, described.serviceName, name)
            }
        }
        return nil
    }

    /// この線が何で繋がっているか（例: 1000baseT）。
    /// ioctl の SIOCGIFMEDIA は定数が Swift へ取り込めないため ifconfig の出力を読む。
    /// メニューを開いたときにしか呼ばないので、外部コマンドを起こす費用は問題にならない。
    static func linkSpeed(of device: String) -> String? {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/sbin/ifconfig")
        process.arguments = [device]

        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = FileHandle.nullDevice

        do { try process.run() } catch { return nil }

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        process.waitUntilExit()

        guard let text = String(data: data, encoding: .utf8) else { return nil }

        // 例: "	media: autoselect (1000baseT <full-duplex>)"
        guard let line = text.split(separator: "\n").first(where: { $0.contains("media:") })
        else { return nil }

        if let open = line.firstIndex(of: "("), let close = line.lastIndex(of: ")") {
            let inside = line[line.index(after: open)..<close]
            return inside.split(separator: " ").first.map(String.init)
        }

        // 括弧が無いのは autoselect のみ（Wi-Fi など）か、種別が読めない場合。どちらも速度としては出さない
        let value = line.replacingOccurrences(of: "media:", with: "").trimmingCharacters(
            in: .whitespaces)
        return value.isEmpty || value == "autoselect" || value.hasPrefix("<") ? nil : value
    }

    /// 指定したデバイスの送受信の累計バイト数
    static func byteCount(of device: String) -> ByteCount? {
        var head: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&head) == 0, head != nil else { return nil }
        defer { freeifaddrs(head) }

        var cursor = head
        while let entry = cursor {
            defer { cursor = entry.pointee.ifa_next }

            guard
                let addr = entry.pointee.ifa_addr,
                addr.pointee.sa_family == UInt8(AF_LINK),
                String(cString: entry.pointee.ifa_name) == device,
                let raw = entry.pointee.ifa_data
            else { continue }

            let data = raw.assumingMemoryBound(to: if_data.self).pointee
            return ByteCount(received: UInt64(data.ifi_ibytes), sent: UInt64(data.ifi_obytes))
        }
        return nil
    }

    /// BSD 名から接続の種類と表示名を引く
    static func describe(device: String) -> (kind: LinkKind, serviceName: String) {
        guard let interface = interface(withBSDName: device) else {
            return (.other, device)
        }

        let name = SCNetworkInterfaceGetLocalizedDisplayName(interface) as String? ?? device

        switch SCNetworkInterfaceGetInterfaceType(interface) as String? {
        case String(kSCNetworkInterfaceTypeIEEE80211):
            return (.wifi, name)
        case String(kSCNetworkInterfaceTypeEthernet):
            return (.wired, name)
        default:
            return (.other, name)
        }
    }

    private static func interface(withBSDName name: String) -> SCNetworkInterface? {
        guard let all = SCNetworkInterfaceCopyAll() as? [SCNetworkInterface] else { return nil }
        return all.first { SCNetworkInterfaceGetBSDName($0) as String? == name }
    }

    private static func ipv4Address(of device: String) -> String? {
        var head: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&head) == 0, let first = head else { return nil }
        defer { freeifaddrs(head) }

        var cursor: UnsafeMutablePointer<ifaddrs>? = first
        while let entry = cursor {
            defer { cursor = entry.pointee.ifa_next }

            guard
                let addr = entry.pointee.ifa_addr,
                addr.pointee.sa_family == UInt8(AF_INET),
                String(cString: entry.pointee.ifa_name) == device
            else { continue }

            var buffer = [CChar](repeating: 0, count: Int(NI_MAXHOST))
            let result = getnameinfo(
                addr, socklen_t(addr.pointee.sa_len),
                &buffer, socklen_t(buffer.count),
                nil, 0, NI_NUMERICHOST)
            if result == 0 { return String(cString: buffer) }
        }
        return nil
    }
}
