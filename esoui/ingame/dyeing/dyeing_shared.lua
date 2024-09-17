do
    local DYEABLE_SLOTS =
    {
        [RESTYLE_MODE_EQUIPMENT] = {},
        [RESTYLE_MODE_COLLECTIBLE] = {},
        [RESTYLE_MODE_OUTFIT] = {},
        [RESTYLE_MODE_COMPANION_COLLECTIBLE] = {},
        [RESTYLE_MODE_COMPANION_OUTFIT] = {},
    }

    local DYEABLE_SORT_ORDER_OVERRIDE =
    {
        [RESTYLE_MODE_EQUIPMENT] =
        {
            [EQUIP_SLOT_OFF_HAND] = 100,
            [EQUIP_SLOT_BACKUP_OFF] = 100,
        },
        [RESTYLE_MODE_OUTFIT] =
        {
            [OUTFIT_SLOT_WEAPON_OFF_HAND] = 100,
            [OUTFIT_SLOT_WEAPON_OFF_HAND_BACKUP] = 100,
        },
    }

    local function DyeableSlotSortComparator(left, right)
        local leftSortOrder = left:GetSortOrder()
        local rightSortOrder = right:GetSortOrder()
        if leftSortOrder == rightSortOrder then
            return left:GetRestyleSlotType() < right:GetRestyleSlotType()
        else
            return leftSortOrder < rightSortOrder
        end
    end

    local function IterateDyeableSlotData(restyleMode, iterationBegin, iterationEnd)
        local slotsTable = DYEABLE_SLOTS[restyleMode]
        local sortOverrideTable = DYEABLE_SORT_ORDER_OVERRIDE[restyleMode]
        for restyleSlotType = iterationBegin, iterationEnd do
            if IsRestyleSlotTypeDyeable(restyleMode, restyleSlotType) then
                local sortOrder = 0
                if sortOverrideTable and sortOverrideTable[restyleSlotType] then
                    sortOrder = sortOverrideTable[restyleSlotType]
                end
                local dyeableSlotData = ZO_RestyleSlotData:New(restyleMode, ZO_RESTYLE_DEFAULT_SET_INDEX, restyleSlotType)
                dyeableSlotData:SetSortOrder(sortOrder)
                table.insert(slotsTable, dyeableSlotData)
            end
        end
        table.sort(slotsTable, DyeableSlotSortComparator)
    end

    function ZO_Dyeing_InitializeDyeableSlotsTables()
        IterateDyeableSlotData(RESTYLE_MODE_EQUIPMENT, EQUIP_SLOT_ITERATION_BEGIN, EQUIP_SLOT_ITERATION_END)
        IterateDyeableSlotData(RESTYLE_MODE_COLLECTIBLE, COLLECTIBLE_CATEGORY_TYPE_ITERATION_BEGIN, COLLECTIBLE_CATEGORY_TYPE_ITERATION_END)
        IterateDyeableSlotData(RESTYLE_MODE_OUTFIT, OUTFIT_SLOT_ITERATION_BEGIN, OUTFIT_SLOT_ITERATION_END)
        IterateDyeableSlotData(RESTYLE_MODE_COMPANION_COLLECTIBLE, COLLECTIBLE_CATEGORY_TYPE_ITERATION_BEGIN, COLLECTIBLE_CATEGORY_TYPE_ITERATION_END)
        IterateDyeableSlotData(RESTYLE_MODE_COMPANION_OUTFIT, OUTFIT_SLOT_ITERATION_BEGIN, OUTFIT_SLOT_ITERATION_END)
    end

    function ZO_Dyeing_GetSlotsForRestyleSet(restyleMode, restyleSetIndex)
        local cachedSlots = DYEABLE_SLOTS[restyleMode]
        -- Companion Equipment mode is not allowed to dye so the diable slots may be nil
        if cachedSlots then
            for _, restyleSlotData in pairs(cachedSlots) do
                -- This is a static cache for lookup/iteration purposes, so we don't have to redo complex checks and table allocation, but it's shared across all sets for a mode
                -- If one is already the right set, they're all already the right set
                if restyleSlotData:GetRestyleSetIndex() == restyleSetIndex then
                    break
                end

                restyleSlotData:SetRestyleSetIndex(restyleSetIndex)
            end
        end

        return cachedSlots
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
ZO_DYEING_NEW_INDEX = 5

