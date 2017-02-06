local ZO_HUDFragment = ZO_SceneFragment:Subclass()

function ZO_HUDFragment:New(...)
    return ZO_SceneFragment.New(self, ...)
end

function ZO_HUDFragment:Initialize(...)
    ZO_SceneFragment.Initialize(self, ...)

    EVENT_MANAGER:RegisterForEvent("HUDFragment", EVENT_PLAYER_DEAD, function() self:UpdateVisibility() end)
    EVENT_MANAGER:RegisterForEvent("HUDFragment", EVENT_PLAYER_ALIVE, function() self:UpdateVisibility() end)
end

function ZO_HUDFragment:UpdateVisibility()
    if(self:GetState() == SCENE_FRAGMENT_HIDDEN) then
        return
    end

    local fragmentHidden = not self:IsShowing()
    local playerDead = IsUnitDead("player")
    local hiddenOrDead = fragmentHidden or playerDead

    COMPASS_FRAME:SetCompassHidden(playerDead)

    ZO_PlayerToPlayerArea:SetHidden(fragmentHidden)
    TUTORIAL_SYSTEM:SuppressTutorialType(TUTORIAL_TYPE_HUD_INFO_BOX, fragmentHidden, TUTORIAL_SUPPRESSED_BY_SCENE)
    INSTANCE_KICK_WARNING_DEAD:SetHiddenForReason("hudScene", fragmentHidden)
    HUD_RAID_LIFE:SetHiddenForReason("hudScene", fragmentHidden)

    OBJECTIVE_CAPTURE_METER:SetHiddenForReason("hudScene", hiddenOrDead)
    SetFloatingMarkerGlobalAlpha(hiddenOrDead and 0 or 1)
    SHARED_INFORMATION_AREA:SetSupressed(hiddenOrDead)
    RETICLE:RequestHidden(hiddenOrDead)
    HUD_INFAMY_METER:RequestHidden(hiddenOrDead)
    HUD_TELVAR_METER:SetHiddenForReason("hudScene", hiddenOrDead)
end

function ZO_HUDFragment:Show()
    self:UpdateVisibility()
    self:OnShown()
end

function ZO_HUDFragment:Hide()
    self:UpdateVisibility()
    self:OnHidden()
end

HUD_FRAGMENT = ZO_HUDFragment:New()

------------------------
--Reticle Mode Fragment
------------------------

local ZO_ReticleModeFragment = ZO_SceneFragment:Subclass()

function ZO_ReticleModeFragment:New()
    return ZO_SceneFragment.New(self)
end

function ZO_ReticleModeFragment:Show()
    ZO_PlayerToPlayerArea:SetHidden(false)
    self:OnShown()
end

function ZO_ReticleModeFragment:Hide()
    ZO_PlayerToPlayerArea:SetHidden(true)
    self:OnHidden()
end

local RETICLE_MODE_FRAGMENT = ZO_ReticleModeFragment:New()

----------------
--HUD Fragments
----------------

local HUD_FRAGMENT_GROUP =
{
    DEATH_RECAP_FRAGMENT,
    PLAYER_PROGRESS_BAR_FRAGMENT,
    COMPASS_FRAME_FRAGMENT,
    FOCUSED_QUEST_TRACKER_FRAGMENT,
    ACTIVITY_TRACKER_FRAGMENT,
    READY_CHECK_TRACKER_FRAGMENT,
    ACTION_BAR_FRAGMENT,
    HUD_EQUIPMENT_STATUS_FRAGMENT,
    CONTEXTUAL_ACTION_BAR_AREA_FRAGMENT,
    HUD_FRAGMENT,
    DEATH_FRAGMENT,
    UNIT_FRAMES_FRAGMENT,
    PLAYER_ATTRIBUTE_BARS_FRAGMENT,
    PERFORMANCE_METER_FRAGMENT,
    PLAYER_PROGRESS_BAR_GAMEPAD_HIDE_NAME_LOCATION_FRAGMENT,
    SUBTITLE_HUD_FRAGMENT,
    GAMEPAD_LOOT_HISTORY_FRAGMENT,
    KEYBOARD_LOOT_HISTORY_FRAGMENT,
    HOUSING_HUD_FRAGMENT,
}

