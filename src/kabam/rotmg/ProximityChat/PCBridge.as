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
            trace("Application directory:", File.applicationDirectory.nativePath);

            var file:File = File.applicationDirectory.resolvePath("ConsoleApp1.exe");

            // Debug: Check if file exists and its path
            trace("Looking for audio program at:", file.nativePath);
            trace("File exists:", file.exists);

            // List all files in the directory to see what's actually there
            var appDir:File = File.applicationDirectory;
            var files:Array = appDir.getDirectoryListing();
            trace("Files in application directory:");
            for each (var f:File in files)
            {
                trace("  - " + f.name);
            }

            if (!file.exists)
            {
                trace("ERROR: ConsoleApp1.exe not found!");
                return;
            }

            var startupInfo:NativeProcessStartupInfo = new NativeProcessStartupInfo();
            startupInfo.executable = file;

            audioProcess = new NativeProcess();
            audioProcess.addEventListener(ProgressEvent.STANDARD_OUTPUT_DATA, onOutputData);
            audioProcess.addEventListener(ProgressEvent.STANDARD_ERROR_DATA, onErrorData);
            audioProcess.addEventListener(NativeProcessExitEvent.EXIT, onProcessExit);

            audioProcess.start(startupInfo);

            setTimeout(connectToPipe, 1000);
        }
        catch (e:Error)
        {
            trace("Error starting audio program:", e.message);
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
        processAudioMessage(output);
    }

    private function onErrorData(e:ProgressEvent):void // Added missing method
    {
        var error:String = audioProcess.standardError.readUTFBytes(audioProcess.standardError.bytesAvailable);
        trace("Audio program error:", error);
    }

    private function onProcessExit(e:NativeProcessExitEvent):void // Updated parameter type
    {
        trace("Audio program exited with code:", e.exitCode);
    }

    private function processAudioMessage(message:String):void {
        var parts:Array = message.split(':');
        if (parts.length < 2) return;

        switch (parts[0]) {
            case "MIC_LIST":
                // Update your Algorithm tab with microphone list
                var micListJson:String = parts.slice(1).join(':');
                updateMicrophoneList(micListJson);
                break;

            case "AUDIO_LEVEL":
                // Update visualizer
                var level:Number = parseFloat(parts[1]);
                proximityChatManager.updateVisualizerLevel(level);
                break;

            case "MIC_STATUS":
                // Update toggle button
                var isEnabled:Boolean = parts[1] == "true";
                proximityChatManager.updateToggleState(isEnabled);
                break;
        }
    }
    public function sendCommand(command:String):void
    {
        if (audioProcess && audioProcess.running)
        {
            audioProcess.standardInput.writeUTFBytes(command + "\n");
            // Remove the flush() call - it's not needed for NativeProcess
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