-- Interaction Mode Setup

ZO_DYEING_STATION_INTERACTION =
{
    type = "Dyeing Station",
    OnInteractSwitch = function()
        internalassert(false, "OnInteractSwitch is being called.")
        SYSTEMS:HideScene("restyle")
        SYSTEMS:HideScene("restyle_station")
    end,
    interactTypes = { INTERACTION_DYE_STATION },
}

-- Shared Show Events
EVENT_MANAGER:RegisterForEvent("Dyeing_Shared", EVENT_DYEING_STATION_INTERACT_START, function(eventCode)
    SYSTEMS:ShowScene("restyle")
end)

EVENT_MANAGER:RegisterForEvent("Dyeing_Shared", EVENT_DYEING_STATION_INTERACT_END, function(eventCode)
    SYSTEMS:HideScene("restyle")
end)

-- Shared Functions
function ZO_Dyeing_GetAchievementText(dyeKnown, achievementId, nonPlayerDye)
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

function ZO_Dyeing_InitializeSwatchPool(owner, parentControl, template, canSelectLocked)
    local function OnClicked(swatchControl, button, upInside)
        if upInside then
            local swatchObject = swatchControl.object
            if button == MOUSE_BUTTON_INDEX_LEFT then
                if not swatchObject.locked then
                    owner:SwitchToDyeingWithDyeId(swatchObject.dyeId)
                end
            elseif button == MOUSE_BUTTON_INDEX_RIGHT then
                local achievementId = swatchObject.achievementId
                local achievementName = GetAchievementInfo(achievementId)
                if achievementName ~= "" then
                    ClearMenu()
                    AddMenuItem(GetString(SI_DYEING_SWATCH_VIEW_ACHIEVEMENT), function() owner:AttemptExit(achievementId) end)
                    ShowMenu(swatchControl)
                end
            end
        end
    end

    local function Factory(objectPool)
        local swatchControl = ZO_ObjectPool_CreateControl(template, objectPool, parentControl)
        swatchControl:SetHandler("OnMouseUp", OnClicked)
        local swatchObject = ZO_DyeingSwatch_Shared:New(swatchControl, owner, canSelectLocked)
        swatchObject:SetControl(swatchControl)
        return swatchObject
    end

    local function Reset(swatchObject)
        swatchObject:SetSelected(false, SKIP_ANIM)
        swatchObject:SetLocked(false)
        swatchObject:SetNew(false)
        ZO_ObjectPool_DefaultResetControl(swatchObject.control)
    end

    local objectPool = ZO_ObjectPool:New(Factory, Reset)

    objectPool:SetCustomAcquireBehavior(function(swatchObject)
        swatchObject.control:SetHidden(false)
    end)

    return objectPool
end

function ZO_Dyeing_DyeSortComparator(left, right)
    return left.sortKey < right.sortKey
end

function ZO_Dyeing_RefreshDyeableSlotControlDyes_Colors(dyeControls, restyleSlotData, ...)
    local isDyeable = restyleSlotData:IsDataDyeable()
    local isChannelDyeableTable = {restyleSlotData:AreDyeChannelsDyeable()}
    for dyeChannel, dyeControl in ipairs(dyeControls) do
        if isDyeable then
            dyeControl:SetHidden(false)
            local currentDyeId = select(dyeChannel, ...)
            ZO_DyeingUtils_SetSlotDyeSwatchDyeId(dyeControl, currentDyeId, isChannelDyeableTable[dyeChannel])
        else
            dyeControl:SetHidden(true)
        end
    end
end

local function GetFrameForDyeChannel(empty)
    return empty and "EsoUI/Art/Dye/dye_amorSlot_empty.dds" or "EsoUI/Art/Dye/dye_amorSlot.dds"
end

function ZO_Dyeing_RefreshDyeableSlotControlDyes(dyeControls, restyleSlotData)
    ZO_Dyeing_RefreshDyeableSlotControlDyes_Colors(dyeControls, restyleSlotData, restyleSlotData:GetPendingDyes())
