local PLAY_ANIMATION = true
local NO_ANIMATION = false

ZO_CompanionCharacterWindow_Keyboard = ZO_InitializingObject:Subclass()

function ZO_CompanionCharacterWindow_Keyboard:Initialize(control)
    self.control = control
    self.isReadOnly = false

    self:InitializeSlots()

    local apparelLabel = control:GetNamedChild("ApparelSectionText")
    local isApparelHidden = IsEquipSlotVisualCategoryHidden(EQUIP_SLOT_VISUAL_CATEGORY_APPAREL, GAMEPLAY_ACTOR_CATEGORY_COMPANION)
    local apparelString = isApparelHidden and GetString(SI_CHARACTER_EQUIP_APPAREL_HIDDEN) or GetString("SI_EQUIPSLOTVISUALCATEGORY", EQUIP_SLOT_VISUAL_CATEGORY_APPAREL)
    apparelLabel:SetText(apparelString)

    self:RegisterForEvents()

    COMPANION_CHARACTER_WINDOW_FRAGMENT = ZO_FadeSceneFragment:New(control)
end

function ZO_CompanionCharacterWindow_Keyboard:RegisterForEvents()
    local control = self.control

    local paperDollTexture = control:GetNamedChild("PaperDoll")
    local function OnActiveCompanionStateChanged()

            local companionId = GetActiveCompanionDefId()

            local companionGender = GetCompanionGender(companionId)
            local companionRaceId = GetCompanionRace(companionId)
            local paperDollTexture = self.control:GetNamedChild("PaperDoll")
            paperDollTexture:SetTexture(GetRaceAndGenderSilhouetteTexture(companionRaceId, companionGender))
        
        self:RefreshWornInventory()
    end

    control:RegisterForEvent(EVENT_ACTIVE_COMPANION_STATE_CHANGED, OnActiveCompanionStateChanged)
    OnActiveCompanionStateChanged()

    local function FullInventoryUpdated()
        self:RefreshWornInventory()
    end

    local function DoWornSlotUpdate(slotId, animationOption, updateReason)
        if slotId and self.slots[slotId] then
            self:RefreshSingleSlot(slotId, self.slots[slotId], animationOption, updateReason)
        end
    end

    local function InventorySlotUpdated(eventCode, bagId, slotId, isNewItem, itemSoundCategory, updateReason)
        DoWornSlotUpdate(slotId, PLAY_ANIMATION, updateReason)
    end

    local function InventorySlotLocked(eventCode, bagId, slotId)
        DoWornSlotUpdate(slotId)
    end

    local function InventorySlotUnlocked(eventCode, bagId, slotId)
        DoWornSlotUpdate(slotId)
    end

    control:RegisterForEvent(EVENT_INVENTORY_FULL_UPDATE, FullInventoryUpdated)

    control:RegisterForEvent(EVENT_INVENTORY_SINGLE_SLOT_UPDATE, InventorySlotUpdated)
    control:AddFilterForEvent(EVENT_INVENTORY_SINGLE_SLOT_UPDATE, REGISTER_FILTER_BAG_ID, BAG_COMPANION_WORN)

    control:RegisterForEvent(EVENT_INVENTORY_SLOT_LOCKED, InventorySlotLocked)
    control:AddFilterForEvent(EVENT_INVENTORY_SLOT_LOCKED, REGISTER_FILTER_BAG_ID, BAG_COMPANION_WORN)

    control:RegisterForEvent(EVENT_INVENTORY_SLOT_UNLOCKED, InventorySlotUnlocked)
    control:AddFilterForEvent(EVENT_INVENTORY_SLOT_UNLOCKED, REGISTER_FILTER_BAG_ID, BAG_COMPANION_WORN)

    local function HandleEquipSlotPickup(slotId)
        self:ShowAppropriateEquipSlotDropCallouts(BAG_COMPANION_WORN, slotId)
    end

    local function HandleInventorySlotPickup(bagId, slotId)
        self:ShowAppropriateEquipSlotDropCallouts(bagId, slotId)
    end

    local function HandleCursorPickup(eventCode, cursorType, param1, param2, param3)
        if cursorType == MOUSE_CONTENT_EQUIPPED_ITEM then
            HandleEquipSlotPickup(param1)
        elseif cursorType == MOUSE_CONTENT_INVENTORY_ITEM then
            HandleInventorySlotPickup(param1, param2)
        end
    end

    local function HandleCursorCleared()
        self:HideAllEquipSlotDropCallouts()
    end

    control:RegisterForEvent(EVENT_CURSOR_PICKUP, HandleCursorPickup)
    control:RegisterForEvent(EVENT_CURSOR_DROPPED, HandleCursorCleared)

    local function OnPlayerDead()
        local PLAYER_IS_DEAD = true
        self:UpdateReadOnly(PLAYER_IS_DEAD)
    end

    local function OnPlayerAlive()
        local PLAYER_IS_ALIVE = false
        self:UpdateReadOnly(PLAYER_IS_ALIVE)
    end

    local function OnPlayerActivated()
        self:UpdateReadOnly(IsUnitDead("player"))
    end

    control:RegisterForEvent(EVENT_PLAYER_DEAD, OnPlayerDead)
    control:RegisterForEvent(EVENT_PLAYER_ALIVE, OnPlayerAlive)
    control:RegisterForEvent(EVENT_PLAYER_ACTIVATED, OnPlayerActivated)
