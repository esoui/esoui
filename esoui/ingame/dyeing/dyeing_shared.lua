ZO_DYEABLE_EQUIP_SLOTS = {}
ZO_DYEABLE_COLLECTIBLE_SLOTS = {}

function ZO_Dyeing_DyeableSlotGamepadSortComparator(left, right)
    return left.gamepadOrder < right.gamepadOrder
end

function ZO_Dyeing_InitializeDyeableSlotsTables()
    ZO_ClearNumericallyIndexedTable(ZO_DYEABLE_EQUIP_SLOTS)
    ZO_ClearNumericallyIndexedTable(ZO_DYEABLE_COLLECTIBLE_SLOTS)

    local numDyeableEquipSlots = GetNumDyeableEquipSlots()
    local numDyeableCollectibleCategories = GetNumDyeableCollectibleCategories()

    for i = 1, numDyeableEquipSlots do
        local dyeableEquipSlotData =
        {
            dyeableSlot = GetDyeableEquipSlot(i),
            gamepadOrder = GetDyeableEquipSlotGamepadOrder(i)
        }
        table.insert(ZO_DYEABLE_EQUIP_SLOTS, dyeableEquipSlotData)
    end

    for j = 1, numDyeableCollectibleCategories do
        local dyeableCollectibleCategoryData =
        {
            dyeableSlot = GetDyeableCollectibleCategory(j),
            gamepadOrder = GetDyeableCollectibleCategoryGamepadOrder(i)
        }
        table.insert(ZO_DYEABLE_COLLECTIBLE_SLOTS, dyeableCollectibleCategoryData)
    end

    if IsInGamepadPreferredMode() then
        table.sort(ZO_DYEABLE_EQUIP_SLOTS, ZO_Dyeing_DyeableSlotGamepadSortComparator)
        table.sort(ZO_DYEABLE_COLLECTIBLE_SLOTS, ZO_Dyeing_DyeableSlotGamepadSortComparator)
    end
end

ZO_DYEING_SWATCH_SELECTION_SCALE = 1.3

-- Common Index Constants
ZO_DYEING_SORT_STYLE_RARITY = 1
ZO_DYEING_SORT_STYLE_HUE = 2

ZO_DYEING_SWATCH_INDEX = 1
ZO_DYEING_FRAME_INDEX = 2
ZO_DYEING_MUNGE_INDEX = 3
ZO_DYEING_LOCK_INDEX = 4

ZO_DYEING_SAVED_VARIABLES_DEFAULTS =
{
    showLocked = true,
    sortStyle = ZO_DYEING_SORT_STYLE_RARITY,
}

-- Interaction Mode Setup
ZO_DYEING_STATION_INTERACTION =
{
    type = "Dyeing Station",
    End = function()
        SYSTEMS:HideScene("dyeing")
    end,
    interactTypes = { INTERACTION_DYE_STATION },
}

-- Shared Show Events
EVENT_MANAGER:RegisterForEvent("Dyeing_Shared", EVENT_DYEING_STATION_INTERACT_START, function(eventCode)
    ZO_Dyeing_InitializeDyeableSlotsTables()
    SYSTEMS:ShowScene("dyeing")
end)

EVENT_MANAGER:RegisterForEvent("Dyeing_Shared", EVENT_DYEING_STATION_INTERACT_END, function(eventCode)
    SYSTEMS:HideScene("dyeing")
end)

-- Shared Functions
function ZO_Dyeing_GetAchivementText(dyeKnown, achievementId, nonPlayerDye)
    local achievementName = GetAchievementInfo(achievementId)
    if dyeKnown then
        if achievementName ~= "" then
            return zo_strformat(SI_DYEING_SWATCH_TOOLTIP_BODY, achievementName), nil
        else
            return GetString(SI_DYEING_SWATCH_TOOLTIP_BODY_HIDDEN), nil
        end
    else
        if nonPlayerDye then
            return GetString(SI_DYEING_SWATCH_TOOLTIP_BODY_NON_PLAYER_DYE), nil
        elseif achievementName ~= "" then
            return zo_strformat(SI_DYEING_SWATCH_TOOLTIP_BODY_LOCKED, achievementName), GetString(SI_DYEING_SWATCH_TOOLTIP_SEE_ACHIEVEMENT)
        else
            return GetString(SI_DYEING_SWATCH_TOOLTIP_BODY_HIDDEN_LOCKED), nil
        end
    end

    -- All cases should be handled above.
    assert(false)
