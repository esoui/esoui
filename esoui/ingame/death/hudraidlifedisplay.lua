local HUDRaidLifeManager = ZO_Object:Subclass()

function HUDRaidLifeManager:New(...)
    local object = ZO_Object.New(self)
    object:Initialize(...)
    return object
end

function HUDRaidLifeManager:Initialize(control)
    self.control = control
    self.displayObject = control:GetNamedChild("Reservoir").object
    self.displayObject:SetAnimatedShowHide(true)

    self:RefreshMode()

    ZO_PlatformStyle:New(function() self:ApplyPlatformStyle() end)

    EVENT_MANAGER:RegisterForEvent("HUDRaidLifeManager", EVENT_INTERFACE_SETTING_CHANGED, function(_, settingType, settingId)
        if(settingType == SETTING_TYPE_UI and settingId == UI_SETTING_SHOW_RAID_LIVES) then
            self:RefreshMode()
        end
    end)

end

function HUDRaidLifeManager:RefreshMode()
    local visibilitySetting = tonumber(GetSetting(SETTING_TYPE_UI, UI_SETTING_SHOW_RAID_LIVES))

    local showInSpecificSituations
    if(visibilitySetting == RAID_LIFE_VISIBILITY_CHOICE_OFF) then
        self.displayObject:SetHiddenForReason("disabled", true)
        showInSpecificSituations = false
    elseif(visibilitySetting == RAID_LIFE_VISIBILITY_CHOICE_AUTOMATIC) then
        self.displayObject:SetHiddenForReason("disabled", false)
        showInSpecificSituations = true
    elseif(visibilitySetting == RAID_LIFE_VISIBILITY_CHOICE_ON) then
        self.displayObject:SetHiddenForReason("disabled", false)
        showInSpecificSituations = false
    end

    self.displayObject:SetShowOnChange(showInSpecificSituations)
end

function HUDRaidLifeManager:SetHiddenForReason(reason, hidden)
    self.displayObject:SetHiddenForReason(reason, hidden)
end

function HUDRaidLifeManager:ApplyPlatformStyle()
    ApplyTemplateToControl(self.control, ZO_GetPlatformTemplate("ZO_HUDRaidLife"))
end

function ZO_HUDRaidLife_OnInitialized(self)
    HUD_RAID_LIFE = HUDRaidLifeManager:New(self)
end