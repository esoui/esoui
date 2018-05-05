--Siege HUD Fragment
--------------------

ZO_SiegeHUDFragment = ZO_SceneFragment:Subclass()

function ZO_SiegeHUDFragment:New()
    local fragment = ZO_SceneFragment.New(self)
    return fragment
end

function ZO_SiegeHUDFragment:Show()
    TUTORIAL_SYSTEM:SuppressTutorialType(TUTORIAL_TYPE_HUD_INFO_BOX, false, TUTORIAL_SUPPRESSED_BY_SCENE)
    SHARED_INFORMATION_AREA:SetSupressed(false)

    self:OnShown()
end

function ZO_SiegeHUDFragment:Hide()
    TUTORIAL_SYSTEM:SuppressTutorialType(TUTORIAL_TYPE_HUD_INFO_BOX, true, TUTORIAL_SUPPRESSED_BY_SCENE)
    SHARED_INFORMATION_AREA:SetSupressed(true)

    self:OnHidden()
end

SIEGE_HUD_FRAGMENT = ZO_SiegeHUDFragment:New()

--Siege Bar
----------------

local SiegeBar = ZO_Object:Subclass()

function SiegeBar:New()
    local manager = ZO_Object.New(self)

    manager:InitializeKeybindDescriptors()

    SIEGE_BAR_SCENE = ZO_Scene:New("siegeBar", SCENE_MANAGER)
    SIEGE_BAR_SCENE:RegisterCallback("StateChange",  function(oldState, newState)
        if(newState == SCENE_SHOWING) then
            KEYBIND_STRIP:RemoveDefaultExit()            
            KEYBIND_STRIP:AddKeybindButtonGroup(manager.keybindStripDescriptor)
        elseif(newState == SCENE_HIDDEN) then
            KEYBIND_STRIP:RemoveKeybindButtonGroup(manager.keybindStripDescriptor)
            KEYBIND_STRIP:RestoreDefaultExit()
        end
    end)

    SIEGE_BAR_UI_SCENE = ZO_Scene:New("siegeBarUI", SCENE_MANAGER)
    SIEGE_BAR_UI_SCENE:RegisterCallback("StateChange",  function(oldState, newState)
        if(newState == SCENE_SHOWING) then
            KEYBIND_STRIP:RemoveDefaultExit()
            KEYBIND_STRIP:AddKeybindButtonGroup(manager.UIModeKeybindStripDescriptor)
        elseif(newState == SCENE_HIDDEN) then
            KEYBIND_STRIP:RemoveKeybindButtonGroup(manager.UIModeKeybindStripDescriptor)
            KEYBIND_STRIP:RestoreDefaultExit()
        end
    end)

    EVENT_MANAGER:RegisterForEvent("SiegeBar", EVENT_BEGIN_SIEGE_CONTROL, function() manager:OnBeginSiegeControl() end)
    EVENT_MANAGER:RegisterForEvent("SiegeBar", EVENT_END_SIEGE_CONTROL, function() manager:OnEndSiegeControl() end)
    EVENT_MANAGER:RegisterForEvent("SiegeBar", EVENT_BEGIN_SIEGE_UPGRADE, function() manager:OnBeginSiegeUpgrade() end)
    EVENT_MANAGER:RegisterForEvent("SiegeBar", EVENT_ENABLE_SIEGE_PACKUP_ABILITY, function() manager:OnEnableSiegePackup() end)
    EVENT_MANAGER:RegisterForEvent("SiegeBar", EVENT_DISABLE_SIEGE_PACKUP_ABILITY, function() manager:OnDisableSiegePackup() end)
    EVENT_MANAGER:RegisterForEvent("SiegeBar", EVENT_ENABLE_SIEGE_FIRE_ABILITY, function() manager:OnEnableSiegeFire() end)
    EVENT_MANAGER:RegisterForEvent("SiegeBar", EVENT_DISABLE_SIEGE_FIRE_ABILITY, function() manager:OnDisableSiegeFire() end)
    EVENT_MANAGER:RegisterForEvent("SiegeBar", EVENT_GAMEPAD_PREFERRED_MODE_CHANGED, function(eventId, isGamepadPreferred) manager:OnGamepadPreferredModeChanged() end)
    
    manager.isDirty = true

    return manager
end

