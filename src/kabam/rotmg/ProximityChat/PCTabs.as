package kabam.rotmg.ProximityChat
{
import flash.display.Sprite;
import flash.display.Shape;
import flash.display.Graphics;
import flash.events.MouseEvent;
import flash.events.Event;
import flash.text.TextField;
import flash.text.TextFormat;
import flash.text.TextFieldAutoSize;

public class PCTabs extends Sprite
{
    // Tab configuration
    private var _tabWidth:Number;
    private var _tabHeight:Number;
    private var _tabSpacing:Number;
    private var _x:Number;
    private var _y:Number;

    // Visual properties
    private var _activeTabColor:uint;
    private var _inactiveTabColor:uint;
    private var _hoverTabColor:uint;
    private var _borderColor:uint;
    private var _textColor:uint;
    private var _activeTextColor:uint;
    private var _cornerRadius:Number;

    // Tab data
    private var tabs:Vector.<TabButton>;
    private var tabBackgrounds:Vector.<Sprite>;
    private var activeTabIndex:int;
    private var targetContainer:Sprite; // Container where backgrounds will be shown

    // Tab button class
    private var blockedTab:TabButton;
    private var algorithmTab:TabButton;
    private var blockedBackground:Sprite;
    private var algorithmBackground:Sprite;

    // Constants
    private static const DEFAULT_TAB_WIDTH:Number = 80;
    private static const DEFAULT_TAB_HEIGHT:Number = 30;
    private static const DEFAULT_TAB_SPACING:Number = 2;
    private static const DEFAULT_ACTIVE_COLOR:uint = 0x444444;
    private static const DEFAULT_INACTIVE_COLOR:uint = 0x2a2a2a;
    private static const DEFAULT_HOVER_COLOR:uint = 0x333333;
    private static const DEFAULT_BORDER_COLOR:uint = 0x666666;
    private static const DEFAULT_TEXT_COLOR:uint = 0xcccccc;
    private static const DEFAULT_ACTIVE_TEXT_COLOR:uint = 0xffffff;

    // Events
    public static const TAB_CHANGED:String = "tabChanged";

    public function PCTabs (
            x:Number = 0,
            y:Number = 0,
            tabWidth:Number = DEFAULT_TAB_WIDTH,
            tabHeight:Number = DEFAULT_TAB_HEIGHT
    )
    {
        this._x = x;
        this._y = y;
        this._tabWidth = tabWidth;
        this._tabHeight = tabHeight;
        this._tabSpacing = DEFAULT_TAB_SPACING;

        // Set default visual properties
        _activeTabColor = DEFAULT_ACTIVE_COLOR;
        _inactiveTabColor = DEFAULT_INACTIVE_COLOR;
        _hoverTabColor = DEFAULT_HOVER_COLOR;
        _borderColor = DEFAULT_BORDER_COLOR;
        _textColor = DEFAULT_TEXT_COLOR;
        _activeTextColor = DEFAULT_ACTIVE_TEXT_COLOR;
        _cornerRadius = 4;

        activeTabIndex = 0;

        initialize();
    }

    private function initialize():void
    {
        // Position the tabs container
        this.x = _x;
        this.y = _y;

        // Initialize collections
        tabs = new Vector.<TabButton>();
        tabBackgrounds = new Vector.<Sprite>();

        // Create tab buttons
        createTabs();

        // Create backgrounds for each tab
        createBackgrounds();

        // Set initial active tab
        setActiveTab(0, false);
    }

    private function createTabs():void
    {
        // Create "Blocked" tab
        blockedTab = new TabButton("Blocked", _tabWidth, _tabHeight);
        blockedTab.x = 0;
        blockedTab.y = 0;
        blockedTab.addEventListener(MouseEvent.CLICK, onBlockedTabClick);
        addChild(blockedTab);
        tabs.push(blockedTab);

        // Create "Algorithm" tab
        algorithmTab = new TabButton("Adjust", _tabWidth, _tabHeight);
        algorithmTab.x = _tabWidth + _tabSpacing;
        algorithmTab.y = 0;
        algorithmTab.addEventListener(MouseEvent.CLICK, onAlgorithmTabClick);
        addChild(algorithmTab);
        tabs.push(algorithmTab);

        // Apply styling to all tabs
        updateTabStyling();
    }

    private function createBackgrounds():void
    {
        // Create background for "Blocked" tab
        blockedBackground = new Sprite();
        createBackgroundContent(blockedBackground, 0x1a1a2a, "Blocked Content Area");
        tabBackgrounds.push(blockedBackground);

        // Create background for "Algorithm" tab
        algorithmBackground = new Sprite();
        createBackgroundContent(algorithmBackground, 0x2a1a1a, "Algorithm Content Area");
        tabBackgrounds.push(algorithmBackground);
    }

    private function createBackgroundContent(background:Sprite, color:uint, labelText:String):void
    {
        // Just add a label for identification (no colored background overlay)
        var label:TextField = new TextField();
        label.text = labelText;
        label.textColor = 0xcccccc;
        label.autoSize = TextFieldAutoSize.LEFT;
        label.x = 10;
        label.y = 10;
        background.addChild(label);

        // You can add specific content for each tab here later
        // For now, each tab just shows its label
    }

    // Event handlers
    private function onBlockedTabClick(e:MouseEvent):void
    {
        setActiveTab(0);
    }

    private function onAlgorithmTabClick(e:MouseEvent):void
    {
        setActiveTab(1);
    }

    // Public methods
    public function setActiveTab(index:int, dispatchEvent:Boolean = true):void
    {
        if (index < 0 || index >= tabs.length) return;
        if (index == activeTabIndex) return;

        activeTabIndex = index;
        updateTabStyling();
        updateBackgroundVisibility();

        if (dispatchEvent)
        {
            this.dispatchEvent(new Event(TAB_CHANGED));
        }
    }

    public function setTargetContainer(container:Sprite):void
    {
        targetContainer = container;

        // Add all backgrounds to the container
        for (var i:int = 0; i < tabBackgrounds.length; i++)
        {
            container.addChild(tabBackgrounds[i]);
        }

        updateBackgroundVisibility();
    }

    private function updateTabStyling():void
    {
        for (var i:int = 0; i < tabs.length; i++)
        {
            var tab:TabButton = tabs[i];
            var isActive:Boolean = (i == activeTabIndex);

            tab.setColors(
                    isActive ? _activeTabColor : _inactiveTabColor,
                    _hoverTabColor,
                    _borderColor,
                    isActive ? _activeTextColor : _textColor
            );

            tab.setActive(isActive);
        }
    }

    private function updateBackgroundVisibility():void
    {
        if (!targetContainer) return;

        // Hide all backgrounds
        for (var i:int = 0; i < tabBackgrounds.length; i++)
        {
            tabBackgrounds[i].visible = false;
        }

        // Show active background
        if (activeTabIndex >= 0 && activeTabIndex < tabBackgrounds.length)
        {
            tabBackgrounds[activeTabIndex].visible = true;
        }
    }

    // Styling methods
    public function setPosition(x:Number, y:Number):void
    {
        this._x = x;
        this._y = y;
        this.x = x;
        this.y = y;
    }

    public function setTabColors(activeColor:uint, inactiveColor:uint, hoverColor:uint):void
    {
        _activeTabColor = activeColor;
        _inactiveTabColor = inactiveColor;
        _hoverTabColor = hoverColor;
        updateTabStyling();
    }

    public function setTextColors(textColor:uint, activeTextColor:uint):void
    {
        _textColor = textColor;
        _activeTextColor = activeTextColor;
        updateTabStyling();
    }

    public function setBorderColor(color:uint):void
    {
        _borderColor = color;
        updateTabStyling();
    }

    public function setCornerRadius(radius:Number):void
    {
        _cornerRadius = radius;
        for (var i:int = 0; i < tabs.length; i++)
        {
            tabs[i].setCornerRadius(radius);
        }
    }

    public function setTabSize(width:Number, height:Number):void
    {
        _tabWidth = width;
        _tabHeight = height;

        // Update tab sizes and positions
        for (var i:int = 0; i < tabs.length; i++)
        {
            tabs[i].setSize(width, height);
            tabs[i].x = i * (width + _tabSpacing);
        }
    }

    // Getters
    public function get activeTab():int { return activeTabIndex; }
    public function get blockedTabBackground():Sprite { return blockedBackground; }
    public function get algorithmTabBackground():Sprite { return algorithmBackground; }
    public function get tabCount():int { return tabs.length; }

    // Cleanup
    public function dispose():void
    {
        // Remove event listeners
        if (blockedTab)
        {
            blockedTab.removeEventListener(MouseEvent.CLICK, onBlockedTabClick);
            blockedTab.dispose();
        }

        if (algorithmTab)
        {
            algorithmTab.removeEventListener(MouseEvent.CLICK, onAlgorithmTabClick);
            algorithmTab.dispose();
        }

        // Clear collections
        tabs = null;
        tabBackgrounds = null;
        targetContainer = null;
        blockedBackground = null;
        algorithmBackground = null;
    }
}
}

