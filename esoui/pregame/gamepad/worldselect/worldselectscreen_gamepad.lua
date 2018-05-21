-- Configuration
local SERVER_STATUS_STRINGS =
{
    [SERVER_STATUS_DOWN]    = GetString(SI_SERVER_STATUS_DOWN),
    [SERVER_STATUS_UP]      = GetString(SI_SERVER_STATUS_UP),
    [SERVER_STATUS_OUT]     = GetString(SI_SERVER_STATUS_OUT),
    [SERVER_STATUS_LOCKED]  = GetString(SI_SERVER_STATUS_LOCKED),
}

local SERVER_STATUS_SELECTED_COLORS =
{
    [SERVER_STATUS_DOWN]    = ZO_ColorDef:New(1, 0, 0),
    [SERVER_STATUS_UP]      = ZO_ColorDef:New(0, 1, 0),
    [SERVER_STATUS_OUT]     = ZO_ColorDef:New(.75, .75, .75),
    [SERVER_STATUS_LOCKED]  = ZO_ColorDef:New(.75, 0, .75),
}

local SERVER_STATUS_UNSELECTED_COLORS =
{
    [SERVER_STATUS_DOWN]    = ZO_ColorDef:New(0.75, 0, 0),
    [SERVER_STATUS_UP]      = ZO_ColorDef:New(0, 0.75, 0),
    [SERVER_STATUS_OUT]     = ZO_ColorDef:New(.5, .5, .5),
    [SERVER_STATUS_LOCKED]  = ZO_ColorDef:New(.5, 0, .5),
}

-- Main class.
local ZO_WorldSelect_Gamepad = ZO_Object:Subclass()

function ZO_WorldSelect_Gamepad:New(control)
    local object = ZO_Object.New(self)
    object:Initialize(control)
    return object
end

function ZO_WorldSelect_Gamepad:Initialize(control)
    self.control = control

    control:RegisterForEvent(EVENT_WORLD_LIST_RECEIVED, function() self:RefreshWorldList() end)

    local worldSelect_Gamepad_Fragment = ZO_FadeSceneFragment:New(self.control)
    WORLD_SELECT_GAMEPAD_SCENE = ZO_Scene:New("WorldSelect_Gamepad", SCENE_MANAGER)
    WORLD_SELECT_GAMEPAD_SCENE:AddFragment(worldSelect_Gamepad_Fragment)

    WORLD_SELECT_GAMEPAD_SCENE:RegisterCallback("StateChange", function(oldState, newState)
                if newState == SCENE_SHOWING then
                    self:PerformDeferredInitialize()

                    self.firstWorldListRefresh = true

                    KEYBIND_STRIP:RemoveDefaultExit()
                    KEYBIND_STRIP:AddKeybindButtonGroup(self.keybindStripDescriptor)

                    if self.dirty then
                        self:RefreshWorldList_Internal()
                    end
                    self.optionsList:Activate()
                    self.worldLoading = false

                elseif newState == SCENE_HIDDEN then
                    self.optionsList:Deactivate()
                    KEYBIND_STRIP:RemoveKeybindButtonGroup(self.keybindStripDescriptor)
                    KEYBIND_STRIP:RestoreDefaultExit()

                end
            end)
end

function ZO_WorldSelect_Gamepad:PerformDeferredInitialize()
    if self.initialized then return end
    self.initialized = true

    self.dirty = true

    self.header = self.control:GetNamedChild("Container"):GetNamedChild("Header")

    self:SetupOptionsList()
    self:InitKeybindingDescriptors()
end

function ZO_WorldSelect_Gamepad:GetSelectedWorldInformation()
    local data = self.optionsList:GetTargetData()
    return data.worldIndex, data.text
end

function ZO_WorldSelect_Gamepad:OnWorldSelected()
    SavePlayerConsoleProfile()
    PregameStateManager_AdvanceState()
end

function ZO_WorldSelect_Gamepad:IsSelectionValid()
    local data = self.optionsList:GetTargetData()
    if not data then
        return false
    end

    return data.worldStatus == SERVER_STATUS_UP
end

function ZO_WorldSelect_Gamepad:InitKeybindingDescriptors()
    self.keybindStripDescriptor = {
        alignment = KEYBIND_STRIP_ALIGN_LEFT,

        -- Select
        {
            name = GetString(SI_GAMEPAD_SELECT_OPTION),
            keybind = "UI_SHORTCUT_PRIMARY",
            callback = function()
                    if(not self.worldLoading) then
                        PlaySound(SOUNDS.DIALOG_ACCEPT)
                        self.worldLoading = true
                        self:OnWorldSelected()
                    end
                end,
            visible = function() return self:IsSelectionValid() end,
        },

        -- Refresh
        {
            name = GetString(SI_GAMEPAD_WORLD_SELECT_REFRESH),
            keybind = "UI_SHORTCUT_SECONDARY",
            callback = function()
                    PlaySound(SOUNDS.DEFAULT_CLICK)
                    self:RefreshWorldList()
                end,
        },

        -- Back
        KEYBIND_STRIP:GenerateGamepadBackButtonDescriptor(function()
                PlaySound(SOUNDS.DIALOG_DECLINE)
                PregameStateManager_SetState("AccountLogin")
            end)
    }
    ZO_Gamepad_AddListTriggerKeybindDescriptors(self.keybindStripDescriptor, self.optionsList)