end

function ZO_Dyeing_InitializeSwatchPool(owner, sharedHighlight, parentControl, template, canSelectLocked, highlightDimensions)
    local swatchInterpolator = ZO_SimpleControlScaleInterpolator:New(1.0, ZO_DYEING_SWATCH_SELECTION_SCALE)
    local swatchPool = ZO_ControlPool:New(template, parentControl)

    local function UpdateSelectedState(swatch, skipAnim)
        if (canSelectLocked or (not swatch.locked)) and (swatch.mousedOver or swatch.selected) then
            if skipAnim then
                swatchInterpolator:ResetToMax(swatch)
            else
                swatchInterpolator:ScaleUp(swatch)
            end
        else
            if skipAnim then
                swatchInterpolator:ResetToMin(swatch)
            else
                swatchInterpolator:ScaleDown(swatch)
            end
        end

        if swatch.selected then
            sharedHighlight:ClearAnchors()
            sharedHighlight:SetAnchor(TOPLEFT, swatch, TOPLEFT, -highlightDimensions, -highlightDimensions)
            sharedHighlight:SetAnchor(BOTTOMRIGHT, swatch, BOTTOMRIGHT, highlightDimensions, highlightDimensions)
            sharedHighlight:SetHidden(false)
        end
    end

    local function SetSelected(swatch, selected, skipAnim, skipSound)
        if swatch.selected ~= selected then
            swatch.selected = selected
            if selected and (not skipSound) and (not owner.suppressSounds) then
                PlaySound(SOUNDS.DYEING_SWATCH_SELECTED)
            end
        end
        UpdateSelectedState(swatch, skipAnim)
    end

    local SKIP_ANIM = true
    local function SetLocked(swatch, locked)
        swatch.locked = locked
        swatch:SetSurfaceHidden(ZO_DYEING_LOCK_INDEX, not locked)
        UpdateSelectedState(swatch, SKIP_ANIM)
    end

    local function IsLocked(swatch)
        return swatch.locked
    end

    local function OnClicked(swatch, button, upInside)
        if upInside then
            if button == MOUSE_BUTTON_INDEX_LEFT then
                if not swatch.locked then
                    owner:SwitchToDyeingWithDyeId(swatch.dyeId)
                end
            elseif button == MOUSE_BUTTON_INDEX_RIGHT then
                local achievementName = GetAchievementInfo(swatch.achievementId)
                if achievementName ~= "" then
                    ClearMenu()
                    AddMenuItem(GetString(SI_DYEING_SWATCH_VIEW_ACHIEVEMENT), function() owner:AttemptExit(swatch.achievementId) end)
                    ShowMenu(swatch)
                end
            end
        end
    end

    local function OnSwatchCreated(swatch)
        swatch:SetHandler("OnMouseUp", OnClicked)
        swatch.SetSelected = SetSelected
        swatch.SetLocked = SetLocked
        swatch.IsLocked = IsLocked
        swatch.UpdateSelectedState = UpdateSelectedState
    end

    local function OnSwatchReset(swatch)
        swatch:SetSelected(false, SKIP_ANIM)
        swatch:SetLocked(false, SKIP_ANIM)
    end

    swatchPool:SetCustomFactoryBehavior(OnSwatchCreated)
    swatchPool:SetCustomResetBehavior(OnSwatchReset)

    return swatchPool
end

