local GAMEPAD_UNSTUCK_CONFIRM_DIALOG = "GAMEPAD_UNSTUCK_CONFIRM_DIALOG"
local GAMEPAD_UNSTUCK_COOLDOWN_DIALOG = "GAMEPAD_UNSTUCK_COOLDOWN_DIALOG"
local GAMEPAD_UNSTUCK_LOADING_DIALOG = "GAMEPAD_UNSTUCK_LOADING_DIALOG"
local GAMEPAD_UNSTUCK_ERROR_ALREADY_IN_PROGRESS_DIALOG = "GAMEPAD_UNSTUCK_ERROR_ALREADY_IN_PROGRESS_DIALOG"
local GAMEPAD_UNSTUCK_ERROR_INVALID_LOCATION_DIALOG = "GAMEPAD_UNSTUCK_ERROR_INVALID_LOCATION_DIALOG"
local GAMEPAD_UNSTUCK_ERROR_IN_COMBAT_DIALOG = "GAMEPAD_UNSTUCK_ERROR_IN_COMBAT_DIALOG"

local GAMEPAD_CS_DISABLED_ON_PC_DIALOG = "GAMEPAD_CS_DISABLED_ON_PC_DIALOG"

local ZO_Help_Root_Gamepad = ZO_Object.MultiSubclass(ZO_Gamepad_ParametricList_Screen, ZO_Stuck_Base)

function ZO_Help_Root_Gamepad:New(...)
    local object = ZO_Object.New(self)
    object:Initialize(...)
    return object    
end

function ZO_Help_Root_Gamepad:Initialize(control)
    HELP_ROOT_GAMEPAD_SCENE = ZO_Scene:New("helpRootGamepad", SCENE_MANAGER)

    ZO_Gamepad_ParametricList_Screen.Initialize(self, control, ZO_GAMEPAD_HEADER_TABBAR_DONT_CREATE, nil, HELP_ROOT_GAMEPAD_SCENE)
    ZO_Stuck_Base.Initialize(self)

    local helpRootFragment = ZO_FadeSceneFragment:New(control)
    HELP_ROOT_GAMEPAD_SCENE:AddFragment(helpRootFragment)

    self.headerData = {
        titleText = GetString(SI_MAIN_MENU_HELP),
        messageText = GetString(SI_GAMEPAD_HELP_ROOT_HEADER),
    }

    local headerMessageControl = control:GetNamedChild("Mask"):GetNamedChild("Container"):GetNamedChild("HeaderContainer"):GetNamedChild("Header"):GetNamedChild("Message")
    headerMessageControl:SetFont("ZoFontGamepadCondensed42")

    local websiteText = CreateControlFromVirtual("$(parent)HelpWebsite", control, "ZO_Gamepad_HelpWebsiteTemplate")
    websiteText:SetParent(self.header)
    local websiteAnchor = ZO_Anchor:New(TOP, headerMessageControl, BOTTOM, 0, 55)
    websiteAnchor:AddToControl(websiteText)
    
    ZO_GamepadGenericHeader_Refresh(self.header, self.headerData)
end

function ZO_Help_Root_Gamepad:InitializeKeybindStripDescriptors()
    self.keybindStripDescriptor =
    {
        alignment = KEYBIND_STRIP_ALIGN_LEFT,

        -- Select
        {
            name = GetString(SI_GAMEPAD_SELECT_OPTION),
            keybind = "UI_SHORTCUT_PRIMARY",
            callback = function()
                    local targetData = self:GetMainList():GetTargetData()
                    local destination = targetData.destination
                    local destinationName = type(destination) == "function" and destination() or destination

                    if targetData.isDialog then
                        ZO_Dialogs_ShowGamepadDialog(destinationName)
                    else
                        SCENE_MANAGER:Push(destinationName)
                    end
                end,
        },
    }

    ZO_Gamepad_AddBackNavigationKeybindDescriptors(self.keybindStripDescriptor, GAME_NAVIGATION_TYPE_BUTTON)
    ZO_Gamepad_AddListTriggerKeybindDescriptors(self.keybindStripDescriptor, self:GetMainList())
