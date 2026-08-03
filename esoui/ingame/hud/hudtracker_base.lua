ZO_HUD_TRACKER_MAX_WIDTH = 350

------------------
--Initialization--
------------------

ZO_HUDTracker_Base = ZO_InitializingCallbackObject:Subclass()

function ZO_HUDTracker_Base:Initialize(control)
    self.control = control
    control.owner = self

    self.container = control:GetNamedChild("Container")
    self.headerLabel = self.container:GetNamedChild("Header")
    self.headerText = self.headerLabel:GetText()
    self.subLabel = self.container:GetNamedChild("SubLabel")
    self.hudElementRef = control:GetNamedChild("HUDElementRef")

    self.fragment = ZO_HUDFadeSceneFragment:New(self.container)
    self.fragment:RegisterCallback("StateChange", function(oldState, newState)
        if newState == SCENE_SHOWING then
            self:OnShowing()
        elseif newState == SCENE_SHOWN then
            self:OnShown()
        elseif newState == SCENE_HIDING then
            self:OnHiding()
        elseif newState == SCENE_HIDDEN then
            self:OnHidden()
        end
        self:OnFragmentStateChanged(oldState, newState)
    end)

    local elementName, config, options = self:GetHUDElementInfo()
    if elementName then
        local config = config or {}
        if config.defaultAnchor == nil then
            config.defaultAnchor = ZO_Anchor:New(TOPRIGHT)
        end

        local key = self:GetHUDElementOptionKeys()
        local derivedIsValid = config.isValid
        config.isValid = function(element)
            if derivedIsValid and not derivedIsValid(element) then
                return false
            end
            local hudTrackerElement = HUD_TRACKER_MANAGER:GetPlatformHUDElement()
            return hudTrackerElement:GetCustomOptionValue("SeparatedTrackers", key)
        end
        config.overrideDrawLevel = config.overrideDrawLevel or ZO_HUD_EDITOR_ELEMENT_DRAW_LEVELS.LOW

        local options = options or {}
        table.insert(options,
        {
            type = ZO_HUD_EDITOR_OPTION_TYPES.BOOLEAN,
            name = GetString(SI_HUD_EDITOR_RECOMBINE_TRACKER_OPTION),
            key = "Recombine",
            tooltipText = GetString(SI_HUD_EDITOR_RECOMBINE_TRACKER_OPTION_TOOLTIP),
            defaultValue = false,
            dontSave = true,
            callback = function(element, subKey, oldValue, newValue)
                local hudTrackerElement = HUD_TRACKER_MANAGER:GetHUDElement(element:IsGamepad())
                hudTrackerElement:SetCustomOptionValue("SeparatedTrackers", key, false)
            end,
            resetToDefaultAnchorCallback = function(element)
                local rebuildElements = false
                local hudTrackerElement = HUD_TRACKER_MANAGER:GetHUDElement(element:IsGamepad())
                if hudTrackerElement:GetCustomOptionValue("SeparatedTrackers", key) then
                    hudTrackerElement:SetCustomOptionValue("SeparatedTrackers", key, false)
                    rebuildElements = true
                end
                HUD_TRACKER_MANAGER:RefreshLayout()
                return rebuildElements
            end,
        })

        self.keyboardHUDElement = HUD_MANAGER:RegisterKeyboardElement(self.control, elementName, config, options)
        self.gamepadHUDElement = HUD_MANAGER:RegisterGamepadElement(self.control, elementName, config, options)
    end

    -- Defer remaining initialization until after all controls have loaded
    -- in order to guarantee that all anchor references will be valid.
    self.control:RegisterForEvent(EVENT_ADD_ONS_LOADED, function(_, name)
        self:DeferredInitialize()
    end)
end

function ZO_HUDTracker_Base:DeferredInitialize()
    self:InitializeStyles()
    self:RegisterEvents()
end

