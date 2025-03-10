local ENTRY_TYPE_CODE_ENTRY = 1
local ENTRY_TYPE_SUBMIT = 2

local CodeRedemption_Gamepad = ZO_Gamepad_ParametricList_Screen:Subclass()

function CodeRedemption_Gamepad:New(...)
    return ZO_Gamepad_ParametricList_Screen.New(self, ...)
end

function CodeRedemption_Gamepad:Initialize(control)
    local scene = ZO_RemoteScene:New("codeRedemptionGamepad", SCENE_MANAGER)
    local ACTIVATE_ON_SHOW = true
    ZO_Gamepad_ParametricList_Screen.Initialize(self, control, ZO_GAMEPAD_HEADER_TABBAR_DONT_CREATE, ACTIVATE_ON_SHOW, scene)

    local codeRedemptionFragment = ZO_SimpleSceneFragment:New(control)
    codeRedemptionFragment:SetHideOnSceneHidden(true)
    scene:AddFragment(codeRedemptionFragment)

    self.codeToRedeem = ""

    self.list = self:GetMainList()

    self:SetListsUseTriggerKeybinds(true)
end

function CodeRedemption_Gamepad:SetupHeader()
    self.headerData =
    {
        titleText = GetString(SI_CODE_REDEMPTION_TITLE)
    }
    ZO_GamepadGenericHeader_Refresh(self.header, self.headerData)
end

function CodeRedemption_Gamepad:BuildList()
    self.list:Clear()

    local enterCodeEntryData = ZO_GamepadEntryData:New()
    enterCodeEntryData.entryType = ENTRY_TYPE_CODE_ENTRY
    enterCodeEntryData:SetHeader(GetString(SI_GAMEPAD_CODE_REDEMPTION_REDEEM_CODE_ENTRY_HEADER))
    enterCodeEntryData.narrationText = ZO_GetDefaultParametricListEditBoxNarrationText
    self.list:AddEntryWithHeader("ZO_GamepadTextFieldItem", enterCodeEntryData)

    local submitEntryData = ZO_GamepadEntryData:New(GetString(SI_GAMEPAD_CODE_REDEMPTION_SUBMIT_ENTRY_NAME))
    submitEntryData.entryType = ENTRY_TYPE_SUBMIT
    self.list:AddEntry("ZO_CodeRedemption_Gamepad_Submit_Template", submitEntryData)

    self.list:Commit()
end

function  CodeRedemption_Gamepad:RequestRedeemCode()
    self:DeactivateCurrentList()
    KEYBIND_STRIP:RemoveKeybindButtonGroup(self.keybindStripDescriptor)
    local codeToRedeem = zo_strgsub(self.codeToRedeem, "%s+", "")
    local dialogData =
    {
        code = codeToRedeem,
    }
    ZO_Dialogs_ShowGamepadDialog("GAMEPAD_CODE_REDEMPTION_PENDING_DIALOG", dialogData)
end

function CodeRedemption_Gamepad:OnRedeemCodeComplete(success)
    self:ActivateCurrentList()
    self.list:SetSelectedIndex(1)
    KEYBIND_STRIP:AddKeybindButtonGroup(self.keybindStripDescriptor)
    if success then
        self.codeToRedeem = ""
        self.list:RefreshVisible()
    end
end

-- begin ZO_Gamepad_ParametricList_Screen overrides

