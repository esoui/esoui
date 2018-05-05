-- Indicators
--------------

local WEAPON_INDICATOR = "WeaponIndicator"
local ARMOR_INDICATOR = "ArmorIndicator"


-- HUDIndicator
----------------

local HUDIndicator = ZO_Object:Subclass()

function HUDIndicator:New(control, data)
    local object = ZO_Object.New(self)
    object:Initialize(control, data)
    return object
end

function HUDIndicator:Initialize(control, data)
    self.control = control
    self.isNotifySoundQueued = false
    self.notifySound = data.notifySound
    self.tooltipString = data.tooltipString
    self.displaySetting = data.displaySetting
    self.refreshFunction = data.refreshFunction

    local function OnInterfaceSettingChanged(_, settingType, settingId)
        if settingType == SETTING_TYPE_UI then
            if settingId == self.displaySetting then
                self:Refresh()
            end
        end
    end
    control:RegisterForEvent(EVENT_INTERFACE_SETTING_CHANGED, OnInterfaceSettingChanged)

    self.control.indicator = self
end

function HUDIndicator:Refresh()
    local settingEnabled = tonumber(GetSetting(SETTING_TYPE_UI, self.displaySetting)) ~= 0
    local showIndicator = settingEnabled and (self.refreshFunction() == true)

    --Play notify sound if the equipment status changed (or queue sound to play later if the HUD is hidden)
    local wasHidden = self.control:IsHidden()
    if (wasHidden and showIndicator) then
        local shouldPlaySound = not self.control:GetParent():IsHidden()
        if shouldPlaySound then
            PlaySound(self.notifySound)
        else
            self.isNotifySoundQueued = true
        end
    elseif not showIndicator then
        self.isNotifySoundQueued = false
    end

    self.control:SetHidden(not showIndicator)
end

function HUDIndicator:TryPlayNotifySound()
    if self.isNotifySoundQueued then
        PlaySound(self.notifySound)
        self.isNotifySoundQueued = false
    end
end

function HUDIndicator:SetTooltip()
    InitializeTooltip(InformationTooltip, self.control, BOTTOM, 0, 0, TOP)
    SetTooltipText(InformationTooltip, self.tooltipString)
end

function HUDIndicator:ClearTooltip()
    ClearTooltip(InformationTooltip)
end

-- Global XML

function ZO_HUDEquipmentStatus_Indicator_OnMouseEnter(control)
    control.indicator:SetTooltip()
end

function ZO_HUDEquipmentStatus_Indicator_OnMouseExit(control)
    control.indicator:ClearTooltip()
end


-- HUDEquipmentStatus
----------------------

local ZO_HUDEquipmentStatus = ZO_Object:Subclass()

ZO_HUDEquipmentStatus.WEAPON_INDICATOR_DATA =
{
    tooltipString = GetString(SI_WEAPON_INDICATOR_TOOLTIP),
    notifySound = SOUNDS.HUD_WEAPON_DEPLETED,
    displaySetting = UI_SETTING_SHOW_WEAPON_INDICATOR,
    refreshFunction = function()

        local function IsEnchantmentEffectivenessReduced(bagId, slotId)
            local currentCharges, maxCharges = GetChargeInfoForItem(bagId, slotId)
            return maxCharges > 0 and currentCharges == 0
        end
        local activeWeaponPair = GetActiveWeaponPairInfo()
        local enchantmentIneffective = false
        local poisonEquipped = false

        if (activeWeaponPair == ACTIVE_WEAPON_PAIR_MAIN) then
            enchantmentIneffective = IsEnchantmentEffectivenessReduced(BAG_WORN, EQUIP_SLOT_MAIN_HAND) or IsEnchantmentEffectivenessReduced(BAG_WORN, EQUIP_SLOT_OFF_HAND)
            poisonEquipped = HasItemInSlot(BAG_WORN, EQUIP_SLOT_POISON)
        elseif (activeWeaponPair == ACTIVE_WEAPON_PAIR_BACKUP) then
            enchantmentIneffective = IsEnchantmentEffectivenessReduced(BAG_WORN, EQUIP_SLOT_BACKUP_MAIN) or IsEnchantmentEffectivenessReduced(BAG_WORN, EQUIP_SLOT_BACKUP_OFF)
            poisonEquipped = HasItemInSlot(BAG_WORN, EQUIP_SLOT_BACKUP_POISON)
        end

        return enchantmentIneffective and not poisonEquipped
    end,
}

