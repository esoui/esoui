ZO_COLLECTIBLE_TILE_KEYBOARD_DIMENSIONS_X = 175
ZO_COLLECTIBLE_TILE_KEYBOARD_DIMENSIONS_Y = 125
ZO_COLLECTIBLE_TILE_KEYBOARD_ICON_DIMENSIONS = 52

local g_mouseOverIconAnimationProvider = ZO_ReversibleAnimationProvider:New("ZO_CollectibleTile_Keyboard_MouseOverIconAnimation")

-- Primary logic class must be subclassed after the platform class so that platform specific functions will have priority over the logic class functionality
ZO_CollectibleTile_Keyboard = ZO_Object.MultiSubclass(ZO_ContextualActionsTile_Keyboard, ZO_ContextualActionsTile)

function ZO_CollectibleTile_Keyboard:New(...)
    return ZO_ContextualActionsTile.New(self, ...)
end

-- Begin ZO_ContextualActionsTile_Keyboard Overrides --

function ZO_CollectibleTile_Keyboard:InitializePlatform()
    ZO_ContextualActionsTile_Keyboard.InitializePlatform(self)
    
    local container = self.control:GetNamedChild("Container")
    self.statusMultiIcon = container:GetNamedChild("Status")
    self.cornerTagTexture = container:GetNamedChild("CornerTag")
    self.cooldownIcon = container:GetNamedChild("CooldownIcon")
    self.cooldownIconDesaturated = container:GetNamedChild("CooldownIconDesaturated")
    self.cooldownTimeLabel = container:GetNamedChild("CooldownTime")
    self.cooldownEdgeTexture = container:GetNamedChild("CooldownEdge")

    self:SetCanFocus(false)

    self.isCooldownActive = false
    self.cooldownDuration = 0
    self.cooldownStartTime = 0
    
    self.onUpdateCooldownsCallback = function() self:OnUpdateCooldowns() end
    self:GetControl():SetHandler("OnUpdate", function() self:OnUpdate() end)
end

function ZO_CollectibleTile_Keyboard:PostInitializePlatform()
    ZO_ContextualActionsTile_Keyboard.PostInitializePlatform(self)

    table.insert(self.keybindStripDescriptor, 
    {
        keybind = "UI_SHORTCUT_PRIMARY",

        name = function()
            return GetString(self:GetPrimaryInteractionStringId())
        end,

        callback = function()
            UseCollectible(self.collectibleData:GetId())
        end,

        visible = function()
            return self.collectibleData and self.collectibleData:IsUsable() and self:GetPrimaryInteractionStringId() ~= nil
        end,
    })

    table.insert(self.keybindStripDescriptor, 
    {
        keybind = "UI_SHORTCUT_SECONDARY",

        name = GetString(SI_COLLECTIBLE_ACTION_RENAME),

        callback = function()
            ZO_CollectionsBook.ShowRenameDialog(self.collectibleData:GetId())
        end,

        visible = function()
            return self.collectibleData and self.collectibleData:IsRenameable()
        end,
    })
end

-- End ZO_ContextualActionsTile_Keyboard Overrides --

function ZO_CollectibleTile_Keyboard:OnUpdate()
    if self.collectibleData and self.isCooldownActive then
        self:UpdateCooldownEffect()
    end
end

function ZO_CollectibleTile_Keyboard:RefreshTitleLabelColor()
    if self.collectibleData then
        local isUnlocked = self.collectibleData:IsUnlocked()
        local isMousedOver = self:IsMousedOver()
        local labelColor
        if isUnlocked then
            labelColor = isMousedOver and ZO_HIGHLIGHT_TEXT or ZO_NORMAL_TEXT
        else
            labelColor = isMousedOver and ZO_SELECTED_TEXT or ZO_DISABLED_TEXT
        end
        self:GetTitleLabel():SetColor(labelColor:UnpackRGBA())
    end
end

function ZO_CollectibleTile_Keyboard:RefreshMouseoverVisuals()
    if self.collectibleData and self:IsMousedOver() then
        -- Tooltip
        ClearTooltip(ItemTooltip)
        local offsetX = self.control:GetParent():GetLeft() - self.control:GetLeft() - 5
        InitializeTooltip(ItemTooltip, self.control, RIGHT, offsetX, 0, LEFT)
        local SHOW_NICKNAME, SHOW_PURCHASABLE_HINT, SHOW_BLOCK_REASON = true, true, true
        ItemTooltip:SetCollectible(self.collectibleData:GetId(), SHOW_NICKNAME, SHOW_PURCHASABLE_HINT, SHOW_BLOCK_REASON)

        -- Tags
        if self.collectibleData:IsPurchasable() then
            self.cornerTagTexture:SetHidden(false)
        end
    else
        self.cornerTagTexture:SetHidden(true)
    end

    self:RefreshTitleLabelColor()
end