end

function ZO_CompanionCharacterWindow_Keyboard:InitializeSlots()
    local control = self.control
    self.slots =
    {
        [EQUIP_SLOT_HEAD]           = control:GetNamedChild("EquipmentSlotsHead"),
        [EQUIP_SLOT_NECK]           = control:GetNamedChild("EquipmentSlotsNeck"),
        [EQUIP_SLOT_CHEST]          = control:GetNamedChild("EquipmentSlotsChest"),
        [EQUIP_SLOT_SHOULDERS]      = control:GetNamedChild("EquipmentSlotsShoulder"),
        [EQUIP_SLOT_MAIN_HAND]      = control:GetNamedChild("EquipmentSlotsMainHand"),
        [EQUIP_SLOT_OFF_HAND]       = control:GetNamedChild("EquipmentSlotsOffHand"),
        [EQUIP_SLOT_WAIST]          = control:GetNamedChild("EquipmentSlotsBelt"),
        [EQUIP_SLOT_LEGS]           = control:GetNamedChild("EquipmentSlotsLeg"),
        [EQUIP_SLOT_FEET]           = control:GetNamedChild("EquipmentSlotsFoot"),
        [EQUIP_SLOT_RING1]          = control:GetNamedChild("EquipmentSlotsRing1"),
        [EQUIP_SLOT_RING2]          = control:GetNamedChild("EquipmentSlotsRing2"),
        [EQUIP_SLOT_HAND]           = control:GetNamedChild("EquipmentSlotsGlove"),
    }

    self.heldSlotLinkage =
    {
        [EQUIP_SLOT_MAIN_HAND] = { linksTo = EQUIP_SLOT_OFF_HAND },
        [EQUIP_SLOT_OFF_HAND] =
        {
            pullFromConditionFn = function()
                return GetItemEquipType(BAG_COMPANION_WORN, EQUIP_SLOT_MAIN_HAND) == EQUIP_TYPE_TWO_HAND
            end,
            pullFromFn = function()
                local slotHasItem, iconFile, _, _, isLocked = GetWornItemInfo(BAG_COMPANION_WORN, EQUIP_SLOT_MAIN_HAND)
                return slotHasItem, iconFile, isLocked
            end,
        },
    }

    local function RestoreMouseOverTexture(...)
        self:RestoreMouseOverTexture(...)
    end

    for equipSlot, slotControl in pairs(self.slots) do
        ZO_Inventory_BindSlot(slotControl, SLOT_TYPE_EQUIPMENT, equipSlot, BAG_COMPANION_WORN)
        slotControl.CustomOnStopCallback = RestoreMouseOverTexture
        ZO_CreateSparkleAnimation(slotControl)
    end
end

function ZO_CompanionCharacterWindow_Keyboard:UpdateSlotAppearance(equipSlot, slotControl, animationOption, copyFromLinkedFn)
    local slotHasItem, iconFile, isLocked

    if copyFromLinkedFn then
        slotHasItem, iconFile, isLocked = copyFromLinkedFn()
    else
        -- make _ local so it doesn't leak globally
        local _
        slotHasItem, iconFile, _, _, isLocked = GetWornItemInfo(BAG_COMPANION_WORN, equipSlot)
    end

    local iconControl = slotControl:GetNamedChild("Icon")
    if slotHasItem then
        iconControl:SetTexture(iconFile)

        if animationOption == PLAY_ANIMATION then
            ZO_PlaySparkleAnimation(slotControl)
        end
    else
        iconControl:SetTexture(ZO_Character_GetEmptyEquipSlotTexture(equipSlot))
    end

    -- need to set stack count so link in chat works
    slotControl.stackCount = slotHasItem and 1 or 0

    if not self:IsReadOnly() then
        local r, g, b, alpha = ZO_DEFAULT_ENABLED_COLOR:UnpackRGBA()
        local desaturation = 0

        if copyFromLinkedFn then
            r, g, b = ZO_ERROR_COLOR:UnpackRGB()
            alpha = 0.5
        elseif isLocked then
            desaturation = 1
        end

        iconControl:SetColor(r, g, b, alpha)
        iconControl:SetDesaturation(desaturation)
    end
