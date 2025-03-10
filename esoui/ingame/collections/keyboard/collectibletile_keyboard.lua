ZO_COLLECTIBLE_TILE_KEYBOARD_DIMENSIONS_X = 175
ZO_COLLECTIBLE_TILE_KEYBOARD_DIMENSIONS_Y = 125
ZO_COLLECTIBLE_TILE_KEYBOARD_ICON_DIMENSIONS = 52

ZO_CollectibleTile_Keyboard_MouseOverIconAnimationProvider = ZO_ReversibleAnimationProvider:New("ZO_CollectibleTile_Keyboard_MouseOverIconAnimation")

-- Primary logic class must be subclassed after the platform class so that platform specific functions will have priority over the logic class functionality
ZO_CollectibleTile_Keyboard = ZO_Object.MultiSubclass(ZO_ContextualActionsTile_Keyboard, ZO_ContextualActionsTile)

function ZO_CollectibleTile_Keyboard:New(...)
    return ZO_ContextualActionsTile.New(self, ...)
end

-- Begin ZO_ContextualActionsTile_Keyboard Overrides --

function ZO_CollectibleTile_Keyboard:InitializePlatform()
    ZO_ContextualActionsTile_Keyboard.InitializePlatform(self)

    self.statusMultiIcon = self.control:GetNamedChild("Status")
    self.cornerTagTexture = self.control:GetNamedChild("CornerTag")
    self.favoriteIcon = self.control:GetNamedChild("IconFavoriteIcon")
    self.cooldownIcon = self.control:GetNamedChild("CooldownIcon")
    self.cooldownIconDesaturated = self.control:GetNamedChild("CooldownIconDesaturated")
    self.cooldownTimeLabel = self.control:GetNamedChild("CooldownTime")
    self.cooldownEdgeTexture = self.control:GetNamedChild("CooldownEdge")

    self.isCooldownActive = false
    self.cooldownDuration = 0
    self.cooldownStartTime = 0

    self.onUpdateCooldownsCallback = function() self:OnUpdateCooldowns() end
    self:GetControl():SetHandler("OnUpdate", function() self:OnUpdate() end)
    self:GetControl():SetHandler("OnDragStart", function(_, ...) self:OnDragStart(...) end)
end

function ZO_CollectibleTile_Keyboard:StartPreview(collectibleId)
    if self:CanPreview() and not ITEM_PREVIEW_KEYBOARD:IsCurrentlyPreviewing(ZO_ITEM_PREVIEW_COLLECTIBLE, collectibleId) then
        ITEM_PREVIEW_KEYBOARD:PreviewCollectible(collectibleId)
        if self:IsMousedOver() then
            WINDOW_MANAGER:SetMouseCursor(MOUSE_CURSOR_DO_NOT_CARE)
            self:UpdateKeybinds()
        end
    end
end