end

function ZO_Help_Root_Gamepad:OnDeferredInitialize()
    self:InitializeDialogs()
end

-- stuck event handling

function ZO_Help_Root_Gamepad:OnPlayerActivated()
    if(IsStuckFixPending()) then
        ZO_Dialogs_ShowGamepadDialog(GAMEPAD_UNSTUCK_LOADING_DIALOG)
    end
end

function ZO_Help_Root_Gamepad:OnStuckBegin()
    ZO_Dialogs_ShowGamepadDialog(GAMEPAD_UNSTUCK_LOADING_DIALOG)
end

function ZO_Help_Root_Gamepad:OnStuckCanceled()
    self.stuckComplete = true
end

function ZO_Help_Root_Gamepad:OnStuckComplete()
    self.stuckComplete = true
end

function ZO_Help_Root_Gamepad:OnStuckErrorAlreadyInProgress()
    ZO_Dialogs_ShowGamepadDialog(GAMEPAD_UNSTUCK_ERROR_ALREADY_IN_PROGRESS_DIALOG)
end

function ZO_Help_Root_Gamepad:OnStuckErrorInvalidLocation()
    ZO_Dialogs_ShowGamepadDialog(GAMEPAD_UNSTUCK_ERROR_INVALID_LOCATION_DIALOG)
end

function ZO_Help_Root_Gamepad:OnStuckErrorInCombat()
    ZO_Dialogs_ShowGamepadDialog(GAMEPAD_UNSTUCK_ERROR_IN_COMBAT_DIALOG)
end

function ZO_Help_Root_Gamepad:OnStuckErrorOnCooldown()
    -- handled by dialogs
end

function ZO_Help_Root_Gamepad:OnShowing()
    ZO_Gamepad_ParametricList_Screen.OnShowing(self)
    self.stuckComplete = false
end

function ZO_Help_Root_Gamepad:InitializeDialogs()
    self:InitializeUnstuckConfirmDialog()
    self:InitializeUnstuckCooldownDialog()
    self:InitializeUnstuckLoadingDialog()
    self:InitializeCSDisabledDialog()

    self:InitializeUnstuckErrorDialog(GAMEPAD_UNSTUCK_ERROR_ALREADY_IN_PROGRESS_DIALOG, SI_STUCK_ERROR_ALREADY_IN_PROGRESS)
    self:InitializeUnstuckErrorDialog(GAMEPAD_UNSTUCK_ERROR_INVALID_LOCATION_DIALOG, SI_GAMEPAD_HELP_UNSTUCK_ERROR_INVALID_STUCK_LOCATION)
    self:InitializeUnstuckErrorDialog(GAMEPAD_UNSTUCK_ERROR_IN_COMBAT_DIALOG, SI_GAMEPAD_HELP_UNSTUCK_ERROR_IN_COMBAT)
end

function ZO_Help_Root_Gamepad:InitializeUnstuckConfirmDialog()
    ZO_Dialogs_RegisterCustomDialog(GAMEPAD_UNSTUCK_CONFIRM_DIALOG,
    {
        canQueue = true,
        mustChoose = true,
        gamepadInfo = {
            dialogType = GAMEPAD_DIALOGS.BASIC,
        },

        title =
        {
            text = SI_GAMEPAD_HELP_GET_ME_UNSTUCK,
        },

        mainText = 
        {
            text = function()
                local cost = GetRecallCost()
                local goldIcon = zo_iconFormat(ZO_GAMEPAD_CURRENCY_ICON_GOLD_TEXTURE, 32, 32)
                local primaryButtonIconPath = ZO_Keybindings_GetTexturePathForKey(KEY_GAMEPAD_BUTTON_1)
                local primaryButtonIcon = zo_iconFormat(primaryButtonIconPath, 64, 64)
                local telvarLossPercentage = zo_floor(GetTelvarStonePercentLossOnNonPvpDeath() * 100)
                local mainText = DoesCurrentZoneHaveTelvarStoneBehavior() and SI_GAMEPAD_HELP_UNSTUCK_CONFIRM_STUCK_PROMPT_TELVAR or SI_GAMEPAD_HELP_UNSTUCK_CONFIRM_STUCK_PROMPT
                local playerMoney = GetCarriedCurrencyAmount(CURT_MONEY)
                
                if cost > playerMoney then
                    cost = playerMoney
                end

                return zo_strformat(mainText, cost, goldIcon, primaryButtonIcon, telvarLossPercentage)
            end,
        },
       
        buttons =
        {
            {
                keybind = "DIALOG_PRIMARY",
                text = SI_GAMEPAD_HELP_UNSTUCK_TELEPORT_KEYBIND_TEXT,
                callback = function()
                    SendPlayerStuck()
                end,
            },

            {
                keybind = "DIALOG_NEGATIVE",
                text = SI_DIALOG_EXIT,
            },
        }
    })
