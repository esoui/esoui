-- Interact Scenes
local GAMEPAD_RESTYLE_ROOT_SCENE_NAME = "gamepad_restyle_root"

local ZO_Restyle_Gamepad = ZO_Object:Subclass()

function ZO_Restyle_Gamepad:New(...)
    local restyle = ZO_Object.New(self)
    restyle:Initialize(...)
    return restyle
end

function ZO_Restyle_Gamepad:Initialize(control)
    self.control = control
    self.header = control:GetNamedChild("HeaderContainer"):GetNamedChild("Header")

    GAMEPAD_RESTYLE_ROOT_SCENE = ZO_InteractScene:New(GAMEPAD_RESTYLE_ROOT_SCENE_NAME, SCENE_MANAGER, ZO_DYEING_STATION_INTERACTION)

    self:InitializeModeList()
    self:InitializeKeybindStripDescriptorsRoot()

    SYSTEMS:RegisterGamepadRootScene("restyle", GAMEPAD_RESTYLE_ROOT_SCENE)

    ZO_GamepadGenericHeader_Initialize(self.header, ZO_GAMEPAD_HEADER_TABBAR_CREATE)

    self.headerData =
    {
        titleText = GetString(SI_RESTYLE_STATION_MENU_ROOT_TITLE)
    }

    GAMEPAD_RESTYLE_ROOT_SCENE:RegisterCallback("StateChange", function(oldState, newState)
        if newState == SCENE_SHOWING then
            self:SetMode(RESTYLE_MODE_SELECTION)
            self.modeList:RefreshVisible()
            self.modeList:Activate()
            local currentlySelectedData = self.modeList:GetTargetData()
            self:UpdateOptionLeftTooltip(currentlySelectedData.mode)
            KEYBIND_STRIP:AddKeybindButtonGroup(self.keybindStripDescriptorRoot)
            ZO_GamepadGenericHeader_Refresh(self.header, self.headerData)

            TriggerTutorial(TUTORIAL_TRIGGER_DYEING_OPENED)
            if IsESOPlusSubscriber() then
                TriggerTutorial(TUTORIAL_TRIGGER_DYEING_OPENED_AS_SUBSCRIBER)
            end
        elseif newState == SCENE_HIDDEN then
            self.modeList:Deactivate()
            ZO_GamepadGenericHeader_Deactivate(self.header)
            KEYBIND_STRIP:RemoveKeybindButtonGroup(self.keybindStripDescriptorRoot)
        end
    end)
end

function ZO_Restyle_Gamepad:SetMode(mode)
    if self.mode ~= mode then
        self.mode = mode
        SetRestylePreviewMode(mode)
    end
end

function ZO_Restyle_Gamepad:GetMode()
    return self.mode
end

local function ZO_RestyleGamepadRootEntry_OnSetup(control, data, selected, selectedDuringRebuild, enabled, activated)
    if data.mode == RESTYLE_MODE_COMPANION_EQUIPMENT or data.mode == RESTYLE_MODE_COMPANION_COLLECTIBLE then
        enabled = enabled and ZO_HasActiveOrBlockedCompanion()
    end
    data.enabled = enabled
    ZO_SharedGamepadEntry_OnSetup(control, data, selected, selectedDuringRebuild, enabled, activated)
    if (data.mode == RESTYLE_MODE_COLLECTIBLE or data.mode == RESTYLE_MODE_COMPANION_COLLECTIBLE) and not CanUseCollectibleDyeing() then
        if selected then
            control.label:SetColor(ZO_NORMAL_TEXT:UnpackRGBA())
        else
            control.label:SetColor(ZO_GAMEPAD_DISABLED_UNSELECTED_COLOR:UnpackRGBA())
        end
    end
end