end

do
    local MOUSE_OVER_TEXTURE = "EsoUI/Art/ActionBar/actionBar_mouseOver.dds"

    function ZO_CompanionCharacterWindow_Keyboard:RestoreMouseOverTexture(slotControl)
        slotControl:SetMouseOverTexture(not self:IsReadOnly() and MOUSE_OVER_TEXTURE or nil)
        slotControl:SetPressedMouseOverTexture(not self:IsReadOnly() and MOUSE_OVER_TEXTURE or nil)
        ZO_ResetSparkleAnimationColor(slotControl)
    end
end

function ZO_CompanionCharacterWindow_Keyboard:RefreshSingleSlot(equipSlot, slotControl, animationOption, updateReason)
    local linkData = self.heldSlotLinkage[equipSlot]
    local pullFromFn = nil

    -- If this slot links to or pulls from another slot, it must have the right fields
    -- in the heldSlotLinkage table.  If it doesn't, the data needs to be fixed up.
    if linkData then
        if linkData.linksTo then
            local animateLinkedSlot = animationOption

            if updateReason == INVENTORY_UPDATE_REASON_ITEM_CHARGE then
                animateLinkedSlot = false
            end
            self:RefreshSingleSlot(linkData.linksTo, self.slots[linkData.linksTo], animateLinkedSlot)
        elseif linkData.pullFromConditionFn() then
            pullFromFn = linkData.pullFromFn
            animationOption = NO_ANIMATION
        end
    end

    self:UpdateSlotAppearance(equipSlot, slotControl, animationOption, pullFromFn)

    if not pullFromFn then
        CALLBACK_MANAGER:FireCallbacks("WornSlotUpdate", slotControl)
    end
end

function ZO_CompanionCharacterWindow_Keyboard:RefreshWornInventory()
    for equipSlot, slotControl in pairs(self.slots) do
        self:RefreshSingleSlot(equipSlot, slotControl)
    end
end

function ZO_CompanionCharacterWindow_Keyboard:HideAllEquipSlotDropCallouts()
    for equipSlot, slotControl in pairs(self.slots) do
        slotControl:GetNamedChild("DropCallout"):SetHidden(true)
    end
end

function ZO_CompanionCharacterWindow_Keyboard:ShowSlotDropCallout(calloutControl, meetsUsageRequirement)
    calloutControl:SetHidden(false)

    if meetsUsageRequirement then
        calloutControl:SetColor(ZO_DEFAULT_ENABLED_COLOR:UnpackRGBA())
    else
        calloutControl:SetColor(ZO_ERROR_COLOR:UnpackRGBA())
    end
end

function ZO_CompanionCharacterWindow_Keyboard:ShowAppropriateEquipSlotDropCallouts(bagId, slotIndex)
    self:HideAllEquipSlotDropCallouts()

    if self:IsReadOnly() then
        return
    end

    local _, _, _, meetsUsageRequirement, _, equipType = GetItemInfo(bagId, slotIndex)

    for equipSlot, equipTypes in ZO_Character_EnumerateEquipSlotToEquipTypes() do
        local slotControl = self.slots[equipSlot]
        local isLocked = IsLockedWeaponSlot(equipSlot)
        if slotControl and not isLocked then
            for i = 1, #equipTypes do
                if equipTypes[i] == equipType then
                    self:ShowSlotDropCallout(slotControl:GetNamedChild("DropCallout"), meetsUsageRequirement)
                    break
                end
            end
        end
    end
end

function ZO_CompanionCharacterWindow_Keyboard:OnReadOnlyStateChanged()
    local readOnly = self:IsReadOnly()
    for equipSlot, slotControl in pairs(self.slots) do
        self:RestoreMouseOverTexture(slotControl)

        --Make sure slots with a condition on them meet that condition.
        local linkData = self.heldSlotLinkage[equipSlot]
        local meetsRequirements = true
        if linkData and linkData.pullFromConditionFn then
            meetsRequirements = not linkData.pullFromConditionFn()
        end

        ZO_ItemSlot_SetupUsableAndLockedColor(slotControl, meetsRequirements, readOnly)
    end
end

function ZO_CompanionCharacterWindow_Keyboard:UpdateReadOnly(isPlayerDead)
    -- currently readOnly is solely determined by whether the player is alive or not
    if isPlayerDead ~= self.isReadOnly then
        self.isReadOnly = isPlayerDead
        self:OnReadOnlyStateChanged()
    end
end

function ZO_CompanionCharacterWindow_Keyboard:IsReadOnly()
    return self.isReadOnly
end

function ZO_CompanionCharacterWindow_Keyboard_TopLevel_OnInitialized(control)
    COMPANION_WINDOW_KEYBOARD = ZO_CompanionCharacterWindow_Keyboard:New(control)
end