end

function ZO_DyeingUtils_SetSlotDyeSwatchDyeId(dyeControl, dyeId, isDyeable)
    local isEmptyFrame, hideBackground, hideInvalid
    if dyeId ~= INVALID_DYE_ID and isDyeable ~= false then
        -- We have a dye and the channel is dyeable
        local dyeInfo = ZO_DYEING_MANAGER:GetDyeInfoById(dyeId)
        dyeControl.swatchTexture:SetColor(dyeInfo.r, dyeInfo.g, dyeInfo.b, 1)
        isEmptyFrame = false
        hideBackground = true
        hideInvalid = true
    else
        -- It's currently not dyed
        dyeControl.swatchTexture:SetColor(0, 0, 0, 0)
        isEmptyFrame = true
        hideBackground = false
        -- Hide invalid if we're explicitly told we can't dye this channel
        hideInvalid = isDyeable ~= false
    end

    if dyeControl.frameTexture then
        dyeControl.frameTexture:SetTexture(GetFrameForDyeChannel(isEmptyFrame))
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

function ZO_Dyeing_UniformRandomize(restyleMode, restyleSetIndex, getRandomUnlockedDyeIdFunction)
    local primaryDyeId = getRandomUnlockedDyeIdFunction()
    local secondaryDyeId = getRandomUnlockedDyeIdFunction()
    local accentDyeId = getRandomUnlockedDyeIdFunction()
    
    local slots = ZO_Dyeing_GetSlotsForRestyleSet(restyleMode, restyleSetIndex)

    for i, dyeableSlotData in ipairs(slots) do
        --don't randomly dye the shield in your other weapon set
        if not dyeableSlotData:ShouldBeHidden() then
            local isPrimaryChannelDyeable, isSecondaryChannelDyeable, isAccentChannelDyeable = dyeableSlotData:AreDyeChannelsDyeable()
            local finalPrimaryDyeId = isPrimaryChannelDyeable and primaryDyeId or INVALID_DYE_ID
            local finalSecondaryDyeId = isSecondaryChannelDyeable and secondaryDyeId or INVALID_DYE_ID
            local finalAccentDyeId = isAccentChannelDyeable and accentDyeId or INVALID_DYE_ID
            dyeableSlotData:SetPendingDyes(finalPrimaryDyeId, finalSecondaryDyeId, finalAccentDyeId)
        end
    end

    PlaySound(SOUNDS.DYEING_RANDOMIZE_DYES)
    return primaryDyeId, secondaryDyeId, accentDyeId
end

function ZO_Dyeing_AreTherePendingDyes(restyleMode, restyleSetIndex)
    local slots = ZO_Dyeing_GetSlotsForRestyleSet(restyleMode, restyleSetIndex)
    -- Companion Equipment mode is not allowed to dye so the diable slots may be nil
    if slots then
        for i, dyeableSlotData in ipairs(slots) do
            if dyeableSlotData:AreTherePendingDyeChanges() then
                return true
            end
        end
    end
    return false
end