// Internal TabButton class
import flash.display.Sprite;
import flash.display.Shape;
import flash.display.Graphics;
import flash.text.TextField;
import flash.text.TextFormat;
import flash.text.TextFieldAutoSize;
import flash.events.MouseEvent;

class TabButton extends Sprite
{
    private var background:Shape;
    private var label:TextField;
    private var _width:Number;
    private var _height:Number;
    private var _text:String;
    private var _cornerRadius:Number;

    // Colors
    private var _normalColor:uint;
    private var _hoverColor:uint;
    private var _borderColor:uint;
    private var _textColor:uint;
    private var _isActive:Boolean;

    public function TabButton(text:String, width:Number, height:Number)
    {
        _text = text;
        _width = width;
        _height = height;
        _cornerRadius = 4;
        _isActive = false;

        initialize();
    }

    private function initialize():void
    {
        // Create background
        background = new Shape();
        addChild(background);

        // Create label
        label = new TextField();
        label.text = _text;
        label.autoSize = TextFieldAutoSize.CENTER;
        label.selectable = false;
        label.mouseEnabled = false;
        addChild(label);

        // Set up mouse interaction
        this.buttonMode = true;
        this.useHandCursor = true;

        // Add hover events
        addEventListener(MouseEvent.MOUSE_OVER, onMouseOver);
        addEventListener(MouseEvent.MOUSE_OUT, onMouseOut);

        centerLabel();
    }

