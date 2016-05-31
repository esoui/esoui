ZO_TimeLockedDialog = ZO_Object:Subclass()

function ZO_TimeLockedDialog:New(...)
    local object = ZO_Object.New(self)
    object:Initialize(...)    
    return object
end

function ZO_TimeLockedDialog:Initialize(dialogName, dialogInfo, cooldownFunction)
    self.control = dialogInfo.customControl
    self.locked = GetControl(self.control, "Locked")
    self.unlocked = GetControl(self.control, "Unlocked")
    self.dialogName = dialogName
    self.cooldownFunction = cooldownFunction
    
    local function SetupTimeLockedDialog(dialog, data)
        self:InitializeDialog(data)
    end

    local function UpdateTimeLockedDialog(control, time)
        local isLocked = self:IsLocked()
        if(isLocked) then
            time = zo_floor(time)
            if(time ~= self.lastUpdateTime) then
                self.lastUpdateTime = time
                self:Refresh()
            end
        else
            if(self.wasLocked ~= isLocked) then
                self:Refresh()
            end
        end

        self.wasLocked = isLocked
    end
    
    dialogInfo.setup = SetupTimeLockedDialog
    dialogInfo.updateFn = UpdateTimeLockedDialog

    ZO_Dialogs_RegisterCustomDialog(dialogName, dialogInfo)
                       
end

function ZO_TimeLockedDialog:IsLocked()
    return self.cooldownFunction() > 0
end

function ZO_TimeLockedDialog:GetSecondsUntilUnlocked()
    return self.cooldownFunction()
end

function ZO_TimeLockedDialog:GetData()
    return self.data
end

function ZO_TimeLockedDialog:GetControl()
    return self.control
end

function ZO_TimeLockedDialog:Show(data)
    ZO_Dialogs_ShowDialog(self.dialogName, data)
end

function ZO_TimeLockedDialog:Hide()
    self.data = nil
    ZO_Dialogs_ReleaseDialogOnButtonPress(self.dialogName)
end

function ZO_TimeLockedDialog:InitializeDialog(data)
    self.data = data
    self.wasLocked = self:IsLocked()
    self.lastUpdateTime = 0
    self:Refresh()
end

function ZO_TimeLockedDialog:Refresh()
    local isLocked = self:IsLocked()
    if(isLocked) then
        self:SetupLocked(self.data)
    else
        self:SetupUnlocked(self.data)
    end

    self.locked:SetHidden(not isLocked)
    self.unlocked:SetHidden(isLocked)
end

function ZO_TimeLockedDialog:SetupUnlocked(data)
    
end

function ZO_TimeLockedDialog:SetupLocked(data)
    
end