function CodeRedemption_Gamepad:SetupList(list)
    list:AddDataTemplate("ZO_CodeRedemption_Gamepad_Submit_Template", ZO_SharedGamepadEntry_OnSetup)

    local function SetupCodeEntryField(control, data, selected, reselectingDuringRebuild, enabled, active)
        control.highlight:SetHidden(not selected)

        local editBoxControl = control.editBoxControl
        data.editBoxControl = editBoxControl

        editBoxControl.textChangedCallback = function(editControl)
            self.codeToRedeem = editControl:GetText()
        end

        editBoxControl.focusLostCallback = function(editControl)
            SCREEN_NARRATION_MANAGER:QueueParametricListEntry(list)
        end

        editBoxControl:SetMaxInputChars(MAX_PROMO_CODE_LENGTH)

        editBoxControl:SetText(self.codeToRedeem)
    end

    local NO_PARAMETRIC_FUNCTION = nil
    local NO_EQUALITY_FUNCTION = nil
    list:AddDataTemplateWithHeader("ZO_GamepadTextFieldItem", SetupCodeEntryField, NO_PARAMETRIC_FUNCTION, NO_EQUALITY_FUNCTION, "ZO_CodeRedemption_Gamepad_RedeemCodeHeaderTemplate")
end

function CodeRedemption_Gamepad:OnDeferredInitialize()
    self:SetupHeader()
    self:BuildList()
    self:RegisterDialogs()
end

function CodeRedemption_Gamepad:InitializeKeybindStripDescriptors()
    self.keybindStripDescriptor =
    {
        alignment = KEYBIND_STRIP_ALIGN_LEFT,

        {
            keybind = "UI_SHORTCUT_PRIMARY",
            name = GetString(SI_GAMEPAD_SELECT_OPTION),
            enabled = function()
                local targetData = self.list:GetTargetData()
                if targetData then
                    if targetData.entryType == ENTRY_TYPE_SUBMIT then
                        return self.codeToRedeem ~= ""
                    end

                    return true
                end

                return false
            end,
            callback = function()
                local targetData = self.list:GetTargetData()
                if targetData.entryType == ENTRY_TYPE_CODE_ENTRY then
                    local editBox = targetData.editBoxControl
                    if editBox:HasFocus() then
                        editBox:LoseFocus()
                    else
                        editBox:TakeFocus()
                    end
                elseif targetData.entryType == ENTRY_TYPE_SUBMIT then
                    self:RequestRedeemCode()
                end
            end,
        },

        KEYBIND_STRIP:GetDefaultGamepadBackButtonDescriptor(),
    }
end

function CodeRedemption_Gamepad:PerformUpdate()
    self.dirty = false
end

function CodeRedemption_Gamepad:OnShowing()
    ZO_Gamepad_ParametricList_Screen.OnShowing(self)

    ZO_GamepadGenericHeader_Refresh(self.header, self.headerData)

    if DoesPlatformSupportDisablingShareFeatures() then
        DisableShareFeatures()
    end

    self.list:SetSelectedIndexWithoutAnimation(1)
    self.list:RefreshVisible()

    CALLBACK_MANAGER:RegisterCallback("OnGamepadDialogHidden", self.OnGamepadDialogHidden)
    GAMEPAD_TOOLTIPS:LayoutRedeemCodeTooltip(GAMEPAD_LEFT_TOOLTIP)
end

function CodeRedemption_Gamepad:OnHiding()
    ZO_Gamepad_ParametricList_Screen.OnHiding(self)

    self.codeToRedeem = ""

    if DoesPlatformSupportDisablingShareFeatures() then
        EnableShareFeatures()
    end

    CALLBACK_MANAGER:UnregisterCallback("OnGamepadDialogHidden", self.OnGamepadDialogHidden)

    GAMEPAD_TOOLTIPS:ClearTooltip(GAMEPAD_LEFT_TOOLTIP)
end

-- end ZO_Gamepad_ParametricList_Screen overrides

local LOADING_DELAY_MS = 500 -- delay is in milliseconds
local function OnCodeRedemptionComplete(data, success, code, redeemCodeResult)
    EVENT_MANAGER:UnregisterForEvent("GAMEPAD_CODE_REDEMPTION", EVENT_CODE_REDEMPTION_COMPLETE)

    -- add a delay so the dialog transition is smoother
    zo_callLater(function()
                    ZO_Dialogs_ReleaseDialogOnButtonPress("GAMEPAD_CODE_REDEMPTION_PENDING_DIALOG")
                    local dialogData =
                    {
                        success = success,
                        code = code,
                        redeemCodeResult = redeemCodeResult,
                    }
                    ZO_Dialogs_ShowGamepadDialog("GAMEPAD_CODE_REDEMPTION_COMPLETE_DIALOG", dialogData)
                    if success then
                        PlaySound(SOUNDS.CODE_REDEMPTION_SUCCESS)
                    else
                        PlaySound(SOUNDS.GENERAL_ALERT_ERROR)
                    end
                end, LOADING_DELAY_MS)