end

function ZO_Help_Root_Gamepad:InitializeUnstuckCooldownDialog()
    ZO_Dialogs_RegisterCustomDialog(GAMEPAD_UNSTUCK_COOLDOWN_DIALOG,
    {
        gamepadInfo = {
            dialogType = GAMEPAD_DIALOGS.COOLDOWN,
        },

        setup = function(dialog)
            dialog:setupFunc()
        end,

        updateFn = function(dialog)
            local cooldownTime = GetTimeUntilStuckAvailable()
            if(cooldownTime > 0) then
                dialog.cooldownLabelControl:SetText(ZO_FormatTimeMilliseconds(cooldownTime, TIME_FORMAT_STYLE_DESCRIPTIVE_SHORT_SHOW_ZERO_SECS, TIME_FORMAT_PRECISION_SECONDS))
            elseif not ZO_Dialogs_IsDialogHiding(GAMEPAD_UNSTUCK_COOLDOWN_DIALOG) then
                ZO_Dialogs_ShowGamepadDialog(GAMEPAD_UNSTUCK_CONFIRM_DIALOG)
                ZO_Dialogs_ReleaseDialogOnButtonPress(GAMEPAD_UNSTUCK_COOLDOWN_DIALOG)
            end
        end,

        title =
        {
            text = GetString(SI_GAMEPAD_HELP_GET_ME_UNSTUCK),
        },

        mainText = 
        {
            text = GetString(SI_GAMEPAD_HELP_UNSTUCK_COOLDOWN_HEADER),
        },
       
        buttons =
        {
            {
                keybind = "DIALOG_NEGATIVE",
                text = GetString(SI_DIALOG_EXIT),
            },
        }
    })
end

function ZO_Help_Root_Gamepad:InitializeUnstuckLoadingDialog()
    ZO_Dialogs_RegisterCustomDialog(GAMEPAD_UNSTUCK_LOADING_DIALOG,
    {
        canQueue = true,
        blockDialogReleaseOnPress = true, 

        gamepadInfo = {
            dialogType = GAMEPAD_DIALOGS.COOLDOWN,
        },

        setup = function(dialog)
            dialog:setupFunc()
        end,

        updateFn = function()
            if(self.stuckComplete) then
                ZO_Dialogs_ReleaseDialogOnButtonPress(GAMEPAD_UNSTUCK_LOADING_DIALOG)
                self.stuckComplete = false
                SCENE_MANAGER:ShowBaseScene()
            end
        end,

        title =
        {
            text = GetString(SI_GAMEPAD_HELP_GET_ME_UNSTUCK),
        },

        loading =
        {
           text = GetString(SI_FIXING_STUCK_TEXT),
        },
       
        buttons =
        {
        },

        mustChoose = true,
    })
end

function ZO_Help_Root_Gamepad:InitializeUnstuckErrorDialog(dialogName, dialogText)
    local formatText = zo_strformat(dialogText)

    ZO_Dialogs_RegisterCustomDialog(dialogName,
    {
        canQueue = true,

        gamepadInfo = {
            dialogType = GAMEPAD_DIALOGS.BASIC,
        },

        title =
        {
            text = SI_GAMEPAD_HELP_GET_ME_UNSTUCK,
        },

        mainText = 
        {
            text = formatText,
        },
       
        buttons =
        {
            {
                keybind = "DIALOG_NEGATIVE",
                text = SI_DIALOG_EXIT,
            },
        }
    })
