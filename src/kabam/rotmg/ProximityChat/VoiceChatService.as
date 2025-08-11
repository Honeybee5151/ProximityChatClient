// Updated VoiceChatService.as
package kabam.rotmg.ProximityChat {

import kabam.rotmg.ProximityChat.PCSettings;

import flash.events.Event;

public class VoiceChatService {
    private static var _instance:VoiceChatService;
    public var audioBridge:PCBridge;
    private var _isEnabled:Boolean = false;
    private var storedMicrophones:Array;
    private var microphoneListeners:Array = [];

    // NEW: Add settings integration
    private var settings:PCSettings;
    private var isInitialized:Boolean = false;
    private var currentPCManager:*; // Store reference to current PCManager

    private var myVoiceID:String;
    private var myPlayerID:String;
    private var gameServerIP:String;
    private var isVoiceConnected:Boolean = false;

    public static function getInstance():VoiceChatService {
        if (!_instance) {
            _instance = new VoiceChatService();
        }
        return _instance;
    }

    public function handleVoiceAuth(voiceID:String, playerID:String, serverIP:String):void {
        trace("VoiceChatService: Received VoiceAuth - VoiceID:", voiceID, "PlayerID:", playerID, "ServerIP:", serverIP);

        myVoiceID = voiceID;
        myPlayerID = playerID;
        gameServerIP = serverIP;

        // Automatically connect to voice server
        connectToVoiceServer();
    }

    public function connectToVoiceServer():void {
        if (!audioBridge) {
            trace("VoiceChatService: AudioBridge not available, cannot connect to voice server");
            return;
        }

        if (myVoiceID && myPlayerID && gameServerIP) {
            var connectCommand:String = "CONNECT_VOICE:" + gameServerIP + ":" + myPlayerID + ":" + myVoiceID;
            trace("VoiceChatService: Sending voice connection command:", connectCommand);
            audioBridge.sendCommand(connectCommand);
        } else {
            trace("VoiceChatService: Cannot connect - missing VoiceID, PlayerID, or server IP");
            trace("VoiceChatService: VoiceID:", myVoiceID, "PlayerID:", myPlayerID, "ServerIP:", gameServerIP);
        }
    }
    public function onVoiceConnected():void {
        isVoiceConnected = true;
        trace("VoiceChatService: Connected to voice server successfully");

        // Notify current PCManager if it exists
        if (currentPCManager && currentPCManager.hasOwnProperty("onVoiceServerConnected")) {
            currentPCManager.onVoiceServerConnected();
        }
    }
    public function onVoiceDisconnected():void {
        isVoiceConnected = false;
        trace("VoiceChatService: Disconnected from voice server");

        // Notify current PCManager if it exists
        if (currentPCManager && currentPCManager.hasOwnProperty("onVoiceServerDisconnected")) {
            currentPCManager.onVoiceServerDisconnected();
        }
    }

    // NEW: Getters for voice auth status
    public function hasVoiceAuth():Boolean {
        return myVoiceID != null && myPlayerID != null && gameServerIP != null;
    }

    public function get voiceConnected():Boolean {
        return isVoiceConnected;
    }

    public function getVoiceID():String {
        return myVoiceID;
    }

    public function getPlayerID():String {
        return myPlayerID;
    }

    public function initialize():void {
        if (isInitialized) {
            trace("VoiceChatService: Already initialized");
            return;
        }

        trace("VoiceChatService: Initializing...");

        // NEW: Initialize settings first
        try {
            settings = PCSettings.getInstance();
            settings.addEventListener(PCSettings.SETTINGS_LOADED, onSettingsLoaded);
            trace("VoiceChatService: Settings initialized successfully");
        } catch (error:Error) {
            trace("VoiceChatService: Failed to initialize settings:", error.message);
            settings = null;
        }

        if (!audioBridge) {
            audioBridge = new PCBridge(null); // No UI dependency
            audioBridge.startAudioProgram();
        }

        isInitialized = true;
    }

    // NEW: Settings loaded handler
    private function onSettingsLoaded(e:Event):void {
        trace("VoiceChatService: Settings loaded, checking for saved preferences");

        // If we already have microphones stored, try to apply saved selection
        if (storedMicrophones && storedMicrophones.length > 0) {
            applySavedMicrophone();
        }

        // Apply saved chat enabled state to current PCManager
        if (settings && currentPCManager) {
            var savedChatEnabled:Boolean = settings.getChatEnabled();
            if (savedChatEnabled) {
                // Actually start the microphone, not just update UI
                startMicrophone();
                trace("VoiceChatService: Started microphone based on saved state");
            }
            currentPCManager.updateToggleState(savedChatEnabled);
            trace("VoiceChatService: Applied saved chat state:", savedChatEnabled);
        }
    }

    // NEW: Apply saved microphone selection
    private function applySavedMicrophone():void {
        if (!settings) {
            trace("VoiceChatService: Settings not available");
            return;
        }

        if (!settings.hasSavedMicrophone()) {
            trace("VoiceChatService: No saved microphone found");
            return;
        }

        var savedMic:Object = settings.applySavedMicrophone(storedMicrophones);
        if (!savedMic) {
            trace("VoiceChatService: Saved microphone no longer available");
            return;
        }

        trace("VoiceChatService: Applying saved microphone:", savedMic.Name);

        // Select the microphone internally (without saving again)
        selectMicrophoneInternal(savedMic.Id);

        // Update any connected PCManager UI
        if (currentPCManager) {
            currentPCManager.updateMicrophoneSelection(savedMic.Id);
            trace("VoiceChatService: Updated UI to show saved microphone");
        }
    }

    // NEW: Internal microphone selection (doesn't save to settings)
    private function selectMicrophoneInternal(microphoneId:String):void {
        if (audioBridge) {
            trace("VoiceChatService: Selecting microphone internally:", microphoneId);
            audioBridge.selectMicrophone(microphoneId);
        } else {
            trace("VoiceChatService: audioBridge is null, cannot select microphone");
        }
    }

    // UPDATED: Modified to save to settings
    public function selectMicrophone(microphoneId:String):void {
        if (audioBridge) {
            trace("VoiceChatService: Selecting microphone:", microphoneId);
            audioBridge.selectMicrophone(microphoneId);

            // NEW: Save the microphone selection
            if (settings && storedMicrophones) {
                for (var i:int = 0; i < storedMicrophones.length; i++) {
                    var mic:Object = storedMicrophones[i];
                    if (mic.Id == microphoneId) {
                        settings.saveSelectedMicrophone(mic.Id, mic.Name);
                        trace("VoiceChatService: Saved microphone selection:", mic.Name);
                        break;
                    }
                }
            }
        } else {
            trace("VoiceChatService: audioBridge is null, cannot select microphone");
        }
    }

    // NEW: Handle chat enabled state with settings
    public function setChatEnabled(enabled:Boolean):void {
        trace("VoiceChatService: Setting chat enabled:", enabled);

        if (enabled) {
            startMicrophone();
        } else {
            stopMicrophone();
        }

        // Save the chat enabled state
        if (settings) {
            settings.saveChatEnabled(enabled);
            trace("VoiceChatService: Saved chat enabled state:", enabled);
        }
    }

    public function startMicrophone():void {
        if (audioBridge) {
            trace("VoiceChatService: Starting microphone");
            audioBridge.startMicrophone();
            _isEnabled = true;
        }
    }

    public function stopMicrophone():void {
        if (audioBridge) {
            trace("VoiceChatService: Stopping microphone");
            audioBridge.stopMicrophone();
            _isEnabled = false;
        }
    }

    public function get isEnabled():Boolean {
        return _isEnabled;
    }

    public function hasStoredMicrophones():Boolean {
        return storedMicrophones && storedMicrophones.length > 0;
    }

    public function getStoredMicrophones():Array {
        return storedMicrophones ? storedMicrophones.slice() : [];
    }

    // UPDATED: Modified to trigger saved microphone application
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

        // NEW: After storing microphones, try to apply saved selection
        if (settings) {
            applySavedMicrophone();
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

    // UPDATED: Store reference to current PCManager
    public function setProximityChatManager(manager:*):void {
        currentPCManager = manager; // NEW: Store reference

        if (audioBridge) {
            audioBridge.proximityChatManager = manager;
            trace("VoiceChatService: Connected PCManager to bridge");

            // NEW: If settings are loaded and we have a saved chat state, apply it
            if (settings) {
                var savedChatEnabled:Boolean = settings.getChatEnabled();
                if (savedChatEnabled) {
                    // Actually start the microphone, not just update UI
                    startMicrophone();
                    trace("VoiceChatService: Started microphone for new PCManager based on saved state");
                }
                manager.updateToggleState(savedChatEnabled);
                trace("VoiceChatService: Applied saved chat state to new PCManager:", savedChatEnabled);
            }
        } else {
            trace("VoiceChatService: Bridge not available yet");
        }
    }

    // UPDATED: Enhanced dispose with settings cleanup
    public function dispose(onComplete:Function = null):void {
        if (settings) {
            settings.removeEventListener(PCSettings.SETTINGS_LOADED, onSettingsLoaded);
            settings = null;
        }

        if (audioBridge) {
            if (onComplete != null) {
                // Add the exit listener before disposing
                audioBridge.addProcessExitListener(onComplete);
            }
            audioBridge.dispose(); // Sends EXIT command
            audioBridge = null;
        } else if (onComplete != null) {
            // No audioBridge, call callback immediately
            onComplete(null);
        }

        currentPCManager = null;
        _isEnabled = false;
        isInitialized = false;
    }
}
}