ZO_HUDEquipmentStatus.ARMOR_INDICATOR_DATA =
{
    tooltipString = GetString(SI_ARMOR_INDICATOR_TOOLTIP),
    notifySound = SOUNDS.HUD_ARMOR_BROKEN,
    displaySetting = UI_SETTING_SHOW_ARMOR_INDICATOR,
    refreshFunction = function()
        local checkSlotBrokenCallback = function(slotId)
            if(DoesItemHaveDurability(BAG_WORN, slotId) and IsArmorEffectivenessReduced(BAG_WORN, slotId)) then
                return true
            end
        end
        return ZO_Inventory_EnumerateEquipSlots(checkSlotBrokenCallback) == true
    end,
}

function ZO_HUDEquipmentStatus:New(...)
    local object = ZO_Object.New(self)
    object:Initialize(...)
    return object
end

function ZO_HUDEquipmentStatus:Initialize(control)
    self.control = control
    self.indicators = {}
    self.indicators[WEAPON_INDICATOR] = HUDIndicator:New(GetControl(self.control, WEAPON_INDICATOR), ZO_HUDEquipmentStatus.WEAPON_INDICATOR_DATA)
    self.indicators[ARMOR_INDICATOR] = HUDIndicator:New(GetControl(self.control, ARMOR_INDICATOR), ZO_HUDEquipmentStatus.ARMOR_INDICATOR_DATA)

    self:UpdateAllIndicators()

    --Events
    local function OnInventorySingleSlotUpdate(bagId)
        if(bagId == BAG_WORN) then
            self:UpdateAllIndicators()
        end
    end

    local function OnWeaponSwitch()
        self.indicators[WEAPON_INDICATOR]:Refresh()
    end

    SHARED_INVENTORY:RegisterCallback("SingleSlotInventoryUpdate", OnInventorySingleSlotUpdate)
    EVENT_MANAGER:RegisterForEvent("ZO_HUDEquipmentStatus", EVENT_INVENTORY_FULL_UPDATE, function() self:UpdateAllIndicators() end)
    EVENT_MANAGER:RegisterForEvent("ZO_HUDEquipmentStatus", EVENT_ACTIVE_WEAPON_PAIR_CHANGED, OnWeaponSwitch)
    EVENT_MANAGER:RegisterForEvent("ZO_HUDEquipmentStatus", EVENT_PLAYER_ACTIVATED, function() self:UpdateAllIndicators() end)

    local KEYBOARD_STYLE =
    {
        template = "ZO_HUDEquipmentStatus_Keyboard_Template",
    }
    local GAMEPAD_STYLE =
    {
        template = "ZO_HUDEquipmentStatus_Gamepad_Template",
    }
    ZO_PlatformStyle:New(function(...) self:ApplyPlatformStyle(...) end, KEYBOARD_STYLE, GAMEPAD_STYLE)

    HUD_EQUIPMENT_STATUS_FRAGMENT = ZO_HUDFadeSceneFragment:New(control)
    HUD_EQUIPMENT_STATUS_FRAGMENT:RegisterCallback("StateChange", function(oldState, newState)
        if(newState == SCENE_FRAGMENT_SHOWING) then    
            self:OnShow()
        end
    end)
end

function ZO_HUDEquipmentStatus:OnShow()
    for _, indicator in pairs(self.indicators) do
        indicator:TryPlayNotifySound()
    end
end

function ZO_HUDEquipmentStatus:UpdateAllIndicators()
    for _, indicator in pairs(self.indicators) do
        indicator:Refresh()
    end
end

function ZO_HUDEquipmentStatus:ApplyPlatformStyle(styleTable)
    ApplyTemplateToControl(self.control, styleTable.template)
end

--Global XML

function ZO_HUDEquipmentStatus_Initialize(control)
    HUD_EQUIPMENT_STATUS = ZO_HUDEquipmentStatus:New(control)
end