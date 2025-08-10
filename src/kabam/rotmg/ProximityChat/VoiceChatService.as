// Create a new file: VoiceChatService.as
package kabam.rotmg.ProximityChat {
public class VoiceChatService{
    private static var _instance:VoiceChatService;
    private var audioBridge:PCBridge;
    private var _isEnabled:Boolean = false;
    private var storedMicrophones:Array;
    private var microphoneListeners:Array = [];

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
    public function selectMicrophone(microphoneId:String):void {
        if (audioBridge) {
            trace("VoiceChatService: Selecting microphone:", microphoneId);
            audioBridge.selectMicrophone(microphoneId);
        } else {
            trace("VoiceChatService: audioBridge is null, cannot select microphone");
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
    public function hasStoredMicrophones():Boolean {
        return storedMicrophones && storedMicrophones.length > 0;
    }

    public function getStoredMicrophones():Array {
        return storedMicrophones ? storedMicrophones.slice() : [];
    }
    public function setStoredMicrophones(mics:Array):void {
        storedMicrophones = mics ? mics.slice() : [];
        trace("VoiceChatService: Stored", storedMicrophones.length, "microphones, notifying listeners");

        // Notify all listeners
        for each (var listener:Function in microphoneListeners) {
            try {
                listener(storedMicrophones.slice());
            } catch (e:Error) {
                trace("VoiceChatService: Error notifying listener:", e.message);
            }
        }
    }
    public function addMicrophoneListener(listener:Function):void {
        if (microphoneListeners.indexOf(listener) == -1) {
            microphoneListeners.push(listener);
        }
    }

    public function removeMicrophoneListener(listener:Function):void {
        var index:int = microphoneListeners.indexOf(listener);
        if (index != -1) {
            microphoneListeners.splice(index, 1);
        }
    }



}
}