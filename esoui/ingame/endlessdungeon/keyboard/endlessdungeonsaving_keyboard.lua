------------------------------------------
-- ZO_EndlessDungeonSaveDetails_Keyboard
------------------------------------------

ZO_EndlessDungeonSaveDetails_Keyboard = ZO_EndlessDungeonSaveDetails_Shared:Subclass()

function ZO_EndlessDungeonSaveDetails_Keyboard:Initialize(...)
    ZO_EndlessDungeonSaveDetails_Shared.Initialize(self, ...)
end

function ZO_EndlessDungeonSaveDetails_Keyboard.OnControlInitialized(control)
    ZO_EndlessDungeonSaveDetails_Keyboard:New(control)
end

-------------------------------------
-- ZO_EndlessDungeonSaving_Keyboard
-------------------------------------

ZO_EndlessDungeonSaving_Keyboard = ZO_DeferredInitializingObject:Subclass()

local NO_SAVE_ID = 0

function ZO_EndlessDungeonSaving_Keyboard:Initialize(control)
    self.control = control

    -- TODO InfiniteArchiveSaving: Make a ZO_InteractScene
    local scene = ZO_Scene:New("endlessDungeonStartRunSceneKeyboard", SCENE_MANAGER)
    SYSTEMS:RegisterKeyboardRootScene("endlessDungeonStartRun", scene)

    ZO_DeferredInitializingObject.Initialize(self, scene)

    self.fragment = ZO_FadeSceneFragment:New(control)
    scene:AddFragment(self.fragment)

    self.saveId = NO_SAVE_ID
end

function ZO_EndlessDungeonSaving_Keyboard:OnDeferredInitialize()
    self.headerLabel = self.control:GetNamedChild("HeaderText")
    self.bodyTextLabel = self.control:GetNamedChild("BodyText")

    self.saveDetailsControl = self.control:GetNamedChild("SaveDetails")
    self.saveDetails = self.saveDetailsControl.object

    self.primaryKeybindButton = self.control:GetNamedChild("Primary")
    self.secondaryKeybindButton = self.control:GetNamedChild("Secondary")
    self.cancelKeybindButton = self.control:GetNamedChild("Cancel")

    self:InitializeKeybindStripDescriptors()
end

function ZO_EndlessDungeonSaving_Keyboard:InitializeKeybindStripDescriptors()
    local function HasEndlessDungeonPlayerSave()
        return self.saveId ~= NO_SAVE_ID
    end

    local function OnAcceptStartNewRun()
        LaunchNewEndlessDungeon()
        SCENE_MANAGER:HideCurrentScene()
    end

    self.primaryKeybindDescriptor =
    {
        name = GetString(SI_ENDLESS_DUNGEON_LOAD_SAVE_LOAD_RUN),
        keybind = "UI_SHORTCUT_PRIMARY",
        ethereal = true,
        narrateEthereal = HasEndlessDungeonPlayerSave,
        etherealNarrationOrder = 1,
        callback = function()
            LoadSavedEndlessDungeonBySaveId(self.saveId)
            SCENE_MANAGER:HideCurrentScene()
        end,
        visible = HasEndlessDungeonPlayerSave,
    }
    self.primaryKeybindButton:SetKeybindButtonDescriptor(self.primaryKeybindDescriptor)

    self.secondaryKeybindDescriptor =
    {
        name = GetString(SI_ENDLESS_DUNGEON_LOAD_SAVE_NEW_RUN),
        keybind = "UI_SHORTCUT_SECONDARY",
        ethereal = true,
        narrateEthereal = true,
        etherealNarrationOrder = 2,
        callback = function()
            if HasEndlessDungeonPlayerSave() then
                ZO_Dialogs_ShowPlatformDialog("ENDLESS_DUNGEON_CONFIRM_START_NEW", { onAcceptCallback = OnAcceptStartNewRun })
            else
                OnAcceptStartNewRun()
            end
        end,
        visible = true,
    }
    self.secondaryKeybindButton:SetKeybindButtonDescriptor(self.secondaryKeybindDescriptor)

    local function CancelCallback()
        SCENE_MANAGER:HideCurrentScene()
    end

    self.cancelKeybindDescriptor =
    {
        name = GetString(SI_CANCEL),
        keybind = "UI_SHORTCUT_EXIT",
        ethereal = true,
        narrateEthereal = true,
        etherealNarrationOrder = 3,
        callback = CancelCallback,
    }
    self.cancelKeybindButton:SetKeybindButtonDescriptor(self.cancelKeybindDescriptor)

    self.keybindStripDescriptor =
    {
        self.primaryKeybindDescriptor,
        self.secondaryKeybindDescriptor,
        self.cancelKeybindDescriptor,
    }
end

function ZO_EndlessDungeonSaving_Keyboard:OnShowing()
    ZO_DeferredInitializingObject.OnShowing(self)
    self:UpdateContent()
    self:UpdateKeybinds()
end

function ZO_EndlessDungeonSaving_Keyboard:UpdateKeybinds()
    KEYBIND_STRIP:UpdateKeybindButtonGroup(self.keybindStripDescriptor)
    self.primaryKeybindButton:UpdateVisibility()
end

function ZO_EndlessDungeonSaving_Keyboard:UpdateContent()
    self.saveId = GetEndlessDungeonPlayerSaveId()
    if self.saveId == NO_SAVE_ID then
        if HasShownNewEndlessDungeonRunDialog() then
            LaunchNewEndlessDungeon()
            SCENE_MANAGER:HideCurrentScene()
        else
            local headerText = GetString(SI_ENDLESS_DUNGEON_LOAD_SAVE_NO_DATA_TITLE)
            self.headerLabel:SetText(headerText)

            local saveCountText = tostring(ZO_ENDLESS_DUNGEON_MAX_SAVE_COUNT)
            local bodyText = zo_strformat(SI_ENDLESS_DUNGEON_LOAD_SAVE_NO_DATA_BODY, saveCountText)
            self.bodyTextLabel:SetText(bodyText)

            self.saveDetailsControl:SetHidden(true)
            SetHasShownNewEndlessDungeonRunDialog(true)
        end
    else
        local headerText = GetString(SI_ENDLESS_DUNGEON_LOAD_SAVE_TITLE)
        self.headerLabel:SetText(headerText)

        local errorText = GetString(SI_ENDLESS_DUNGEON_LOAD_SAVE_BODY_ERROR_KEYBOARD)
        errorText = ZO_ERROR_COLOR:Colorize(errorText)
        local bodyText = zo_strformat(SI_ENDLESS_DUNGEON_LOAD_SAVE_BODY_KEYBOARD, errorText)
        self.bodyTextLabel:SetText(bodyText)

        self.saveDetailsControl:SetHidden(false)
        self.saveDetails:Layout(self.saveId)
    end
end

function ZO_EndlessDungeonSaving_Keyboard.OnControlInitialized(control)
    ENDLESS_DUNGEON_SAVING_KEYBOARD = ZO_EndlessDungeonSaving_Keyboard:New(control)
end