function ZO_CollectibleTile_Keyboard:GetPrimaryInteractionStringId()
    local stringId
    local collectibleData = self.collectibleData

    if collectibleData:IsActive() then
        if collectibleData:IsCategoryType(COLLECTIBLE_CATEGORY_TYPE_VANITY_PET) or collectibleData:IsCategoryType(COLLECTIBLE_CATEGORY_TYPE_ASSISTANT) then
            stringId = SI_COLLECTIBLE_ACTION_DISMISS
        else
            stringId = SI_COLLECTIBLE_ACTION_PUT_AWAY
        end
    elseif self.isCooldownActive ~= true and not collectibleData:IsBlocked() then
        if collectibleData:IsCategoryType(COLLECTIBLE_CATEGORY_TYPE_MEMENTO) then
            stringId = SI_COLLECTIBLE_ACTION_USE
        else
            stringId = SI_COLLECTIBLE_ACTION_SET_ACTIVE
        end
    end
    return stringId
end

function ZO_CollectibleTile_Keyboard:ShowMenu()
    local collectibleData = self.collectibleData
    if collectibleData then
        ClearMenu()

        local collectibleId = collectibleData:GetId()

        --Use
        if collectibleData:IsUsable() then
            local stringId = self:GetPrimaryInteractionStringId()
            if stringId then
                AddMenuItem(GetString(stringId), function() UseCollectible(collectibleId) end)
            end
        end

        if IsChatSystemAvailableForCurrentPlatform() then
            --Link in chat
            local link = GetCollectibleLink(collectibleId, LINK_STYLE_BRACKETS)
            AddMenuItem(GetString(SI_ITEM_ACTION_LINK_TO_CHAT), function() ZO_LinkHandler_InsertLink(zo_strformat(SI_TOOLTIP_ITEM_NAME, link)) end)
        end

        --Rename
        if collectibleData:IsRenameable() then
            AddMenuItem(GetString(SI_COLLECTIBLE_ACTION_RENAME), ZO_CollectionsBook.GetShowRenameDialogClosure(collectibleId))
        end

        ShowMenu(self.control)
    end
end

function ZO_CollectibleTile_Keyboard:BeginCooldown()
    self.isCooldownActive = true
    self.cooldownIcon:SetHidden(false)
    self.cooldownIconDesaturated:SetHidden(false)
    self.cooldownTimeLabel:SetHidden(false)
    self.cooldownEdgeTexture:SetHidden(false)
    if self:IsMousedOver() then
        self:SetHighlightHidden(true)
        self:UpdateKeybinds()
    end
end

function ZO_CollectibleTile_Keyboard:EndCooldown()
    self.isCooldownActive = false
    self.cooldownIcon:SetTextureCoords(0, 1, 0, 1)
    self.cooldownIcon:SetHeight(ZO_COLLECTIBLE_TILE_KEYBOARD_ICON_DIMENSIONS)
    self.cooldownIcon:SetHidden(true)
    self.cooldownIconDesaturated:SetHidden(true)
    self.cooldownTimeLabel:SetHidden(true)
    self.cooldownTimeLabel:SetText("")
    self.cooldownEdgeTexture:SetHidden(true)
    if self:IsMousedOver() then
        self:SetHighlightHidden(false)
        self:UpdateKeybinds()
    end
end

function ZO_CollectibleTile_Keyboard:UpdateCooldownEffect()
    local duration = self.cooldownDuration
    local cooldown = self.cooldownStartTime + duration - GetFrameTimeMilliseconds()
    local percentCompleted = (1 - (cooldown / duration)) or 1
    local height = zo_ceil(ZO_COLLECTIBLE_TILE_KEYBOARD_ICON_DIMENSIONS * percentCompleted)
    local textureCoord = 1 - (height / ZO_COLLECTIBLE_TILE_KEYBOARD_ICON_DIMENSIONS)
    self.cooldownIcon:SetHeight(height)
    self.cooldownIcon:SetTextureCoords(0, 1, textureCoord, 1)

    if not self.collectibleData:IsActive() then
        local secondsRemaining = cooldown / 1000
        self.cooldownTimeLabel:SetText(ZO_FormatTimeAsDecimalWhenBelowThreshold(secondsRemaining))
    else
        self.cooldownTimeLabel:SetText("")
    end
end

function ZO_CollectibleTile_Keyboard:OnUpdateCooldowns()
    if self.control:IsHidden() then
        self:MarkDirty()
    else
        local collectibleData = self.collectibleData
        if collectibleData and collectibleData:IsUsable() then
            local remaining, duration = GetCollectibleCooldownAndDuration(collectibleData:GetId())
            if remaining > 0 and duration > 0 then
                self.cooldownDuration = duration
                self.cooldownStartTime = GetFrameTimeMilliseconds() - (duration - remaining)
                if not self.isCooldownActive then
                    self:BeginCooldown()
                end
                return
            end
        end

        self:EndCooldown()
    end
end

-- Begin ZO_Tile Overrides --

function ZO_CollectibleTile_Keyboard:RefreshLayoutInternal()
    -- Currently this only happens with cooldowns
    self:OnUpdateCooldowns()
end