function SiegeBar:CleanDirty()
    if self.isDirty then
        self.isDirty = false
        self:SetupSceneFragments()
        self:RealignReleaseKeybind()
    end
end

function SiegeBar:SetupSceneFragments()
    if IsInGamepadPreferredMode() then
        SIEGE_BAR_SCENE:AddFragment(KEYBIND_STRIP_GAMEPAD_FRAGMENT)
        SIEGE_BAR_SCENE:RemoveFragment(KEYBIND_STRIP_FADE_FRAGMENT)

        SIEGE_BAR_UI_SCENE:AddFragment(KEYBIND_STRIP_GAMEPAD_FRAGMENT)
        SIEGE_BAR_UI_SCENE:RemoveFragment(KEYBIND_STRIP_FADE_FRAGMENT)
    else
        SIEGE_BAR_SCENE:AddFragment(KEYBIND_STRIP_FADE_FRAGMENT)
        SIEGE_BAR_SCENE:RemoveFragment(KEYBIND_STRIP_GAMEPAD_FRAGMENT)

        SIEGE_BAR_UI_SCENE:AddFragment(KEYBIND_STRIP_FADE_FRAGMENT)
        SIEGE_BAR_UI_SCENE:RemoveFragment(KEYBIND_STRIP_GAMEPAD_FRAGMENT)
    end
end

do
    -- Release
    local g_releaseKeybind =
    {
        name = GetString(SI_EXIT_BUTTON),
        keybind = "SIEGE_RELEASE",
        callback = function() SiegeWeaponRelease() end,
    }

    function SiegeBar:RealignReleaseKeybind()
        g_releaseKeybind.alignment = IsInGamepadPreferredMode() and KEYBIND_STRIP_ALIGN_CENTER or KEYBIND_STRIP_ALIGN_RIGHT
    end

    function SiegeBar:InitializeKeybindDescriptors()
        self:RealignReleaseKeybind()

        self.keybindStripDescriptor =
        {
            alignment = KEYBIND_STRIP_ALIGN_CENTER,

            -- Fire
            {
                name = GetString(SI_SIEGE_BAR_FIRE),
                keybind = "SIEGE_FIRE",        
                visible = function() return CanSiegeWeaponFire() end,
                callback = function() SiegeWeaponFire() end,
            },

            --Pack Up
            {
                name = GetString(SI_SIEGE_BAR_PACK_UP),
                keybind = "SIEGE_PACK_UP",
                visible = function() return CanSiegeWeaponPackUp() end,
                callback = function() SiegeWeaponPackUp() end,
            },
            g_releaseKeybind,
        }

        self.UIModeKeybindStripDescriptor =
        {
            g_releaseKeybind
        }
    end
end

--Events

function SiegeBar:OnBeginSiegeControl()    
    if(SCENE_MANAGER:IsShowingBaseScene()) then
        self:CleanDirty()
        SCENE_MANAGER:SetHUDScene("siegeBar")
        SCENE_MANAGER:SetHUDUIScene("siegeBarUI", true)
    else
        SiegeWeaponRelease()
    end
end

function SiegeBar:OnEndSiegeControl()
    SCENE_MANAGER:RestoreHUDScene()
    SCENE_MANAGER:RestoreHUDUIScene()
end

function SiegeBar:OnControlledSiegeSocketsChanged()
    --Update Ammo Display
end

function SiegeBar:OnBeginSiegeUpgrade()
    --Start Siege Socketing
end

function SiegeBar:OnEnableSiegePackup()
    KEYBIND_STRIP:UpdateKeybindButtonGroup(self.keybindStripDescriptor)
end

function SiegeBar:OnDisableSiegePackup()
    KEYBIND_STRIP:UpdateKeybindButtonGroup(self.keybindStripDescriptor)
end

function SiegeBar:OnEnableSiegeFire()
    KEYBIND_STRIP:UpdateKeybindButtonGroup(self.keybindStripDescriptor)
end

function SiegeBar:OnDisableSiegeFire()
    KEYBIND_STRIP:UpdateKeybindButtonGroup(self.keybindStripDescriptor)
end

function SiegeBar:OnGamepadPreferredModeChanged()
    self.isDirty = true
    SiegeWeaponRelease()
end

--Local XML

--Global XML

function ZO_SiegeBar_Initialize()
    SIEGE_BAR = SiegeBar:New()
end

ZO_SiegeBar_Initialize()