if IsConsoleUI() then
    table.insert(HUD_FRAGMENT_GROUP, GAMEPAD_TEXT_CHAT_FRAGMENT)
end

local NO_DEAD_FRAGMENTS =
{
    FOCUSED_QUEST_TRACKER_FRAGMENT,
    ACTIVITY_TRACKER_FRAGMENT,
    READY_CHECK_TRACKER_FRAGMENT,
    ACTION_BAR_FRAGMENT,
    HUD_EQUIPMENT_STATUS_FRAGMENT,
    CONTEXTUAL_ACTION_BAR_AREA_FRAGMENT,
    PLAYER_ATTRIBUTE_BARS_FRAGMENT,
    SUBTITLE_HUD_FRAGMENT,
    HOUSING_HUD_FRAGMENT,
}

local DEAD_ONLY_FRAGMENTS =
{
    DEATH_FRAGMENT,
}

local function UpdateDeathFragments()
    local playerDead = IsUnitDead("player")
    for _, fragment in ipairs(NO_DEAD_FRAGMENTS) do
        fragment:SetHiddenForReason("Dead", playerDead)
    end
    for _, fragment in ipairs(DEAD_ONLY_FRAGMENTS) do
        fragment:SetHiddenForReason("Dead", not playerDead)
    end
end

EVENT_MANAGER:RegisterForEvent("HUDFragments", EVENT_PLAYER_DEAD, UpdateDeathFragments)
EVENT_MANAGER:RegisterForEvent("HUDFragments", EVENT_PLAYER_ALIVE, UpdateDeathFragments)
UpdateDeathFragments()

local HOUSING_ONLY_FRAGMENTS =
{
    HOUSING_HUD_FRAGMENT,
}

local function UpdateHousingFragments()
    local isHousingZone = GetCurrentZoneHouseId() ~= 0
    for _, fragment in ipairs(HOUSING_ONLY_FRAGMENTS) do
        fragment:SetHiddenForReason("Housing", not isHousingZone)
    end
end


EVENT_MANAGER:RegisterForEvent("HUDFragments", EVENT_PLAYER_ACTIVATED, UpdateHousingFragments)

---------------
--ZO_HUDScene
---------------

ZO_HUDScene = ZO_Scene:Subclass()

function ZO_HUDScene:New()
    local scene = ZO_Scene.New(self, "hud", SCENE_MANAGER)
    scene:AddFragment(RETICLE_MODE_FRAGMENT)
    scene:AddFragmentGroup(HUD_FRAGMENT_GROUP)
    return scene
end

HUD_SCENE = ZO_HUDScene:New()

----------------
--ZO_HUDUIScene
----------------

ZO_HUDUIScene = ZO_Scene:Subclass()

function ZO_HUDUIScene:New()
    local scene = ZO_Scene.New(self, "hudui", SCENE_MANAGER)
    scene:AddFragment(MOUSE_UI_MODE_FRAGMENT)
    scene:AddFragmentGroup(HUD_FRAGMENT_GROUP)

    return scene
end

HUD_UI_SCENE = ZO_HUDUIScene:New()

-----------------------
--Loot Scene
-----------------------

LOOT_SCENE:AddFragmentGroup(FRAGMENT_GROUP.MOUSE_DRIVEN_UI_WINDOW_NO_COMBAT_OVERLAY)
LOOT_SCENE:AddFragment(LOOT_WINDOW_FRAGMENT)
LOOT_SCENE:AddFragmentGroup(HUD_FRAGMENT_GROUP)
LOOT_SCENE:AddFragment(FRAME_EMOTE_FRAGMENT_LOOT)
LOOT_SCENE:AddFragment(PLAYER_PROGRESS_BAR_FRAGMENT)