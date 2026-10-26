import Flutter
import UIKit

class SceneDelegate: FlutterSceneDelegate {

    override func sceneDidBecomeActive(_ scene: UIScene) {
        super.sceneDidBecomeActive(scene)
        AlarmFlowLogger.shared.log("SceneDelegate: sceneDidBecomeActive")

        if let (alarmId, trackId) = PendingPlaybackManager.shared.consumePendingRequestIfValid() {
            AlarmFlowLogger.shared.log("SceneDelegate: Found valid pending request for alarmId=\(alarmId), trackId=\(trackId)")
            AppDelegate.launchedFromAlarm = true
            AudioPlaybackManager.shared.start(audioTrackId: trackId)
        }
    }
}