function ZO_Restyle_Gamepad:InitializeModeList()
    self.modeList = ZO_GamepadVerticalItemParametricScrollList:New(self.control:GetNamedChild("Mask"):GetNamedChild("Container"):GetNamedChild("RootList"))
    self.modeList:SetAlignToScreenCenter(true)
    self.modeList:AddDataTemplate("ZO_GamepadItemEntryTemplate", ZO_RestyleGamepadRootEntry_OnSetup, ZO_GamepadMenuEntryTemplateParametricListFunction)

    local function AddEntry(name, mode, icon, sceneName)
        local data = ZO_GamepadEntryData:New(GetString(name), icon)
        data:SetIconTintOnSelection(true)
        data.mode = mode
        data.sceneName = sceneName
        self.modeList:AddEntry("ZO_GamepadItemEntryTemplate", data)
    end


    local function OnSelectedDataChanged(list, selectedData)
        if GAMEPAD_RESTYLE_ROOT_SCENE:IsShowing() then
            self.currentlySelectedOptionData = selectedData
            self:UpdateOptionLeftTooltip(selectedData.mode)
            KEYBIND_STRIP:UpdateKeybindButtonGroup(self.keybindStripDescriptorRoot)
        end
    end

    self.modeList:SetOnSelectedDataChangedCallback(OnSelectedDataChanged)

    self.modeList:Clear()
    AddEntry(SI_DYEING_DYE_EQUIPMENT_TAB, RESTYLE_MODE_EQUIPMENT, "EsoUI/Art/Restyle/Gamepad/gp_dyes_tabIcon_outfitStyleDye.dds", "gamepad_restyle_station")
    AddEntry(SI_DYEING_DYE_COLLECTIBLE_TAB, RESTYLE_MODE_COLLECTIBLE, "EsoUI/Art/Dye/Gamepad/dye_tabIcon_costumeDye.dds", "gamepad_restyle_station")
    AddEntry(SI_GAMEPAD_DYEING_COMPANION_EQUIPMENT_TAB, RESTYLE_MODE_COMPANION_EQUIPMENT, "EsoUI/Art/Restyle/Gamepad/gp_dyes_tabIcon_companionOutfitStyleDye.dds", "gamepad_restyle_station")
    AddEntry(SI_GAMEPAD_DYEING_COMPANION_COLLECTIBLE_TAB, RESTYLE_MODE_COMPANION_COLLECTIBLE, "EsoUI/Art/Dye/Gamepad/dye_tabIcon_companionCostumeDye.dds", "gamepad_restyle_station")
    self.modeList:Commit()
end

function ZO_Restyle_Gamepad:UpdateOptionLeftTooltip(restyleMode)
    if restyleMode == RESTYLE_MODE_EQUIPMENT then
        GAMEPAD_TOOLTIPS:LayoutTitleAndDescriptionTooltip(GAMEPAD_LEFT_TOOLTIP, GetString(SI_DYEING_DYE_EQUIPMENT_TAB), GetString(SI_GAMEPAD_DYEING_EQUIPMENT_DESCRIPTION))
    elseif restyleMode == RESTYLE_MODE_COLLECTIBLE then
        local descriptionOne
        local descriptionTwo
        if CanUseCollectibleDyeing() then
            descriptionOne = ZO_DEFAULT_ENABLED_COLOR:Colorize(GetString(SI_ESO_PLUS_STATUS_UNLOCKED))
            descriptionTwo = GetString(SI_DYEING_COLLECTIBLE_TAB_DESCRIPTION_UNLOCKED)
        else
            descriptionOne = ZO_DEFAULT_ENABLED_COLOR:Colorize(GetString(SI_ESO_PLUS_STATUS_LOCKED))
            descriptionTwo = GetString(SI_DYEING_COLLECTIBLE_TAB_DESCRIPTION_LOCKED)
        end
        GAMEPAD_TOOLTIPS:LayoutTitleAndMultiSectionDescriptionTooltip(GAMEPAD_LEFT_TOOLTIP, GetString(SI_DYEING_DYE_COLLECTIBLE_TAB), descriptionOne, descriptionTwo)
    elseif restyleMode == RESTYLE_MODE_OUTFIT then
        GAMEPAD_TOOLTIPS:LayoutTitleAndDescriptionTooltip(GAMEPAD_LEFT_TOOLTIP, GetString(SI_DYEING_DYE_OUTFIT_STYLES_TAB), GetString(SI_GAMEPAD_RESTYLE_OUTFITS_DESCRIPTION))
    elseif restyleMode == RESTYLE_MODE_COMPANION_EQUIPMENT then
        GAMEPAD_TOOLTIPS:LayoutTitleAndDescriptionTooltip(GAMEPAD_LEFT_TOOLTIP, GetString(SI_GAMEPAD_DYEING_COMPANION_EQUIPMENT_TAB), GetString(SI_GAMEPAD_DYEING_COMPANION_EQUIPMENT_TAB_DESCRIPTION))
    elseif restyleMode == RESTYLE_MODE_COMPANION_COLLECTIBLE then
        local descriptionOne
        local descriptionTwo
        local descriptionThree
        if ZO_HasActiveOrBlockedCompanion() and CanUseCollectibleDyeing() then
            descriptionOne = ZO_DEFAULT_ENABLED_COLOR:Colorize(GetString(SI_ESO_PLUS_STATUS_UNLOCKED))
            descriptionTwo = GetString(SI_GAMEPAD_DYEING_COMPANION_COLLECTIBLE_TAB_DESCRIPTION_UNLOCKED)
        else
            descriptionOne = ZO_DEFAULT_ENABLED_COLOR:Colorize(GetString(SI_ESO_PLUS_STATUS_LOCKED))
            descriptionTwo = GetString(SI_GAMEPAD_DYEING_COMPANION_COLLECTIBLE_TAB_DESCRIPTION_LOCKED)
            descriptionThree = GetString(SI_OUTFIT_COMPANION_DISABLED_DESCRIPTION)
        end
        GAMEPAD_TOOLTIPS:LayoutTitleAndMultiSectionDescriptionTooltip(GAMEPAD_LEFT_TOOLTIP, GetString(SI_GAMEPAD_DYEING_COMPANION_COLLECTIBLE_TAB), descriptionOne, descriptionTwo, descriptionThree)
    elseif restyleMode == RESTYLE_MODE_COMPANION_OUTFIT then
        GAMEPAD_TOOLTIPS:LayoutTitleAndDescriptionTooltip(GAMEPAD_LEFT_TOOLTIP, GetString(SI_DYEING_DYE_OUTFIT_STYLES_TAB), GetString(SI_GAMEPAD_RESTYLE_OUTFITS_DESCRIPTION))
    end
