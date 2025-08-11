package kabam.rotmg.ProximityChat {

import flash.display.Shape;
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

    private var voiceService:VoiceChatService;



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

        // CREATE A VIRTUAL SCROLLABLE BACKGROUND
        var virtualBackground:Shape = new Shape();
        virtualBackground.graphics.beginFill(0x000000, 0); // Transparent
        virtualBackground.graphics.drawRect(0, 0, _containerWidth, _containerHeight * 3); // 3x height
        virtualBackground.graphics.endFill();
        chatContent.addChild(virtualBackground); // Add this FIRST so it defines the content area

        // Create vertical slider
        verticalSlider = new PCSlider(
                _sliderWidth,
                _containerHeight - (_sliderMargin * 2),
                _containerX + _containerWidth + _sliderMargin,
                _containerY + _sliderMargin,
                PCSlider.VERTICAL,
                0,
                _containerHeight * 2  // Set initial scroll range
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

        voiceService = VoiceChatService.getInstance();
        voiceService.initialize();

        chatTabs.addEventListener("microphoneSelected", onMicrophoneSelected);

        // At the end of PCManager.initialize():

        trace("PCManager: initialize() complete, getting VoiceChatService");
        var voiceService:VoiceChatService = VoiceChatService.getInstance();
        voiceService.initialize();

// Listen for microphone updates
        voiceService.addMicrophoneListener(onMicrophonesReceived);

// Check if already available
        trace("PCManager: Checking for stored microphones");
        if (voiceService.hasStoredMicrophones()) {
            trace("PCManager: Found stored microphones, retrieving them");
            var mics:Array = voiceService.getStoredMicrophones();
            onMicrophonesReceived(mics);
        } else {
            trace("PCManager: No stored microphones found, waiting for notification");
        }
        voiceService.setProximityChatManager(this);

    }



    private function onMicrophonesReceived(mics:Array):void
    {
        trace("PCManager: Received", mics.length, "microphones from VoiceChatService");
        setAvailableMicrophones(mics);
        // No more settings logic here - VoiceChatService handles it
    }




// Modify your existing onMicrophoneSelected method:
    private function onMicrophoneSelected(e:Event):void
    {
        trace("=== onMicrophoneSelected START ===");

        if (!chatTabs || !chatTabs.algorithmTabBackground) {
            trace("ERROR: chatTabs or algorithmTabBackground is null");
            return;
        }

        var micSelector:PCMicSelector = chatTabs.getMicSelectorForBackground(chatTabs.algorithmTabBackground);
        if (!micSelector) {
            trace("ERROR: micSelector is null");
            return;
        }

        var selectedMicId:String = micSelector.selectedMicrophoneId;

        if (!selectedMicId) {
            trace("ERROR: selectedMicrophoneId is null");
            return;
        }

        trace("PCManager: Microphone selected:", micSelector.selectedMicrophoneName);

        var voiceService:VoiceChatService = VoiceChatService.getInstance();
        if (!voiceService) {
            trace("ERROR: voiceService is null");
            return;
        }

        // VoiceChatService will handle both selection AND saving
        voiceService.selectMicrophone(selectedMicId);

        trace("=== onMicrophoneSelected END ===");
    }

// 3. MODIFY your onToggleChanged method in PCManager:



    public function setAvailableMicrophones(mics:Array):void {
        trace("PCManager: setAvailableMicrophones called with", mics.length, "microphones");

        if (chatTabs && chatTabs.algorithmTabBackground) {
            var micSelector:PCMicSelector = chatTabs.getMicSelectorForBackground(chatTabs.algorithmTabBackground);
            if (micSelector) {
                trace("PCManager: Found mic selector, setting microphones");
                micSelector.setMicrophones(mics);
            } else {
                trace("PCManager: Mic selector not found in background");
            }
        } else {
            trace("PCManager: chatTabs or algorithmTabBackground is null");
        }
    }
    public function getMicSelectorForBackground(background:Sprite):PCMicSelector {
        if (chatTabs) {
            return chatTabs.getMicSelectorForBackground(background);
        }
        return null;
    }
    private function onToggleChanged(e:Event):void
    {
        var toggle:PCToggle = e.target as PCToggle;
        trace("PCManager: Toggle state changed to:", toggle.getStateString());

        var voiceService:VoiceChatService = VoiceChatService.getInstance();

        // VoiceChatService will handle both the microphone AND saving the state
        voiceService.setChatEnabled(toggle.isOn);
    }

    private function applyDefaultStyling():void
    {
        // Style the mask/background
        maskBackground.setBackgroundColor(0x1a1a1a, 0.9);
        maskBackground.setBorder(0x444444, 1);
        maskBackground.setCornerRadius(8);

        // Style the slider
        verticalSlider.setTrackColor(0x2a2a2a, 0.8);
        verticalSlider.setThumbColor(0xBBBBBB, 0xDDDDDD, 1.0);
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
    public function updateMicrophoneSelection(micId:String):void
    {
        if (!chatTabs || !chatTabs.algorithmTabBackground) {
            trace("PCManager: Cannot update microphone selection - UI not ready");
            return;
        }

        var micSelector:PCMicSelector = chatTabs.getMicSelectorForBackground(chatTabs.algorithmTabBackground);
        if (!micSelector) {
            trace("PCManager: Cannot update microphone selection - selector not found");
            return;
        }

        if (micSelector.selectMicrophoneById(micId)) {
            trace("PCManager: Updated UI to show microphone ID:", micId);
        } else {
            trace("PCManager: Failed to update UI for microphone ID:", micId);
        }
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
        // Calculate the total content height (excluding the virtual background)
        var maxY:Number = 0;
        for (var i:int = 1; i < chatContent.numChildren; i++) // Start from 1 to skip virtual background
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

        // Always maintain at least 2x container height for scrolling
        _maxScrollRange = _containerHeight * 2;

        // Update slider range
        verticalSlider.setRange(0, _maxScrollRange);

        // Always show slider
        verticalSlider.visible = true;
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
        // Step 1: Remove event listeners FIRST (prevent any callbacks)
        if (verticalSlider)
        {
            verticalSlider.removeEventListener(PCSlider.VALUE_CHANGED, onSliderValueChanged);
        }

        if (chatToggle)
        {
            chatToggle.removeEventListener(PCToggle.TOGGLE_CHANGED, onToggleChanged);
        }
        if (chatTabs) {
            chatTabs.removeEventListener("microphoneSelected", onMicrophoneSelected);
        }

        // Step 2: Clear content BEFORE disposing slider (while slider still works)
        clearChatContent();
        var voiceService:VoiceChatService = VoiceChatService.getInstance();
        voiceService.removeMicrophoneListener(onMicrophonesReceived);
        // Step 3: Now dispose components in reverse order of creation
        if (audioBridge)
        {
            audioBridge.dispose();
            audioBridge = null;
        }

        if (chatVisualizer)
        {
            chatVisualizer.dispose();
            if (chatVisualizer.parent) removeChild(chatVisualizer);
            chatVisualizer = null;
        }

        if (chatToggle)
        {
            chatToggle.dispose();
            if (chatToggle.parent) removeChild(chatToggle);
            chatToggle = null;
        }

        if (chatTabs)
        {
            chatTabs.dispose();
            if (chatTabs.parent) removeChild(chatTabs);
            chatTabs = null;
        }

        // Step 4: Dispose slider AFTER content is cleared
        if (verticalSlider && verticalSlider.parent)
        {
            removeChild(verticalSlider);
            verticalSlider.dispose();
        }

        // Step 5: Dispose mask/background last
        if (maskBackground && maskBackground.parent)
        {
            removeChild(maskBackground);
            maskBackground.dispose();
        }

        // Step 6: Set references to null
        maskBackground = null;
        verticalSlider = null;
        chatContent = null;
    }










}
}