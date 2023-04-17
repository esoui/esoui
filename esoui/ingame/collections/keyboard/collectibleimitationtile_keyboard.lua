-- Primary logic class must be subclassed after the platform class so that platform specific functions will have priority over the logic class functionality
ZO_CollectibleImitationTile_Keyboard = ZO_Object.MultiSubclass(ZO_ContextualActionsTile_Keyboard, ZO_ContextualActionsTile)

function ZO_CollectibleImitationTile_Keyboard:New(...)
    return ZO_ContextualActionsTile.New(self, ...)
end

-- Begin ZO_ContextualActionsTile_Keyboard Overrides --

function ZO_CollectibleImitationTile_Keyboard:InitializePlatform()
    ZO_ContextualActionsTile_Keyboard.InitializePlatform(self)

    self.statusMultiIcon = self.control:GetNamedChild("Status")
end

function ZO_CollectibleImitationTile_Keyboard:PostInitializePlatform()
    -- keybindStripDescriptor and canFocus need to be set after initialize, because ZO_ContextualActionsTile
    -- won't have finished initializing those until after InitializePlatform is called
    ZO_ContextualActionsTile_Keyboard.PostInitializePlatform(self)

    table.insert(self.keybindStripDescriptor,
    {
        keybind = "UI_SHORTCUT_PRIMARY",

        name = function()
            return GetString(self:GetPrimaryInteractionStringId())
        end,

        callback = function()
            self:Use()
        end,

        visible = function()
            return self:IsUsable() and self:GetPrimaryInteractionStringId() ~= nil
        end,
    })

    self:SetCanFocus(false)
end

-- End ZO_ContextualActionsTile_Keyboard Overrides --

-- Begin ZO_Tile Overrides --

function ZO_CollectibleImitationTile_Keyboard:Reset()
    self.imitationCollectibleData = nil

    self:SetCanFocus(false)
    local INSTANT = true
    self:SetHighlightHidden(true, INSTANT)
    self:SetTitle("")
    self.statusMultiIcon:ClearIcons()
end

-- End ZO_Tile Overrides --

-- Begin ZO_ContextualActionsTile Overrides --

function ZO_CollectibleImitationTile_Keyboard:OnControlHidden()
    self:OnMouseExit()
    ZO_ContextualActionsTile.OnControlHidden(self)
end

function ZO_CollectibleImitationTile_Keyboard:OnFocusChanged(isFocused)
    ZO_ContextualActionsTile.OnFocusChanged(self, isFocused)

    if not isFocused then
        ClearTooltip(InformationTooltip)
    end
    self:RefreshMouseoverVisuals()
end

function ZO_CollectibleImitationTile_Keyboard:SetHighlightHidden(hidden, instant)
    ZO_ContextualActionsTile.SetHighlightHidden(self, hidden, instant)

    if hidden then
        ZO_CollectibleTile_Keyboard_MouseOverIconAnimationProvider:PlayBackward(self:GetIconTexture(), instant)
    else
        ZO_CollectibleTile_Keyboard_MouseOverIconAnimationProvider:PlayForward(self:GetIconTexture(), instant)
    end
end

-- End ZO_ContextualActionsTile Overrides --

-- Begin ZO_ContextualActionsTile_Keyboard Overrides --

function ZO_CollectibleImitationTile_Keyboard:LayoutPlatform(imitationCollectibleData)
    self.imitationCollectibleData = imitationCollectibleData
    self:SetCanFocus(true)

    -- Title
    self:SetTitle(imitationCollectibleData:GetName())

    -- Icon/Highlight
    local iconTexture = self:GetIconTexture()
    iconTexture:SetTexture(imitationCollectibleData:GetIcon())

    local desaturation = imitationCollectibleData:IsBlocked(self:GetActorCategory()) and 1 or 0
    self:GetHighlightControl():SetDesaturation(desaturation)
    iconTexture:SetDesaturation(desaturation)

    self:Refresh()
end

function ZO_CollectibleImitationTile_Keyboard:Refresh()
    -- Status
    local statusMultiIcon = self.statusMultiIcon
    statusMultiIcon:ClearIcons()

    if self:IsActive() and not self.imitationCollectibleData:ShouldSuppressActiveState(self:GetActorCategory()) then
        statusMultiIcon:AddIcon(ZO_CHECK_ICON)
    end

    statusMultiIcon:Show()

    self:UpdateKeybinds()

    -- Mouseover
    self:RefreshMouseoverVisuals()
