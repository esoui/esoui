ZO_WorldMapInfo_Shared = ZO_Object:Subclass()

function ZO_WorldMapInfo_Shared:New(...)
    local object = ZO_Object.New(self)
    object:Initialize(...)
    return object
end

function ZO_WorldMapInfo_Shared:Initialize(control, fragmentClass)
    self.control = control

    self.worldMapInfoFragment = fragmentClass:New(control)
    self.worldMapInfoFragment:RegisterCallback("StateChange", function(oldState, newState)
        if newState == SCENE_FRAGMENT_SHOWING then
            self:OnShowing()
        elseif newState == SCENE_FRAGMENT_HIDDEN then
            self:OnHidden()
        end
    end)

    self:InitializeTabs()
end

function ZO_WorldMapInfo_Shared:GetFragment()
    return self.worldMapInfoFragment
end

function ZO_WorldMapInfo_Shared:OnShowing()
    -- To be overridden
end

function ZO_WorldMapInfo_Shared:OnHidden()
    -- To be overridden
end