do
    local STACK_COUNT = 1

    function ZO_Dyeing_SetupDyeableSlotControl(control, dyeableSlot)
        local icon = GetDyeableSlotIcon(dyeableSlot)
        if icon == ZO_NO_TEXTURE_FILE then
            icon = ZO_Character_GetEmptyDyeableSlotTexture(dyeableSlot)
        end

        local equipSlot = GetEquipSlotFromDyeableSlot(dyeableSlot)
        if equipSlot ~= EQUIP_SLOT_NONE then
            ZO_Inventory_BindSlot(control, SLOT_TYPE_DYEABLE_EQUIPMENT, equipSlot, BAG_WORN)
        end

        control.dyeableSlot = dyeableSlot

        ZO_ItemSlot_SetupSlot(control, STACK_COUNT, icon)
    end
end

function ZO_Dyeing_DyeSortComparator(left, right)
    return left.sortKey < right.sortKey
end

function ZO_Dyeing_RefreshDyeableSlotControlDyes_Colors(slotControl, dyeableSlot, ...)
    local isDyeable = IsDyeableSlotDyeable(dyeableSlot)
    local isChannelDyeableTable = {AreDyeableSlotDyeChannelsDyeable(dyeableSlot)}
    for dyeChannel, dyeControl in ipairs(slotControl.dyeControls) do
        if isDyeable then
            dyeControl:SetHidden(false)
            local currentDyeId = select(dyeChannel, ...)
            ZO_DyeingUtils_SetSlotDyeSwatchDyeId(dyeChannel, dyeControl, currentDyeId, isChannelDyeableTable[dyeChannel])
        else
            dyeControl:SetHidden(true)
        end
    end
end

local function GetFrameForDyeChannel(empty)
    return empty and "EsoUI/Art/Dye/dye_amorSlot_empty.dds" or "EsoUI/Art/Dye/dye_amorSlot.dds"
end

function ZO_Dyeing_RefreshDyeableSlotControlDyes(slotControl, dyeableSlot)
    ZO_Dyeing_RefreshDyeableSlotControlDyes_Colors(slotControl, dyeableSlot, GetPendingSlotDyes(dyeableSlot))
end

function ZO_Dyeing_GetActiveOffhandDyeableSlot()
    local activeWeaponPair = GetActiveWeaponPairInfo()
    if activeWeaponPair == ACTIVE_WEAPON_PAIR_BACKUP then
        return DYEABLE_SLOT_BACKUP_OFF
    end

    return DYEABLE_SLOT_OFF_HAND
end

function ZO_DyeingUtils_SetSlotDyeSwatchDyeId(dyeChannel, dyeControl, dyeId, isDyeable)   
    local isEmptyFrame, hideMunge, hideBackground, hideInvalid
    --We have a dye and the channel is dyeable
    if dyeId ~= INVALID_DYE_ID and isDyeable ~= false then
        local dyeName, known, rarity, hueCategory, achievementId, r, g, b, sortKey = GetDyeInfoById(dyeId)
        dyeControl.swatchTexture:SetColor(r, g, b, 1)
        isEmptyFrame = false
        hideMunge = false
        hideBackground = true
        hideInvalid = true
    --We were explicitly told we can't dye this channel
    elseif isDyeable == false then
        dyeControl.swatchTexture:SetColor(0, 0, 0, 0)
        isEmptyFrame = true
        hideMunge = true
        hideBackground = false
        hideInvalid = false
    --We can dye the channel, but it's currently not dyed
    else
        dyeControl.swatchTexture:SetColor(0, 0, 0, 0)
        isEmptyFrame = true
        hideMunge = true
        hideBackground = false
        hideInvalid = true
    end

    if dyeControl.frameTexture then
        dyeControl.frameTexture:SetTexture(GetFrameForDyeChannel(isEmptyFrame))
    end
    if dyeControl.mungeTexture then
        dyeControl.mungeTexture:SetHidden(hideMunge)
    end
    if dyeControl.background then
        dyeControl.background:SetHidden(hideBackground)
    end
    if dyeControl.invalidTexture then
        dyeControl.invalidTexture:SetHidden(hideInvalid)
        if dyeControl.edgeFrame then
            dyeControl.edgeFrame:SetEdgeColor((hideInvalid and ZO_NORMAL_TEXT or ZO_DISABLED_TEXT):UnpackRGB())
        end
    else
        dyeControl:SetHidden(not hideInvalid)
    end
