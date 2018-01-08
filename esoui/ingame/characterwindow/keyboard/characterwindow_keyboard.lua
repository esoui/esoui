local g_isReadOnly = false
local isDeadReadOnly = false
local isShowingReadOnlyFragment = false

local MOUSE_OVER_TEXTURE = "EsoUI/Art/ActionBar/actionBar_mouseOver.dds"

local function RestoreMouseOverTexture(slotControl)
    slotControl:SetMouseOverTexture(not ZO_Character_IsReadOnly() and MOUSE_OVER_TEXTURE or nil)
    slotControl:SetPressedMouseOverTexture(not ZO_Character_IsReadOnly() and MOUSE_OVER_TEXTURE or nil)
end

local slots = nil
local heldSlotLinkage = nil

local function GetEquippedItemType(slotId)
    local _, _, _, _, _, equipType = GetItemInfo(BAG_WORN, slotId)
    return equipType
end

local function InitializeSlots()
    slots =
    {
        [EQUIP_SLOT_HEAD]           = ZO_CharacterEquipmentSlotsHead,
        [EQUIP_SLOT_NECK]           = ZO_CharacterEquipmentSlotsNeck,
        [EQUIP_SLOT_CHEST]          = ZO_CharacterEquipmentSlotsChest,
        [EQUIP_SLOT_SHOULDERS]      = ZO_CharacterEquipmentSlotsShoulder,
        [EQUIP_SLOT_MAIN_HAND]      = ZO_CharacterEquipmentSlotsMainHand,
        [EQUIP_SLOT_OFF_HAND]       = ZO_CharacterEquipmentSlotsOffHand,
        [EQUIP_SLOT_POISON]         = ZO_CharacterEquipmentSlotsPoison,
        [EQUIP_SLOT_WAIST]          = ZO_CharacterEquipmentSlotsBelt,
        [EQUIP_SLOT_LEGS]           = ZO_CharacterEquipmentSlotsLeg,
        [EQUIP_SLOT_FEET]           = ZO_CharacterEquipmentSlotsFoot,
        [EQUIP_SLOT_COSTUME]        = ZO_CharacterEquipmentSlotsCostume,
        [EQUIP_SLOT_RING1]          = ZO_CharacterEquipmentSlotsRing1,
        [EQUIP_SLOT_RING2]          = ZO_CharacterEquipmentSlotsRing2,
        [EQUIP_SLOT_HAND]           = ZO_CharacterEquipmentSlotsGlove,
        [EQUIP_SLOT_BACKUP_MAIN]    = ZO_CharacterEquipmentSlotsBackupMain,
        [EQUIP_SLOT_BACKUP_OFF]     = ZO_CharacterEquipmentSlotsBackupOff,
        [EQUIP_SLOT_BACKUP_POISON]  = ZO_CharacterEquipmentSlotsBackupPoison,
    }

    heldSlotLinkage =
    {
        [EQUIP_SLOT_MAIN_HAND] = { linksTo = EQUIP_SLOT_OFF_HAND },
        [EQUIP_SLOT_BACKUP_MAIN] = { linksTo = EQUIP_SLOT_BACKUP_OFF },
        [EQUIP_SLOT_OFF_HAND] = 
        { 
            pullFromConditionFn =   function() 
                                        return GetEquippedItemType(EQUIP_SLOT_MAIN_HAND) == EQUIP_TYPE_TWO_HAND 
                                    end,
            pullFromFn =    function()
                                local iconFile, slotHasItem, _, _, _, locked = GetEquippedItemInfo(EQUIP_SLOT_MAIN_HAND)
                                return iconFile, slotHasItem, locked
                            end,
        },

        [EQUIP_SLOT_BACKUP_OFF] =
        {
            pullFromConditionFn =   function() 
                                        return GetEquippedItemType(EQUIP_SLOT_BACKUP_MAIN) == EQUIP_TYPE_TWO_HAND 
                                    end,

            pullFromFn =    function()
                                local iconFile, slotHasItem, _, _, _, locked = GetEquippedItemInfo(EQUIP_SLOT_BACKUP_MAIN)
                                return iconFile, slotHasItem, locked
                            end,
        },
    }

    for slotId, slotControl in pairs(slots) do
        ZO_Inventory_BindSlot(slotControl, SLOT_TYPE_EQUIPMENT, slotId, BAG_WORN)
        slotControl.CustomOnStopCallback = RestoreMouseOverTexture
        ZO_CreateSparkleAnimation(slotControl)
    end