end

local function PendingCodeRedemptionDialogSetup(dialog, data)
    dialog:setupFunc(data)
    if RequestRedeemCode(data.code) then
        EVENT_MANAGER:RegisterForEvent("GAMEPAD_CODE_REDEMPTION", EVENT_CODE_REDEMPTION_COMPLETE, function(eventId, ...) OnCodeRedemptionComplete(data, ...) end)
    else
        local dialogData =
        {
            success = false,
            code = data.code,
            redeemCodeResult = REDEEM_CODE_RESULT_ERROR,
        }
        ZO_Dialogs_ShowGamepadDialog("GAMEPAD_CODE_REDEMPTION_COMPLETE_DIALOG", dialogData)
    end
end

function CodeRedemption_Gamepad:RegisterDialogs()
    ZO_Dialogs_RegisterCustomDialog("GAMEPAD_CODE_REDEMPTION_PENDING_DIALOG",
    {
        setup = PendingCodeRedemptionDialogSetup,
        gamepadInfo =
        {
            dialogType = GAMEPAD_DIALOGS.COOLDOWN,
            dialogFragmentGroup = ZO_GAMEPAD_KEYBINDS_FRAGMENT_GROUP,
        },
        title =
        {
            text = GetString(SI_CODE_REDEMPTION_PENDING_TITLE),
        },
        mainText =
        {
            text = "",
        },
        loading = 
        {
            text = GetString(SI_CODE_REDEMPTION_PENDING_LOADING_TEXT),
        },
        canQueue = true,
        mustChoose = true,
    })

    ZO_Dialogs_RegisterCustomDialog("GAMEPAD_CODE_REDEMPTION_COMPLETE_DIALOG",
        {
            setup = function(dialog)
                dialog:setupFunc(dialog.data)
            end,
            gamepadInfo =
            {
                dialogType = GAMEPAD_DIALOGS.BASIC,
                dialogFragmentGroup = ZO_GAMEPAD_KEYBINDS_FRAGMENT_GROUP,
            },
            title =
            {
                text =  function(dialog)
                    local success = dialog.data.success
                    if success then
                        return GetString(SI_CODE_REDEMPTION_DIALOG_SUCCESS_TITLE)
                    else
                        return GetString(SI_CODE_REDEMPTION_DIALOG_FAILED_TITLE)
                    end
                end,
            },
            mainText =
            {
                text = function(dialog)
                    local data = dialog.data
                    if data.success then
                        local rewardNames = REWARDS_MANAGER:GetListOfRewardNamesFromLastCodeRedemption()
                        if #rewardNames > 0 then
                            local listOfRewardNames = ZO_WHITE:Colorize(ZO_GenerateCommaSeparatedListWithoutAnd(rewardNames))
                            return zo_strformat(SI_CODE_REDEMPTION_DIALOG_SUCCESS_WITH_REWARD_NAMES_BODY, listOfRewardNames)
                        end
                    end

                    local redeemCodeResult = data.redeemCodeResult
                    return GetString("SI_REDEEMCODERESULT", redeemCodeResult)
                end,
            },
            canQueue = true,
            mustChoose = true,
            buttons =
            {
                {
                    keybind = "DIALOG_NEGATIVE",
                    text = SI_DIALOG_EXIT,
                },
            },
            finishedCallback = function(dialog)
                self:OnRedeemCodeComplete(dialog.data.success)
            end
        })
end


-- global XML functions

function ZO_CodeRedemption_Gamepad_OnInitialized(control)
    local codeRedemption = CodeRedemption_Gamepad:New(control)
end
