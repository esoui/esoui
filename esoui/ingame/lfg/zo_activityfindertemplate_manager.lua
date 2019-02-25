--This data will determine how the screens are laid out and presented to the player.  It lets you control what goes into the dropdown and what goes into the list (keyboard)
--Or what goes into root list and what gets drilled down into a sub list (gamepad).  Should be initialized with any number of LFG activity types.
ZO_ActivityFinderFilterModeData = ZO_Object:Subclass()

function ZO_ActivityFinderFilterModeData:New(...)
    local manager = ZO_Object.New(self)
    manager:Initialize(...)
    return manager
end

function ZO_ActivityFinderFilterModeData:Initialize(...)
    self.activityTypes = { ... }
    self.areSpecificsInSubmenu = false
    self:SetVisibleEntryTypes(ZO_ACTIVITY_FINDER_LOCATION_ENTRY_TYPE.SPECIFIC, ZO_ACTIVITY_FINDER_LOCATION_ENTRY_TYPE.SET)
end

function ZO_ActivityFinderFilterModeData:GetActivityTypes()
    return self.activityTypes
end

function ZO_ActivityFinderFilterModeData:SetSubmenuFilterNames(specificFilterName, randomFilterName)
    self.specificFilterName = specificFilterName
    self.randomFilterName = randomFilterName
end

function ZO_ActivityFinderFilterModeData:GetSpecificFilterName()
    return self.specificFilterName
end

function ZO_ActivityFinderFilterModeData:GetRandomFilterName()
    return self.randomFilterName
end

function ZO_ActivityFinderFilterModeData:SetVisibleEntryTypes(...)
    self.visibleEntryTypes = { ... }
end

function ZO_ActivityFinderFilterModeData:GetVisibleEntryTypes()
    return self.visibleEntryTypes
end

function ZO_ActivityFinderFilterModeData:IsEntryTypeVisible(entryTypeToCheck)
    for _, entryType in ipairs(self.visibleEntryTypes) do
        if entryType == entryTypeToCheck then
            return true
        end
    end
    return false
end

------------------
--Initialization--
------------------

ZO_ActivityFinderTemplate_Manager = ZO_Object:Subclass()

function ZO_ActivityFinderTemplate_Manager:New(...)
    local manager = ZO_Object.New(self)
    manager:Initialize(...)
    return manager
end

function ZO_ActivityFinderTemplate_Manager:Initialize(name, categoryData, filterModeData)
    self.name = name
    self.filterModeData = filterModeData
    if not IsConsoleUI() then
        self.keyboardObject = ZO_ActivityFinderTemplate_Keyboard:New(self, categoryData.keyboardData, categoryData.priority)
    end
    self.gamepadObject = ZO_ActivityFinderTemplate_Gamepad:New(self, categoryData.gamepadData, categoryData.priority)
    self.lockingCooldownTypes = {}
end

function ZO_ActivityFinderTemplate_Manager:GetName()
    return self.name
end

function ZO_ActivityFinderTemplate_Manager:GetFilterModeData()
    return self.filterModeData
end

function ZO_ActivityFinderTemplate_Manager:GetKeyboardObject()
    return self.keyboardObject
end

function ZO_ActivityFinderTemplate_Manager:GetGamepadObject()
    return self.gamepadObject
end

function ZO_ActivityFinderTemplate_Manager:SetLockingCooldownTypes(...)
    self.lockingCooldownTypes = { ... }
end

function ZO_ActivityFinderTemplate_Manager:IsLockedByCooldown()
    for _, cooldownType in ipairs(self.lockingCooldownTypes) do
        if ZO_ACTIVITY_FINDER_ROOT_MANAGER:IsLFGCooldownTypeOnCooldown(cooldownType) then
            return true
        end
    end
    return false
end

do
    local VERBOSE_COOLDOWN_TEXT = true

    function ZO_ActivityFinderTemplate_Manager:GetCooldownLockText()
        for _, cooldownType in ipairs(self.lockingCooldownTypes) do
            if ZO_ACTIVITY_FINDER_ROOT_MANAGER:IsLFGCooldownTypeOnCooldown(cooldownType) then
                --if the text is a function, that means theres a timer involved that we want to refresh on update
                return function() return ZO_ACTIVITY_FINDER_ROOT_MANAGER:GetLFGCooldownLockText(cooldownType, VERBOSE_COOLDOWN_TEXT) end
            end
        end
        return nil
    end
end

function ZO_ActivityFinderTemplate_Manager:GetManagerLockInfo()
    local isManagerLocked = false
    local managerLockReasons =
    {
        isLockedByCooldown = self:IsLockedByCooldown()
    }

    for _, reason in pairs(managerLockReasons) do
        if reason == true then
            isManagerLocked = true
            break
        end
    end

    return isManagerLocked, managerLockReasons
end

function ZO_ActivityFinderTemplate_Manager:GetManagerLockText()
    local isManagerLocked, managerLockReasons = self:GetManagerLockInfo()
    local lockReasonText
    if isManagerLocked then
        if managerLockReasons.isLockedByCooldown then
            lockReasonText = self:GetCooldownLockText()
        end
    end
    return lockReasonText
end