end

local PLAY_ANIMATION = true
local NO_ANIMATION = false

local function UpdateSlotAppearance(slotId, slotControl, animationOption, copyFromLinkedFn)
    local iconControl = slotControl:GetNamedChild("Icon")
    local iconFile, slotHasItem, locked

    if(copyFromLinkedFn) then
        iconFile, slotHasItem, locked = copyFromLinkedFn()
    else
        local _
        iconFile, slotHasItem, _, _, _, locked = GetEquippedItemInfo(slotId)
    end

    local disabled = ((slotId == EQUIP_SLOT_BACKUP_MAIN) or (slotId == EQUIP_SLOT_BACKUP_OFF) or (slotId == EQUIP_SLOT_BACKUP_POISON)) and GetUnitLevel("player") < GetWeaponSwapUnlockedLevel()

    slotControl:SetMouseEnabled(not disabled)

    if disabled then
        iconControl:SetTexture("EsoUI/Art/CharacterWindow/weaponSwap_locked.dds")
    elseif(slotHasItem) then
        iconControl:SetTexture(iconFile)
        
        if(animationOption == PLAY_ANIMATION) then
            ZO_PlaySparkleAnimation(slotControl)
        end
    else
        iconControl:SetTexture(ZO_Character_GetEmptyEquipSlotTexture(slotId))
    end

    local stackCountLabel = GetControl(slotControl, "StackCount")
    if slotId == EQUIP_SLOT_POISON or slotId == EQUIP_SLOT_BACKUP_POISON then
        slotControl.stackCount = select(2, GetItemInfo(BAG_WORN, slotId))
        if (slotControl.stackCount > 1) then
            local USE_LOWERCASE_NUMBER_SUFFIXES = false
            stackCountLabel:SetText(zo_strformat(SI_NUMBER_FORMAT, ZO_AbbreviateNumber(slotControl.stackCount, NUMBER_ABBREVIATION_PRECISION_LARGEST_UNIT, USE_LOWERCASE_NUMBER_SUFFIXES)))
        else
            stackCountLabel:SetText("")
        end
    else
        slotControl.stackCount = slotHasItem and 1 or 0
        stackCountLabel:SetText("")
    end

    if not g_isReadOnly then
        if(not disabled and copyFromLinkedFn) then
            iconControl:SetDesaturation(0)
            iconControl:SetColor(1, 0, 0, .5)
        else
            iconControl:SetColor(1, 1, 1, 1)

            if(not disabled and locked) then
                iconControl:SetDesaturation(1)
            else
                iconControl:SetDesaturation(0)
            end
        end
    end
end

local function RefreshSingleSlot(slotId, slotControl, animationOption, updateReason)
    local linkData = heldSlotLinkage[slotId]
    local pullFromFn = nil

    -- If this slot links to or pulls from another slot, it must have the right fields
    -- in the heldSlotLinkage table.  If it doesn't, the data needs to be fixed up.
    if(linkData) then
        if(linkData.linksTo) then
            local animateLinkedSlot = animationOption
            
            if(updateReason == INVENTORY_UPDATE_REASON_ITEM_CHARGE) then
                animateLinkedSlot = false
            end
            RefreshSingleSlot(linkData.linksTo, slots[linkData.linksTo], animateLinkedSlot)
        elseif(linkData.pullFromConditionFn()) then
            pullFromFn = linkData.pullFromFn
            animationOption = NO_ANIMATION
        end
    end

    UpdateSlotAppearance(slotId, slotControl, animationOption, pullFromFn)

    if(not pullFromFn) then
        CALLBACK_MANAGER:FireCallbacks("WornSlotUpdate", slotControl)
    end
