import AppKit
import Sparkle

// 自動更新。
//
// galopen と同じ挙動に揃える。確認は起動時に1回だけで、定期的には見に行かない。
// 見つかったときだけ画面を出し、入れるかどうかを毎回尋ねる。
//
// Sparkle は既定だと初回起動で「自動で確認していいか」を尋ねる画面を出すので、
// Info.plist の SUEnableAutomaticChecks を false にして止めてある。

final class Updater: NSObject, SPUUpdaterDelegate {
    static let shared = Updater()

    private lazy var controller = SPUStandardUpdaterController(
        startingUpdater: true, updaterDelegate: self, userDriverDelegate: nil)

    /// 起動時の確認。何も無ければ黙って終わる
    func checkQuietly() {
        controller.updater.checkForUpdateInformation()
    }

    /// 設定画面の「更新を確認」。最新のときも結果を出す
    func checkNow() {
        NSApp.activate(ignoringOtherApps: true)
        controller.updater.checkForUpdates()
    }

    // MARK: - SPUUpdaterDelegate

    /// 黙って確認した結果、更新があった。ここで初めて画面を出す
    func updater(_ updater: SPUUpdater, didFindValidUpdate item: SUAppcastItem) {
        controller.updater.checkForUpdates()
    }
}
