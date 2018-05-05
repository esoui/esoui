----
-- ZO_ActionTile
----

------
-- For order of instantiation to happen in the intended order the base class must be inherited before it's platform counterpart
-- (IMPLEMENTS OF THESE FUNCTIONS IN THIS CLASS WILL BE COMPETELY OVERRIDDEN BY PLATFORM SPECIFIC IMPLEMENTATIONS)
--    SetActionAvailable
--    SetActionText
--    SetActionCallback
------

ZO_ActionTile = ZO_Tile:Subclass()

function ZO_ActionTile:New(...)
    return ZO_Tile.New(self, ...)
end

function ZO_ActionTile:Initialize(control)
    ZO_Tile.Initialize(self, control)

    -- Store isActionAvailable since the action button could be hidden 
    -- for reason other than the availability. Default action to be available.
    self.isActionAvailable = true

    self.container = control:GetNamedChild("Container")
    self.headerLabel = self.container:GetNamedChild("Header")
    self.titleLabel = self.container:GetNamedChild("Title")
    self.backgroundTexture = self.container:GetNamedChild("Background")
    self.highlightControl = self.container:GetNamedChild("Highlight")

    self.canFocus = true
end

function ZO_ActionTile:SetHeaderText(headerText)
    self.headerLabel:SetText(headerText)
end

function ZO_ActionTile:SetHeaderColor(headerColor)
    self.headerLabel:SetColor(headerColor:UnpackRGB())
end

function ZO_ActionTile:SetTitle(titleText)
    self.titleLabel:SetText(titleText)
end

function ZO_ActionTile:SetTitleColor(titleColor)
    self.titleLabel:SetColor(titleColor:UnpackRGB())
end

function ZO_ActionTile:SetBackground(backgroundFile)
    self.backgroundTexture:SetTexture(backgroundFile)
end

function ZO_ActionTile:SetBackgroundColor(backgroundColor)
    self.backgroundTexture:SetColor(backgroundColor:UnpackRGB())
end

function ZO_ActionTile:SetActionAvailable(available)
    self.isActionAvailable = available
end

function ZO_ActionTile:IsActionAvailable()
    return self.isActionAvailable
end

function ZO_ActionTile:SetActionText(actionText)
    -- To be overridden
end

function ZO_ActionTile:SetActionSound(actionSound)
    -- To be overridden
end

function ZO_ActionTile:SetActionCallback(actionCallback)
    self.actionCallback = actionCallback
end

function ZO_ActionTile:SetHighlightAnimationProvider(provider)
    self.highlightAnimationProvider = provider
end

function ZO_ActionTile:SetCanFocus(canFocus)
    self.canFocus = canFocus
end

function ZO_ActionTile:OnFocusChanged(isFocused)
    if isFocused and self.canFocus then
        self:SetHighlightHidden(false)
    else
        self:SetHighlightHidden(true)
    end
end

function ZO_ActionTile:IsHighlightHidden()
    return self.hidden
end

function ZO_ActionTile:SetHighlightHidden(hidden, instant)
    self.hidden = hidden
    if self.highlightAnimationProvider and self.highlightControl then
        if hidden then
            self.highlightAnimationProvider:PlayBackward(self.highlightControl, instant)
        else
            self.highlightAnimationProvider:PlayForward(self.highlightControl, instant)
        end
    end
end

-- Begin ZO_Tile Overrides --

function ZO_ActionTile:OnControlHidden()
    ZO_Tile.OnControlHidden(self)
    local IS_NOT_FOCUSED = false
    self:OnFocusChanged(IS_NOT_FOCUSED)
end

-- End ZO_Tile Overrides --