end

function ZO_CollectibleImitationTile_Keyboard:OnMouseUp(button, upInside)
    if upInside and button == MOUSE_BUTTON_INDEX_RIGHT then
        self:ShowMenu()
    end
end

function ZO_CollectibleImitationTile_Keyboard:OnMouseDoubleClick(button)
    if button == MOUSE_BUTTON_INDEX_LEFT and self:IsUsable() then
        self:Use()
    end
end

-- End ZO_ContextualActionsTile_Keyboard Overrides --

function ZO_CollectibleImitationTile_Keyboard:GetActorCategory()
    return self.imitationCollectibleData.actorCategory or GAMEPLAY_ACTOR_CATEGORY_PLAYER
end

function ZO_CollectibleImitationTile_Keyboard:RefreshTitleLabelColor()
    local labelColor = self:IsMousedOver() and ZO_HIGHLIGHT_TEXT or ZO_NORMAL_TEXT
    self:GetTitleLabel():SetColor(labelColor:UnpackRGBA())
end

function ZO_CollectibleImitationTile_Keyboard:RefreshMouseoverVisuals()
    if self:IsMousedOver() then
        local description = self.imitationCollectibleData:GetDescription(self:GetActorCategory())
        if description then
            -- Tooltip
            ClearTooltip(InformationTooltip)
            local offsetX = self.control:GetParent():GetLeft() - self.control:GetLeft() - 5
            InitializeTooltip(InformationTooltip, self.control, RIGHT, offsetX, 0, LEFT)

            local DEFAULT_FONT = ""
            local r, g, b = ZO_NORMAL_TEXT:UnpackRGB()
            InformationTooltip:AddLine(self.imitationCollectibleData:GetName(), DEFAULT_FONT, r, g, b)
            InformationTooltip:AddLine(description, DEFAULT_FONT, r, g, b)

            if self:IsActive() and self.imitationCollectibleData.GetActiveCollectibleText then
                local activeCollectibleText = self.imitationCollectibleData:GetActiveCollectibleText(self:GetActorCategory())
                if activeCollectibleText ~= nil and activeCollectibleText ~= "" then
                    InformationTooltip:AddLine(activeCollectibleText, DEFAULT_FONT, r, g, b)
                end
            end

            if self.imitationCollectibleData:IsBlocked(self:GetActorCategory()) then
                local errorR, errorG, errorB = ZO_ERROR_COLOR:UnpackRGB()
                InformationTooltip:AddLine(self.imitationCollectibleData:GetBlockReason(self:GetActorCategory()), DEFAULT_FONT, errorR, errorG, errorB)
            end
        end
    end

    self:RefreshTitleLabelColor()
end

function ZO_CollectibleImitationTile_Keyboard:GetPrimaryInteractionStringId()
    if not self.imitationCollectibleData:IsBlocked(self:GetActorCategory()) then
        return self.imitationCollectibleData:GetPrimaryInteractionStringId(self:GetActorCategory())
    end
    return nil
end

function ZO_CollectibleImitationTile_Keyboard:ShowMenu()
    ClearMenu()

    --Use
    local stringId = self:GetPrimaryInteractionStringId()
    if stringId and self:IsUsable() then
        AddMenuItem(GetString(stringId), function() self:Use() end)
    end

    ShowMenu(self.control)
end

function ZO_CollectibleImitationTile_Keyboard:IsActive()
    return self.imitationCollectibleData:IsActive(self:GetActorCategory())
end

function ZO_CollectibleImitationTile_Keyboard:IsUsable()
    return self.imitationCollectibleData:IsUsable(self:GetActorCategory())
end

function ZO_CollectibleImitationTile_Keyboard:Use()
    self.imitationCollectibleData:Use(self:GetActorCategory())
end

-- Begin Global XML Functions --

function ZO_CollectibleImitationTile_Keyboard_OnInitialized(control)
    ZO_CollectibleImitationTile_Keyboard:New(control)
end

-- End Global XML Functions --