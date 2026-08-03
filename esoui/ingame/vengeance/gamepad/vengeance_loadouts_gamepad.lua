--------------------------------------------
-- Vengeance Loadouts Gamepad
--------------------------------------------

ZO_Vengeance_Loadouts_Gamepad = ZO_Gamepad_ParametricList_Screen:Subclass()

function ZO_Vengeance_Loadouts_Gamepad:Initialize(control)
    GAMEPAD_VENGEANCE_LOADOUTS_SCENE = ZO_Scene:New("gamepad_vengeance_loadouts", SCENE_MANAGER)
    ZO_Gamepad_ParametricList_Screen.Initialize(self, control, ZO_GAMEPAD_HEADER_TABBAR_DONT_CREATE, ACTIVATE_LIST_ON_SHOW, GAMEPAD_VENGEANCE_LOADOUTS_SCENE)

    local vengeanceLoadoutsFragment = ZO_FadeSceneFragment:New(control)
    GAMEPAD_VENGEANCE_LOADOUTS_SCENE:AddFragment(vengeanceLoadoutsFragment)

    self.headerData =
    {
        titleText = GetString(SI_CAMPAIGN_OVERVIEW_SUBCATEGORY_LOADOUTS),
        messageText = function(headerControl)
            local targetData = self:GetTargetData()
            if targetData then
                local selectedLoadoutIndex = targetData.data:GetLoadoutIndex()
                local canEquipResult = CanLoadoutRoleBeEquippedByIndex(selectedLoadoutIndex)
                if canEquipResult ~= VENGEANCE_ACTION_RESULT_SUCCESS
                    and canEquipResult ~= VENGEANCE_ACTION_RESULT_ROLE_ALREADY_EQUIPPED then
                    headerControl:SetColor(ZO_ERROR_COLOR:UnpackRGBA())
                    return GetString("SI_VENGEANCEACTIONRESULT", canEquipResult)
                end
            end

            headerControl:SetColor(ZO_NORMAL_TEXT:UnpackRGBA())
            return GetString(SI_CAMPAIGN_VENGEANCE_SELECT_LOADOUT)
        end
    }
    ZO_GamepadGenericHeader_Refresh(self.header, self.headerData)

    self:InitializeLists()
    self:RegisterForEvents()
end

function ZO_Vengeance_Loadouts_Gamepad:RegisterForEvents()
    self.control:RegisterForEvent(EVENT_VENGEANCE_LOADOUT_ROLE_UPDATED, function() self:RefreshLoadouts() end)

    self.control:SetHandler("OnUpdate", function() ZO_GamepadGenericHeader_Refresh(self.header, self.headerData) end)
end

function ZO_Vengeance_Loadouts_Gamepad:InitializeLists()
    local list = self:GetMainList()

    local function OnLoadoutChanged(list, targetData, oldTargetData)
        if self:IsShowing() then
            if targetData.data:IsEquipped() then
                SCENE_MANAGER:AddFragment(ZO_VENGEANCE_EQUIPPED_LOADOUT_OVERVIEW_GAMEPAD_FRAGMENT)
                SCENE_MANAGER:RemoveFragment(ZO_VENGEANCE_UNEQUIPPED_LOADOUT_OVERVIEW_GAMEPAD_FRAGMENT)
            else
                VENGEANCE_UNEQUIPPED_LOADOUT_OVERVIEW_GAMEPAD:SetLoadout(targetData.data)
                SCENE_MANAGER:AddFragment(ZO_VENGEANCE_UNEQUIPPED_LOADOUT_OVERVIEW_GAMEPAD_FRAGMENT)
                SCENE_MANAGER:RemoveFragment(ZO_VENGEANCE_EQUIPPED_LOADOUT_OVERVIEW_GAMEPAD_FRAGMENT)
            end
            GAMEPAD_TOOLTIPS:LayoutLoadoutStatComparison(GAMEPAD_RIGHT_TOOLTIP, targetData.data)
            GAMEPAD_TOOLTIPS:SetStatusLabelText(GAMEPAD_RIGHT_TOOLTIP, GetString(SI_GAMEPAD_INVENTORY_ITEM_COMPARE_TOOLTIP_TITLE))
            self:UpdateKeybinds(self.keybindStripDescriptor)
        end
    end

    list:SetOnTargetDataChangedCallback(OnLoadoutChanged)
end

function ZO_Vengeance_Loadouts_Gamepad:InitializeKeybindStripDescriptors()
    self.keybindStripDescriptor =
    {
        alignment = KEYBIND_STRIP_ALIGN_LEFT,

        -- Select
        {
            name = function()
                local targetData = self:GetTargetData()
                local loadoutData = ZO_VENGEANCE_MANAGER:GetLoadoutDataByIndex(targetData.data:GetLoadoutIndex())
                return zo_strformat(SI_CAMPAIGN_VENGEANCE_LOADOUT_EQUIP_ACTION, loadoutData:GetRawName())
            end,
            keybind = "UI_SHORTCUT_PRIMARY",
            onShowCooldown = function()
                return GetRemainingCooldownForRoleSwapMs() / 1000
            end,
            callback = function()
                local targetData = self:GetTargetData()
                RequestSetLoadoutRoleByIndex(targetData.data:GetLoadoutIndex())
            end,
            enabled = function()
                local targetData = self:GetTargetData()
                local canEquipResult = CanLoadoutRoleBeEquippedByIndex(targetData.data:GetLoadoutIndex())
                return canEquipResult == VENGEANCE_ACTION_RESULT_SUCCESS, GetString("SI_VENGEANCEACTIONRESULT", canEquipResult)
            end,
            visible = function()
                local targetData = self:GetTargetData()
                if targetData then
                    return ZO_VENGEANCE_MANAGER:IsLoadoutIndexKeybindVisible(targetData.data:GetLoadoutIndex())
                end
                return false
            end,
        },
    }

    local function BackNavigationCallback()
        GAMEPAD_AVA_BROWSER:SetFromVengeanceScreenIndex(ZO_VENGEANCE_SCREEN_GAMEPAD_INDEX.LOADOUTS)
        SCENE_MANAGER:HideCurrentScene()
    end

    ZO_Gamepad_AddBackNavigationKeybindDescriptors(self.keybindStripDescriptor, GAME_NAVIGATION_TYPE_BUTTON, BackNavigationCallback)

    self:SetListsUseTriggerKeybinds(true)