function ZO_CollectibleTile_Keyboard:Reset()
    self.collectibleId = nil
    self.collectibleData = nil

    self:SetCanFocus(false)
    local INSTANT = true
    self:SetHighlightHidden(true, INSTANT)
    self:SetTitle("")
    self:GetIconTexture():SetHidden(true)
    self.statusMultiIcon:ClearIcons()
    self.cornerTagTexture:SetHidden(true)
    COLLECTIONS_BOOK_SINGLETON:UnregisterCallback("OnUpdateCooldowns", self.onUpdateCooldownsCallback)
    self:EndCooldown()
end

-- End ZO_Tile Overrides --

-- Begin ZO_ContextualActionsTile Overrides --

function ZO_CollectibleTile_Keyboard:OnFocusChanged(isFocused)
    ZO_ContextualActionsTile.OnFocusChanged(self, isFocused)

    local collectibleData = self.collectibleData
    if collectibleData then
        if not isFocused then
            ClearTooltip(ItemTooltip)

            if collectibleData:GetNotificationId() then
                RemoveCollectibleNotification(collectibleData:GetNotificationId())
            end

            if collectibleData:IsNew() then
                ClearCollectibleNewStatus(collectibleData:GetId())
            end
        end

        self:RefreshMouseoverVisuals()
    end
end

function ZO_CollectibleTile_Keyboard:SetHighlightHidden(hidden, instant)
    ZO_ContextualActionsTile.SetHighlightHidden(self, hidden, instant)

    if hidden or self.isCooldownActive then
        g_mouseOverIconAnimationProvider:PlayBackward(self:GetIconTexture(), instant)
    else
        g_mouseOverIconAnimationProvider:PlayForward(self:GetIconTexture(), instant)
    end
end

-- End ZO_ContextualActionsTile Overrides --

-- Begin ZO_ContextualActionsTile_Keyboard Overrides --

function ZO_CollectibleTile_Keyboard:LayoutPlatform(collectibleId)
    local collectibleData = ZO_COLLECTIBLE_DATA_MANAGER:GetCollectibleDataById(collectibleId)
    internalassert(collectibleData ~= nil)
    self.collectibleData = collectibleData
    self:SetCanFocus(true)

    -- Title
    self:SetTitle(collectibleData:GetFormattedName())

    -- Icon/Highlight
    local iconFile = collectibleData:GetIcon()
    local iconTexture = self:GetIconTexture()
    iconTexture:SetTexture(iconFile)
        
    local desaturation = (collectibleData:IsLocked() or collectibleData:IsBlocked()) and 1 or 0
    iconTexture:SetDesaturation(desaturation)
    self:GetHighlightControl():SetDesaturation(desaturation)

    local textureSampleProcessingWeightTable = collectibleData:IsUnlocked() and ZO_UNLOCKED_ICON_SAMPLE_PROCESSING_WEIGHT_TABLE or ZO_LOCKED_ICON_SAMPLE_PROCESSING_WEIGHT_TABLE
    for type, weight in pairs(textureSampleProcessingWeightTable) do
        iconTexture:SetTextureSampleProcessingWeight(type, weight)
    end
    iconTexture:SetHidden(false)

    -- Status
    local statusMultiIcon = self.statusMultiIcon
    statusMultiIcon:ClearIcons()

    if collectibleData:IsUnlocked() then
        if collectibleData:IsActive() then
            statusMultiIcon:AddIcon(ZO_CHECK_ICON)

            if collectibleData:WouldBeHidden() then
                statusMultiIcon:AddIcon("EsoUI/Art/Inventory/inventory_icon_hiddenBy.dds")
            end
        end

        if collectibleData:IsNew() then
            statusMultiIcon:AddIcon(ZO_KEYBOARD_NEW_ICON)
        end
    end

    statusMultiIcon:Show()

    -- Mouseover
    self:RefreshMouseoverVisuals()

    --Cooldowns
    self.cooldownIcon:SetTexture(iconFile)
    self.cooldownIconDesaturated:SetTexture(iconFile)
    self.cooldownTimeLabel:SetText("")
    self:OnUpdateCooldowns()
    COLLECTIONS_BOOK_SINGLETON:RegisterCallback("OnUpdateCooldowns", self.onUpdateCooldownsCallback)
end

function ZO_CollectibleTile_Keyboard:OnMouseUp(button, upInside)
    if upInside and button == MOUSE_BUTTON_INDEX_RIGHT then
        self:ShowMenu()
    end
end

function ZO_CollectibleTile_Keyboard:OnMouseDoubleClick(button)
    if button == MOUSE_BUTTON_INDEX_LEFT then
        local collectibleData = self.collectibleData
        if collectibleData and collectibleData:IsUsable() then
            UseCollectible(collectibleData:GetId())
        end
    end
end

-- End ZO_ContextualActionsTile_Keyboard Overrides --

-- Begin Global XML Functions --

function ZO_CollectibleTile_Keyboard_OnInitialized(control)
    ZO_CollectibleTile_Keyboard:New(control)
end

-- End Global XML Functions --