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

    self.titleLabel = self.control:GetNamedChild("Title")
    self.iconTexture = self.control:GetNamedChild("Icon")
    self.highlightControl = self.control:GetNamedChild("Highlight")

    self.keybindStripDescriptor = {}
    self.isFocused = false
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

function ZO_ContextualActionsTile:CanFocus()
    return self.canFocus
end

function ZO_ContextualActionsTile:SetCanFocus(canFocus)
    if self:CanFocus() ~= canFocus then
        if not canFocus then
            self:Defocus()
        end

        self.canFocus = canFocus
    end
end

function ZO_ContextualActionsTile:IsFocused()
    return self.isFocused
end

function ZO_ContextualActionsTile:Focus()
    if self:CanFocus() and not self:IsFocused() then
        self.isFocused = true
        self:OnFocusChanged(self.isFocused)
    end
end

function ZO_ContextualActionsTile:Defocus()
    if self:CanFocus() and self:IsFocused() then
        self.isFocused = false
        self:OnFocusChanged(self.isFocused)
    end
end

function ZO_ContextualActionsTile:OnFocusChanged(isFocused)
    if isFocused then
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
    self:Defocus()
end

-- End ZO_Tile Overrides --