end

function ZO_Restyle_Gamepad:InitializeKeybindStripDescriptorsRoot()
    self.keybindStripDescriptorRoot =
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
                local targetMode = targetData.mode
                if targetMode == RESTYLE_MODE_EQUIPMENT or targetMode == RESTYLE_MODE_COMPANION_EQUIPMENT then
                    local expectedActorCategory = ZO_OUTFIT_MANAGER.GetActorCategoryByRestyleMode(targetMode)
                    local actorCategory, outfitIndex = ZO_OUTFITS_SELECTOR_GAMEPAD:GetCurrentActorCategoryAndIndex()
                    if not actorCategory or actorCategory ~= expectedActorCategory then
                        ZO_OUTFITS_SELECTOR_GAMEPAD:SetCurrentActorCategory(expectedActorCategory)
                        actorCategory, outfitIndex = ZO_OUTFITS_SELECTOR_GAMEPAD:GetCurrentActorCategoryAndIndex()
                    end
                    if outfitIndex then
                        ZO_OUTFITS_SELECTOR_GAMEPAD:SetCurrentActorCategory(actorCategory)
                        targetMode = ZO_OUTFIT_MANAGER.GetRestyleModeByActorCategory(actorCategory)
                    end
                end
                self:SetMode(targetMode)
                ZO_RESTYLE_STATION_GAMEPAD:Update()
                SCENE_MANAGER:Push(targetData.sceneName)
            end,
            enabled = function()
                local targetData = self.modeList:GetTargetData()
                local targetMode = targetData.mode
                if targetMode == RESTYLE_MODE_COMPANION_EQUIPMENT or targetMode == RESTYLE_MODE_COMPANION_COLLECTIBLE then
                    return ZO_HasActiveOrBlockedCompanion()
                end
                return true
            end,
            visible = function()
                local targetData = self.modeList:GetTargetData()
                if targetData.mode == RESTYLE_MODE_COLLECTIBLE or targetData.mode == RESTYLE_MODE_COMPANION_COLLECTIBLE then
                    return CanUseCollectibleDyeing()
                end
                return true
            end
        },
    }

    ZO_Gamepad_AddBackNavigationKeybindDescriptors(self.keybindStripDescriptorRoot, GAME_NAVIGATION_TYPE_BUTTON)
    ZO_Gamepad_AddListTriggerKeybindDescriptors(self.keybindStripDescriptorRoot, self.modeList)
end

function ZO_Restyle_Gamepad:CancelExit()
    MAIN_MENU_MANAGER:CancelBlockingSceneNextScene()
end

function ZO_Restyle_Gamepad:UndoPendingChanges()
    InitializePendingDyes()
    PlaySound(SOUNDS.DYEING_UNDO_CHANGES)
end

function ZO_Restyle_Gamepad:ConfirmCommitSelection()
    ZO_RESTYLE_STATION_GAMEPAD:CompleteDyeChanges()
end

function ZO_Restyle_Gamepad:AttemptExit()
    SCENE_MANAGER:HideCurrentScene()
end

function ZO_Restyle_Gamepad_OnInitialized(control)
    RESTYLE_GAMEPAD = ZO_Restyle_Gamepad:New(control)
    SYSTEMS:RegisterGamepadObject("restyle", RESTYLE_GAMEPAD)
end
