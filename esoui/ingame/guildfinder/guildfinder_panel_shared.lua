----------------------------
-- Guild Finder Panel --
----------------------------

ZO_GuildFinder_Panel_Shared = ZO_Object:Subclass()

function ZO_GuildFinder_Panel_Shared:New(...)
    local panel = ZO_Object.New(self)
    panel:Initialize(...)
    return panel
end

function ZO_GuildFinder_Panel_Shared:Initialize(control)
    self.control = control

    local ALWAYS_ANIMATE = true
    self.fragment = ZO_FadeSceneFragment:New(control, ALWAYS_ANIMATE)

    self.fragment:RegisterCallback("StateChange", function(oldState, newState)
        if newState == SCENE_FRAGMENT_SHOWING then
            self:OnShowing()
        elseif newState == SCENE_FRAGMENT_HIDING then
            self:OnHiding()
        elseif newState == SCENE_FRAGMENT_HIDDEN then
            self:OnHidden()
        end
    end)
end

function ZO_GuildFinder_Panel_Shared:OnShowing()
    -- override in derived classes
end

function ZO_GuildFinder_Panel_Shared:OnHiding()
    -- override in derived classes
end

function ZO_GuildFinder_Panel_Shared:OnHidden()
    -- override in derived classes
end

function ZO_GuildFinder_Panel_Shared:ShowCategory()
    SCENE_MANAGER:AddFragment(self.fragment)
end

function ZO_GuildFinder_Panel_Shared:HideCategory()
    SCENE_MANAGER:RemoveFragment(self.fragment)
end

function ZO_GuildFinder_Panel_Shared:GetFragment()
    return self.fragment
end