end

function ZO_DyeingUtils_GetHeaderTextFromSortType(sortStyleType, rarityOrHueCategory)
    if sortStyleType == ZO_DYEING_SORT_STYLE_RARITY then
        return GetString("SI_DYERARITY", rarityOrHueCategory)
    elseif sortStyleType == ZO_DYEING_SORT_STYLE_HUE then
        return GetString("SI_DYEHUECATEGORY", rarityOrHueCategory)
    end
end

function ZO_Dyeing_UniformRandomize(mode, getRandomUnlockedDyeIdFunction)
    local primaryDyeId = getRandomUnlockedDyeIdFunction()
    local secondaryDyeId = getRandomUnlockedDyeIdFunction()
    local accentDyeId = getRandomUnlockedDyeIdFunction()
    
    local slots = ZO_Dyeing_GetSlotsForMode(mode)
    local activeDyeableSlot = ZO_Dyeing_GetActiveOffhandDyeableSlot()

    for i, dyeableSlotData in ipairs(slots) do
        local dyeableSlot = dyeableSlotData.dyeableSlot
        --don't randomly dye the shield in your other weapon set
        if (dyeableSlot ~= DYEABLE_SLOT_OFF_HAND and dyeableSlot ~= DYEABLE_SLOT_BACKUP_OFF)
            or dyeableSlot == activeDyeableSlot then
                local isPrimaryChannelDyeable, isSecondaryChannelDyeable, isAccentChannelDyeable = AreDyeableSlotDyeChannelsDyeable(dyeableSlot)
                local finalPrimaryDyeId = isPrimaryChannelDyeable and primaryDyeId or INVALID_DYE_ID
                local finalSecondaryDyeId = isSecondaryChannelDyeable and secondaryDyeId or INVALID_DYE_ID
                local finalAccentDyeId = isAccentChannelDyeable and accentDyeId or INVALID_DYE_ID
                SetPendingSlotDyes(dyeableSlot, finalPrimaryDyeId, finalSecondaryDyeId, finalAccentDyeId)
        end
    end

    PlaySound(SOUNDS.DYEING_RANDOMIZE_DYES)
end

function ZO_Dyeing_AreTherePendingDyes(mode)
    local slots = ZO_Dyeing_GetSlotsForMode(mode)
    for i, dyeableSlotData in ipairs(slots) do
        if ZO_Dyeing_AreTherePendingDyesForDyeableSlot(dyeableSlotData.dyeableSlot) then
            return true
        end
    end
    return false
end

do
    local NUM_DYE_CHANNELS = 3
    function ZO_Dyeing_AreTherePendingDyesForDyeableSlot(dyeableSlot)
        local currentDyes = { GetDyeableSlotCurrentDyes(dyeableSlot) }
        local pendingDyes = { GetPendingSlotDyes(dyeableSlot) }
        for j = 1, NUM_DYE_CHANNELS do
            local currentColor = currentDyes[j]
            local pendingColor = pendingDyes[j]
            if currentColor ~= pendingColor then
                return true
            end
        end

        return false
    end
end

function ZO_Dyeing_AreAllItemsBound(mode)
    local slots = ZO_Dyeing_GetSlotsForMode(mode)

    if mode == DYE_MODE_EQUIPMENT then
        local activeWeaponPair = GetActiveWeaponPairInfo()
        local doNotCheckThisSlot = ZO_Dyeing_GetOppositeOffHandDyeableSlot(activeWeaponPair)
        for i, dyeableSlotData in ipairs(slots) do
            local dyeableSlot = dyeableSlotData.dyeableSlot
            if doNotCheckThisSlot ~= dyeableSlot and IsDyeableSlotDyeable(dyeableSlot) and not IsDyeableSlotBound(dyeableSlot) and ZO_Dyeing_AreTherePendingDyesForDyeableSlot(dyeableSlot) then
                return false
            end
        end
    end
    return true
