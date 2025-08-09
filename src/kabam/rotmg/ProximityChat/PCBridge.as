package kabam.rotmg.ProximityChat {
import flash.desktop.NativeProcess;
import flash.desktop.NativeProcessStartupInfo;
import flash.events.NativeProcessExitEvent;
import flash.filesystem.File;
import flash.events.ProgressEvent;
import flash.events.Event;
import flash.utils.ByteArray;
import flash.utils.setTimeout;

public class PCBridge
{
    private var audioProcess:NativeProcess;
    private var proximityChatManager:PCManager; // Fixed class name

    public function PCBridge(manager:PCManager) // Fixed constructor name (had extra 'e')
    {
        proximityChatManager = manager;
    }

    public function startAudioProgram():void
    {
        try
        {
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
            for each (var f:File in files)
            {
                trace("  - " + f.name);
            }

            if (!file.exists)
            {
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
        }
        catch (e:Error)
        {
            trace("PCBridge: Error starting audio program:", e.message);
            trace("PCBridge: Error details:", e.toString());
        }
    }


    private function connectToPipe():void
    {
        // Send initial commands
        sendCommand("GET_MICS");
    }

    private function onOutputData(e:ProgressEvent):void
    {
        var output:String = audioProcess.standardOutput.readUTFBytes(audioProcess.standardOutput.bytesAvailable);
        trace("PCBridge: *** RECEIVED FROM C# ***:", output);
        processAudioMessage(output);
    }

    private function onErrorData(e:ProgressEvent):void
    {
        var error:String = audioProcess.standardError.readUTFBytes(audioProcess.standardError.bytesAvailable);
        trace("PCBridge: *** C# ERROR ***:", error);
    }

    private function onProcessExit(e:NativeProcessExitEvent):void // Updated parameter type
    {
        trace("Audio program exited with code:", e.exitCode);
    }

    private function processAudioMessage(message:String):void
    {
        try
        {
            var lines:Array = message.split('\n');

            for each (var line:String in lines)
            {
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
                        trace("PCBridge: Entered MIC_STATUS case");

                        // Simpler, more reliable processing
                        var rawValue:String = parts[1] ? String(parts[1]) : "";

                        // Simple cleanup - just remove spaces and convert to lowercase
                        rawValue = rawValue.split(" ").join("").toLowerCase();

                        var isEnabled:Boolean = (rawValue == "true");
                        trace("PCBridge: Raw MIC_STATUS value:", parts[1], "Cleaned:", rawValue, "Parsed as:", isEnabled);

                        trace("PCBridge: proximityChatManager =", proximityChatManager);

                        if (proximityChatManager) {
                            trace("PCBridge: Calling updateToggleState with:", isEnabled);
                            proximityChatManager.updateToggleState(isEnabled);
                            trace("PCBridge: updateToggleState completed");
                        } else {
                            trace("PCBridge: ERROR - proximityChatManager is null!");
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
                }
            }
        }
        catch (error:Error)
        {
            trace("PCBridge: ERROR in processAudioMessage:", error.message);
            trace("PCBridge: Error stack:", error.getStackTrace());
            trace("PCBridge: Raw message was:", message);
        }
    }
    public function sendCommand(command:String):void
    {
        trace("PCBridge: Attempting to send command:", command); // Add this

        if (audioProcess && audioProcess.running)
        {
            trace("PCBridge: Process is running, sending command"); // Add this
            audioProcess.standardInput.writeUTFBytes(command + "\n");
            trace("PCBridge: Command sent successfully"); // Add this
        }
        else
        {
            trace("PCBridge: ERROR - Process not running or null"); // Add this
            trace("PCBridge: audioProcess =", audioProcess);
            if (audioProcess) trace("PCBridge: audioProcess.running =", audioProcess.running);
        }
    }
    public function startMicrophone():void
    {
        sendCommand("START_MIC");
    }

    public function stopMicrophone():void
    {
        sendCommand("STOP_MIC");
    }

    public function selectMicrophone(micId:String):void
    {
        sendCommand("SELECT_MIC:" + micId);
    }

    private function updateMicrophoneList(jsonString:String):void
    {
        // Parse JSON and update your Algorithm tab UI
        // You'll need to implement a dropdown in your Algorithm tab background
        trace("Received microphone list:", jsonString);
    }

    public function dispose():void
    {
        // Send exit command before closing
        sendCommand("EXIT");

        if (audioProcess && audioProcess.running)
        {
            audioProcess.exit(true); // Force close
        }
    }
}
}