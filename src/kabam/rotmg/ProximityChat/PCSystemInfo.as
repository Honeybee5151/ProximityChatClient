package kabam.rotmg.ProximityChat {
import flash.display.Sprite;
import flash.text.TextField;
import flash.text.TextFormat;
import flash.text.TextFieldAutoSize;

public class PCSystemInfo extends Sprite {
    private var textFields:Vector.<TextField>;
    private var _width:Number;
    private var _height:Number;

    // Visual properties
    private var _textColor:uint = 0xcccccc;

    public function PCSystemInfo(width:Number = 350, height:Number = 2000) {
        _width = width;
        _height = height;
        initialize();
    }

    private function initialize():void {
        // Create multiple text fields
        createTextFields();
    }

    private function createTextFields():void {
        textFields = new Vector.<TextField>();

        // Split content into manageable sections
        var sections:Array = [
            "This system is opensource, made by Claude, and prompted by Shangapallia\n\nIf it makes you lag, turn off output by the top on/off button and sliding the slider to off\n\nRange is 15 tiles, and maximum input is from 4 people\n\nIn dungeons people will be grouped into groups of 4\n\nIf you would like to contribute to the system: https://github.com/Honeybee5151"

            //"TECHNICAL SPECIFICATIONS:\n• Uses raw PCM audio for zero CPU encoding overhead\n• TCP connection ensures reliable audio transmission\n• Server-side proximity filtering and routing\n• Automatic reconnection on network interruptions\n• 44.1kHz mono audio at 16-bit depth\n• 100ms audio chunks for low latency",

            //"GAMEPLAY MODES:\n• Realm Mode: Dynamic proximity-based groups\n  - Players hear others within 15 tile range\n  - Groups form and dissolve naturally as players move\n  - Encourages spontaneous social interaction\n• Dungeon Mode: Fixed coordination groups\n  - Stable groups formed when entering dungeons\n  - Optimized for tactical coordination\n  - Groups persist throughout dungeon completion\n• Automatic mode switching based on world location",

            //"BANDWIDTH AND PERFORMANCE:\n• Approximately 440KB/sec with 6 people talking nearby\n• Bandwidth scales with local player density\n• Optimized for stable performance on modest hardware\n• 6-person audio cap prevents exponential bandwidth growth\n• Server handles routing to reduce client processing load",

            //"AUDIO QUALITY FEATURES:\n• Distance-based volume attenuation\n• Noise gate to filter quiet background sounds\n• Microphone gain control and audio level monitoring\n• Real-time audio level visualization\n• Support for multiple audio devices",

            //"SOCIAL FEATURES:\n• Respects existing ignore list settings\n• No voice data sent to ignored players\n• Seamless integration with game social systems\n• Encourages meeting new players organically",

            //"SYSTEM REQUIREMENTS:\n• Any microphone (built-in or external)\n• Broadband internet connection (1+ Mbps recommended)\n• Windows audio system compatibility\n• Minimal additional CPU/memory overhead",

            //"PURPOSE AND DESIGN PHILOSOPHY:\nThis system encourages spontaneous interaction between\nplayers without the complexity of setting up external\nvoice chat channels. It's designed to facilitate casual\ncoordination, help new players get guidance, and create\norganic social moments that enhance the gaming experience.\nUnlike Discord or other platforms, proximity chat works\nautomatically based on your location in the game world,\nmaking it perfect for meeting new people and coordinating\nwith nearby players without any setup required.",

            //"PERFORMANCE OPTIMIZATION:\nThe system is engineered to work reliably with modest\nhardware specifications while maintaining good audio\nquality for effective communication during gameplay.\nRaw PCM audio was chosen over compressed formats to\neliminate CPU encoding overhead that could impact\ngame performance, prioritizing stable frame rates\nover bandwidth efficiency.\n\nThis approach ensures consistent performance across\ndifferent hardware configurations while providing\nthe low-latency communication essential for\nreal-time gaming coordination."
        ];

        var currentY:Number = 25;

        for (var i:int = 0; i < sections.length; i++) {
            var textField:TextField = new TextField();
            textField.x = 5;
            textField.y = currentY;
            textField.width = _width - 10;
            textField.multiline = true;
            textField.wordWrap = true;
            textField.selectable = true;
            textField.textColor = _textColor;
            textField.background = false;
            textField.border = false;
            textField.autoSize = TextFieldAutoSize.LEFT;

            // Set text formatting
            var format:TextFormat = new TextFormat();
            format.font = "Arial";
            format.size = 11;
            format.leading = 3;
            textField.defaultTextFormat = format;

            textField.text = sections[i];

            addChild(textField);
            textFields.push(textField);

            currentY += textField.textHeight + 20; // Add spacing between sections
        }
    }

    // Public methods for customization
    public function setTextColor(color:uint):void {
        _textColor = color;
        if (textFields) {
            for each (var field:TextField in textFields) {
                field.textColor = color;
            }
        }
    }

    public function updateInfoText(newText:String):void {
        // For updating, you could rebuild the sections or modify specific ones
        // This is a simplified version that replaces the first field
        if (textFields && textFields.length > 0) {
            textFields[0].text = newText;
        }
    }

    public function setSize(width:Number, height:Number):void {
        _width = width;
        _height = height;

        if (textFields) {
            for each (var field:TextField in textFields) {
                field.width = width - 10;
            }
        }
    }

    public function dispose():void {
        if (textFields) {
            for each (var field:TextField in textFields) {
                if (field && field.parent) {
                    removeChild(field);
                }
            }
            textFields = null;
        }
    }
}
}