end

function ZO_Dyeing_GetOppositeOffHandDyeableSlot(activeWeaponPair)
    if activeWeaponPair == ACTIVE_WEAPON_PAIR_MAIN then
        return DYEABLE_SLOT_BACKUP_OFF
    elseif activeWeaponPair == ACTIVE_WEAPON_PAIR_BACKUP then
        return DYEABLE_SLOT_OFF_HAND
    end
end

function ZO_Dyeing_GetSlotsForMode(mode)
    if mode == DYE_MODE_EQUIPMENT then
        return ZO_DYEABLE_EQUIP_SLOTS
    elseif mode == DYE_MODE_COLLECTIBLE then
        return ZO_DYEABLE_COLLECTIBLE_SLOTS
    end
end

do
    local TEXTURE_WIDTH = 128
    local TEXTURE_HEIGHT = 128

    local FRAME_WIDTH = 24
    local FRAME_HEIGHT = 24

    local FRAME_SLICE_WIDTH = 32
    local FRAME_SLICE_HEIGHT = 32

    local FRAME_PADDING_X = (FRAME_SLICE_WIDTH - FRAME_WIDTH)
    local FRAME_PADDING_Y = (FRAME_SLICE_HEIGHT - FRAME_HEIGHT)

    local FRAME_WIDTH_TEX_COORD = FRAME_WIDTH / TEXTURE_WIDTH
    local FRAME_HEIGHT_TEX_COORD = FRAME_HEIGHT / TEXTURE_HEIGHT

    local FRAME_PADDING_X_TEX_COORD = FRAME_PADDING_X / TEXTURE_WIDTH
    local FRAME_PADDING_Y_TEX_COORD = FRAME_PADDING_Y / TEXTURE_HEIGHT

    local FRAME_START_TEXCOORD_X = 0.5 + FRAME_PADDING_X_TEX_COORD * .5
    local FRAME_START_TEXCOORD_Y = 0.0 + FRAME_PADDING_Y_TEX_COORD * .5

    local FRAME_NUM_COLS = 2
    local FRAME_NUM_ROWS = 4

    local function PickRandomFrame(self)
        local col = zo_random(FRAME_NUM_COLS)
        local row = zo_random(FRAME_NUM_ROWS)

        local left = FRAME_START_TEXCOORD_X + (col - 1) * (FRAME_WIDTH_TEX_COORD + FRAME_PADDING_X_TEX_COORD)
        local right = left + FRAME_WIDTH_TEX_COORD

        local top = FRAME_START_TEXCOORD_Y + (row - 1) * (FRAME_HEIGHT_TEX_COORD + FRAME_PADDING_Y_TEX_COORD)
        local bottom = top + FRAME_HEIGHT_TEX_COORD
        self:SetTextureCoords(ZO_DYEING_FRAME_INDEX, left, right, top, bottom)
    end

    local MUNGE_WIDTH = 24
    local MUNGE_HEIGHT = 24

    local MUNGE_WIDTH_TEX_COORD = MUNGE_WIDTH / TEXTURE_WIDTH
    local MUNGE_HEIGHT_TEX_COORD = MUNGE_HEIGHT / TEXTURE_HEIGHT

    local MUNGE_START_TEXCOORD_X = 0.0
    local MUNGE_START_TEXCOORD_Y = 0.5

    local MUNGE_END_TEXCOORD_X = 0.5
    local MUNGE_END_TEXCOORD_Y = 1.0

    local function PickRandomMunge(self)
        local left = zo_lerp(MUNGE_START_TEXCOORD_X, MUNGE_END_TEXCOORD_X - MUNGE_WIDTH_TEX_COORD, zo_random())
        local right = left + MUNGE_WIDTH_TEX_COORD

        local top = zo_lerp(MUNGE_START_TEXCOORD_Y, MUNGE_END_TEXCOORD_Y - MUNGE_HEIGHT_TEX_COORD, zo_random())
        local bottom = top + MUNGE_HEIGHT_TEX_COORD
        self:SetTextureCoords(ZO_DYEING_MUNGE_INDEX, left, right, top, bottom)
    end

    function ZO_DyeingUtils_DyeingSwatchVisuals_OnInitialized(self)
        PickRandomFrame(self)
        PickRandomMunge(self)
    end

    function ZO_DyeingUtils_DyeingSwatchVisuals_OnInitialized_Gamepad(self)
        self:SetSurfaceHidden(ZO_DYEING_FRAME_INDEX, true)
        self:SetSurfaceHidden(ZO_DYEING_MUNGE_INDEX, true)  --no munge on gamepad!
    end