end

local function RefreshWornInventory()
    for slotId, slotControl in pairs(slots) do
        RefreshSingleSlot(slotId, slotControl)
    end
end

local function RefreshBackUpWeaponSlotStates()
    RefreshSingleSlot(EQUIP_SLOT_BACKUP_MAIN, ZO_CharacterEquipmentSlotsBackupMain)
    RefreshSingleSlot(EQUIP_SLOT_BACKUP_OFF, ZO_CharacterEquipmentSlotsBackupOff)
    RefreshSingleSlot(EQUIP_SLOT_BACKUP_POISON, ZO_CharacterEquipmentSlotsBackupPoison)
end

local function OnUnitCreated(eventCode, unitTag)
    if unitTag == "player" then
        ZO_CharacterPaperDoll:SetTexture(GetUnitSilhouetteTexture(unitTag))
        RefreshWornInventory()
        RefreshBackUpWeaponSlotStates()
    end
end

local function FullInventoryUpdated()
    RefreshWornInventory()
end

local function DoWornSlotUpdate(bagId, slotId, animationOption, updateReason)
    if bagId == BAG_WORN and slotId and slots[slotId] then
        RefreshSingleSlot(slotId, slots[slotId], animationOption, updateReason)
    end
end

local function InventorySlotUpdated(eventCode, bagId, slotId, isNewItem, itemSoundCategory, updateReason)
    DoWornSlotUpdate(bagId, slotId, PLAY_ANIMATION, updateReason)
end

local function InventorySlotLocked(eventCode, bagId, slotId)
    DoWornSlotUpdate(bagId, slotId)
end

local function InventorySlotUnlocked(eventCode, bagId, slotId)
    DoWornSlotUpdate(bagId, slotId)
end

local function HideAllEquipSlotDropCallouts()
    for equipSlot, slotControl in pairs(slots) do
        slotControl:GetNamedChild("DropCallout"):SetHidden(true)
    end
end

local function ShowSlotDropCallout(calloutControl, meetsUsageRequirement)
    calloutControl:SetHidden(false)

    if meetsUsageRequirement then
        calloutControl:SetColor(ZO_DEFAULT_ENABLED_COLOR:UnpackRGBA())
    else
        calloutControl:SetColor(ZO_ERROR_COLOR:UnpackRGBA())
    end
end

local function ShowAppropriateEquipSlotDropCallouts(bagId, slotIndex)
    HideAllEquipSlotDropCallouts()

    if ZO_Character_IsReadOnly() then
        return
    end

    local _, _, _, meetsUsageRequirement, _, equipType = GetItemInfo(bagId, slotIndex)

    for equipSlot, equipTypes in ZO_Character_EnumerateEquipSlotToEquipTypes() do
        local slotControl = slots[equipSlot]
        local locked = IsLockedWeaponSlot(equipSlot)
        if(slotControl and not locked) then
            for i = 1, #equipTypes do
                if(equipTypes[i] == equipType) then
                    ShowSlotDropCallout(slotControl:GetNamedChild("DropCallout"), meetsUsageRequirement)
                    break
                end
            end
        end
    end
end

local function HandleEquipSlotPickup(slotId)
    ShowAppropriateEquipSlotDropCallouts(BAG_WORN, slotId)
end

local function HandleInventorySlotPickup(bagId, slotId)
    ShowAppropriateEquipSlotDropCallouts(bagId, slotId)
end