end

function ZO_WorldSelect_Gamepad:RefreshKeybindStrip()
    KEYBIND_STRIP:UpdateKeybindButtonGroup(self.keybindStripDescriptor)
end

function ZO_WorldSelect_Gamepad:RefreshWorldList()
    if self.control:IsHidden() then
        self.dirty = true
        return
    end

    self:RefreshWorldList_Internal()
end

function ZO_WorldSelect_Gamepad:AddServerEntry(worldIndex, worldName, worldStatus, hasHeader)
    local selectedColor = SERVER_STATUS_SELECTED_COLORS[worldStatus]
    local unselectedColor = SERVER_STATUS_UNSELECTED_COLORS[worldStatus]

    local option = ZO_GamepadEntryData:New(worldName)
    option.worldIndex = worldIndex
    option.worldStatus = worldStatus
    option:AddSubLabel(SERVER_STATUS_STRINGS[worldStatus])
    option:SetNameColors(selectedColor, unselectedColor)
    option:SetSubLabelColors(selectedColor, unselectedColor)
    option:SetShowUnselectedSublabels(true)    -- These entries always show their sub-labels.
    option.selectedCallback = function() self:WorldSelected() end

    local template
    if hasHeader then
        option:SetHeader(GetString(SI_SELECT_SERVER))
        template = "ZO_GamepadMenuEntryTemplateWithHeader"
    else
        template = "ZO_GamepadMenuEntryTemplate"
    end

    self.optionsList:AddEntry(template, option)
end

function ZO_WorldSelect_Gamepad:RefreshWorldList_Internal()
    self.dirty = false
    self.optionsList:Clear()

    local lastRealmName = GetCVar("LastRealm")
    local selectedIndex
    local numWorlds = GetNumWorlds()
    local worlds = {}
    for worldIndex = 0, numWorlds - 1 do
        local worldName, worldStatus = GetWorldInfo(worldIndex)
        table.insert(worlds, { worldIndex = worldIndex, worldName = worldName, worldStatus = worldStatus })
    end

    table.sort(worlds, function(a, b) return a.worldName < b.worldName end)

    for i, world in ipairs(worlds) do
        self:AddServerEntry(world.worldIndex, world.worldName, world.worldStatus, i == 1)
        if world.worldName == lastRealmName then
            selectedIndex = i
        end
    end

    self.optionsList:Commit()

    --Only auto select the first time we refresh the list after showing it. Otherwise it will keep setting the list back to the last select or first entry everytime it refreshes on the timer
    if self.firstWorldListRefresh then
        self.firstWorldListRefresh = false
        -- Select the last realm, and enter a quick launch, if configured.
        if selectedIndex then
            local ALLOW_IF_DISABLED = true
            self.optionsList:SetSelectedIndex(selectedIndex, ALLOW_IF_DISABLED)
            self.optionsList:RefreshVisible() -- Force the previous selection to take place immediately.

            if (GetCVar("QuickLaunch") == "1") then
                self:OnWorldSelected()
            end
        else
            self.optionsList:SetSelectedIndex(1)
        end
    end
end

function ZO_WorldSelect_Gamepad:SetupOptionsList()
    -- Setup the actual list.
    self.optionsControl = self.control:GetNamedChild("Container"):GetNamedChild("Options")
    self.optionsList = ZO_GamepadVerticalParametricScrollList:New(self.optionsControl:GetNamedChild("List"))
    self.optionsList:SetOnSelectedDataChangedCallback(function() self:RefreshKeybindStrip() end)

    self.optionsList:SetAlignToScreenCenter(true)

    self.optionsList:AddDataTemplate("ZO_GamepadMenuEntryTemplate", ZO_SharedGamepadEntry_OnSetup, ZO_GamepadMenuEntryTemplateParametricListFunction)
    self.optionsList:AddDataTemplateWithHeader("ZO_GamepadMenuEntryTemplate", ZO_SharedGamepadEntry_OnSetup, ZO_GamepadMenuEntryTemplateParametricListFunction, nil, "ZO_GamepadMenuEntryHeaderTemplate")

    self:RefreshWorldList()
end

function ZO_WorldSelect_Gamepad:SetImagesFragment(fragment)
    if fragment == self.imagesFragment then return end

    if self.imagesFragment then
        WORLD_SELECT_GAMEPAD_SCENE:RemoveFragment(self.imagesFragment)
    end
    if fragment then
        WORLD_SELECT_GAMEPAD_SCENE:AddFragment(fragment)
    end
    self.imagesFragment = fragment
end

function ZO_WorldSelect_Gamepad:SetBackgroundFragment(fragment)
    if fragment == self.backgroundFragment then return end

    if self.backgroundFragment then
        WORLD_SELECT_GAMEPAD_SCENE:RemoveFragment(self.backgroundFragment)
    end
    if fragment then
        WORLD_SELECT_GAMEPAD_SCENE:AddFragment(fragment)
    end
    self.backgroundFragment = fragment
end

function ZO_WorldSelect_Gamepad_Initialize(self)
    WORLD_SELECT_GAMEPAD = ZO_WorldSelect_Gamepad:New(self)
end
