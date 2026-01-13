ZO_AdventureZoneBossTree_Gamepad = ZO_Object.MultiSubclass(ZO_AdventureZoneBossTree_Shared, ZO_GamepadMultiFocusArea_Manager)

function ZO_AdventureZoneBossTree_Gamepad:Initialize(...)
    ZO_AdventureZoneBossTree_Shared.Initialize(self, ...)
    ZO_GamepadMultiFocusArea_Manager.Initialize(self, ...)

    local scene = self:GetScene()
    ADVENTURE_ZONE_BOSS_TREE_SCENE_GAMEPAD = scene
    SYSTEMS:RegisterGamepadRootScene("adventureZoneBossTree", scene)
end

function ZO_AdventureZoneBossTree_Gamepad:OnDeferredInitialize()
    ZO_AdventureZoneBossTree_Shared.OnDeferredInitialize(self)

    self:InitializeMultiFocusAreas()
    self:InitializeNarrationInfo()
end

function ZO_AdventureZoneBossTree_Gamepad:InitializeMultiFocusAreas()
    self.easyFocus = ZO_GamepadFocus:New(self.easyContainer, DEFAULT_MOVEMENT_CONTROLLER, MOVEMENT_CONTROLLER_DIRECTION_HORIZONTAL)
    self.mediumFocus = ZO_GamepadFocus:New(self.mediumContainer, DEFAULT_MOVEMENT_CONTROLLER, MOVEMENT_CONTROLLER_DIRECTION_HORIZONTAL)
    self.hardFocus = ZO_GamepadFocus:New(self.hardContainer, DEFAULT_MOVEMENT_CONTROLLER, MOVEMENT_CONTROLLER_DIRECTION_HORIZONTAL)
    -- Order matters for this loop
    for boss = ADVENTURE_ZONE_BOSS_ITERATION_BEGIN, ADVENTURE_ZONE_BOSS_ITERATION_END do
        local bossControl = self.bossControls[boss]
        local bossFocusData =
        {
            activate = function()
                self.selectedBoss = boss
                self:UpdateKeybinds()
                bossControl:GetNamedChild("SelectionBox"):SetAlpha(1)
                GAMEPAD_TOOLTIPS:LayoutAdventureZoneBossTooltip(GAMEPAD_RIGHT_TOOLTIP, boss)
                SCREEN_NARRATION_MANAGER:QueueCustomEntry("AdventureZoneBossTree")
            end,
            deactivate = function()
                self.previousBoss = self.selectedBoss
                self.selectedBoss = nil
                self:UpdateKeybinds()
                bossControl:GetNamedChild("SelectionBox"):SetAlpha(0)
                GAMEPAD_TOOLTIPS:ClearTooltip(GAMEPAD_RIGHT_TOOLTIP)
            end,
        }

        if boss < ADVENTURE_ZONE_BOSS_SKITTERING_INSTANCE_BOSS then
            self.easyFocus:AddEntry(bossFocusData)
        elseif boss < ADVENTURE_ZONE_BOSS_TRIAL_BOSS then
            self.mediumFocus:AddEntry(bossFocusData)
        else
            self.hardFocus:AddEntry(bossFocusData)
        end
    end

    local function EasyActivateCallback()
        self.easyFocus:Activate()
        local bossToSelect = self.easyFocus:GetFocus() or 1
        if self.previousBoss and self.previousBoss >= ADVENTURE_ZONE_BOSS_SKITTERING_INSTANCE_BOSS then
            bossToSelect = (self.previousBoss - 6) * 2 or ADVENTURE_ZONE_BOSS_SKITTERING_WORLD_BOSS_1
            -- Convert to Lua index.
            bossToSelect = bossToSelect + 1
        end

        self.easyFocus:SetFocusByIndex(bossToSelect)
    end

    local function EasyDeactivateCallback()
        self.easyFocus:Deactivate()
    end

    local function MediumActivateCallback()
        self.mediumFocus:Activate()

        local bossToSelect = self.mediumFocus:GetFocus() or 1
        if self.previousBoss and self.previousBoss < ADVENTURE_ZONE_BOSS_SKITTERING_INSTANCE_BOSS then
            bossToSelect = zo_floor((self.previousBoss / 2) + 1)
        end

        self.mediumFocus:SetFocusByIndex(bossToSelect)
    end

    local function MediumDeactivateCallback()
        self.mediumFocus:Deactivate()
    end

    local function HardActivateCallback()
        self.hardFocus:Activate()
    end

    local function HardDeactivateCallback()
        self.hardFocus:Deactivate()
    end

    self.easyFocusArea = ZO_GamepadMultiFocusArea_Base:New(self, EasyActivateCallback, EasyDeactivateCallback)
    self.mediumFocusArea = ZO_GamepadMultiFocusArea_Base:New(self, MediumActivateCallback, MediumDeactivateCallback)
    self.hardFocusArea = ZO_GamepadMultiFocusArea_Base:New(self, HardActivateCallback, HardDeactivateCallback)
    self:AddNextFocusArea(self.hardFocusArea)
    self:AddNextFocusArea(self.mediumFocusArea)
    self:AddNextFocusArea(self.easyFocusArea)
end

function ZO_AdventureZoneBossTree_Gamepad:InitializeNarrationInfo()
    local narrationInfo =
    {
        canNarrate = function()
            return self:IsShowing()
        end,

        headerNarrationFunction = function()
            return SCREEN_NARRATION_MANAGER:CreateNarratableObject(GetString(SI_ADVENTURE_ZONE_BOSS_TREE_TITLE))
        end,

        -- Selection narrated via tooltip
    }
    SCREEN_NARRATION_MANAGER:RegisterCustomObject("AdventureZoneBossTree", narrationInfo)
end

function ZO_AdventureZoneBossTree_Gamepad:OnShowing()
    ZO_AdventureZoneBossTree_Shared.OnShowing(self)

    if self:GetCurrentFocus() then
        self:ActivateCurrentFocus()
    else
        self:SelectFocusArea(self.easyFocusArea)
        self:ActivateFocusArea(self.easyFocusArea)
    end

    local NARRATE_HEADER = true
    SCREEN_NARRATION_MANAGER:QueueCustomEntry("AdventureZoneBossTree", NARRATE_HEADER)
    DIRECTIONAL_INPUT:Activate(self, self.control)
end

function ZO_AdventureZoneBossTree_Gamepad:OnHiding()
    ZO_AdventureZoneBossTree_Shared.OnHiding(self)

    self.previousBoss = nil
    self:DeactivateCurrentFocus()
    DIRECTIONAL_INPUT:Deactivate(self)
end

function ZO_AdventureZoneBossTree_Gamepad:GetSceneName()
    return "adventureZoneBossTreeGamepad"
end

function ZO_AdventureZoneBossTree_Gamepad.OnControlInitialized(control)
    ADVENTURE_ZONE_BOSS_TREE_GAMEPAD = ZO_AdventureZoneBossTree_Gamepad:New(control)
end