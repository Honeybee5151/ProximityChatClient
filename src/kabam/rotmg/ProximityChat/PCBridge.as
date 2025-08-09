package kabam.rotmg.ProximityChat {
import flash.desktop.NativeProcess;
import flash.desktop.NativeProcessStartupInfo;
import flash.events.NativeProcessExitEvent;
import flash.filesystem.File;
import flash.events.ProgressEvent;
import flash.events.Event;
import flash.utils.ByteArray;
import flash.utils.setTimeout;

public class PCBridge {
    private var audioProcess:NativeProcess;
    private var proximityChatManager:PCManager; // Fixed class name
    private var availableMicrophones:Array;


    public function PCBridge(manager:PCManager = null) {
        proximityChatManager = manager; // Can be null
    }

    public function startAudioProgram():void {
        trace("PCBridge: CONSTRUCTOR CALLED - VERSION 789 - NEW CODE LOADED");
        try {
            // Debug: Check application directory
            trace("PCBridge: Application directory:", File.applicationDirectory.nativePath);

            var file:File = File.applicationDirectory.resolvePath("ConsoleApp1.exe");

            // Debug: Check if file exists and its path
            trace("PCBridge: Looking for audio program at:", file.nativePath);
            trace("PCBridge: File exists:", file.exists);

            // List all files in the directory to see what's actually there
            var appDir:File = File.applicationDirectory;
            var files:Array = appDir.getDirectoryListing();
            trace("PCBridge: Files in application directory:");
            for each (var f:File in files) {
                trace("  - " + f.name);
            }

            if (!file.exists) {
                trace("PCBridge: ERROR - ConsoleApp1.exe not found!");
                return;
            }

            var startupInfo:NativeProcessStartupInfo = new NativeProcessStartupInfo();
            startupInfo.executable = file;

            audioProcess = new NativeProcess();
            audioProcess.addEventListener(ProgressEvent.STANDARD_OUTPUT_DATA, onOutputData);
            audioProcess.addEventListener(ProgressEvent.STANDARD_ERROR_DATA, onErrorData);
            audioProcess.addEventListener(NativeProcessExitEvent.EXIT, onProcessExit);

            trace("PCBridge: Starting audio process...");
            audioProcess.start(startupInfo);

            trace("PCBridge: Process started successfully");
            trace("PCBridge: Process running =", audioProcess.running);
            trace("PCBridge: Process info:", audioProcess.toString());

            setTimeout(connectToPipe, 1000);
        } catch (e:Error) {
            trace("PCBridge: Error starting audio program:", e.message);
            trace("PCBridge: Error details:", e.toString());
        }
    }


    private function connectToPipe():void {
        // Send initial commands
        sendCommand("GET_MICS");
    }

    private function onOutputData(e:ProgressEvent):void {
        var output:String = audioProcess.standardOutput.readUTFBytes(audioProcess.standardOutput.bytesAvailable);
        trace("PCBridge: *** RECEIVED FROM C# ***:", output);
        processAudioMessage(output);
    }

    private function onErrorData(e:ProgressEvent):void {
        var error:String = audioProcess.standardError.readUTFBytes(audioProcess.standardError.bytesAvailable);
        trace("PCBridge: *** C# ERROR ***:", error);
    }

    private function onProcessExit(e:NativeProcessExitEvent):void // Updated parameter type
    {
        trace("Audio program exited with code:", e.exitCode);
    }

    private function processAudioMessage(message:String):void {
        try {
            var lines:Array = message.split('\n');

            for each (var line:String in lines) {
                if (line.length == 0) continue;

                trace("PCBridge: Processing line:", line); // Debug each line

                var parts:Array = line.split(':');
                if (parts.length < 2) continue;

// Safe trace that won't crash
                var command:String = parts[0] ? parts[0].toString() : "null";
                var value:String = parts[1] ? parts[1].toString() : "null";
                trace("PCBridge: Command:", command, "Value:", value);

                switch (parts[0]) {
                    case "MIC_STATUS":
                        try {
                            trace("PCBridge: Entered MIC_STATUS case");

                            var rawValue:String = parts[1] ? String(parts[1]) : "";

                            // Remove ALL whitespace characters including \r, \n, \t, and spaces
                            rawValue = rawValue.replace(/\s/g, "").toLowerCase();

                            var isEnabled:Boolean = (rawValue == "true");
                            trace("PCBridge: MIC_STATUS -", parts[1], "→", isEnabled);

                            if (proximityChatManager) {
                                proximityChatManager.updateToggleState(isEnabled);
                            }
                        } catch (e:Error) {
                            trace("PCBridge: ERROR in MIC_STATUS:", e.message);
                        }
                        break;
                    case "MIC_COUNT":
                        trace("PCBridge: Found", parts[1], "microphones");
                        break;

                    case "SELECTED_MIC":
                        trace("PCBridge: Selected microphone:", parts[1]);
                        break;

                    default:
                        trace("PCBridge: Unknown command:", parts[0]);
                        break;
                    case "AUDIO_LEVEL":
                        var level:Number = parseFloat(parts[1]);
                        trace("PCBridge: Audio level:", level);
                        if (proximityChatManager) { // Only update UI if it exists
                            proximityChatManager.updateVisualizerLevel(level);
                        }
                        break;
                    case "MIC_DEVICE":
                        trace("PCBridge: *** MIC_DEVICE case triggered ***");
                        // Parse microphone data: ID|Name|IsDefault
                        var micData:Array = value.split('|');
                        trace("PCBridge: Parsed mic data:", micData);
                        if (micData.length >= 3) {
                            var micInfo:Object = {
                                Id: micData[0].replace(/\s/g, ""),
                                Name: micData[1],
                                IsDefault: micData[2].replace(/\s/g, "").toLowerCase() == "true"
                            };
                            trace("PCBridge: Created mic info:", micInfo.Name, "Default:", micInfo.IsDefault);

                            if (!availableMicrophones) availableMicrophones = [];
                            availableMicrophones.push(micInfo);
                            trace("PCBridge: Total mics collected:", availableMicrophones.length);
                        }
                        break;
                    case "DEFAULT_MIC":
                        trace("PCBridge: *** DEFAULT_MIC case triggered ***");
                        trace("PCBridge: availableMicrophones length:", availableMicrophones ? availableMicrophones.length : 0);

                        if (availableMicrophones) {
                            // Store in VoiceChatService instead of sending to PCManager
                            VoiceChatService.getInstance().setStoredMicrophones(availableMicrophones);
                            trace("PCBridge: Microphones stored in VoiceChatService");

                            // Also send to PCManager if it exists
                            if (proximityChatManager) {
                                trace("PCBridge: Sending to current PCManager");
                                proximityChatManager.setAvailableMicrophones(availableMicrophones);
                            }

                            availableMicrophones = []; // Reset
                        }
                        break;


                }
            }
        } catch (error:Error) {
            trace("PCBridge: ERROR in processAudioMessage:", error.message);
            trace("PCBridge: Error stack:", error.getStackTrace());
            trace("PCBridge: Raw message was:", message);
        }
    }

    public function sendCommand(command:String):void {
        trace("PCBridge: Attempting to send command:", command); // Add this

        if (audioProcess && audioProcess.running) {
            trace("PCBridge: Process is running, sending command"); // Add this
            audioProcess.standardInput.writeUTFBytes(command + "\n");
            trace("PCBridge: Command sent successfully"); // Add this
        } else {
            trace("PCBridge: ERROR - Process not running or null"); // Add this
            trace("PCBridge: audioProcess =", audioProcess);
            if (audioProcess) trace("PCBridge: audioProcess.running =", audioProcess.running);
        }
    }

    public function startMicrophone():void {
        sendCommand("START_MIC");
    }

    public function stopMicrophone():void {
        sendCommand("STOP_MIC");
    }

    public function selectMicrophone(micId:String):void {
        sendCommand("SELECT_MIC:" + micId);
    }

    private function updateMicrophoneList(jsonString:String):void {
        // Parse JSON and update your Algorithm tab UI
        // You'll need to implement a dropdown in your Algorithm tab background
        trace("Received microphone list:", jsonString);
    }

    public function dispose():void {
        trace("PCBridge: dispose() called");

        try {
            // Send exit command ONLY if process is actually running
            if (audioProcess && audioProcess.running) {
                sendCommand("EXIT");

                // Give the process a moment to exit gracefully
                setTimeout(function ():void {
                    if (audioProcess && audioProcess.running) {
                        trace("PCBridge: Force closing process");
                        audioProcess.exit(true);
                    }
                }, 100);
            }
        } catch (e:Error) {
            trace("PCBridge: Error during disposal:", e.message);
            // Force close if graceful exit fails
            if (audioProcess) {
                try {
                    audioProcess.exit(true);
                } catch (e2:Error) {
                    trace("PCBridge: Force close also failed:", e2.message);
                }
            }
        }
    }
    public function sendStoredMicrophones():void {
        trace("PCBridge: sendStoredMicrophones() called");
        trace("PCBridge: availableMicrophones exists:", availableMicrophones != null);
        trace("PCBridge: availableMicrophones length:", availableMicrophones ? availableMicrophones.length : 0);
        trace("PCBridge: proximityChatManager exists:", proximityChatManager != null);

        if (availableMicrophones && availableMicrophones.length > 0 && proximityChatManager) {
            trace("PCBridge: Sending stored microphones to PCManager");
            proximityChatManager.setAvailableMicrophones(availableMicrophones);
            availableMicrophones = []; // Reset after sending
        }
    }


}
}
