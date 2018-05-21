----
-- ZO_DailyRewardsTile_Keyboard
----

ZO_DAILY_REWARDS_TILE_KEYBOARD_DEFAULT_HIGHLIGHT_ANIMATION_PROVIDER = ZO_ReversibleAnimationProvider:New("ShowOnMouseOverLabelAnimation")

-- Primary logic class must be subclassed after the platform class so that platform specific functions will have priority over the logic class functionality
ZO_DailyRewardsTile_Keyboard = ZO_Object.MultiSubclass(ZO_ClaimTile_Keyboard, ZO_DailyRewardsTile)

function ZO_DailyRewardsTile_Keyboard:New(...)
    return ZO_DailyRewardsTile.New(self, ...)
end

-- Begin ZO_ActionTile_Keyboard Overrides --

function ZO_DailyRewardsTile_Keyboard:PostInitializePlatform()
    ZO_ClaimTile_Keyboard.PostInitializePlatform(self)

    self:SetHighlightAnimationProvider(ZO_DAILY_REWARDS_TILE_KEYBOARD_DEFAULT_HIGHLIGHT_ANIMATION_PROVIDER)

    local function OnActionButtonMouseEnter()
        self:OnMouseEnter()
    end

    local function OnActionButtonMouseExit()
        self:OnMouseExit()
    end

    self.actionButton:SetHandler("OnMouseEnter", OnActionButtonMouseEnter)
    self.actionButton:SetHandler("OnMouseExit", OnActionButtonMouseExit)
end

function ZO_DailyRewardsTile_Keyboard:OnMouseEnter()
    ZO_ActionTile_Keyboard.OnMouseEnter(self)
    self.isMousedOver = true

    self.actionButton:SetShowingHighlight(self.isMousedOver)
end

function ZO_DailyRewardsTile_Keyboard:OnMouseExit()
    ZO_ActionTile_Keyboard.OnMouseExit(self)
    self.isMousedOver = false

    self.actionButton:SetShowingHighlight(self.isMousedOver)
end

function ZO_DailyRewardsTile_Keyboard:OnMouseUp(button, upInside)
    if self.actionCallback and self:IsActionAvailable() then
        self.actionCallback()
    end
end

function ZO_DailyRewardsTile_Keyboard:ShouldUseSelectedHeaderColor()
    return true
end

-- End ZO_ActionTile_Keyboard Overrides --

-----
-- Global XML Functions
-----

function ZO_DailyRewardsTile_Keyboard_OnInitialized(control)
    ZO_DailyRewardsTile_Keyboard:New(control)
end