    private function centerLabel():void
    {
        label.x = (_width - label.width) / 2;
        label.y = (_height - label.height) / 2;
    }

    private function drawBackground(color:uint):void
    {
        var g:Graphics = background.graphics;
        g.clear();
        g.beginFill(color, 1);
        g.lineStyle(1, _borderColor, 1);

        if (_cornerRadius > 0)
        {
            g.drawRoundRect(0, 0, _width, _height, _cornerRadius * 2, _cornerRadius * 2);
        }
        else
        {
            g.drawRect(0, 0, _width, _height);
        }

        g.endFill();
    }

    private function onMouseOver(e:MouseEvent):void
    {
        if (!_isActive)
        {
            drawBackground(_hoverColor);
        }
    }

    private function onMouseOut(e:MouseEvent):void
    {
        if (!_isActive)
        {
            drawBackground(_normalColor);
        }
    }

    public function setColors(normalColor:uint, hoverColor:uint, borderColor:uint, textColor:uint):void
    {
        _normalColor = normalColor;
        _hoverColor = hoverColor;
        _borderColor = borderColor;
        _textColor = textColor;

        label.textColor = textColor;
        drawBackground(_isActive ? _normalColor : _normalColor);
    }

    public function setActive(active:Boolean):void
    {
        _isActive = active;
        drawBackground(_normalColor);
    }

    public function setSize(width:Number, height:Number):void
    {
        _width = width;
        _height = height;
        drawBackground(_normalColor);
        centerLabel();
    }

    public function setCornerRadius(radius:Number):void
    {
        _cornerRadius = radius;
        drawBackground(_normalColor);
    }

    public function dispose():void
    {
        removeEventListener(MouseEvent.MOUSE_OVER, onMouseOver);
        removeEventListener(MouseEvent.MOUSE_OUT, onMouseOut);

        if (background && background.parent) removeChild(background);
        if (label && label.parent) removeChild(label);

        background = null;
        label = null;
    }
}