end

function ZO_Help_Root_Gamepad:InitializeCSDisabledDialog()
    ZO_Dialogs_RegisterCustomDialog(GAMEPAD_CS_DISABLED_ON_PC_DIALOG,
    {
        canQueue = true,

        gamepadInfo = {
            dialogType = GAMEPAD_DIALOGS.BASIC,
        },

        title =
        {
            text = GetString(SI_GAMEPAD_HELP_CS_DISABLED_TITLE),
        },

        mainText = 
        {
            text = GetString(SI_GAMEPAD_HELP_CS_DISABLED_TEXT),
        },
       
        buttons =
        {
            {
                keybind = "DIALOG_NEGATIVE",
                text = SI_DIALOG_EXIT,
            },
        }
    })
end

do
    local IS_DIALOG = true
    local IS_SCENE = false
    
    local function AddEntry(list, name, icon, destination, isDialog)
        local data = ZO_GamepadEntryData:New(GetString(name), icon)
        data:SetIconTintOnSelection(true)
        data.destination = destination
        data.isDialog = isDialog
        list:AddEntry("ZO_GamepadMenuEntryTemplate", data)
    end

    local function UnstuckDialogNameCallback()
        if GetTimeUntilStuckAvailable() > 0 then
            return GAMEPAD_UNSTUCK_COOLDOWN_DIALOG
        else
            return GAMEPAD_UNSTUCK_CONFIRM_DIALOG
        end
    end

    function ZO_Help_Root_Gamepad:PopulateList()
        local list = self:GetMainList()
        list:Clear()

        AddEntry(list, SI_GAMEPAD_HELP_CUSTOMER_SERVICE, "EsoUI/Art/Notifications/Gamepad/gp_notification_cs.dds", "helpCustomerServiceGamepad", IS_SCENE)
        AddEntry(list, SI_GAMEPAD_HELP_GET_ME_UNSTUCK, "EsoUI/Art/MenuBar/Gamepad/gp_playerMenu_icon_unstuck.dds", UnstuckDialogNameCallback, IS_DIALOG)
        AddEntry(list, SI_HELP_TUTORIALS, "EsoUI/Art/MenuBar/Gamepad/gp_playerMenu_icon_tutorial.dds", "helpTutorialsCategoriesGamepad", IS_SCENE)
        AddEntry(list, SI_GAMEPAD_HELP_LEGAL_MENU, "EsoUI/Art/MenuBar/Gamepad/gp_playerMenu_icon_terms.dds", "helpLegalDocsGamepad", IS_SCENE)
        AddEntry(list, SI_CUSTOMER_SERVICE_QUEST_ASSISTANCE, "EsoUI/Art/MenuBar/Gamepad/gp_playerMenu_icon_quests.dds", "helpQuestAssistanceGamepad", IS_SCENE)
        AddEntry(list, SI_CUSTOMER_SERVICE_ITEM_ASSISTANCE, "EsoUI/Art/MenuBar/Gamepad/gp_playerMenu_icon_inventory.dds", "helpItemAssistanceGamepad", IS_SCENE)
        
        list:Commit()
    end
end

function ZO_Help_Root_Gamepad:PerformUpdate()
    self:PopulateList()

    KEYBIND_STRIP:UpdateKeybindButtonGroup(self.keybindStripDescriptor)

    self.headerData.titleText = GetString(SI_MAIN_MENU_HELP)
    self.headerData.messageText = GetString(SI_GAMEPAD_HELP_ROOT_HEADER)
    ZO_GamepadGenericHeader_Refresh(self.header, self.headerData)

    self.dirty = false
end

-- XML Functions

function ZO_Gamepad_Help_Root_OnInitialize(control)
    HELP_ROOT_GAMEPAD = ZO_Help_Root_Gamepad:New(control)
    SYSTEMS:RegisterGamepadObject(ZO_STUCK_NAME, HELP_ROOT_GAMEPAD)
end