function ZO_CollectibleTile_Keyboard:PostInitializePlatform()
    -- keybindStripDescriptor and canFocus need to be set after initialize, because ZO_ContextualActionsTile
    -- won't have finished initializing those until after InitializePlatform is called
    ZO_ContextualActionsTile_Keyboard.PostInitializePlatform(self)

    table.insert(self.keybindStripDescriptor,
    {
        keybind = "UI_SHORTCUT_PRIMARY",

        name = function()
            local collectibleData = self.collectibleData
            if collectibleData then
                if collectibleData:IsUsable(self:GetActorCategory()) and self:GetPrimaryInteractionStringId() ~= nil then
                    return GetString(self:GetPrimaryInteractionStringId())
                elseif collectibleData.CanPlaceInCurrentHouse and collectibleData:CanPlaceInCurrentHouse() then
                    return GetString(SI_ITEM_ACTION_PLACE_FURNITURE)
                end
            end
        end,

        callback = function()
            local collectibleData = self.collectibleData
            if collectibleData then
                if collectibleData:IsUsable(self:GetActorCategory()) and self:GetPrimaryInteractionStringId() ~= nil then
                    if IsCurrentlyPreviewing() then
                        ITEM_PREVIEW_KEYBOARD:EndCurrentPreview()
                    end
                    collectibleData:Use(self:GetActorCategory())
                elseif collectibleData.CanPlaceInCurrentHouse and collectibleData:CanPlaceInCurrentHouse() then
                    COLLECTIONS_BOOK_SINGLETON.TryPlaceCollectibleFurniture(collectibleData)
                end
            end
        end,

        visible = function()
            local collectibleData = self.collectibleData
            if collectibleData then
                if collectibleData:IsUsable(self:GetActorCategory()) and self:GetPrimaryInteractionStringId() ~= nil then
                    return true
                elseif collectibleData.CanPlaceInCurrentHouse and collectibleData:CanPlaceInCurrentHouse() then
                    return true
                end
            end
            return false
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

    table.insert(self.keybindStripDescriptor,
    {
        keybind = "UI_SHORTCUT_TERTIARY",

        name = GetString(SI_COLLECTIBLE_ACTION_ASSIGN),

        callback = function()
            local emoteId = self.collectibleData:GetReferenceId()
            local emoteInfo = PLAYER_EMOTE_MANAGER:GetEmoteItemInfo(emoteId)
            if emoteInfo then
                KEYBOARD_PLAYER_EMOTE:ShowCategory(emoteInfo.emoteCategory)
            end
        end,

        visible = function()
            return self.collectibleData and self.collectibleData:IsUnlocked() and self.collectibleData:IsCategoryType(COLLECTIBLE_CATEGORY_TYPE_EMOTE)
        end,
    })

    table.insert(self.keybindStripDescriptor,
    {
        keybind = "UI_SHORTCUT_QUINARY",

        name = GetString(SI_COLLECTIBLE_ACTION_PREVIEW),

        callback = function()
            self:StartPreview(self.collectibleData:GetId())
        end,

        enabled = function()
            return IsCharacterPreviewingAvailable(), GetString(SI_PREVIEW_UNAVAILABLE_ERROR)
        end,

        visible = function()
            return self:CanPreview() and not ITEM_PREVIEW_KEYBOARD:IsCurrentlyPreviewing(ZO_ITEM_PREVIEW_COLLECTIBLE, self.collectibleData:GetId())
        end,
    })

    self:SetCanFocus(false)
end

-- End ZO_ContextualActionsTile_Keyboard Overrides --

function ZO_CollectibleTile_Keyboard:GetActorCategory()
    return self.actorCategory or GAMEPLAY_ACTOR_CATEGORY_PLAYER
end

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
        local SHOW_NICKNAME = true
        local SHOW_PURCHASABLE_HINT = true
        local SHOW_BLOCK_REASON = true
        ItemTooltip:SetCollectible(self.collectibleData:GetId(), SHOW_NICKNAME, SHOW_PURCHASABLE_HINT, SHOW_BLOCK_REASON, self:GetActorCategory())

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
    if self.isCooldownActive ~= true and not self.collectibleData:IsBlocked(self:GetActorCategory()) then
        return self.collectibleData:GetPrimaryInteractionStringId(self:GetActorCategory())
    end
    return nil
end

function ZO_CollectibleTile_Keyboard:ShowMenu()
    local collectibleData = self.collectibleData
    if collectibleData then
        ClearMenu()
        self:AddMenuOptions()
        ShowMenu(self.control)
    end
end

function ZO_CollectibleTile_Keyboard:AddMenuOptions()
    local collectibleData = self.collectibleData

    --Use
    if collectibleData:IsUsable(self:GetActorCategory()) then
        local stringId = self:GetPrimaryInteractionStringId()
        if stringId then
            local function UseCollectible()
                if IsCurrentlyPreviewing() then
                    ITEM_PREVIEW_KEYBOARD:EndCurrentPreview()
                end
                collectibleData:Use(self:GetActorCategory())
            end
            AddMenuItem(GetString(stringId), UseCollectible)
        end
    end

    local collectibleId = collectibleData:GetId()

    --Place Furniture
    if collectibleData.CanPlaceInCurrentHouse and collectibleData:CanPlaceInCurrentHouse() then
        AddMenuItem(GetString(SI_ITEM_ACTION_PLACE_FURNITURE), function() COLLECTIONS_BOOK_SINGLETON.TryPlaceCollectibleFurniture(collectibleData) end)
    end

    --Link in chat
    if IsChatSystemAvailableForCurrentPlatform() then
        AddMenuItem(GetString(SI_ITEM_ACTION_LINK_TO_CHAT), function() ZO_LinkHandler_InsertLink(GetCollectibleLink(collectibleId, LINK_STYLE_BRACKETS)) end)
    end

    -- Achievement
    local linkedAchievement = collectibleData:GetLinkedAchievement()
    if linkedAchievement > 0 then
        AddMenuItem(GetString(SI_COLLECTIBLE_ACTION_SHOW_ACHIEVEMENT), function()
            SYSTEMS:GetObject("achievements"):ShowAchievement(linkedAchievement)
        end)
    end

    -- Go to Skill
    if collectibleData:IsSkillStyle() then
        local skillStyleProgressionId = collectibleData:GetSkillStyleProgressionId()
        local skillData = SKILLS_DATA_MANAGER:GetSkillDataByProgressionId(skillStyleProgressionId)
        if skillData:IsPurchased() then
            AddMenuItem(GetString(SI_COLLECTIBLE_ACTION_SHOW_IN_SKILLS), function()
                MAIN_MENU_KEYBOARD:ShowScene("skills")
                SKILLS_WINDOW:BrowseToSkill(skillData)
            end)
        end
    end

    --Rename
    if collectibleData:IsRenameable() then
        AddMenuItem(GetString(SI_COLLECTIBLE_ACTION_RENAME), ZO_CollectionsBook.GetShowRenameDialogClosure(collectibleId))
    end

    -- Preview
    if ITEM_PREVIEW_KEYBOARD:IsCurrentlyPreviewing(ZO_ITEM_PREVIEW_COLLECTIBLE, collectibleId) then
        AddMenuItem(GetString(SI_COLLECTIBLE_ACTION_END_PREVIEW), function() ITEM_PREVIEW_KEYBOARD:EndCurrentPreview() end)
    elseif IsCharacterPreviewingAvailable() and self:CanPreview() then
        AddMenuItem(GetString(SI_COLLECTIBLE_ACTION_PREVIEW), function() self:StartPreview(collectibleId) end)
    end

    --Assign and Remove
    if collectibleData:IsUnlocked() then
        local utilityWheel = self.utilityWheel
        if utilityWheel and utilityWheel:IsActionTypeSupported(ACTION_TYPE_COLLECTIBLE) then
            local hotbarCategory = utilityWheel:GetHotbarCategory()
            local slottedEntries = ZO_GetUtilityWheelSlottedEntries(hotbarCategory)
            local matchingSlots = {}
            --First find any slots matching this collectible
            for i, slotData in ipairs(slottedEntries) do
                if slotData.type == ACTION_TYPE_COLLECTIBLE and slotData.id == collectibleId then
                    table.insert(matchingSlots, slotData.slotIndex)
                end
            end

            --If the collectible is slotted in at least one slot, show the Remove option
            if #matchingSlots > 0 then
                AddMenuItem(GetString(SI_ABILITY_ACTION_CLEAR_SLOT), function()
                    for i, slotIndex in ipairs(matchingSlots) do
                        ClearSlot(slotIndex, hotbarCategory)
                    end
                end)
            else
                --If the collectible is not slotted and there is a valid slot available, show the Assign option
                local validSlot = GetFirstFreeValidSlotForSimpleAction(ACTION_TYPE_COLLECTIBLE, collectibleId, hotbarCategory)
                if validSlot then
                    AddMenuItem(GetString(SI_COLLECTIBLE_ACTION_ASSIGN), function()
                        SelectSlotSimpleAction(ACTION_TYPE_COLLECTIBLE, collectibleId, validSlot, hotbarCategory)
                    end)
                end
            end
        end

        if self:GetActorCategory() == GAMEPLAY_ACTOR_CATEGORY_PLAYER and collectibleData:IsFavoritable() then
            if collectibleData:IsFavorite() then
                AddMenuItem(GetString(SI_COLLECTIBLE_ACTION_REMOVE_FAVORITE), function()
                    SetOrClearCollectibleUserFlag(collectibleId, COLLECTIBLE_USER_FLAG_FAVORITE, false)
                end)
            else
                AddMenuItem(GetString(SI_COLLECTIBLE_ACTION_ADD_FAVORITE), function()
                    SetOrClearCollectibleUserFlag(collectibleId, COLLECTIBLE_USER_FLAG_FAVORITE, true)
                end)
            end
        end
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

    if not self.collectibleData:IsActive(self:GetActorCategory()) then
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
        if collectibleData and collectibleData:IsUsable(self:GetActorCategory()) then
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
    self.actorCategory = nil

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

function ZO_CollectibleTile_Keyboard:OnControlHidden()
    self:OnMouseExit()
    ZO_ContextualActionsTile.OnControlHidden(self)
end

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
        ZO_CollectibleTile_Keyboard_MouseOverIconAnimationProvider:PlayBackward(self:GetIconTexture(), instant)
    else
        ZO_CollectibleTile_Keyboard_MouseOverIconAnimationProvider:PlayForward(self:GetIconTexture(), instant)
    end
end

-- End ZO_ContextualActionsTile Overrides --

-- Begin ZO_ContextualActionsTile_Keyboard Overrides --

function ZO_CollectibleTile_Keyboard:LayoutPlatform(data)
    local collectibleData = ZO_COLLECTIBLE_DATA_MANAGER:GetCollectibleDataById(data.collectibleId)
    internalassert(collectibleData ~= nil)
    self.collectibleData = collectibleData
    self.actorCategory = data.actorCategory
    self.utilityWheel = data.utilityWheel
    self:SetCanFocus(true)

    -- Title
    self:SetTitle(collectibleData:GetFormattedName())

    -- Icon/Highlight
    local iconFile = collectibleData:GetIcon()
    local iconTexture = self:GetIconTexture()
    iconTexture:SetTexture(iconFile)
        
    local desaturation = (collectibleData:IsLocked() or collectibleData:IsBlocked(self:GetActorCategory())) and 1 or 0
    self:GetHighlightControl():SetDesaturation(desaturation)

    local isLocked = collectibleData:IsLocked()
    ZO_SetDefaultIconSilhouette(iconTexture, isLocked)
    iconTexture:SetDesaturation(desaturation)

    iconTexture:SetHidden(false)

    self:SetFavoriteIconVisibility(collectibleData:IsFavorite())

    -- Status
    local statusMultiIcon = self.statusMultiIcon
    statusMultiIcon:ClearIcons()

    if collectibleData:IsUnlocked() then
        local actorCategory = self:GetActorCategory()
        if collectibleData:IsActive(actorCategory) and not collectibleData:ShouldSuppressActiveState(actorCategory) then
            statusMultiIcon:AddIcon(ZO_CHECK_ICON)

            if collectibleData:WouldBeHidden(actorCategory) then
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

function ZO_CollectibleTile_Keyboard:CanPreview()
    if self.collectibleData then
        -- TODO: Temporarily disable mementos until time can be scheduled to audit mementos that don't preview correctly
        if self.collectibleData:GetCategoryType() == COLLECTIBLE_CATEGORY_TYPE_MEMENTO then
            return false
        elseif self:GetActorCategory() == GAMEPLAY_ACTOR_CATEGORY_COMPANION then
            -- TODO: Temporarily disable previewing on companion collectibles until time can be taken to get the previewing to work properly
            return false
        end
        return CanCollectibleBePreviewed(self.collectibleData:GetId())
    end
    return false
end

function ZO_CollectibleTile_Keyboard:OnMouseExit()
    ZO_ContextualActionsTile_Keyboard.OnMouseExit(self)

    WINDOW_MANAGER:SetMouseCursor(MOUSE_CURSOR_DO_NOT_CARE)
end

function ZO_CollectibleTile_Keyboard:OnMouseUp(button, upInside)
    if upInside then
        if button == MOUSE_BUTTON_INDEX_RIGHT then
            self:ShowMenu()
        end
    end
end

function ZO_CollectibleTile_Keyboard:OnMouseDoubleClick(button)
    if button == MOUSE_BUTTON_INDEX_LEFT then
        local collectibleData = self.collectibleData
        if collectibleData and collectibleData:IsUsable(self:GetActorCategory()) and not self.collectibleData:IsSkillStyle() then
            if IsCurrentlyPreviewing() then
                ITEM_PREVIEW_KEYBOARD:EndCurrentPreview()
            end
            collectibleData:Use(self:GetActorCategory())
        end
    end
end

function ZO_CollectibleTile_Keyboard:OnDragStart(button)
    if button == MOUSE_BUTTON_INDEX_LEFT then
        if self.collectibleData and self.collectibleData:IsUnlocked() and self.utilityWheel and self.utilityWheel:IsActionTypeSupported(ACTION_TYPE_COLLECTIBLE) and GetCursorContentType() == MOUSE_CONTENT_EMPTY then
            PickupCollectible(self.collectibleData:GetId())
        end
    end
end

function ZO_CollectibleTile_Keyboard:SetFavoriteIconVisibility(visible)
    self.favoriteIcon:SetHidden(not visible)
end

-- End ZO_ContextualActionsTile_Keyboard Overrides --

-- Begin Global XML Functions --

function ZO_CollectibleTile_Keyboard_OnInitialized(control)
    ZO_CollectibleTile_Keyboard:New(control)
end

-- End Global XML Functions --