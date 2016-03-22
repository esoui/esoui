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
    self.randomInfo = {}
    self.areSpecificsInSubmenu = false
end

function ZO_ActivityFinderFilterModeData:GetActivityTypes()
    return self.activityTypes
end

--Describes how to populate the singular panel for a random (any) entry for the specified activity type.
--Will only generate a "random" entry if the activity type is both in randomInfo and activityTypes, and if DoesLFGActivityHasAllOption returns true for the activitiyType
function ZO_ActivityFinderFilterModeData:AddRandomInfo(activityType, description, keyboardBackground, gamepadBackground)
    self.randomInfo[activityType] =
    {
        description = description,
        keyboardBackground = keyboardBackground,
        gamepadBackground = gamepadBackground,
    }
end

function ZO_ActivityFinderFilterModeData:GetRandomInfo(activityType)
    return self.randomInfo[activityType]
end

function ZO_ActivityFinderFilterModeData:SetSubmenuFilterNames(specificFilterName, randomFilterName)
    self.specificFilterName = specificFilterName
    self.randomFilterName = randomFilterName
end

--If true, put specific activites into a list form and add a single entry to the filters to show this list.  Currently gamepad does this automatically, but that could change in the future
function ZO_ActivityFinderFilterModeData:SetSpecificsInSubmenu(areSpecificsInSubmenu)
    self.areSpecificsInSubmenu = areSpecificsInSubmenu
end

function ZO_ActivityFinderFilterModeData:AreSpecificsInSubmenu()
    return self.areSpecificsInSubmenu
end

function ZO_ActivityFinderFilterModeData:GetSpecificFilterName()
    return self.specificFilterName
end

function ZO_ActivityFinderFilterModeData:GetRandomFilterName()
    return self.randomFilterName
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
        self.keyboardObject = ZO_ActivityFinderTemplate_Keyboard:New(self, categoryData.keyboardData)
    end
    self.gamepadObject = ZO_ActivityFinderTemplate_Gamepad:New(self, categoryData.gamepadData)
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