function ZO_HUDTracker_Base:InitializeStyles()
    self.styles = self.styles or {}
    local styles = self.styles
    styles.keyboard = styles.keyboard or {}
    styles.gamepad = styles.gamepad or {}

    local keyboardStyle = styles.keyboard
    local gamepadStyle = styles.gamepad
    local allConstants = { keyboardStyle, gamepadStyle }
    for _, constants in ipairs(allConstants) do
        constants.CONTAINER_PRIMARY_ANCHOR = constants.CONTAINER_PRIMARY_ANCHOR or ZO_Anchor:New(TOPRIGHT)
        constants.HEADER_PRIMARY_ANCHOR = constants.HEADER_PRIMARY_ANCHOR or ZO_Anchor:New(TOPRIGHT)
    end

    keyboardStyle.SUBLABEL_PRIMARY_ANCHOR_OFFSET_Y = keyboardStyle.SUBLABEL_PRIMARY_ANCHOR_OFFSET_Y or 5
    keyboardStyle.SUBLABEL_PRIMARY_ANCHOR = keyboardStyle.SUBLABEL_PRIMARY_ANCHOR or ZO_Anchor:New(TOPRIGHT, self.headerLabel, BOTTOMRIGHT, 0, keyboardStyle.SUBLABEL_PRIMARY_ANCHOR_OFFSET_Y)
    keyboardStyle.TEXT_TYPE_HEADER = keyboardStyle.TEXT_TYPE_HEADER or MODIFY_TEXT_TYPE_NONE
    keyboardStyle.RESIZE_TO_FIT_PADDING_HEIGHT = keyboardStyle.RESIZE_TO_FIT_PADDING_HEIGHT or 10
    keyboardStyle.FONT_HEADER = keyboardStyle.FONT_HEADER or "ZoFontGameShadow"
    keyboardStyle.FONT_SUBLABEL = keyboardStyle.FONT_SUBLABEL or "ZoFontGameShadow"

    gamepadStyle.SUBLABEL_PRIMARY_ANCHOR_OFFSET_Y = gamepadStyle.SUBLABEL_PRIMARY_ANCHOR_OFFSET_Y or 10
    gamepadStyle.SUBLABEL_PRIMARY_ANCHOR = gamepadStyle.SUBLABEL_PRIMARY_ANCHOR or ZO_Anchor:New(TOPRIGHT, self.headerLabel, BOTTOMRIGHT, 0, gamepadStyle.SUBLABEL_PRIMARY_ANCHOR_OFFSET_Y)
    gamepadStyle.TEXT_TYPE_HEADER = gamepadStyle.TEXT_TYPE_HEADER or MODIFY_TEXT_TYPE_UPPERCASE
    gamepadStyle.RESIZE_TO_FIT_PADDING_HEIGHT = gamepadStyle.RESIZE_TO_FIT_PADDING_HEIGHT or 20
    gamepadStyle.FONT_HEADER = gamepadStyle.FONT_HEADER or "ZoFontGamepadBold27"
    gamepadStyle.FONT_SUBLABEL = gamepadStyle.FONT_SUBLABEL or "ZoFontGamepad34"

    ZO_PlatformStyle:New(function(style) self:ApplyPlatformStyle(style) end, keyboardStyle, gamepadStyle)
end

ZO_HUDTracker_Base:MUST_IMPLEMENT("GetHUDElementInfo")
ZO_HUDTracker_Base:MUST_IMPLEMENT("GetHUDElementOptionKeys")

function ZO_HUDTracker_Base:RegisterEvents()
    -- To be overridden
end

function ZO_HUDTracker_Base:Update()
    -- To be overridden
end

function ZO_HUDTracker_Base:OnShowing()
    HUD_TRACKER_MANAGER:RefreshLayout()
end

function ZO_HUDTracker_Base:OnShown()
    -- To be overridden
end

function ZO_HUDTracker_Base:OnHiding()
    -- To be overridden
end

function ZO_HUDTracker_Base:OnHidden()
    HUD_TRACKER_MANAGER:RefreshLayout()
end

function ZO_HUDTracker_Base:OnFragmentStateChanged(...)
    -- To be overridden
end

function ZO_HUDTracker_Base:GetFragment()
    return self.fragment
end

function ZO_HUDTracker_Base:GetContainerControl()
    return self.container
end

function ZO_HUDTracker_Base:GetPriority()
    return 0
end

function ZO_HUDTracker_Base:IsActive()
    -- HideReasons drives the on/off state, independently of general HUD behavior
    return not self.fragment:IsHiddenForAnyReason()
end

function ZO_HUDTracker_Base:GetPlatformHUDElement()
    return IsInGamepadPreferredMode() and self.gamepadHUDElement or self.keyboardHUDElement
end

function ZO_HUDTracker_Base:IsDetached()
    local parentTracker = self:GetParentTracker()
    if parentTracker then
        return parentTracker:IsDetached()
    end
    local hudElement = self:GetPlatformHUDElement()
    return hudElement and hudElement:IsValid()
end

function ZO_HUDTracker_Base:GetParentTracker()
    return nil
end

function ZO_HUDTracker_Base:SetHeaderText(text)
    self.headerText = text
    self.headerLabel:SetText(text)
end

function ZO_HUDTracker_Base:SetSubLabelText(text)
    self.subLabel:SetText(text)
end

function ZO_HUDTracker_Base:ApplyPlatformStyle(style)
    self.currentStyle = style
    
    if style.TEXT_HORIZONTAL_ALIGNMENT then
        self.headerLabel:SetHorizontalAlignment(style.TEXT_HORIZONTAL_ALIGNMENT)
    end
    self.headerLabel:SetModifyTextType(style.TEXT_TYPE_HEADER)
    self.headerLabel:SetFont(style.FONT_HEADER)
    self.headerLabel:SetText(self.headerText)
    self.subLabel:SetFont(style.FONT_SUBLABEL)
    self.container:SetResizeToFitPadding(0, style.RESIZE_TO_FIT_PADDING_HEIGHT)

    self:RefreshAnchors()

    self:Update()
end

function ZO_HUDTracker_Base:RefreshAnchorSetOnControl(control, primaryAnchor, secondaryAnchor)
    control:ClearAnchors()
    if primaryAnchor then
        primaryAnchor:AddToControl(control)
        if secondaryAnchor then
            secondaryAnchor:AddToControl(control)
        end
    end
end

function ZO_HUDTracker_Base:RefreshAnchors()
    local style = self.currentStyle

    self:RefreshAnchorSetOnControl(self.container, style.CONTAINER_PRIMARY_ANCHOR, style.CONTAINER_SECONDARY_ANCHOR)
    self:RefreshAnchorSetOnControl(self.headerLabel, style.HEADER_PRIMARY_ANCHOR, style.HEADER_SECONDARY_ANCHOR)
    self:RefreshAnchorSetOnControl(self.subLabel, style.SUBLABEL_PRIMARY_ANCHOR, style.SUBLABEL_SECONDARY_ANCHOR)
end