local function HandleCursorPickup(eventCode, cursorType, param1, param2, param3)
    if(cursorType == MOUSE_CONTENT_EQUIPPED_ITEM) then
        HandleEquipSlotPickup(param1)
    elseif(cursorType == MOUSE_CONTENT_INVENTORY_ITEM) then
        HandleInventorySlotPickup(param1, param2)
    end
end

local function HandleCursorCleared()
    HideAllEquipSlotDropCallouts()
end

local function OnReadOnlyStateChanged(readOnly)
    for equipSlot, slotControl in pairs(slots) do
        RestoreMouseOverTexture(slotControl)

        --Make sure slots with a condition on them meet that condition.
        local linkData = heldSlotLinkage[equipSlot]
        local meetsRequirements = nil
        if linkData and linkData.pullFromConditionFn then
            meetsRequirements = not linkData.pullFromConditionFn()
        end

        ZO_ItemSlot_SetupUsableAndLockedColor(slotControl, meetsRequirements, readOnly)
    end
end

function ZO_Character_UpdateReadOnly()
    local readOnly = isDeadReadOnly or isShowingReadOnlyFragment

    if readOnly ~= g_isReadOnly then
        g_isReadOnly = readOnly
        OnReadOnlyStateChanged(g_isReadOnly)
        ZO_WeaponSwap_SetExternallyLocked(ZO_CharacterWeaponSwap, g_isReadOnly)
    end
end

function ZO_Character_IsReadOnly()
    return g_isReadOnly
end

function ZO_Character_SetIsShowingReadOnlyFragment(isReadOnly)
    isShowingReadOnlyFragment = isReadOnly
    ZO_Character_UpdateReadOnly()
end

local function OnPlayerDead()
    isDeadReadOnly = true
    ZO_Character_UpdateReadOnly()
end

local function OnPlayerAlive()
    isDeadReadOnly = false
    ZO_Character_UpdateReadOnly()
end

local function OnPlayerActivated()
    isDeadReadOnly = IsUnitDead("player")
end

function ZO_Character_Initialize(control)
    InitializeSlots()

    ZO_Character:RegisterForEvent(EVENT_UNIT_CREATED, OnUnitCreated)
    ZO_Character:RegisterForEvent(EVENT_INVENTORY_FULL_UPDATE, FullInventoryUpdated)
    ZO_Character:RegisterForEvent(EVENT_INVENTORY_SINGLE_SLOT_UPDATE, InventorySlotUpdated)
    ZO_Character:RegisterForEvent(EVENT_INVENTORY_SLOT_LOCKED, InventorySlotLocked)
    ZO_Character:RegisterForEvent(EVENT_INVENTORY_SLOT_UNLOCKED, InventorySlotUnlocked)
    ZO_Character:RegisterForEvent(EVENT_CURSOR_PICKUP, HandleCursorPickup)
    ZO_Character:RegisterForEvent(EVENT_CURSOR_DROPPED, HandleCursorCleared)
    ZO_Character:RegisterForEvent(EVENT_PLAYER_DEAD, OnPlayerDead)
    ZO_Character:RegisterForEvent(EVENT_PLAYER_ALIVE, OnPlayerAlive)
    ZO_Character:RegisterForEvent(EVENT_PLAYER_ACTIVATED, OnPlayerActivated)

    CALLBACK_MANAGER:RegisterCallback("BackpackFullUpdate", OnBackpackFullUpdate)
    CALLBACK_MANAGER:RegisterCallback("BackpackSlotUpdate", OnBackpackSlotUpdate)

    local function OnActiveWeaponPairChanged(event, activeWeaponPair)
        local unlockLevel = GetWeaponSwapUnlockedLevel()
        local playerLevel = GetUnitLevel("player")
        local disabled = playerLevel < unlockLevel

        ZO_CharacterEquipmentSlotsMainHandHighlight:SetHidden(disabled or activeWeaponPair ~= ACTIVE_WEAPON_PAIR_MAIN)
        ZO_CharacterEquipmentSlotsOffHandHighlight:SetHidden(disabled or activeWeaponPair ~= ACTIVE_WEAPON_PAIR_MAIN)
        ZO_CharacterEquipmentSlotsPoisonHighlight:SetHidden(disabled or activeWeaponPair ~= ACTIVE_WEAPON_PAIR_MAIN)

        ZO_CharacterEquipmentSlotsBackupMainHighlight:SetHidden(disabled or activeWeaponPair ~= ACTIVE_WEAPON_PAIR_BACKUP)
        ZO_CharacterEquipmentSlotsBackupOffHighlight:SetHidden(disabled or activeWeaponPair ~= ACTIVE_WEAPON_PAIR_BACKUP)
        ZO_CharacterEquipmentSlotsBackupPoisonHighlight:SetHidden(disabled or activeWeaponPair ~= ACTIVE_WEAPON_PAIR_BACKUP)
    end

    local function OnLevelUpdate(_, unitTag)
        if(unitTag == "player") then
            RefreshBackUpWeaponSlotStates()
            OnActiveWeaponPairChanged(nil, GetActiveWeaponPairInfo())
        end
    end

    ZO_Character:RegisterForEvent(EVENT_LEVEL_UPDATE, OnLevelUpdate)
    ZO_Character:RegisterForEvent(EVENT_ACTIVE_WEAPON_PAIR_CHANGED, OnActiveWeaponPairChanged)
    OnActiveWeaponPairChanged(nil, GetActiveWeaponPairInfo())

	local apparelHiddenLabel = control:GetNamedChild("ApparelHidden")
	apparelHiddenLabel:SetText(ZO_SELECTED_TEXT:Colorize(GetString(SI_HIDDEN_GENERAL)))

    OnUnitCreated(nil, "player")
