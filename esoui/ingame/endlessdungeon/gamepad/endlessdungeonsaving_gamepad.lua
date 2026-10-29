------------------------------------------
-- ZO_EndlessDungeonSaveDetails_Gamepad
------------------------------------------

ZO_EndlessDungeonSaveDetails_Gamepad = ZO_EndlessDungeonSaveDetails_Shared:Subclass()

function ZO_EndlessDungeonSaveDetails_Gamepad.OnControlInitialized(control)
    ZO_EndlessDungeonSaveDetails_Gamepad:New(control)
end

---------------------------------------
-- ZO_EndlessDungeon_StartRun_Gamepad
---------------------------------------

ZO_EndlessDungeon_StartRun_Gamepad = ZO_Gamepad_ParametricList_Screen:Subclass()

local NO_SAVE_ID = 0

function ZO_EndlessDungeon_StartRun_Gamepad:Initialize(control)
    -- TODO InfiniteArchiveSaving: Make a ZO_InteractScene
    ENDLESS_DUNGEON_START_RUN_ROOT_GAMEPAD_SCENE = ZO_Scene:New("endlessDungeonStartRunRootGamepad", SCENE_MANAGER)
    local ACTIVATE_ON_SHOW = true
    ZO_Gamepad_ParametricList_Screen.Initialize(self, control, ZO_GAMEPAD_HEADER_NO_TABBAR, ACTIVATE_ON_SHOW, ENDLESS_DUNGEON_START_RUN_ROOT_GAMEPAD_SCENE)

    ENDLESS_DUNGEON_START_RUN_GAMEPAD_FRAGMENT = ZO_FadeSceneFragment:New(control)
    ENDLESS_DUNGEON_START_RUN_GAMEPAD_FRAGMENT:RegisterCallback("StateChange", function(oldState, newState)
        if newState == SCENE_FRAGMENT_SHOWING then
            self:RefreshList()
        end
    end)
    self.scene:AddFragment(ENDLESS_DUNGEON_START_RUN_GAMEPAD_FRAGMENT)

    self.rightPane = self.control:GetNamedChild("RightPane")
    local contentContainer = self.rightPane:GetNamedChild("ContentContainer")
    self.contentHeader = contentContainer:GetNamedChild("Header")
    local saveDetailsControl = self.rightPane:GetNamedChild("SaveDetails")
    self.saveDetails = saveDetailsControl.object

    self.contentHeaderData =
    {
        titleText = GetString(SI_ENDLESS_DUNGEON_LOAD_SAVE_DETAILS_TITLE)
    }
    ZO_GamepadGenericHeader_Initialize(self.contentHeader, ZO_GAMEPAD_HEADER_TABBAR_DONT_CREATE, ZO_GAMEPAD_HEADER_LAYOUTS.CONTENT_HEADER_DATA_PAIRS_LINKED)

    SYSTEMS:RegisterGamepadRootScene("endlessDungeonStartRun", ENDLESS_DUNGEON_START_RUN_ROOT_GAMEPAD_SCENE)

    self.saveId = NO_SAVE_ID
end

function ZO_EndlessDungeon_StartRun_Gamepad:OnDeferredInitialize()
    ZO_Gamepad_ParametricList_Screen.OnDeferredInitialize(self)

    self:RefreshHeader()
end

function ZO_EndlessDungeon_StartRun_Gamepad:PerformUpdate()
    self.dirty = false
end

function ZO_EndlessDungeon_StartRun_Gamepad:InitializeKeybindStripDescriptors()
    local function OnAcceptStartNewRun()
        LaunchNewEndlessDungeon()
        SCENE_MANAGER:HideCurrentScene()
    end

    self.keybindStripDescriptor =
    {
        alignment = KEYBIND_STRIP_ALIGN_LEFT,
        {
            keybind = "UI_SHORTCUT_PRIMARY",
            name = GetString(SI_ENDLESS_DUNGEON_LOAD_SAVE_LOAD_RUN),
            callback = function()
                LoadSavedEndlessDungeonBySaveId(self.saveId)
                SCENE_MANAGER:HideCurrentScene()
            end,
            visible = function()
                return self:HasEndlessDungeonPlayerSave()
            end,
            sound = SOUNDS.GAMEPAD_MENU_FORWARD,
        },
        {
            keybind = "UI_SHORTCUT_SECONDARY",
            name = function()
                if self:HasEndlessDungeonPlayerSave() then
                    return GetString(SI_ENDLESS_DUNGEON_LOAD_SAVE_NEW_RUN)
                else
                    return GetString(SI_DIALOG_CONFIRM)
                end
            end,
            callback = function()
                if self:HasEndlessDungeonPlayerSave() then
                    ZO_Dialogs_ShowPlatformDialog("ENDLESS_DUNGEON_CONFIRM_START_NEW", { onAcceptCallback = OnAcceptStartNewRun })
                else
                    OnAcceptStartNewRun()
                end
            end,
        },
        {
            keybind = "UI_SHORTCUT_NEGATIVE",
            name = GetString(SI_GAMEPAD_BACK_OPTION),
            callback = function()
                SCENE_MANAGER:HideCurrentScene()
            end,
        },
    }
