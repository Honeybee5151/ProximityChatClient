// Create a new file: VoiceChatService.as
package kabam.rotmg.ProximityChat {
public class VoiceChatService{
    private static var _instance:VoiceChatService;
    private var audioBridge:PCBridge;
    private var _isEnabled:Boolean = false;

    public static function getInstance():VoiceChatService {
        if (!_instance) {
            _instance = new VoiceChatService();
        }
        return _instance;
    }

    public function initialize():void {
        if (!audioBridge) {
            audioBridge = new PCBridge(null); // No UI dependency
            audioBridge.startAudioProgram();
        }
    }

    public function startMicrophone():void {
        if (audioBridge) {
            audioBridge.startMicrophone();
            _isEnabled = true;
        }
    }

    public function stopMicrophone():void {
        if (audioBridge) {
            audioBridge.stopMicrophone();
            _isEnabled = false;
        }
    }

    public function get isEnabled():Boolean {
        return _isEnabled;
    }

    public function dispose():void {
        if (audioBridge) {
            audioBridge.dispose();
            audioBridge = null;
        }
        _isEnabled = false;
    }
}
}