end

local DEFAULT_STAT_SPACING = 5
local STAT_GROUP_SPACING = 25

local CHARACTER_STAT_CONTROLS = {}

function ZO_CharacterWindowStats_Initialize(control)
    local parentControl = control:GetNamedChild("ScrollScrollChild")
    local lastControl
    local nextPaddingY = 0
    for _, statGroup in ipairs(ZO_INVENTORY_STAT_GROUPS) do
        for _, stat in ipairs(statGroup) do
            local statControl = CreateControlFromVirtual("$(parent)StatEntry", parentControl, "ZO_StatsEntry", stat)
            CHARACTER_STAT_CONTROLS[stat] = statControl
            local relativeAnchorSide = (lastControl == nil) and TOP or BOTTOM
            statControl:SetAnchor(TOP, lastControl, relativeAnchorSide, 0, nextPaddingY)

            local statEntry = ZO_StatEntry_Keyboard:New(statControl, stat)
            statEntry.tooltipAnchorSide = LEFT
            lastControl = statControl
            nextPaddingY = DEFAULT_STAT_SPACING
        end
        nextPaddingY = STAT_GROUP_SPACING
    end
end

function ZO_CharacterWindowStats_ShowComparisonValues(bagId, slotId)
    local statDeltaLookup = ZO_GetStatDeltaLookupFromItemComparisonReturns(CompareBagItemToCurrentlyEquipped(bagId, slotId))
    for _, statGroup in ipairs(ZO_INVENTORY_STAT_GROUPS) do
        for _, stat in ipairs(statGroup) do
            local statDelta = statDeltaLookup[stat]
            if statDelta then
                local statControl = CHARACTER_STAT_CONTROLS[stat]
                statControl.statEntry:ShowComparisonValue(statDelta)
            end
        end
    end
end

function ZO_CharacterWindowStats_HideComparisonValues()
    for _, statGroup in ipairs(ZO_INVENTORY_STAT_GROUPS) do
        for _, stat in ipairs(statGroup) do
            local statControl = CHARACTER_STAT_CONTROLS[stat]
            statControl.statEntry:HideComparisonValue()
        end
    end
end
