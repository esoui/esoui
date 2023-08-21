ZO_WorldMapInfo_Shared = ZO_InitializingObject:Subclass()

function ZO_WorldMapInfo_Shared:Initialize(control, fragmentClass)
    self.control = control

    self.worldMapInfoFragment = fragmentClass:New(control)
    self.worldMapInfoFragment:RegisterCallback("StateChange", function(oldState, newState)
        if newState == SCENE_FRAGMENT_SHOWING then
            self:OnShowing()
        elseif newState == SCENE_FRAGMENT_SHOWN then
            self:OnShown()
        elseif newState == SCENE_FRAGMENT_HIDING then
            self:OnHiding()
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
    -- Optional override
end

function ZO_WorldMapInfo_Shared:OnShown()
    -- Optional override
end

function ZO_WorldMapInfo_Shared:OnHiding()
    -- Optional override
end

function ZO_WorldMapInfo_Shared:OnHidden()
    -- Optional override
end