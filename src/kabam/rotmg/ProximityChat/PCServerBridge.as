package kabam.rotmg.ProximityChat {
public class PCServerBridge {
    private static var _instance:PCServerBridge;

    public function PCServerBridge() {
        if (_instance) {
            throw new Error("PCServerBridge is a singleton!");
        }
    }

    public static function getInstance():PCServerBridge {
        if (!_instance) {
            _instance = new PCServerBridge();
        }
        return _instance;
    }

    // Handle incoming voice from server
    public function handleIncomingVoice(playerId:String, audioData:String, volume:Number):void {
        trace("PCServerBridge: Playing voice from player:", playerId);
        playProximityAudio(playerId, audioData, volume);
    }

    private function playProximityAudio(playerId:String, audioData:String, volume:Number):void {
        // Convert and play audio in ActionScript
        // Implementation depends on your audio format
    }
}
}