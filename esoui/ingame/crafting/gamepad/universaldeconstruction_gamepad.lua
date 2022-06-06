ZO_UniversalDeconstruction_Gamepad = ZO_Smithing_Common:Subclass()

function ZO_UniversalDeconstruction_Gamepad:Initialize(control)
    ZO_Smithing_Common.Initialize(self, control)

    self.mode = SMITHING_MODE_DECONSTRUCTION
    self.craftingTypes = ZO_UNIVERSAL_DECONSTRUCTION_CRAFTING_TYPES
    self.floatingControl = self.control:GetNamedChild("Floating")
    self.maskControl = self.control:GetNamedChild("Mask")
    self.panelControl = self.maskControl:GetNamedChild("Panel")
    self.skillInfoBar = ZO_UniversalDeconstructionSkillInfoTopLevel_Gamepad

    self.scene = self:CreateInteractScene("universalDeconstructionSceneGamepad")
    UNIVERSAL_DECONSTRUCTION_GAMEPAD_SCENE = self.scene
    self.scene:SetInputPreferredMode(INPUT_PREFERRED_MODE_ALWAYS_GAMEPAD)
    self.scene:AddFragment(ZO_SimpleSceneFragment:New(self.skillInfoBar))

    ZO_GamepadCraftingUtils_InitializeGenericHeader(self, ZO_GAMEPAD_HEADER_TABBAR_CREATE)

    local NOT_REFINEMENT = false
    self.deconstructionPanel = ZO_UniversalDeconstructionPanel_Gamepad:New(self.panelControl, self.floatingControl, self, NOT_REFINEMENT, UNIVERSAL_DECONSTRUCTION_GAMEPAD_SCENE)

    local function OnCraftingInteractStarted(eventCode, craftingType, sameStation, craftingMode)
        if self.CanSceneShowForCraftingMode(craftingMode) then
            SCENE_MANAGER:Show("universalDeconstructionSceneGamepad")
            GAMEPAD_CRAFTING_RESULTS:SetTooltipAnimationSounds(SOUNDS.UNIVERSAL_DECONSTRUCTION_SUCCESS, SOUNDS.UNIVERSAL_DECONSTRUCTION_FAIL)
        end
    end
    self.control:RegisterForEvent(EVENT_CRAFTING_STATION_INTERACT, OnCraftingInteractStarted)

    local function OnCraftingInteractEnded(eventCode, craftingType, craftingMode)
        if self.CanSceneShowForCraftingMode(craftingMode) then
            if SCENE_MANAGER:IsShowing("universalDeconstructionSceneGamepad") or SCENE_MANAGER:IsShowingNext("universalDeconstructionSceneGamepad") then
                SCENE_MANAGER:ShowBaseScene()
                return
            end
        end
    end
    self.control:RegisterForEvent(EVENT_END_CRAFTING_STATION_INTERACT, OnCraftingInteractEnded)

    ZO_Smithing_AddScene("universalDeconstructionSceneGamepad", self)
end

function ZO_UniversalDeconstruction_Gamepad:SetEnableSkillBar(enable)
    if enable then
        ZO_MultipleCraftingSkillsXpBar_TieSkillInfoHeaderToCraftingTypes(self.skillInfoBar, self.craftingTypes)
    else
        ZO_MultipleCraftingSkillsXpBar_UntieSkillInfoHeaderToCraftingTypes(self.skillInfoBar)
    end
end

function ZO_UniversalDeconstruction_Gamepad:UpdateKeybindStrip()
    KEYBIND_STRIP:UpdateKeybindButtonGroup(self.keybindStripDescriptor)
end

function ZO_UniversalDeconstruction_Gamepad.CanSceneShowForCraftingMode(craftingMode)
    return IsInGamepadPreferredMode() and ZO_Smithing_IsUniversalDeconstructionCraftingMode(craftingMode)
end

function ZO_UniversalDeconstruction_Gamepad_Initialize(control)
    UNIVERSAL_DECONSTRUCTION_GAMEPAD = ZO_UniversalDeconstruction_Gamepad:New(control)
end