function ZO_Dyeing_AreAllItemsBound(restyleMode, restyleSetIndex)
    if restyleMode == RESTYLE_MODE_EQUIPMENT then
        local slots = ZO_Dyeing_GetSlotsForRestyleSet(restyleMode, restyleSetIndex)
        local doNotCheckThisSlot = ZO_Restyle_GetOppositeOffHandEquipSlotType()
        for i, dyeableSlotData in ipairs(slots) do
            local restyleSlotType = dyeableSlotData:GetRestyleSlotType()
            if doNotCheckThisSlot ~= restyleSlotType and dyeableSlotData:IsDataDyeable() and not IsRestyleEquipmentSlotBound(restyleSlotType) and dyeableSlotData:AreTherePendingDyeChanges() then
                return false
            end
        end
    end
    return true
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

    local function PickRandomFrame(swatchControl)
        local col = zo_random(FRAME_NUM_COLS)
        local row = zo_random(FRAME_NUM_ROWS)

        local left = FRAME_START_TEXCOORD_X + (col - 1) * (FRAME_WIDTH_TEX_COORD + FRAME_PADDING_X_TEX_COORD)
        local right = left + FRAME_WIDTH_TEX_COORD

        local top = FRAME_START_TEXCOORD_Y + (row - 1) * (FRAME_HEIGHT_TEX_COORD + FRAME_PADDING_Y_TEX_COORD)
        local bottom = top + FRAME_HEIGHT_TEX_COORD
        swatchControl:SetTextureCoords(ZO_DYEING_FRAME_INDEX, left, right, top, bottom)
    end

    local MUNGE_WIDTH = 24
    local MUNGE_HEIGHT = 24

    local MUNGE_WIDTH_TEX_COORD = MUNGE_WIDTH / TEXTURE_WIDTH
    local MUNGE_HEIGHT_TEX_COORD = MUNGE_HEIGHT / TEXTURE_HEIGHT

    local MUNGE_START_TEXCOORD_X = 0.0
    local MUNGE_START_TEXCOORD_Y = 0.5

    local MUNGE_END_TEXCOORD_X = 0.5
    local MUNGE_END_TEXCOORD_Y = 1.0

    local function PickRandomMunge(swatchControl)
        local left = zo_randomDecimalRange(MUNGE_START_TEXCOORD_X, MUNGE_END_TEXCOORD_X - MUNGE_WIDTH_TEX_COORD)
        local right = left + MUNGE_WIDTH_TEX_COORD

        local top = zo_randomDecimalRange(MUNGE_START_TEXCOORD_Y, MUNGE_END_TEXCOORD_Y - MUNGE_HEIGHT_TEX_COORD)
        local bottom = top + MUNGE_HEIGHT_TEX_COORD
        swatchControl:SetTextureCoords(ZO_DYEING_MUNGE_INDEX, left, right, top, bottom)
    end

    function ZO_DyeingUtils_DyeingSwatchVisuals_OnInitialized(swatchControl)
        PickRandomFrame(swatchControl)
        PickRandomMunge(swatchControl)
    end

    function ZO_DyeingUtils_DyeingSwatchVisuals_OnInitialized_Gamepad(swatchControl)
        swatchControl:SetSurfaceHidden(ZO_DYEING_FRAME_INDEX, true)
        swatchControl:SetSurfaceHidden(ZO_DYEING_MUNGE_INDEX, true)  --no munge on gamepad!
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

