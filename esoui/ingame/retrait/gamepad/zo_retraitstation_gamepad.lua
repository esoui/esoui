------
-- ZO_RetraitStation_Gamepad
------

local GAMEPAD_RETRAIT_ROOT_SCENE_NAME = "retrait_gamepad_root"
local GAMEPAD_RETRAIT_SCENE_NAME = "retrait_gamepad"

local MODE_TO_SCENE_NAME =
{
    [ZO_RETRAIT_MODE_ROOT] = GAMEPAD_RETRAIT_ROOT_SCENE_NAME,
    [ZO_RETRAIT_MODE_RETRAIT] = GAMEPAD_RETRAIT_SCENE_NAME,
}

ZO_RetraitStation_Gamepad = ZO_RetraitStation_Base:Subclass()

function ZO_RetraitStation_Gamepad:New(...)
    return ZO_RetraitStation_Base.New(self, ...)
end

function ZO_RetraitStation_Gamepad:Initialize(control)
    ZO_RetraitStation_Base.Initialize(self, control, GAMEPAD_RETRAIT_ROOT_SCENE_NAME)

    ZO_GamepadCraftingUtils_InitializeGenericHeader(self, ZO_GAMEPAD_HEADER_TABBAR_DONT_CREATE)

    GAMEPAD_RETRAIT_ROOT_SCENE = self.interactScene

    local fragment = ZO_FadeSceneFragment:New(control)
    self.interactScene:AddFragment(fragment)

    SYSTEMS:RegisterGamepadRootScene("retrait", self.interactScene)
    SYSTEMS:RegisterGamepadObject("retrait", self)

    GAMEPAD_RETRAIT_SCENE = ZO_InteractScene:New(GAMEPAD_RETRAIT_SCENE_NAME, SCENE_MANAGER, self.retraitStationInteraction)
    local gamepadRetraitModeTopLevel = CreateControlFromVirtual("ZO_RetraitStation_RetraitMode_Gamepad", GuiRoot, "ZO_RetraitStation_Retrait_GamepadTopLevel")
    ZO_RETRAIT_STATION_RETRAIT_GAMEPAD = ZO_RetraitStation_Retrait_Gamepad:New(gamepadRetraitModeTopLevel, GAMEPAD_RETRAIT_SCENE)

    ZO_RETRAIT_STATION_MANAGER:RegisterRetraitScene(GAMEPAD_RETRAIT_SCENE_NAME)

    self:InitializeModeList()
    self:InitializeKeybindStripDescriptors()
end

function ZO_RetraitStation_Gamepad:OnInteractSceneShowing()
     KEYBIND_STRIP:AddKeybindButtonGroup(self.keybindStripDescriptor)
    self.modeList:Activate()

    ZO_GamepadCraftingUtils_SetupGenericHeader(self, GetString(SI_RETRAIT_STATION_HEADER))
    ZO_GamepadCraftingUtils_RefreshGenericHeader(self)

    self:ResetMode()
end

function ZO_RetraitStation_Gamepad:OnInteractSceneHiding()
    ZO_InventorySlot_RemoveMouseOverKeybinds()
    KEYBIND_STRIP:RemoveKeybindButtonGroup(self.keybindStripDescriptor)
    self.modeList:Deactivate()

    self:HandleDirtyEvent()
end

function ZO_RetraitStation_Gamepad:InitializeKeybindStripDescriptors()
    self.keybindStripDescriptor =
    {
        -- Select mode.
        {
            keybind = "UI_SHORTCUT_PRIMARY",
            alignment = KEYBIND_STRIP_ALIGN_LEFT,

            name = function()
                return GetString(SI_GAMEPAD_SELECT_OPTION)
            end,

            callback = function()
                local targetData = self.modeList:GetTargetData()
                self:SetMode(targetData.mode)
            end,
        },
    }

    ZO_Gamepad_AddBackNavigationKeybindDescriptors(self.keybindStripDescriptor, GAME_NAVIGATION_TYPE_BUTTON)
    ZO_Gamepad_AddListTriggerKeybindDescriptors(self.keybindStripDescriptor, self.modeList)
end

function ZO_RetraitStation_Gamepad:CreateModeEntry(name, mode, icon)
    local data = ZO_GamepadEntryData:New(GetString(name), icon)
    data:SetIconTintOnSelection(true)
    data.mode = mode
    return data
end

function ZO_RetraitStation_Gamepad:InitializeModeList()
    self.modeList = ZO_GamepadVerticalItemParametricScrollList:New(self.control:GetNamedChild("MaskContainerList"))
    self.modeList:SetAlignToScreenCenter(true)
    self.modeList:AddDataTemplate("ZO_GamepadItemEntryTemplate", ZO_SharedGamepadEntry_OnSetup, ZO_GamepadMenuEntryTemplateParametricListFunction)

    local retraitModeEntry = self:CreateModeEntry(SI_RETRAIT_STATION_RETRAIT_MODE, ZO_RETRAIT_MODE_RETRAIT, "EsoUI/Art/Crafting/Gamepad/gp_retrait_tabIcon.dds")

    self.modeList:AddEntry("ZO_GamepadItemEntryTemplate", retraitModeEntry)
    self.modeList:Commit()
end

function ZO_RetraitStation_Gamepad:ResetMode()
    self.mode = ZO_RETRAIT_MODE_ROOT
end

function ZO_RetraitStation_Gamepad:SetMode(mode)
    if self.mode ~= mode then
        self.mode = mode
        SCENE_MANAGER:Push(MODE_TO_SCENE_NAME[mode])
        KEYBIND_STRIP:UpdateKeybindButtonGroup(self.keybindStripDescriptor)
    end
end

function ZO_RetraitStation_Gamepad:IsItemAlreadySlottedToCraft(bag, slot)
    if self.mode == ZO_RETRAIT_MODE_RETRAIT then
        return ZO_RETRAIT_STATION_RETRAIT_GAMEPAD:IsItemAlreadySlottedToCraft(bag, slot)
    end
    return false
end

function ZO_RetraitStation_Gamepad:CanItemBeAddedToCraft(bag, slot)
    if self.mode == ZO_RETRAIT_MODE_RETRAIT then
        return ZO_RETRAIT_STATION_RETRAIT_GAMEPAD:CanItemBeAddedToCraft(bag, slot)
    end
    return false
end

function ZO_RetraitStation_Gamepad:AddItemToCraft(bag, slot)
    if self.mode == ZO_RETRAIT_MODE_RETRAIT then
        ZO_RETRAIT_STATION_RETRAIT_GAMEPAD:AddItemToCraft(bag, slot)
    end
end

function ZO_RetraitStation_Gamepad:RemoveItemFromCraft(bag, slot)
    if self.mode == ZO_RETRAIT_MODE_RETRAIT then
        ZO_RETRAIT_STATION_RETRAIT_GAMEPAD:RemoveItemFromCraft(bag, slot)
    end
end

function ZO_RetraitStation_Gamepad:OnRetraitResult(result)
    if self.mode == ZO_RETRAIT_MODE_RETRAIT then
        ZO_RETRAIT_STATION_RETRAIT_GAMEPAD:OnRetraitResult(result)
    end
end

function ZO_RetraitStation_Gamepad:HandleDirtyEvent()
    ZO_RETRAIT_STATION_RETRAIT_GAMEPAD:HandleDirtyEvent()
end

-- Global XML functions

function ZO_RetraitStation_Gamepad_Initialize(control)
    ZO_RETRAIT_STATION_GAMEPAD = ZO_RetraitStation_Gamepad:New(control)
end