end

do
    local STRIDE = 16
    local SWATCH_SIZE = 24
    local GAMEPAD_SWATCH_SIZE = 32
    local PADDING = 6
    local INITIAL_OFFSET_X = 27
    local INITIAL_OFFSET_Y = 18
    local GAMEPAD_INITIAL_OFFSET_X = 27
    local GAMEPAD_INITIAL_OFFSET_Y = 1

    function AnchorDyeSwatch(currentAnchor, swatch, index)
        local _, _, _, offsetY = ZO_Anchor_BoxLayout(currentAnchor, swatch, index - 1, STRIDE, PADDING, PADDING, SWATCH_SIZE, SWATCH_SIZE, INITIAL_OFFSET_X, INITIAL_OFFSET_Y)
        return offsetY
    end

    function AnchorDyeSwatch_Gamepad(currentAnchor, swatch, index)
        local _, _, _, offsetY = ZO_Anchor_BoxLayout(currentAnchor, swatch, index - 1, STRIDE, PADDING, PADDING, GAMEPAD_SWATCH_SIZE, GAMEPAD_SWATCH_SIZE, GAMEPAD_INITIAL_OFFSET_X, GAMEPAD_INITIAL_OFFSET_Y)
        return offsetY
    end

    function GetNextDyeHeaderOffsetY(maxOffsetY, lastHeader)
        return maxOffsetY + SWATCH_SIZE + PADDING + lastHeader:GetHeight()
    end

    function GetDyeSwatchNumRows(swatchCount)
        return math.ceil(swatchCount / STRIDE)
    end

    function GetDyeSwatchRow(swatchIndex)
        return math.ceil(swatchIndex / STRIDE)
    end

    function GetDyeSwatchMaxRowWidth_Gamepad()
        return ((GAMEPAD_SWATCH_SIZE + PADDING) * STRIDE) - PADDING
    end

    function GetDyeSwatchSize_Gamepad()
        return GAMEPAD_SWATCH_SIZE
    end
end

local function GetOrCreateDyeParentCategory(sortStyle, activeSwatches, rarity, hueCategory)
    if sortStyle == ZO_DYEING_SORT_STYLE_RARITY then
        if not activeSwatches[rarity] then
            activeSwatches[rarity] = {}
        end
        return activeSwatches[rarity]
    elseif sortStyle == ZO_DYEING_SORT_STYLE_HUE then
        if not activeSwatches[hueCategory] then
            activeSwatches[hueCategory] = {}
        end
        return activeSwatches[hueCategory]
    end
end

