package kabam.rotmg.ProximityChat {
public class PCServerBridge {
    private static var _instance:PCServerBridge;
    private static var _incomingVolume:Number = 1.0;

    public function PCServerBridge() {
        if (_instance) {
            throw new Error("PCServerBridge is a singleton!");
        }
        var savedVolume:Number = PCSettings.getInstance().getIncomingVolume();
        setIncomingVolume(savedVolume);
        trace("PCServerBridge: Loaded saved volume on startup:", savedVolume);
    }

    public static function getInstance():PCServerBridge {
        if (!_instance) {
            _instance = new PCServerBridge();
        }
        return _instance;
    }

    // Handle incoming voice from server
    public function handleIncomingVoice(playerId:String, audioData:String, volume:Number):void {
        // Check volume setting FIRST to prevent processing when muted
        if (!shouldProcessIncomingAudio()) {
            trace("PCServerBridge: Incoming audio muted, skipping all processing");
            return; // Skip entirely - no lag!
        }

        // Apply volume adjustment
        var adjustedVolume:Number = volume * _incomingVolume;

        trace("PCServerBridge: Playing voice from player:", playerId,
                "original:", volume, "adjusted:", adjustedVolume);

        playProximityAudio(playerId, audioData, adjustedVolume);
    }
    public static function setIncomingVolume(volume:Number):void {
        _incomingVolume = Math.max(0, Math.min(1, volume));
        trace("PCServerBridge: Global incoming volume set to:", _incomingVolume);
    }

    public static function getIncomingVolume():Number {
        return _incomingVolume;
    }

    public static function shouldProcessIncomingAudio():Boolean {
        return _incomingVolume > 0;
    }

    private function playProximityAudio(playerId:String, audioData:String, volume:Number):void {
        // Convert and play audio in ActionScript
        // Implementation depends on your audio format
    }
}
}