function ZO_Dyeing_LayoutSwatches(includeLocked, sortStyle, swatchPool, headerPool, layoutOptions, container, useSearchResults)
    local dyesBySortStyleCategory = (sortStyle == ZO_DYEING_SORT_STYLE_RARITY) and ZO_DYEING_MANAGER:GetPlayerDyesByRarity() or ZO_DYEING_MANAGER:GetPlayerDyesByHueCategory()
    local searchResults = useSearchResults and ZO_DYEING_MANAGER:GetSearchResults()

    swatchPool:ReleaseAllObjects()
    headerPool:ReleaseAllObjects()

    local sortedCategories = {}
    for category in pairs(dyesBySortStyleCategory) do
        table.insert(sortedCategories, category)
    end
    table.sort(sortedCategories)

    local nextHeaderOffsetY = 0
    local totalHeaderOffsetY = 0
    local lastHeader
    
    local swatchByDyeId = {}
    local swatchesByPosition = {}
    local positionByDyeId = {}

    local stride
    local swatchWidth
    local swatchHeight
    local halfSelectedSwatchHeight
    local padding = layoutOptions.padding
    local leftMargin = layoutOptions.leftMargin
    local topMargin = layoutOptions.topMargin
    local rightMargin = layoutOptions.rightMargin
    local bottomMargin = layoutOptions.bottomMargin

    for _, category in ipairs(sortedCategories) do
        local header
        local currentAnchor
        local currentRowTable
        
        local dyes = dyesBySortStyleCategory[category]
        local maxHeaderOffsetY = 0
        local swatchIndex = 0
        for _, dyeInfo in ipairs(dyes) do
            local known = dyeInfo.known
            local isNew = dyeInfo.isNew
            local passesSearch = not searchResults or searchResults[dyeInfo.dyeIndex]
            local passesFilter = known or includeLocked
            if passesSearch and passesFilter then
                if swatchIndex == 0 then
                    header = headerPool:AcquireObject()
                    header:SetAnchor(TOPLEFT, lastHeader, TOPLEFT, 0, nextHeaderOffsetY)
                    header:SetText(ZO_DyeingUtils_GetHeaderTextFromSortType(sortStyle, category))
                    currentAnchor = ZO_Anchor:New(CENTER, header, BOTTOMLEFT)
                end

                swatchIndex = swatchIndex + 1

                local dyeId = dyeInfo.dyeId
                local swatchObject = swatchPool:AcquireObject()
                local swatchControl = swatchObject.control

                swatchObject:SetDataSource(dyeInfo)
                swatchObject:SetLocked(not known)
                swatchObject:SetNew(isNew)
                swatchControl:SetColor(ZO_DYEING_SWATCH_INDEX, dyeInfo.r, dyeInfo.g, dyeInfo.b)

                swatchByDyeId[dyeId] = swatchObject

                if not stride then
                    swatchWidth, swatchHeight = swatchControl:GetDimensions()
                    halfSelectedSwatchHeight = (swatchHeight * layoutOptions.selectionScale) / 2
                    local containerWidth = container:GetDimensions()
                    stride = zo_floor((containerWidth - leftMargin + rightMargin) / (swatchWidth + padding))
                end

                local _, _, _, offsetY = ZO_Anchor_BoxLayout(currentAnchor, swatchControl, swatchIndex - 1, stride, padding, padding, swatchWidth, swatchHeight, leftMargin, topMargin)
                maxHeaderOffsetY = zo_max(maxHeaderOffsetY, offsetY)

                if (swatchIndex % stride) == 1 then
                    currentRowTable = {}
                    table.insert(swatchesByPosition, currentRowTable)
                end
                table.insert(currentRowTable, swatchObject)

                positionByDyeId[dyeId] = {#swatchesByPosition, #currentRowTable}

                swatchObject.effectiveTop = totalHeaderOffsetY + offsetY - halfSelectedSwatchHeight
                swatchObject.effectiveBottom = totalHeaderOffsetY + offsetY + swatchHeight + halfSelectedSwatchHeight + header:GetHeight()
            end
        end

        if swatchIndex > 0 then
            nextHeaderOffsetY = maxHeaderOffsetY + swatchHeight + bottomMargin + header:GetHeight()
            totalHeaderOffsetY = totalHeaderOffsetY + nextHeaderOffsetY
            lastHeader = header
        end
    end

    return swatchesByPosition, positionByDyeId, swatchByDyeId
end

function ZO_DyeingSwatch_OnMouseEnter(swatchControl)
    local swatchObject = swatchControl.object
    if swatchObject then
        swatchObject.mousedOver = true
        swatchObject:UpdateSelectedState()

        ZO_Dyeing_CreateTooltipOnMouseEnter(swatchControl, swatchObject.dyeName, swatchObject.known, swatchObject.achievementId)
    end
end

function ZO_DyeingSwatch_OnMouseExit(swatchControl)
    local swatchObject = swatchControl.object
    if swatchObject then
        swatchObject.mousedOver = false
        swatchObject:UpdateSelectedState()

        if swatchObject:IsNew() then
            swatchObject:SetNew(false)
        end

        ZO_Dyeing_ClearTooltipOnMouseExit(swatchControl)
    end
end

do
    local INFORMATION_TOOLTIP_X_OFFSET = 15
    local INFORMATION_TOOLTIP_VERTICAL_PADDING = 10
    local INFORMATION_TOOLTIP_RETURN_VALUE_Y_POSITION = 2
    function ZO_Dyeing_CreateTooltipOnMouseEnter(swatchControl, dyeName, isDyeKnown, achievementId, nonPlayerDye, isRightAnchored)
        if swatchControl then
            local anchorPoint
            local relativePoint
            local xOffset
            if isRightAnchored == false then
                anchorPoint = LEFT
                relativePoint = TOPRIGHT
                xOffset = INFORMATION_TOOLTIP_X_OFFSET
            else
                anchorPoint = RIGHT
                relativePoint = TOPLEFT
                xOffset = -INFORMATION_TOOLTIP_X_OFFSET
            end
            InitializeTooltip(InformationTooltip, swatchControl:GetParent(), anchorPoint, xOffset, select(INFORMATION_TOOLTIP_RETURN_VALUE_Y_POSITION, swatchControl:GetCenter()) - swatchControl:GetParent():GetTop(), relativePoint)
            SetTooltipText(InformationTooltip, zo_strformat(SI_DYEING_SWATCH_TOOLTIP_TITLE, dyeName))
            InformationTooltip:AddVerticalPadding(INFORMATION_TOOLTIP_VERTICAL_PADDING)

            local line1, line2 = ZO_Dyeing_GetAchievementText(isDyeKnown, achievementId, nonPlayerDye)
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

function ZO_DyeSwatchesGridSort(left, right)
    if left.categoryOrder ~= right.categoryOrder then
        return left.categoryOrder < right.categoryOrder
    elseif left.known ~= right.known then
        return left.known
    elseif left.sortKey ~= right.sortKey then
        return left.sortKey < right.sortKey
    else
        return left.dyeName < right.dyeName
    end
end

ZO_DyeingSwatch_Shared = ZO_DataSourceObject:Subclass()

function ZO_DyeingSwatch_Shared:New(...)
    local object = ZO_DataSourceObject.New(self)
    object:Initialize(...)
    return object
end

function ZO_DyeingSwatch_Shared:Initialize(owner, canSelectLocked)
    self.owner = owner
    self.canSelectLocked = canSelectLocked
    self.swatchInterpolator = ZO_SimpleControlScaleInterpolator:New(1.0, ZO_DYEING_SWATCH_SELECTION_SCALE)
end

function ZO_DyeingSwatch_Shared:SetControl(control)
    self.control = control
    control.object = self
    self.highlightControl = self.control:GetNamedChild("Highlight")
end

function ZO_DyeingSwatch_Shared:UpdateSelectedState(skipAnim, isChecked)
    if (self.canSelectLocked or not self.locked) and (self.mousedOver or self.selected or isChecked) then
        if skipAnim then
            self.swatchInterpolator:ResetToMax(self.control)
        else
            self.swatchInterpolator:ScaleUp(self.control)
        end
    else
        if skipAnim then
            self.swatchInterpolator:ResetToMin(self.control)
        else
            self.swatchInterpolator:ScaleDown(self.control)
        end
    end

    self.highlightControl:SetHidden(not self.selected)
end

function ZO_DyeingSwatch_Shared:SetSelected(selected, skipAnim, skipSound)
    if self.selected ~= selected then
        self.selected = selected
        if selected and not skipSound and not self.owner.suppressSounds then
            PlaySound(SOUNDS.DYEING_SWATCH_SELECTED)
        end
    end
    self:UpdateSelectedState(skipAnim)
end

do
    local SKIP_ANIM = true

    function ZO_DyeingSwatch_Shared:SetLocked(locked)
        self.locked = locked
        self.control:SetSurfaceHidden(ZO_DYEING_LOCK_INDEX, not locked)
        self:UpdateSelectedState(SKIP_ANIM)
    end

    function ZO_DyeingSwatch_Shared:SetNew(isNew) 
        self.isNew = isNew
        self.control:SetSurfaceHidden(ZO_DYEING_NEW_INDEX, not isNew)
        self:UpdateSelectedState(SKIP_ANIM)
    end
end

function ZO_DyeingSwatch_Shared:IsLocked()
    return self.locked
end

function ZO_DyeingSwatch_Shared:IsNew()
    return self.isNew
end

--
--[[ Dyeing Singleton ]]--
--

local Dyeing_Manager = ZO_CallbackObject:Subclass()

function Dyeing_Manager:New(...)
    local dyeing = ZO_CallbackObject.New(self)
    dyeing:Initialize(...)
    return dyeing
end

function Dyeing_Manager:Initialize()
    ZO_Dyeing_InitializeDyeableSlotsTables()
    
    self.dyesById = {}
    self.nonPlayerDyesById = {}
    self.unlockedDyes = {}

    self.dyesByHueCategory = {}
    for hueCategory = DYE_HUE_CATEGORY_ITERATION_BEGIN, DYE_HUE_CATEGORY_ITERATION_END do
        self.dyesByHueCategory[hueCategory] = {}
    end
    self.dyesByRarity = {}
    for rarity = DYE_RARITY_ITERATION_BEGIN, DYE_RARITY_ITERATION_END do
        self.dyesByRarity[rarity] = {}
    end

    self.searchString = ""
    self.searchResults = {}
    
    EVENT_MANAGER:RegisterForEvent("Dyeing_Manager", EVENT_UNLOCKED_DYES_UPDATED, function() self:UpdateDyeData() end)
    EVENT_MANAGER:RegisterForEvent("Dyeing_Manager", EVENT_DYES_SEARCH_RESULTS_READY, function() self:UpdateSearchResults() end)

    local function OnAddOnLoaded(event, name)
        if name == "ZO_Ingame" then
            local DEFAULTS =
            {
                showLocked = true,
                sortStyle = ZO_DYEING_SORT_STYLE_RARITY,
            }
            self.savedVars = ZO_SavedVars:New("ZO_Ingame_SavedVariables", 1, "Dyeing", DEFAULTS)
            EVENT_MANAGER:UnregisterForEvent("Dyeing_Manager", EVENT_ADD_ON_LOADED)
            self:FireCallbacks("OptionsInfoAvailable")
        end
    end
    EVENT_MANAGER:RegisterForEvent("Dyeing_Manager", EVENT_ADD_ON_LOADED, OnAddOnLoaded)

    self:UpdateDyeData()
end

function Dyeing_Manager:UpdateDyeData()
    ZO_ClearNumericallyIndexedTable(self.unlockedDyes)
    local dyesById = {}
    local newUnlockedDyes = {}
    for hueCategory = DYE_HUE_CATEGORY_ITERATION_BEGIN, DYE_HUE_CATEGORY_ITERATION_END do
        ZO_ClearNumericallyIndexedTable(self.dyesByHueCategory[hueCategory])
    end
    for rarity = DYE_RARITY_ITERATION_BEGIN, DYE_RARITY_ITERATION_END do
        ZO_ClearNumericallyIndexedTable(self.dyesByRarity[rarity])
    end

    for dyeIndex = 1, GetNumDyes() do
        local dyeName, known, rarity, hueCategory, achievementId, r, g, b, sortKey, dyeId = GetDyeInfo(dyeIndex)
        local dyeInfo = 
        {
            dyeId = dyeId,
            dyeName = dyeName,
            known = known,
            isNew = false,
            rarity = rarity,
            hueCategory = hueCategory,
            achievementId = achievementId,
            sortKey = sortKey,
            r = r,
            g = g,
            b = b,
            dyeIndex = dyeIndex,
            narrationText = function(entryData)
                local bodyText = ZO_Dyeing_GetAchievementText(entryData.known, entryData.achievementId)
                return { SCREEN_NARRATION_MANAGER:CreateNarratableObject(entryData.dyeName), SCREEN_NARRATION_MANAGER:CreateNarratableObject(bodyText) }
            end,
        }
        
        dyesById[dyeId] = dyeInfo
        if known then
            table.insert(self.unlockedDyes, dyeInfo)
            local previousDyeInfo = self.dyesById[dyeId]
            if previousDyeInfo then
                if not previousDyeInfo.known then
                    table.insert(newUnlockedDyes, dyeInfo)
                    dyeInfo.isNew = true
                end
                if previousDyeInfo.isNew then 
                    dyeInfo.isNew = true
                end
            end
        end
        table.insert(self.dyesByHueCategory[hueCategory], dyeInfo)
        table.insert(self.dyesByRarity[rarity], dyeInfo)
    end

    self.dyesById = dyesById

    for hueCategory = DYE_HUE_CATEGORY_ITERATION_BEGIN, DYE_HUE_CATEGORY_ITERATION_END do
        table.sort(self.dyesByHueCategory[hueCategory], ZO_Dyeing_DyeSortComparator)
    end

    for rarity = DYE_RARITY_ITERATION_BEGIN, DYE_RARITY_ITERATION_END do
        table.sort(self.dyesByRarity[rarity], ZO_Dyeing_DyeSortComparator)
    end

    self:FireCallbacks("UpdateDyeData", newUnlockedDyes)
end

function Dyeing_Manager:GetPlayerDyesById()
    return self.dyesById
end

function Dyeing_Manager:GetUnlockedPlayerDyes()
    return self.unlockedDyes
end

function Dyeing_Manager:GetRandomUnlockedDyeId()
    if #self.unlockedDyes > 0 then
        return self.unlockedDyes[zo_random(1, #self.unlockedDyes)].dyeId
    end
    return nil
end

function Dyeing_Manager:GetDyeInfoById(dyeId)
    local playerDyeInfo = self:GetPlayerDyeInfoById(dyeId)
    if playerDyeInfo then
        return playerDyeInfo
    end

    return self:GetOrCreateNonPlayerDyeInfoById(dyeId)
end

function Dyeing_Manager:GetPlayerDyeInfoById(dyeId)
    return self.dyesById[dyeId]
end

function Dyeing_Manager:GetOrCreateNonPlayerDyeInfoById(dyeId)
    if self.dyesById[dyeId] then
        return nil -- this is a player dye
    end

    -- Get
    if self.nonPlayerDyesById[dyeId] then
        return self.nonPlayerDyesById[dyeId]
    end

    -- Create
    local dyeName, known, rarity, hueCategory, achievementId, r, g, b, sortKey = GetDyeInfoById(dyeId)
    if dyeName ~= "" then
        local dyeInfo = 
        {
            dyeId = dyeId,
            dyeName = dyeName,
            known = known,
            rarity = rarity,
            hueCategory = hueCategory,
            achievementId = achievementId,
            sortKey = sortKey,
            r = r,
            g = g,
            b = b,
            narrationText = function(entryData)
                local bodyText = ZO_Dyeing_GetAchievementText(entryData.known, entryData.achievementId)
                return { SCREEN_NARRATION_MANAGER:CreateNarratableObject(entryData.dyeName), SCREEN_NARRATION_MANAGER:CreateNarratableObject(bodyText) }
            end,
        }

        self.nonPlayerDyesById[dyeId] = dyeInfo
        return dyeInfo
    end

    -- the passed in dyeId does not have data to go with it
    return nil
end

function Dyeing_Manager:GetPlayerDyesByHueCategory()
    return self.dyesByHueCategory
end

function Dyeing_Manager:GetPlayerDyesByRarity()
    return self.dyesByRarity
end

function Dyeing_Manager:SetSearchString(searchString)
    self.searchString = searchString or ""
    StartDyesSearch(searchString)
end

function Dyeing_Manager:UpdateSearchResults()
    ZO_ClearTable(self.searchResults)

    for i = 1, GetNumDyesSearchResults() do
        self.searchResults[GetDyesSearchResult(i)] = true
    end

    self:FireCallbacks("UpdateSearchResults")
end

function Dyeing_Manager:GetSearchResults()
    if zo_strlen(self.searchString) > 1 then
        return self.searchResults
    end
    return nil
end

function Dyeing_Manager:GetShowLocked()
    return self.savedVars.showLocked
end

function Dyeing_Manager:SetShowLocked(showLocked)
    if self.savedVars.showLocked ~= showLocked then
        self.savedVars.showLocked = showLocked
        self:FireCallbacks("UpdateDyeLists")
    end
end

function Dyeing_Manager:GetSortStyle()
    return self.savedVars.sortStyle
end

function Dyeing_Manager:SetSortStyle(sortStyle)
    if self.savedVars.sortStyle ~= sortStyle then
        self.savedVars.sortStyle = sortStyle
        self:FireCallbacks("UpdateDyeLists")
    end
end

ZO_DYEING_MANAGER = Dyeing_Manager:New()

-- XML functions --

function ZO_SwatchSlotDyes_OnInitialize(control)
    control.dyeControls = 
    {
        control:GetNamedChild("Primary"),
        control:GetNamedChild("Secondary"),
        control:GetNamedChild("Accent"),
    }
end