end

function ZO_Vengeance_Loadouts_Gamepad:UpdateKeybinds()
    KEYBIND_STRIP:UpdateKeybindButtonGroup(self.keybindStripDescriptor)

    for _, keybindDesc in ipairs(self.keybindStripDescriptor) do
        local onShowCooldown = keybindDesc.onShowCooldown
        if onShowCooldown then
            KEYBIND_STRIP:TriggerCooldown(keybindDesc, onShowCooldown)
        end
    end
end

function ZO_Vengeance_Loadouts_Gamepad:OnShowing()
    ZO_Gamepad_ParametricList_Screen.OnShowing(self)

    TriggerTutorial(TUTORIAL_TRIGGER_VENGEANCE_LOADOUTS_OPENED)

    local targetData = self:GetTargetData()
    if targetData.data:IsEquipped() then
        SCENE_MANAGER:AddFragment(ZO_VENGEANCE_EQUIPPED_LOADOUT_OVERVIEW_GAMEPAD_FRAGMENT)
    else
        VENGEANCE_UNEQUIPPED_LOADOUT_OVERVIEW_GAMEPAD:SetLoadout(targetData.data)
        SCENE_MANAGER:AddFragment(ZO_VENGEANCE_UNEQUIPPED_LOADOUT_OVERVIEW_GAMEPAD_FRAGMENT)
    end
    SCENE_MANAGER:AddFragment(GAMEPAD_NAV_QUADRANT_2_BACKGROUND_FRAGMENT)
end


function ZO_Vengeance_Loadouts_Gamepad:OnHiding()
    SCENE_MANAGER:RemoveFragment(ZO_VENGEANCE_UNEQUIPPED_LOADOUT_OVERVIEW_GAMEPAD_FRAGMENT)
    SCENE_MANAGER:RemoveFragment(ZO_VENGEANCE_EQUIPPED_LOADOUT_OVERVIEW_GAMEPAD_FRAGMENT)
    SCENE_MANAGER:RemoveFragment(GAMEPAD_NAV_QUADRANT_2_BACKGROUND_FRAGMENT)
end

function ZO_Vengeance_Loadouts_Gamepad:GetTargetData()
    local currentList = self:GetCurrentList()
    if currentList then
        return currentList:GetTargetData()
    end
    return nil
end

function ZO_Vengeance_Loadouts_Gamepad:SetupList(list)
    local NO_EQUALITY_FUNCTION = nil
    list:AddDataTemplate("ZO_GamepadItemEntryTemplate", ZO_SharedGamepadEntry_OnSetup, ZO_GamepadMenuEntryTemplateParametricListFunction)
    list:AddDataTemplateWithHeader("ZO_GamepadItemEntryTemplate", ZO_SharedGamepadEntry_OnSetup, ZO_GamepadMenuEntryTemplateParametricListFunction, NO_EQUALITY_FUNCTION, "ZO_GamepadMenuEntryHeaderTemplate")
end

function ZO_Vengeance_Loadouts_Gamepad:PerformUpdate()
    self:RefreshLoadouts()
end

function ZO_Vengeance_Loadouts_Gamepad:RefreshLoadouts()
    local list = self:GetMainList()
    list:Clear()

    for _, loadoutData in ZO_VENGEANCE_MANAGER:LoadoutDataIterator() do
        local entryData = ZO_GamepadEntryData:New(loadoutData:GetFormattedName(), loadoutData:GetIcon())
        entryData.data = loadoutData
        entryData.isSelected = loadoutData:IsEquipped()
        entryData:SetIconTintOnSelection(true)
        entryData:SetIconDisabledTintOnSelection(true)
        entryData.narrationText = function(listEntryData, listEntryControl)
            local narrations = {}

            if listEntryData.data:IsEquipped() then
                ZO_AppendNarration(narrations, VENGEANCE_EQUIPPED_LOADOUT_OVERVIEW_GAMEPAD:GetNarrationText())
            else
                ZO_AppendNarration(narrations, VENGEANCE_UNEQUIPPED_LOADOUT_OVERVIEW_GAMEPAD:GetNarrationText())
            end

            return narrations
        end
        list:AddEntry("ZO_GamepadItemEntryTemplate", entryData)
    end

    list:Commit()
end

-----------------------------
-- Global XML Functions
-----------------------------

function ZO_Vengeance_Loadouts_Gamepad.OnControlInitialized(control)
    VENGEANCE_LOADOUTS_GAMEPAD = ZO_Vengeance_Loadouts_Gamepad:New(control)
end