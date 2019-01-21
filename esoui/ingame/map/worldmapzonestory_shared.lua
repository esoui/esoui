ZO_WORLD_MAP_ZONE_STORY_HIDE_REASONS =
{
    NO_DATA = 1,
    MAP_INFO_SHOWN = 2,
    KEEP_INFO_SHOWN = 3,
}

ZO_WorldMapZoneStory_Shared = ZO_Object:Subclass()

function ZO_WorldMapZoneStory_Shared:New(...)
    local object = ZO_Object.New(self)
    object:Initialize(...)
    return object
end

function ZO_WorldMapZoneStory_Shared:Initialize(control, fragmentClass)
    self.control = control
    self.currentZoneStoryZoneId = 0

    self:InitializeList()
    self:InitializeKeybindDescriptor()

    self.fragment = fragmentClass:New(control)
    self.fragment:RegisterCallback("StateChange", function(_, newState)
        if newState == SCENE_FRAGMENT_SHOWING then
            self:OnShowing()
        elseif newState == SCENE_FRAGMENT_HIDING then
            self:OnHiding()
        elseif newState == SCENE_FRAGMENT_HIDDEN then
            self:OnHidden()
        end
    end)
    ZO_MixinHideableSceneFragment(self.fragment)

    -- make sure to have the fragment hidden at the start
    -- since our current zone id is 0, that means we have no data
    self.fragment:SetHiddenForReason(ZO_WORLD_MAP_ZONE_STORY_HIDE_REASONS.NO_DATA, true)

    self:RegisterForEvents()
    self:RefreshZoneStoryZone()
end

function ZO_WorldMapZoneStory_Shared:InitializeList()
    -- To be overridden
end

function ZO_WorldMapZoneStory_Shared:InitializeKeybindDescriptor()
    -- To be overridden
end

function ZO_WorldMapZoneStory_Shared:RegisterForEvents()
    CALLBACK_MANAGER:RegisterCallback("OnWorldMapChanged", function()
        self:RefreshZoneStoryZone()
    end)
end

function ZO_WorldMapZoneStory_Shared:GetFragment()
    return self.fragment
end

function ZO_WorldMapZoneStory_Shared:IsShowing()
    return self.fragment:IsShowing()
end

function ZO_WorldMapZoneStory_Shared:GetBackgroundFragment()
    assert(false) -- Must be overriden
end

function ZO_WorldMapZoneStory_Shared:GetCurrentZoneStoryZoneId()
    return self.currentZoneStoryZoneId
end

function ZO_WorldMapZoneStory_Shared:RefreshZoneStoryZone()
    local oldZoneStoryZoneId = self.currentZoneStoryZoneId
    local currentZoneIndex = GetCurrentMapZoneIndex()
    self.currentZoneStoryZoneId = ZO_ExplorationUtils_GetZoneStoryZoneIdByZoneIndex(currentZoneIndex)
    if oldZoneStoryZoneId ~= self.currentZoneStoryZoneId then
        local hasData = ZONE_STORIES_MANAGER:GetZoneData(self.currentZoneStoryZoneId) ~= nil
        self.fragment:SetHiddenForReason(ZO_WORLD_MAP_ZONE_STORY_HIDE_REASONS.NO_DATA, not hasData)
        self:RefreshInfo()
    end
end

function ZO_WorldMapZoneStory_Shared:HasZoneStoryData()
    -- So that we're not dependent on order of which system registered for world map callbacks when, this function should always be forced to be up to date
    self:RefreshZoneStoryZone()
    return ZONE_STORIES_MANAGER:GetZoneData(self.currentZoneStoryZoneId) ~= nil
end

function ZO_WorldMapZoneStory_Shared:RefreshInfo()
    -- To be overridden
end

function ZO_WorldMapZoneStory_Shared:CanCycleTooltip()
    assert(false) -- Must be overriden, platform specific
end

function ZO_WorldMapZoneStory_Shared:OnShowing()
    local backgroundFragment = self:GetBackgroundFragment()
    if backgroundFragment then
        SCENE_MANAGER:AddFragment(backgroundFragment)
    end
    self:RefreshInfo()
end

function ZO_WorldMapZoneStory_Shared:OnHiding()
    local backgroundFragment = self:GetBackgroundFragment()
    if backgroundFragment then
        SCENE_MANAGER:RemoveFragment(self:GetBackgroundFragment())
    end
end

function ZO_WorldMapZoneStory_Shared:OnHidden()
    -- To be overridden
end