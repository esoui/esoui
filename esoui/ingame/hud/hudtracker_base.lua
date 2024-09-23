------------------
--Initialization--
------------------

ZO_HUDTracker_Base = ZO_InitializingCallbackObject:Subclass()

function ZO_HUDTracker_Base:Initialize(control)
    self.control = control
    control.owner = self

    self.container = control:GetNamedChild("Container")
    self.headerLabel = self.container:GetNamedChild("Header")
    self.subLabel = self.container:GetNamedChild("SubLabel")

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
    end)

    -- Defer remaining initialization until after all controls have loaded
    -- in order to guarantee that all anchor references will be valid.
    self.control:RegisterForEvent(EVENT_ADD_ON_LOADED, function(_, name)
        if name == "ZO_Ingame" then
            self.control:UnregisterForEvent(EVENT_ADD_ON_LOADED)
            self:DeferredInitialize()
        end
    end)
end

function ZO_HUDTracker_Base:DeferredInitialize()
    self:InitializeStyles()
    self:RegisterEvents()
end

function ZO_HUDTracker_Base:InitializeStyles()
    local keyboardStyle = self.styles.keyboard
    local gamepadStyle = self.styles.gamepad
    local allConstants = { keyboardStyle, gamepadStyle }
    for _, constants in ipairs(allConstants) do
        constants.HEADER_PRIMARY_ANCHOR = ZO_Anchor:New(TOPRIGHT)
        constants.SUBLABEL_PRIMARY_ANCHOR = ZO_Anchor:New(TOPRIGHT, self.headerLabel, BOTTOMRIGHT, 0, constants.SUBLABEL_PRIMARY_ANCHOR_OFFSET_Y)
    end

    keyboardStyle.HEADER_SECONDARY_ANCHOR = ZO_Anchor:New(TOPLEFT)
    keyboardStyle.SUBLABEL_SECONDARY_ANCHOR = ZO_Anchor:New(TOPLEFT, self.headerLabel, BOTTOMLEFT, 10, keyboardStyle.SUBLABEL_PRIMARY_ANCHOR_OFFSET_Y)

    ZO_PlatformStyle:New(function(style) self:ApplyPlatformStyle(style) end, keyboardStyle, gamepadStyle)
end

function ZO_HUDTracker_Base:RegisterEvents()
    local function OnQuestTrackerFragmentStateChanged(oldState, newState)
        if newState == SCENE_FRAGMENT_SHOWING or newState == SCENE_FRAGMENT_HIDDEN then
            self:RefreshAnchors()
        end
    end

    FOCUSED_QUEST_TRACKER:RegisterCallback("QuestTrackerFragmentStateChange", OnQuestTrackerFragmentStateChanged)
end

function ZO_HUDTracker_Base:Update()
    -- To be overridden
end

function ZO_HUDTracker_Base:OnShowing()
    -- To be overridden
end

function ZO_HUDTracker_Base:OnShown()
    -- To be overridden
end

function ZO_HUDTracker_Base:OnHiding()
    -- To be overridden
end

function ZO_HUDTracker_Base:OnHidden()
    -- To be overridden
end

function ZO_HUDTracker_Base:GetFragment()
    return self.fragment
end

function ZO_HUDTracker_Base:GetPrimaryAnchor()
    -- To be overridden
    return nil
end

function ZO_HUDTracker_Base:GetSecondaryAnchor()
    -- To be overridden
    return nil
end

function ZO_HUDTracker_Base:SetHeaderText(text)
    self.headerLabel:SetText(text)
end

function ZO_HUDTracker_Base:SetSubLabelText(text)
    self.subLabel:SetText(text)
end

function ZO_HUDTracker_Base:ApplyPlatformStyle(style)
    self.currentStyle = style

    self.headerLabel:SetModifyTextType(style.TEXT_TYPE_HEADER)
    self.headerLabel:SetFont(style.FONT_HEADER)
    self.subLabel:SetFont(style.FONT_SUBLABEL)
    self.control:SetResizeToFitPadding(0, style.RESIZE_TO_FIT_PADDING_HEIGHT)

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

    self:RefreshAnchorSetOnControl(self.control, self:GetPrimaryAnchor(), self:GetSecondaryAnchor())
    self:RefreshAnchorSetOnControl(self.container, style.CONTAINER_PRIMARY_ANCHOR, style.CONTAINER_SECONDARY_ANCHOR)
    self:RefreshAnchorSetOnControl(self.headerLabel, style.HEADER_PRIMARY_ANCHOR, style.HEADER_SECONDARY_ANCHOR)
    self:RefreshAnchorSetOnControl(self.subLabel, style.SUBLABEL_PRIMARY_ANCHOR, style.SUBLABEL_SECONDARY_ANCHOR)
end