function ZO_Dyeing_LayoutSwatches(includeLocked, sortStyle, swatchPool, headerPool, layoutOptions, container)
    local activeSwatches = {}
    local swatchByDyeId = {}

    swatchPool:ReleaseAllObjects()

    for i=1, GetNumDyes() do
        local dyeName, known, rarity, hueCategory, achievementId, r, g, b, sortKey, dyeId = GetDyeInfo(i)

        if known or includeLocked then
            local parentCategory = GetOrCreateDyeParentCategory(sortStyle, activeSwatches, rarity, hueCategory)
            local swatch = swatchPool:AcquireObject()

            swatch:SetColor(ZO_DYEING_SWATCH_INDEX, r, g, b)
            swatch.sortKey = sortKey
            swatch.dyeName = dyeName
            swatch.known = known
            swatch.dyeId = dyeId
            swatch.achievementId = achievementId
            swatch:SetLocked(not known)

            table.insert(parentCategory, swatch)
            swatchByDyeId[dyeId] = swatch
        end
    end

    headerPool:ReleaseAllObjects()

    local sortedCategories = {}
    for category in pairs(activeSwatches) do
        table.insert(sortedCategories, category)
    end
    table.sort(sortedCategories)

    local nextHeaderOffsetY = 0
    local totalHeaderOffsetY = 0
    local lastHeader

    local swatchesByPosition = {}
    local positionByDyeId = {}
    local unlockedDyeIds = {}

    local stride
    local padding = layoutOptions.padding
    local leftMargin = layoutOptions.leftMargin
    local topMargin = layoutOptions.topMargin
    local rightMargin = layoutOptions.rightMargin
    local bottomMargin = layoutOptions.bottomMargin

    for i, category in ipairs(sortedCategories) do
        local swatches = activeSwatches[category]
        local header = headerPool:AcquireObject()

        header:SetAnchor(TOPLEFT, lastHeader, TOPLEFT, 0, nextHeaderOffsetY)
        header:SetText(ZO_DyeingUtils_GetHeaderTextFromSortType(sortStyle, category))

        local currentAnchor = ZO_Anchor:New(CENTER, header, BOTTOMLEFT)
        local currentRowTable

        table.sort(swatches, ZO_Dyeing_DyeSortComparator)
        local maxHeaderOffsetY = 0
        for j, swatch in ipairs(swatches) do
            if not stride then
                swatchWidth, swatchHeight = swatch:GetDimensions()
                halfSelectedSwatchHeight = (swatchHeight * layoutOptions.selectionScale) / 2
                local containerWidth = container:GetDimensions()
                stride = zo_floor((containerWidth - leftMargin + rightMargin) / (swatchWidth + padding))
            end
            local _, _, _, offsetY = ZO_Anchor_BoxLayout(currentAnchor, swatch, j - 1, stride, padding, padding, swatchWidth, swatchHeight, leftMargin, topMargin)
            maxHeaderOffsetY = zo_max(maxHeaderOffsetY, offsetY)

            if (j % stride) == 1 then
                currentRowTable = {}
                table.insert(swatchesByPosition, currentRowTable)
            end
            table.insert(currentRowTable, swatch)

            positionByDyeId[swatch.dyeId] = {#swatchesByPosition, #currentRowTable}

            swatch.effectiveTop = totalHeaderOffsetY + offsetY - halfSelectedSwatchHeight
            swatch.effectiveBottom = totalHeaderOffsetY + offsetY + swatchHeight + halfSelectedSwatchHeight + header:GetHeight()

            if not swatch:IsLocked() then
                table.insert(unlockedDyeIds, swatch.dyeId)
            end
        end

        nextHeaderOffsetY = maxHeaderOffsetY + swatchHeight + bottomMargin + header:GetHeight()
        totalHeaderOffsetY = totalHeaderOffsetY + nextHeaderOffsetY
        lastHeader = header
    end

    return swatchesByPosition, positionByDyeId, unlockedDyeIds, swatchByDyeId
end

function ZO_DyeingSwatch_OnMouseEnter(swatch)
    swatch.mousedOver = true
    swatch:UpdateSelectedState()

    if swatch then
        ZO_Dyeing_CreateTooltipOnMouseEnter(swatch, swatch.dyeName, swatch.known, swatch.achievementId)
    end
end

function ZO_DyeingSwatch_OnMouseExit(swatch)
    swatch.mousedOver = false
    swatch:UpdateSelectedState()
     
    ZO_Dyeing_ClearTooltipOnMouseExit(swatch)
end

do
    local INFORMATION_TOOLTIP_X_OFFSET = -15
    local INFORMATION_TOOLTIP_VERTICAL_PADDING = 10
    local INFORMATION_TOOLTIP_RETURN_VALUE_Y_POSITION = 2
    function ZO_Dyeing_CreateTooltipOnMouseEnter(control, dyeName, isDyeKnown, achievementId, nonPlayerDye)
        if control then
            InitializeTooltip(InformationTooltip, control:GetParent(), TOPRIGHT, INFORMATION_TOOLTIP_X_OFFSET, select(INFORMATION_TOOLTIP_RETURN_VALUE_Y_POSITION, control:GetCenter()) - control:GetParent():GetTop())
    
            SetTooltipText(InformationTooltip, zo_strformat(SI_DYEING_SWATCH_TOOLTIP_TITLE, dyeName))
            InformationTooltip:AddVerticalPadding(INFORMATION_TOOLTIP_VERTICAL_PADDING)

            local line1, line2 = ZO_Dyeing_GetAchivementText(isDyeKnown, achievementId, nonPlayerDye)
            InformationTooltip:AddLine(line1, "", ZO_NORMAL_TEXT:UnpackRGB())
            if line2 then
                InformationTooltip:AddLine(line2, "", ZO_NORMAL_TEXT:UnpackRGB())
            end
        end
    end
end

function ZO_Dyeing_ClearTooltipOnMouseExit()
    ClearTooltip(InformationTooltip)
end

local DYEABLE_SLOT_TEXTURES =
{
    [DYEABLE_SLOT_HEAD]       = "EsoUI/Art/CharacterWindow/gearSlot_head.dds",
    [DYEABLE_SLOT_CHEST]      = "EsoUI/Art/CharacterWindow/gearSlot_chest.dds",
    [DYEABLE_SLOT_SHOULDERS]  = "EsoUI/Art/CharacterWindow/gearSlot_shoulders.dds",
    [DYEABLE_SLOT_OFF_HAND]   = "EsoUI/Art/CharacterWindow/gearSlot_offHand.dds",
    [DYEABLE_SLOT_WAIST]      = "EsoUI/Art/CharacterWindow/gearSlot_belt.dds",
    [DYEABLE_SLOT_LEGS]       = "EsoUI/Art/CharacterWindow/gearSlot_legs.dds",
    [DYEABLE_SLOT_FEET]       = "EsoUI/Art/CharacterWindow/gearSlot_feet.dds",
    [DYEABLE_SLOT_HAND]       = "EsoUI/Art/CharacterWindow/gearSlot_hands.dds",
    [DYEABLE_SLOT_BACKUP_OFF] = "EsoUI/Art/CharacterWindow/gearSlot_offHand.dds",
    [DYEABLE_SLOT_COSTUME]    = "EsoUI/Art/Dye/dye_costume.dds",
    [DYEABLE_SLOT_HAT]        = "EsoUI/Art/Dye/dye_hat.dds",
}

function ZO_Character_GetEmptyDyeableSlotTexture(dyeableSlot)
    return DYEABLE_SLOT_TEXTURES[dyeableSlot]
end

--
--[[ Dyeing Singleton ]]--
--

local Dyeing_Manager = ZO_CallbackObject:Subclass()

function Dyeing_Manager:New(...)
    local dyeing = ZO_CallbackObject.New(self)
    return dyeing
end

function Dyeing_Manager:RegisterForDyeListUpdates(callback)
    self:RegisterCallback("UpdateDyeLists", callback)
end

function Dyeing_Manager:UpdateAllDyeLists()
    self:FireCallbacks("UpdateDyeLists")
end

ZO_DYEING_MANAGER = Dyeing_Manager:New()