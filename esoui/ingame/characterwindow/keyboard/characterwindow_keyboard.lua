local g_isReadOnly = false
local isDeadReadOnly = false
local isShowingReadOnlyFragment = false

local g_areEffectsDirty = true
local g_mundusStonesStatEntry = nil

local MOUSE_OVER_TEXTURE = "EsoUI/Art/ActionBar/actionBar_mouseOver.dds"

local function RestoreMouseOverTexture(slotControl)
    slotControl:SetMouseOverTexture(not ZO_Character_IsReadOnly() and MOUSE_OVER_TEXTURE or nil)
    slotControl:SetPressedMouseOverTexture(not ZO_Character_IsReadOnly() and MOUSE_OVER_TEXTURE or nil)
    ZO_ResetSparkleAnimationColor(slotControl)
end

local slots = nil
local heldSlotLinkage = nil

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
                return GetItemEquipType(BAG_WORN, EQUIP_SLOT_MAIN_HAND) == EQUIP_TYPE_TWO_HAND
            end,
            pullFromFn =    function()
                local slotHasItem, iconFile, _, _, locked = GetWornItemInfo(BAG_WORN, EQUIP_SLOT_MAIN_HAND)
                return iconFile, slotHasItem, locked
            end,
        },

        [EQUIP_SLOT_BACKUP_OFF] =
        {
            pullFromConditionFn =   function()
                return GetItemEquipType(BAG_WORN, EQUIP_SLOT_BACKUP_MAIN) == EQUIP_TYPE_TWO_HAND 
            end,
            pullFromFn =    function()
                local slotHasItem, iconFile, _, _, locked = GetWornItemInfo(BAG_WORN, EQUIP_SLOT_BACKUP_MAIN)
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

local CHARACTER_WINDOW_TOOLTIP_ANCHOR_SIDE = LEFT
local CHARACTER_STAT_CONTROLS = {}

local function UpdateSlotAppearance(slotId, slotControl, animationOption, copyFromLinkedFn)
    local iconControl = slotControl:GetNamedChild("Icon")
    local slotHasItem, iconFile, locked

    if copyFromLinkedFn then
        iconFile, slotHasItem, locked = copyFromLinkedFn()
    else
        -- make _ local so it doesn't leak globally
        local _
        slotHasItem, iconFile, _, _, locked = GetWornItemInfo(BAG_WORN, slotId)
    end

    local disabled = ((slotId == EQUIP_SLOT_BACKUP_MAIN) or (slotId == EQUIP_SLOT_BACKUP_OFF) or (slotId == EQUIP_SLOT_BACKUP_POISON)) and GetUnitLevel("player") < GetWeaponSwapUnlockedLevel()

    slotControl:SetMouseEnabled(not disabled)

    if disabled then
        iconControl:SetTexture("EsoUI/Art/CharacterWindow/weaponSwap_locked.dds")
    elseif slotHasItem then
        iconControl:SetTexture(iconFile)

        if animationOption == PLAY_ANIMATION then
            ZO_PlaySparkleAnimation(slotControl)
        end
    else
        iconControl:SetTexture(ZO_Character_GetEmptyEquipSlotTexture(slotId))
    end

    local stackCountLabel = GetControl(slotControl, "StackCount")
    if slotId == EQUIP_SLOT_POISON or slotId == EQUIP_SLOT_BACKUP_POISON then
        slotControl.stackCount = select(2, GetItemInfo(BAG_WORN, slotId))
        if slotControl.stackCount > 1 then
            local USE_LOWERCASE_NUMBER_SUFFIXES = false
            stackCountLabel:SetText(ZO_AbbreviateAndLocalizeNumber(slotControl.stackCount, NUMBER_ABBREVIATION_PRECISION_LARGEST_UNIT, USE_LOWERCASE_NUMBER_SUFFIXES))
        else
            stackCountLabel:SetText("")
        end
    else
        slotControl.stackCount = slotHasItem and 1 or 0
        stackCountLabel:SetText("")
    end

    if not disabled and copyFromLinkedFn then
        iconControl:SetDesaturation(0)
        local r, g, b = ZO_ERROR_COLOR:UnpackRGB()
        iconControl:SetColor(r, g, b, 0.5)
    else
        local alpha = g_isReadOnly and 0.5 or 1
        local r, g, b = ZO_WHITE:UnpackRGB()
        iconControl:SetColor(r, g, b, alpha)

        if not disabled and locked then
            iconControl:SetDesaturation(1)
        else
            iconControl:SetDesaturation(0)
        end
    end
end

local function RefreshSingleSlot(slotId, slotControl, animationOption, updateReason)
    local linkData = heldSlotLinkage[slotId]
    local pullFromFn = nil

    -- If this slot links to or pulls from another slot, it must have the right fields
    -- in the heldSlotLinkage table.  If it doesn't, the data needs to be fixed up.
    if linkData then
        if linkData.linksTo then
            local animateLinkedSlot = animationOption

            if updateReason == INVENTORY_UPDATE_REASON_ITEM_CHARGE or updateReason == INVENTORY_UPDATE_REASON_PLAYER_LOCKED then
                animateLinkedSlot = false
            end
            RefreshSingleSlot(linkData.linksTo, slots[linkData.linksTo], animateLinkedSlot)
        elseif linkData.pullFromConditionFn() then
            pullFromFn = linkData.pullFromFn
            animationOption = NO_ANIMATION
        end
    end

    UpdateSlotAppearance(slotId, slotControl, animationOption, pullFromFn)

    if not pullFromFn then
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
    ZO_Character_UpdateEffects()
end

local function DoWornSlotUpdate(bagId, slotId, animationOption, updateReason)
    if bagId == BAG_WORN and slotId and slots[slotId] then
        RefreshSingleSlot(slotId, slots[slotId], animationOption, updateReason)
    end
end

local function InventorySlotUpdated(eventCode, bagId, slotId, isNewItem, itemSoundCategory, updateReason)
    DoWornSlotUpdate(bagId, slotId, PLAY_ANIMATION, updateReason)
    ZO_Character_UpdateEffects()
end

local function InventoryEquipMythicFailed(eventCode, bagId, slotId)
    local mythicColor = GetItemQualityColor(ITEM_DISPLAY_QUALITY_MYTHIC_OVERRIDE)
    ZO_PlayColorSparkleAnimation(slots[slotId], mythicColor)
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
        if slotControl and not locked then
            for i = 1, #equipTypes do
                if equipTypes[i] == equipType then
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
    if cursorType == MOUSE_CONTENT_EQUIPPED_ITEM then
        HandleEquipSlotPickup(param1)
    elseif cursorType == MOUSE_CONTENT_INVENTORY_ITEM then
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

function ZO_Character_UpdateEffects()
    if not (g_mundusStonesStatEntry and not CHARACTER_WINDOW_HEADER_FRAGMENT:IsHidden()) then
        g_areEffectsDirty = true
        return
    end
    g_areEffectsDirty = false

    local mundusIconControls =
    {
        g_mundusStonesStatEntry.mundus1,
        g_mundusStonesStatEntry.mundus2,
    }
    local function GetDerivedStatByTypeFunction(statType)
        return CHARACTER_STAT_CONTROLS[statType]
    end

    -- Reset all stats to have no mundus icons
    for _, control in pairs(CHARACTER_STAT_CONTROLS) do
        control.statEntry:SetHasMundusEffect(false)
        control.statEntry:UpdateStatValue()
    end

    ZO_SharedStats_SetupMundusIconControls(mundusIconControls, CHARACTER_WINDOW_TOOLTIP_ANCHOR_SIDE, 5, GetDerivedStatByTypeFunction)
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
    ZO_Character:RegisterForEvent(EVENT_INVENTORY_EQUIP_MYTHIC_FAILED, InventoryEquipMythicFailed)
    ZO_Character:RegisterForEvent(EVENT_INVENTORY_SLOT_LOCKED, InventorySlotLocked)
    ZO_Character:RegisterForEvent(EVENT_INVENTORY_SLOT_UNLOCKED, InventorySlotUnlocked)
    ZO_Character:RegisterForEvent(EVENT_CURSOR_PICKUP, HandleCursorPickup)
    ZO_Character:RegisterForEvent(EVENT_CURSOR_DROPPED, HandleCursorCleared)
    ZO_Character:RegisterForEvent(EVENT_PLAYER_DEAD, OnPlayerDead)
    ZO_Character:RegisterForEvent(EVENT_PLAYER_ALIVE, OnPlayerAlive)
    ZO_Character:RegisterForEvent(EVENT_PLAYER_ACTIVATED, OnPlayerActivated)
    ZO_Character:RegisterForEvent(EVENT_EFFECT_CHANGED, ZO_Character_UpdateEffects)
    ZO_Character:RegisterForEvent(EVENT_ATTRIBUTE_UPGRADE_UPDATED, ZO_Character_UpdateEffects)

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
        if unitTag == "player" then
            RefreshBackUpWeaponSlotStates()
            OnActiveWeaponPairChanged(nil, GetActiveWeaponPairInfo())
        end
    end

    ZO_Character:RegisterForEvent(EVENT_LEVEL_UPDATE, OnLevelUpdate)
    ZO_Character:RegisterForEvent(EVENT_ACTIVE_WEAPON_PAIR_CHANGED, OnActiveWeaponPairChanged)
    OnActiveWeaponPairChanged(nil, GetActiveWeaponPairInfo())

    local apparelText = control:GetNamedChild("ApparelSectionText")
    local isApparelHidden = IsEquipSlotVisualCategoryHidden(EQUIP_SLOT_VISUAL_CATEGORY_APPAREL, GAMEPLAY_ACTOR_CATEGORY_PLAYER)
    local apparelString = isApparelHidden and GetString(SI_CHARACTER_EQUIP_APPAREL_HIDDEN) or GetString("SI_EQUIPSLOTVISUALCATEGORY", EQUIP_SLOT_VISUAL_CATEGORY_APPAREL)
    apparelText:SetText(apparelString)

    local headerSection = control:GetNamedChild("HeaderSection")
    CHARACTER_WINDOW_HEADER_FRAGMENT = ZO_SimpleSceneFragment:New(headerSection)

    OnUnitCreated(nil, "player")
end

local DEFAULT_STAT_SPACING = 0
local STAT_GROUP_SPACING = 20
local STAT_GROUP_OFFSET_X = 10

function ZO_CharacterWindowStats_Initialize(control)
    local parentControl = control:GetNamedChild("ScrollScrollChild")
    local lastControl = nil
    local nextPaddingY = 0
    for _, statGroup in ipairs(ZO_INVENTORY_STAT_GROUPS) do
        for _, stat in ipairs(statGroup) do
            local statControl = CreateControlFromVirtual("$(parent)StatEntry", parentControl, "ZO_StatsEntry", stat)
            CHARACTER_STAT_CONTROLS[stat] = statControl

            if lastControl then
                statControl:SetAnchor(TOP, lastControl, BOTTOM, 0, nextPaddingY)
            else
                statControl:SetAnchor(TOP, lastControl, TOP, STAT_GROUP_OFFSET_X, nextPaddingY)
            end

            local statEntry = ZO_StatEntry_Keyboard:New(statControl, stat)
            statEntry.tooltipAnchorSide = CHARACTER_WINDOW_TOOLTIP_ANCHOR_SIDE
            lastControl = statControl
            nextPaddingY = DEFAULT_STAT_SPACING
        end
        nextPaddingY = STAT_GROUP_SPACING
    end

    do
        -- Add Mundus Stones stat entry.
        local MUNDUS_PADDING = 10
        local statControl = CreateControlFromVirtual("$(parent)ZO_MundusStonesStatsEntry", parentControl, "ZO_MundusStonesStatsEntry")
        g_mundusStonesStatEntry = statControl
        statControl:SetAnchor(TOP, lastControl, BOTTOM, 0, MUNDUS_PADDING)
    end
end

do
    local keybindButtons =
    {
        {
            alignment = KEYBIND_STRIP_ALIGN_RIGHT,
            name = GetString(SI_STATS_MUNDUS_INFO_BUTTON),
            keybind = "UI_SHORTCUT_PRIMARY",
            callback = function()
                local helpCategoryIndex, helpIndex = GetMundusStoneHelpIndices()
                HELP:ShowSpecificHelp(helpCategoryIndex, helpIndex)
            end,
        },
    }

    function ZO_CharacterWindowStats_RefreshKeybinds()
        if g_mundusStonesStatEntry and not CHARACTER_WINDOW_HEADER_FRAGMENT:IsHidden() and ZO_StatsMundus_ShouldShowHelpKeybind then
            if KEYBIND_STRIP:HasKeybindButtonGroup(keybindButtons) then
                KEYBIND_STRIP:UpdateKeybindButtonGroup(keybindButtons)
            else
                KEYBIND_STRIP:AddKeybindButtonGroup(keybindButtons)
            end
        else
            KEYBIND_STRIP:RemoveKeybindButtonGroup(keybindButtons)
        end
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

function ZO_CharacterWindowStats_ShowMundusComparisonValues(statEffects)
    for _, statGroup in ipairs(ZO_INVENTORY_STAT_GROUPS) do
        for _, stat in ipairs(statGroup) do
            for _, data in ipairs(statEffects) do
                if stat == data.statType then
                    local EXCLUDE_DELTA = true
                    local statControl = CHARACTER_STAT_CONTROLS[stat]
                    statControl.statEntry:ShowComparisonValue(data.effect, EXCLUDE_DELTA)
                end
            end
        end
    end
end