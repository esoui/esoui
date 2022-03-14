ZO_ITEM_SET_COLLECTION_PIECE_TILE_KEYBOARD_DIMENSIONS = 67
ZO_ITEM_SET_COLLECTION_PIECE_TILE_KEYBOARD_ICON_DIMENSIONS = 52

local g_mouseOverIconAnimationProvider = ZO_ReversibleAnimationProvider:New("ZO_ItemSetCollectionPieceTile_Keyboard_MouseOverIconAnimation")

-- Primary logic class must be subclassed after the platform class so that platform specific functions will have priority over the logic class functionality
ZO_ItemSetCollectionPieceTile_Keyboard = ZO_Object.MultiSubclass(ZO_ContextualActionsTile_Keyboard, ZO_ContextualActionsTile)

function ZO_ItemSetCollectionPieceTile_Keyboard:New(...)
    return ZO_ContextualActionsTile.New(self, ...)
end

-- Begin ZO_ContextualActionsTile_Keyboard Overrides --

function ZO_ItemSetCollectionPieceTile_Keyboard:InitializePlatform()
    ZO_ContextualActionsTile_Keyboard.InitializePlatform(self)

    self.statusMultiIcon = self.control:GetNamedChild("Status")
end

function ZO_ItemSetCollectionPieceTile_Keyboard:PostInitializePlatform()
    -- keybindStripDescriptor and canFocus need to be set after initialize, because ZO_ContextualActionsTile
    -- won't have finished initializing those until after InitializePlatform is called
    ZO_ContextualActionsTile_Keyboard.PostInitializePlatform(self)

    table.insert(self.keybindStripDescriptor, 
    {
        keybind = "UI_SHORTCUT_PRIMARY",

        name = GetString(SI_ITEM_RECONSTRUCTION_SELECT),

        callback = function()
            self:ShowReconstructOptions()
        end,

        enabled = function()
            return self:CanReconstruct()
        end,

        visible = function()
            return ZO_RECONSTRUCT_KEYBOARD:IsSelectionModeShowing()
        end,
    })

    self:SetCanFocus(false)
end

-- End ZO_ContextualActionsTile_Keyboard Overrides --

function ZO_ItemSetCollectionPieceTile_Keyboard:RefreshMouseoverVisuals()
    if self.itemSetCollectionPieceData and self:IsMousedOver() then
        -- Tooltip
        ClearTooltip(ItemTooltip)
        local offsetX = self.control:GetParent():GetLeft() - self.control:GetLeft() - 5
        InitializeTooltip(ItemTooltip, self.control, RIGHT, offsetX, 0, LEFT)
        local HIDE_TRAIT = true
        ItemTooltip:SetItemSetCollectionPieceLink(self.itemSetCollectionPieceData:GetItemLink(), HIDE_TRAIT)
    end
end

function ZO_ItemSetCollectionPieceTile_Keyboard:ShowMenu()
    ClearMenu()

    local itemSetCollectionPieceData = self.itemSetCollectionPieceData
    if itemSetCollectionPieceData then
        if IsChatSystemAvailableForCurrentPlatform() then
            --Link in chat
            local link = itemSetCollectionPieceData:GetItemLink()
            AddMenuItem(GetString(SI_ITEM_ACTION_LINK_TO_CHAT), function() ZO_LinkHandler_InsertLink(zo_strformat(SI_TOOLTIP_ITEM_NAME, link)) end)
        end

        ShowMenu(self.control)
    end
end

function ZO_ItemSetCollectionPieceTile_Keyboard:CanReconstruct()
    return self.itemSetCollectionPieceData and self.itemSetCollectionPieceData:IsUnlocked()
end

function ZO_ItemSetCollectionPieceTile_Keyboard:ShowReconstructOptions()
    if self:CanReconstruct() then
        ZO_RECONSTRUCT_KEYBOARD:SelectItemSetPieceData(self.itemSetCollectionPieceData)
    end
end

-- Begin ZO_Tile Overrides --

function ZO_ItemSetCollectionPieceTile_Keyboard:Reset()
    self.itemSetCollectionPieceData = nil

    self:SetCanFocus(false)
    local INSTANT = true
    self:SetHighlightHidden(true, INSTANT)
    self:GetIconTexture():SetHidden(true)
    self.statusMultiIcon:ClearIcons()
    self.isNew = false
end

-- End ZO_Tile Overrides --

-- Begin ZO_ContextualActionsTile Overrides --

function ZO_ItemSetCollectionPieceTile_Keyboard:OnControlHidden()
    self:OnMouseExit()
    ZO_ContextualActionsTile.OnControlHidden(self)
end

function ZO_ItemSetCollectionPieceTile_Keyboard:OnFocusChanged(isFocused)
    ZO_ContextualActionsTile.OnFocusChanged(self, isFocused)

    local itemSetCollectionPieceData = self.itemSetCollectionPieceData
    if itemSetCollectionPieceData then
        if not isFocused then
            ClearTooltip(ItemTooltip)

            if self.isNew then
                itemSetCollectionPieceData:ClearNew()
            end
        end

        self:RefreshMouseoverVisuals()
    end
end

function ZO_ItemSetCollectionPieceTile_Keyboard:SetHighlightHidden(hidden, instant)
    ZO_ContextualActionsTile.SetHighlightHidden(self, hidden, instant)

    if hidden then
        g_mouseOverIconAnimationProvider:PlayBackward(self:GetIconTexture(), instant)
    else
        g_mouseOverIconAnimationProvider:PlayForward(self:GetIconTexture(), instant)
    end
end

-- End ZO_ContextualActionsTile Overrides --

-- Begin ZO_ContextualActionsTile_Keyboard Overrides --

function ZO_ItemSetCollectionPieceTile_Keyboard:LayoutPlatform(data)
    local itemSetCollectionPieceData = data
    internalassert(itemSetCollectionPieceData ~= nil)
    self.itemSetCollectionPieceData = itemSetCollectionPieceData 
    self:SetCanFocus(true)

    -- Icon/Highlight
    local iconFile = itemSetCollectionPieceData:GetIcon()
    local iconTexture = self:GetIconTexture()
    iconTexture:SetTexture(iconFile)

    local isUnlocked = itemSetCollectionPieceData:IsUnlocked()
    local desaturation = isUnlocked and 0 or 1
    self:GetHighlightControl():SetDesaturation(desaturation)
    ZO_SetDefaultIconSilhouette(iconTexture, not isUnlocked)
    iconTexture:SetHidden(false)

    -- Status
    local statusMultiIcon = self.statusMultiIcon
    statusMultiIcon:ClearIcons()

    if isUnlocked then
        if itemSetCollectionPieceData:IsNew() then
            statusMultiIcon:AddIcon(ZO_KEYBOARD_NEW_ICON)
            self.isNew = true
        end
    end

    statusMultiIcon:Show()

    -- Mouseover
    self:RefreshMouseoverVisuals()
end

function ZO_ItemSetCollectionPieceTile_Keyboard:OnMouseUp(button, upInside)
    if upInside and button == MOUSE_BUTTON_INDEX_RIGHT then
        self:ShowMenu()
    end
end

function ZO_ItemSetCollectionPieceTile_Keyboard:OnMouseDoubleClick(button)
    if button == MOUSE_BUTTON_INDEX_LEFT then
        self:ShowReconstructOptions()
    end
end

-- End ZO_ContextualActionsTile_Keyboard Overrides --

-- Begin Global XML Functions --

function ZO_ItemSetCollectionPieceTile_Keyboard_OnInitialized(control)
    ZO_ItemSetCollectionPieceTile_Keyboard:New(control)
end

-- End Global XML Functions --