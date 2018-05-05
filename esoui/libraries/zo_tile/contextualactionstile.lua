------
-- For order of instantiation to happen in the intended order the base class must be inherited after it's platform counterpart
-- "Focus" will be determined by the nature of "selection" per platform
------

ZO_ContextualActionsTile = ZO_Tile:Subclass()

function ZO_ContextualActionsTile:New(...)
    return ZO_Tile.New(self, ...)
end

function ZO_ContextualActionsTile:Initialize(control)
    ZO_Tile.Initialize(self, control)

    self.container = control:GetNamedChild("Container")
    self.titleLabel = self.container:GetNamedChild("Title")
    self.iconTexture = self.container:GetNamedChild("Icon")
    self.highlightControl = self.container:GetNamedChild("Highlight")

    self.keybindStripDescriptor = {}
    self.canFocus = true
end

function ZO_ContextualActionsTile:GetTitleLabel()
    return self.titleLabel
end

function ZO_ContextualActionsTile:SetTitle(titleText)
    self.titleLabel:SetText(titleText)
end

function ZO_ContextualActionsTile:GetIconTexture()
    return self.iconTexture
end

function ZO_ContextualActionsTile:SetIcon(iconFile)
    self.iconTexture:SetTexture(iconFile)
end

function ZO_ContextualActionsTile:GetHighlightControl()
    return self.highlightControl
end

function ZO_ContextualActionsTile:SetHighlightAnimationProvider(provider)
    self.highlightAnimationProvider = provider
end

function ZO_ContextualActionsTile:GetKeybindStripDescriptor()
    return self.keybindStripDescriptor
end

function ZO_ContextualActionsTile:SetCanFocus(canFocus)
    self.canFocus = canFocus
end

function ZO_ContextualActionsTile:OnFocusChanged(isFocused)
    if isFocused and self.canFocus then
        KEYBIND_STRIP:AddKeybindButtonGroup(self.keybindStripDescriptor)
        self:SetHighlightHidden(false)
    else
        KEYBIND_STRIP:RemoveKeybindButtonGroup(self.keybindStripDescriptor)
        self:SetHighlightHidden(true)
    end
end

function ZO_ContextualActionsTile:SetHighlightHidden(hidden, instant)
    if self.highlightAnimationProvider then
        if hidden then
            self.highlightAnimationProvider:PlayBackward(self.highlightControl, instant)
        else
            self.highlightAnimationProvider:PlayForward(self.highlightControl, instant)
        end
    end
end

function ZO_ContextualActionsTile:UpdateKeybinds()
    KEYBIND_STRIP:UpdateKeybindButtonGroup(self.keybindStripDescriptor)
end

-- Begin ZO_Tile Overrides --

function ZO_ContextualActionsTile:OnControlHidden()
    ZO_Tile.OnControlHidden(self)
    local IS_NOT_FOCUSED = false
    self:OnFocusChanged(IS_NOT_FOCUSED)
end

-- End ZO_Tile Overrides --