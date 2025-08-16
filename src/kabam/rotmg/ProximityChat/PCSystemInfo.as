package kabam.rotmg.ProximityChat {
import flash.display.Sprite;
import flash.text.TextField;
import flash.text.TextFormat;
import flash.text.TextFieldAutoSize;

public class PCSystemInfo extends Sprite {
    private var infoTextField:TextField;
    private var _width:Number;
    private var _height:Number;

    // Visual properties
    private var _textColor:uint = 0xcccccc;
    private var _backgroundColor:uint = 0x1a1a2a;
    private var _borderColor:uint = 0x666666;

    public function PCSystemInfo(width:Number = 280, height:Number = 200) {
        _width = width;
        _height = height;
        initialize();
    }

    private function initialize():void {
        // Draw background
        drawBackground();

        // Create and configure text field
        createTextField();

        // Set the info content
        setInfoText();
    }

    private function drawBackground():void {
        graphics.clear();
        graphics.beginFill(_backgroundColor, 0.8);
        graphics.lineStyle(1, _borderColor, 0.5);
        graphics.drawRoundRect(0, 0, _width, _height, 8, 8);
        graphics.endFill();
    }

    private function createTextField():void {
        infoTextField = new TextField();
        infoTextField.x = 10;
        infoTextField.y = 10;
        infoTextField.width = _width - 20; // Account for padding
        infoTextField.height = _height - 20;
        infoTextField.multiline = true;
        infoTextField.wordWrap = true;
        infoTextField.selectable = true;
        infoTextField.textColor = _textColor;

        // Set text formatting
        var format:TextFormat = new TextFormat();
        format.font = "Arial";
        format.size = 12;
        format.leading = 2; // Line spacing
        infoTextField.defaultTextFormat = format;

        addChild(infoTextField);
    }

    private function setInfoText():void {
        var infoText:String = "PROXIMITY CHAT SYSTEM\n" +
                "====================\n\n" +

                "BASIC FEATURES:\n" +
                "• Voice chat works within 15 tiles\n" +
                "• Maximum 6 people heard simultaneously\n" +
                "• Distance affects volume (closer = louder)\n" +
                "• Push-to-talk reduces background noise\n" +
                "• Adjustable incoming volume\n\n" +
                "• At minimum volume the receiving end is off\n\n"


                "TECHNICAL INFO:\n" +
                "• Uses raw PCM audio for zero CPU overhead\n" +
                "• TCP connection for reliable transmission\n" +
                "• Server-side proximity filtering\n" +
                "• Automatic reconnection on network issues\n\n" +

                "GAMEPLAY MODES:\n" +
                "• Realm: Dynamic proximity-based groups\n" +
                "• Dungeons: Fixed coordination groups\n" +
                "• Automatic mode switching by location\n\n" +

                "BANDWIDTH USAGE:\n" +
                "• ~440KB/sec with 6 people nearby\n" +
                "• Scales with player density\n" +
                "• Optimized for stable performance\n\n" +

                "This system encourages spontaneous interaction\n" +
                "between players without the complexity of\n" +
                "setting up Discord channels.";

        infoTextField.text = infoText;
    }

    // Public methods for customization
    public function setTextColor(color:uint):void {
        _textColor = color;
        if (infoTextField) {
            infoTextField.textColor = color;
        }
    }

    public function setBackgroundColor(color:uint):void {
        _backgroundColor = color;
        drawBackground();
    }

    public function setBorderColor(color:uint):void {
        _borderColor = color;
        drawBackground();
    }

    public function updateInfoText(newText:String):void {
        if (infoTextField) {
            infoTextField.text = newText;
        }
    }

    public function setSize(width:Number, height:Number):void {
        _width = width;
        _height = height;
        drawBackground();

        if (infoTextField) {
            infoTextField.width = width - 20;
            infoTextField.height = height - 20;
        }
    }

    public function dispose():void {
        if (infoTextField && infoTextField.parent) {
            removeChild(infoTextField);
        }
        infoTextField = null;
    }
}
}