end

function ZO_EndlessDungeon_StartRun_Gamepad:InitializeLists()
    local list = self:GetMainList()
    list:AddDataTemplate("ZO_GamepadMenuEntryTemplate", ZO_SharedGamepadEntry_OnSetup, ZO_GamepadMenuEntryTemplateParametricListFunction)
end

function ZO_EndlessDungeon_StartRun_Gamepad:RefreshHeader()
    --First, set up the header data that never changes
    if not self.headerData then
        self.headerData =
        {
            titleText = function()
                if self:HasEndlessDungeonPlayerSave() then
                    return GetString(SI_ENDLESS_DUNGEON_LOAD_SAVE_TITLE)
                else
                    return GetString(SI_ENDLESS_DUNGEON_LOAD_SAVE_NO_DATA_TITLE)
                end
            end,
            messageText = function()
                if self:HasEndlessDungeonPlayerSave() then
                    return ZO_ERROR_COLOR:Colorize(GetString(SI_ENDLESS_DUNGEON_LOAD_SAVE_BODY_ERROR_GAMEPAD))
                else
                    local saveCountText = tostring(ZO_ENDLESS_DUNGEON_MAX_SAVE_COUNT)
                    saveCountText = ZO_SELECTED_TEXT:Colorize(saveCountText)
                    return zo_strformat(SI_ENDLESS_DUNGEON_LOAD_SAVE_NO_DATA_BODY, saveCountText)
                end
            end,
        }
    end

    ZO_GamepadGenericHeader_Refresh(self.header, self.headerData)
end

function ZO_EndlessDungeon_StartRun_Gamepad:RefreshList()
    local list = self:GetMainList()
    list:Clear()

    if self:HasEndlessDungeonPlayerSave() then
        local currentSaveData = ZO_GamepadEntryData:New(GetString(SI_ENDLESS_DUNGEON_SAVED_ENTRY_GAMEPAD))
        list:AddEntry("ZO_GamepadMenuEntryTemplate", currentSaveData)
    end

    list:Commit()
end

function ZO_EndlessDungeon_StartRun_Gamepad:OnShowing()
    ZO_Gamepad_ParametricList_Screen.OnShowing(self)
    self:UpdateContentPane()
end

function ZO_EndlessDungeon_StartRun_Gamepad:UpdateContentPane()
    self.saveId = GetEndlessDungeonPlayerSaveId()

    if self:HasEndlessDungeonPlayerSave() then
        self.rightPane:SetHidden(false)
        self.scene:AddFragment(GAMEPAD_NAV_QUADRANT_2_3_BACKGROUND_FRAGMENT)
        self.saveDetails:Layout(self.saveId)
    elseif HasShownNewEndlessDungeonRunDialog() then
        LaunchNewEndlessDungeon()
        SCENE_MANAGER:HideCurrentScene()
    else
        self.rightPane:SetHidden(true)
        self.scene:RemoveFragment(GAMEPAD_NAV_QUADRANT_2_3_BACKGROUND_FRAGMENT)
        SetHasShownNewEndlessDungeonRunDialog(true)
    end

    ZO_GamepadGenericHeader_Refresh(self.contentHeader, self.contentHeaderData)
end

function ZO_EndlessDungeon_StartRun_Gamepad:HasEndlessDungeonPlayerSave()
    return self.saveId ~= NO_SAVE_ID
end

function ZO_EndlessDungeon_StartRun_Gamepad.OnControlInitialized(control)
    ENDLESS_DUNGEON_START_RUN_GAMEPAD = ZO_EndlessDungeon_StartRun_Gamepad:New(control)
end
