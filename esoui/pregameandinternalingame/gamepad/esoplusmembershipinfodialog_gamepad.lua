ZO_EsoPlusMembershipInfoDialog_Gamepad = ZO_Object:Subclass()

function ZO_EsoPlusMembershipInfoDialog_Gamepad:New(...)
    local object = ZO_Object.New(self)
    object:Initialize(...)
    return object
end

function ZO_EsoPlusMembershipInfoDialog_Gamepad:Initialize(control)
    self.control = control

    self:InitializeDialog(control)

    local keybindLabelText = zo_strformat(SI_GAMEPAD_BACK_OPTION)
    self.control:GetNamedChild("BackKeybind"):SetText(keybindLabelText)
    self:BuildDialogInfo()

    ZO_Dialogs_RegisterCustomDialog("ESO_PLUS_MEMBERSHIP_INFO", self.dialogInfo)
end

function ZO_EsoPlusMembershipInfoDialog_Gamepad:InitializeDialog(dialog)
    dialog.fragment = ZO_FadeSceneFragment:New(dialog)
    ZO_GenericGamepadDialog_OnInitialized(dialog)

    self.benefitLinePool = ZO_ControlPool:New("ZO_GamepadMembershipInfoDialog_BenefitLine", dialog.scrollChild)

    local function SetupBenefitLine(benefitLine)
        benefitLine.iconTexture = benefitLine:GetNamedChild("Icon")
        benefitLine.headerLabel = benefitLine:GetNamedChild("HeaderText")
        benefitLine.lineLabel = benefitLine:GetNamedChild("LineText")
    end
    self.benefitLinePool:SetCustomFactoryBehavior(SetupBenefitLine)
end

function ZO_EsoPlusMembershipInfoDialog_Gamepad:BuildDialogInfo()
    self.dialogInfo =
    {
        setup = function(...) self:DialogSetupFunction(...) end,
        customControl = self.control,
        gamepadInfo = 
        {
            dialogType = GAMEPAD_DIALOGS.CUSTOM,
        },
        title =
        {
            text = SI_MARKET_SUBSCRIPTION_PAGE_BENEFITS_TITLE,
        },
        mainText =
        {
            text = "", -- no main text
        },
        narrationText = function(...) return self:GetNarrationText(...) end,
        buttons =
        {
            {
                --Even though this is an ethereal keybind, the name will still be read during screen narration
                name = GetString(SI_GAMEPAD_BACK_OPTION),
                ethereal = true,
                narrateEthereal = true,
                keybind = "DIALOG_NEGATIVE",
                clickSound = SOUNDS.DIALOG_DECLINE,
                callback = function(dialog)
                    self:Hide()
                end,
            },
        }
    }
end

function ZO_EsoPlusMembershipInfoDialog_Gamepad:DialogSetupFunction(dialog)
    dialog.headerData.titleTextAlignment = TEXT_ALIGN_CENTER
    ZO_GamepadGenericHeader_Refresh(dialog.header, dialog.headerData)

    self.benefitLinePool:ReleaseAllObjects()

    local numLines = GetNumGamepadMarketSubscriptionBenefitLines()
    local controlToAnchorTo = dialog.scrollChild
    for i = 1, numLines do
        local lineText, headerText, icon = GetGamepadMarketSubscriptionBenefitLineInfo(i);
        local benefitLine = self.benefitLinePool:AcquireObject()
        benefitLine.lineLabel:SetText(lineText)
        benefitLine.headerLabel:SetText(headerText)
        benefitLine.iconTexture:SetTexture(icon)
        benefitLine:ClearAnchors()
        if i == 1 then
            benefitLine:SetAnchor(TOPLEFT, controlToAnchorTo, TOPLEFT, 0, 0)
        else
            benefitLine:SetAnchor(TOPLEFT, controlToAnchorTo, BOTTOMLEFT, 0, 25)
        end
        controlToAnchorTo = benefitLine
    end
end

function ZO_EsoPlusMembershipInfoDialog_Gamepad:Show()
    ZO_Dialogs_ShowGamepadDialog("ESO_PLUS_MEMBERSHIP_INFO")
end

function ZO_EsoPlusMembershipInfoDialog_Gamepad:Hide()
    ZO_Dialogs_ReleaseDialog("ESO_PLUS_MEMBERSHIP_INFO")
end

function ZO_EsoPlusMembershipInfoDialog_Gamepad:GetNarrationText(dialog)
    local narrations = {}
    local numLines = GetNumGamepadMarketSubscriptionBenefitLines()
    for i = 1, numLines do
        local lineText, headerText, icon = GetGamepadMarketSubscriptionBenefitLineInfo(i);
        ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(headerText))
        ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(lineText))
    end
    return narrations
end
--
--[[ XML Handlers ]]--
--

function ZO_EsoPlusMembershipInfoDialog_Gamepad_OnInitialized(control)
    ZO_ESO_PLUS_MEMBERSHIP_DIALOG = ZO_EsoPlusMembershipInfoDialog_Gamepad:New(control)
end