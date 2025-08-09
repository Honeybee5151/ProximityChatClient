package kabam.rotmg.ProximityChat {

import flash.display.Sprite;
import flash.events.Event;
import flash.geom.Rectangle;


public class PCManager extends Sprite
{
    // Configuration
    private var _containerWidth:Number;
    private var _containerHeight:Number;
    private var _containerX:Number;
    private var _containerY:Number;

    // Components
    private var maskBackground:PCMask;
    private var verticalSlider:PCSlider;
    private var chatContent:Sprite;

    // Content management
    private var _contentHeight:Number;
    private var _maxScrollRange:Number;

    // Visual configuration
    private var _sliderWidth:Number;
    private var _sliderMargin:Number;

    // Default values
    private static const DEFAULT_WIDTH:Number = 320;
    private static const DEFAULT_HEIGHT:Number = 240;
    private static const DEFAULT_SLIDER_WIDTH:Number = 15;
    private static const DEFAULT_SLIDER_MARGIN:Number = 5;

    // Events
    public static const CHAT_READY:String = "chatReady";
    public static const CONTENT_SCROLLED:String = "contentScrolled";

    private var chatTabs:PCTabs;

    private var chatToggle:PCToggle;

    private var chatVisualizer:PCVisualiser;

    private var audioBridge:PCBridge;

    public function PCManager(
            x:Number = 100,
            y:Number = 100,
            width:Number = DEFAULT_WIDTH,
            height:Number = DEFAULT_HEIGHT
    )
    {
        this._containerX = x;
        this._containerY = y;
        this._containerWidth = width;
        this._containerHeight = height;
        this._sliderWidth = DEFAULT_SLIDER_WIDTH;
        this._sliderMargin = DEFAULT_SLIDER_MARGIN;
        this._contentHeight = 0;
        this._maxScrollRange = 0;

        initialize();
    }

    private function initialize():void
    {
        // Create the main container with mask and background
        maskBackground = new PCMask(
                _containerWidth,
                _containerHeight,
                _containerX,
                _containerY
        );

        // Create chat content container
        chatContent = new Sprite();

        // Create vertical slider (positioned to the right of the main container)
        verticalSlider = new PCSlider(
                _sliderWidth,
                _containerHeight - (_sliderMargin * 2),
                _containerX + _containerWidth + _sliderMargin,
                _containerY + _sliderMargin,
                PCSlider.VERTICAL,
                0,
                0  // Will be updated when content is added
        );

        // Link slider to control chat content
        verticalSlider.setTargetBackground(chatContent);

        // Add components to display list
        addChild(maskBackground);
        addChild(verticalSlider);

        // Add chat content to the masked container
        maskBackground.addChild(chatContent);

        // Set up event listeners
        verticalSlider.addEventListener(PCSlider.VALUE_CHANGED, onSliderValueChanged);

        // Apply default styling
        applyDefaultStyling();

        // Dispatch ready event
        dispatchEvent(new Event(CHAT_READY));

        chatTabs = new PCTabs(
                _containerX,
                _containerY - 35, // Position above the container
                80,  // tab width
                30   // tab height
        );
        chatTabs.setTargetContainer(chatContent);

// Add to display list
        addChild(chatTabs);

// Style the tabs to match
        chatTabs.setTabColors(0x444444, 0x2a2a2a, 0x333333);
        chatTabs.setTextColors(0xcccccc, 0xffffff);
        chatTabs.setBorderColor(0x666666);

        chatToggle = new PCToggle(
                _containerX + (80 * 2) + (2 * 1) + 2, // x position: to the right of Algorithm tab
                _containerY - 35, // y position: same as tabs
                35,  // width (smaller)
                30,  // height (same as tabs)
                "ON",   // on text (shorter)
                "OFF",  // off text (shorter)
                false // initial state (off)
        );

        addChild(chatToggle);
        chatToggle.addEventListener(PCToggle.TOGGLE_CHANGED, onToggleChanged);

        var toggleEndX:Number = chatToggle.x + chatToggle.toggleWidth;
        var availableWidth:Number = (_containerX + _containerWidth) - toggleEndX - 2; // 5px margin from mask edge

        // Create sound visualizer
        chatVisualizer = new PCVisualiser(
                toggleEndX + 2, // x position: right of toggle button + small margin
                _containerY - 35, // y position: same as tabs and toggle
                availableWidth, // width: fills remaining space to mask edge
                30  // height: same as buttons
        );
        addChild(chatVisualizer);

        audioBridge = new PCBridge(this);
        audioBridge.startAudioProgram();


    }
    private function onToggleChanged(e:Event):void
    {
        var toggle:PCToggle = e.target as PCToggle;
        trace("PCManager: Toggle state changed to:", toggle.getStateString());

        if (audioBridge)
        {
            trace("PCManager: audioBridge exists, sending command");
            if (toggle.isOn)
            {
                trace("PCManager: Calling startMicrophone()");
                audioBridge.startMicrophone();
            }
            else
            {
                trace("PCManager: Calling stopMicrophone()");
                audioBridge.stopMicrophone();
            }
        }
        else
        {
            trace("PCManager: ERROR - audioBridge is null!");
        }
    }
    private function applyDefaultStyling():void
    {
        // Style the mask/background
        maskBackground.setBackgroundColor(0x1a1a1a, 0.9);
        maskBackground.setBorder(0x444444, 1);
        maskBackground.setCornerRadius(8);

        // Style the slider
        verticalSlider.setTrackColor(0x2a2a2a, 0.8);
        verticalSlider.setThumbColor(0x555555, 0x777777, 1.0);
        verticalSlider.setCornerRadius(4);
        verticalSlider.setThumbSize(18);
    }

    // Event handlers
    private function onSliderValueChanged(e:Event):void
    {
        dispatchEvent(new Event(CONTENT_SCROLLED));
    }

    // Public methods for content management
    public function addChatMessage(message:Sprite):void
    {
        chatContent.addChild(message);
        updateContentHeight();
    }

    public function removeChatMessage(message:Sprite):void
    {
        if (chatContent.contains(message))
        {
            chatContent.removeChild(message);
            updateContentHeight();
        }
    }

    public function clearChatContent():void
    {
        while (chatContent.numChildren > 0)
        {
            chatContent.removeChildAt(0);
        }
        updateContentHeight();
    }

    private function updateContentHeight():void
    {
        // Calculate the total content height
        var maxY:Number = 0;
        for (var i:int = 0; i < chatContent.numChildren; i++)
        {
            var child:Sprite = chatContent.getChildAt(i) as Sprite;
            if (child)
            {
                var childBottom:Number = child.y + child.height;
                if (childBottom > maxY)
                {
                    maxY = childBottom;
                }
            }
        }

        _contentHeight = maxY;
        _maxScrollRange = Math.max(0, _contentHeight - _containerHeight);

        // Update slider range
        verticalSlider.setRange(0, _maxScrollRange);

        // Show/hide slider based on content
        verticalSlider.visible = _maxScrollRange > 0;
    }

    // Position and sizing methods
    public function setPosition(x:Number, y:Number):void
    {
        this._containerX = x;
        this._containerY = y;

        maskBackground.setPosition(x, y);
        verticalSlider.setPosition(x + _containerWidth + _sliderMargin, y + _sliderMargin);
    }

    public function setSize(width:Number, height:Number):void
    {
        this._containerWidth = width;
        this._containerHeight = height;

        maskBackground.setSize(width, height);
        verticalSlider.setSize(_sliderWidth, height - (_sliderMargin * 2));
        verticalSlider.setPosition(_containerX + width + _sliderMargin, _containerY + _sliderMargin);

        updateContentHeight();
    }

    // Styling methods
    public function setBackgroundStyle(color:uint, alpha:Number = 0.9, borderColor:uint = 0x444444, borderThickness:Number = 1):void
    {
        maskBackground.setBackgroundColor(color, alpha);
        maskBackground.setBorder(borderColor, borderThickness);
    }

    public function setSliderStyle(trackColor:uint, thumbColor:uint, thumbHoverColor:uint = 0):void
    {
        verticalSlider.setTrackColor(trackColor);
        verticalSlider.setThumbColor(thumbColor, thumbHoverColor > 0 ? thumbHoverColor : thumbColor + 0x222222);
    }

    public function setCornerRadius(radius:Number):void
    {
        maskBackground.setCornerRadius(radius);
        verticalSlider.setCornerRadius(Math.min(radius, 6)); // Slider uses smaller radius
    }

    public function setSliderWidth(width:Number):void
    {
        this._sliderWidth = width;
        verticalSlider.setSize(width, _containerHeight - (_sliderMargin * 2));
        verticalSlider.setPosition(_containerX + _containerWidth + _sliderMargin, _containerY + _sliderMargin);
    }

    // Scrolling control
    public function scrollToTop():void
    {
        verticalSlider.setValue(0);
    }

    public function scrollToBottom():void
    {
        verticalSlider.setValue(_maxScrollRange);
    }

    public function scrollByAmount(amount:Number):void
    {
        var newValue:Number = verticalSlider.value + amount;
        verticalSlider.setValue(newValue);
    }

    // Getters
    public function get containerBounds():Rectangle
    {
        return new Rectangle(_containerX, _containerY, _containerWidth, _containerHeight);
    }

    public function get contentContainer():Sprite { return chatContent; }
    public function get maskContainer():PCMask { return maskBackground; }
    public function get slider():PCSlider{ return verticalSlider; }
    public function get contentHeight():Number { return _contentHeight; }
    public function get maxScrollRange():Number { return _maxScrollRange; }
    public function get isScrollable():Boolean { return _maxScrollRange > 0; }
    public function get visualizer():PCVisualiser { return chatVisualizer; }
    public function get toggleButton():PCToggle { return chatToggle; }

    // Utility methods
    public function getContentBounds():Rectangle
    {
        return maskBackground.getContentBounds();
    }

    public function hitTestChat(localX:Number, localY:Number):Boolean
    {
        var bounds:Rectangle = containerBounds;
        return (localX >= bounds.x && localX <= bounds.x + bounds.width &&
                localY >= bounds.y && localY <= bounds.y + bounds.height);
    }

    public function updateVisualizerLevel(level:Number):void
    {
        if (chatVisualizer)
        {
            chatVisualizer.setAudioLevel(level);
        }
    }

    public function updateToggleState(isEnabled:Boolean):void
    {
        if (chatToggle)
        {
            chatToggle.setState(isEnabled, false);
        }
    }
    public function dispose():void
    {
        // Remove event listeners
        if (verticalSlider)
        {
            verticalSlider.removeEventListener(PCSlider.VALUE_CHANGED, onSliderValueChanged);
            verticalSlider.dispose();
        }

        // Clear content
        clearChatContent();

        // Remove components
        if (maskBackground && maskBackground.parent)
        {
            removeChild(maskBackground);
            maskBackground.dispose();
        }

        if (verticalSlider && verticalSlider.parent)
        {
            removeChild(verticalSlider);
        }

        if (chatTabs)
        {
            chatTabs.dispose();
            if (chatTabs.parent) removeChild(chatTabs);
            chatTabs = null;
        }
        if (chatToggle)
        {
            chatToggle.removeEventListener(PCToggle.TOGGLE_CHANGED, onToggleChanged);
            chatToggle.dispose();
            if (chatToggle.parent) removeChild(chatToggle);
            chatToggle = null;
        }

        if (chatVisualizer)
        {
            chatVisualizer.dispose();
            if (chatVisualizer.parent) removeChild(chatVisualizer);
            chatVisualizer = null;
        }

        if (audioBridge)
        {
            audioBridge.dispose();
            audioBridge = null;
        }
        maskBackground = null;
        verticalSlider = null;
        chatContent = null;


    }









}
}