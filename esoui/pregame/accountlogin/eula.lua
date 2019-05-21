
local PREGAME_EULAS = {
    EULA_TYPE_PREGAME_EULA,
    EULA_TYPE_TERMS_OF_SERVICE,
    EULA_TYPE_PRIVACY_POLICY,
    EULA_TYPE_CODE_OF_CONDUCT,
    EULA_TYPE_NON_DISCLOSURE_AGREEMENT,
}

--[[
    Fragment Creation
--]]

local ZO_EULAFragment = ZO_FadeSceneFragment:Subclass()

function ZO_EULAFragment:New(control)
    local fragment = ZO_FadeSceneFragment.New(self, control, 1500)
    fragment.dialog = control
    return fragment
end

function ZO_EULAFragment:Show()
    EULA_SCREEN:ShowNextEULA()

    -- Call base class for animations after everything has been tweaked
    ZO_FadeSceneFragment.Show(self)
end

function ZO_EULAFragment:OnHidden()
    ZO_FadeSceneFragment.OnHidden(self)
    ZO_Dialogs_ReleaseDialog("SHOW_EULA")
    PregameStateManager_AdvanceState()
end


local ZO_EULA = ZO_Object:Subclass()

function ZO_EULA:New(control)
    local object = ZO_Object.New(self)
    object:Initialize(control)
    return object    
end

function ZO_EULA:Initialize(control)
    self.control = control
    self.isShowingLinkConfirmation = false
    self.agreeButton = control:GetNamedChild("Agree")
    self.notifyUpdatedTextLabel = control:GetNamedChild("NotifyUpdatedText")
    self.readTextCheckContainer = control:GetNamedChild("ReadTextCheckContainer")
    self.readTextCheckBox = self.readTextCheckContainer:GetNamedChild("CheckBox")
    self.scroll = control:GetNamedChild("ContainerScroll")
    self:InitializeDialog(control)
    self:CreateEULAScene(control)
    LINK_HANDLER:RegisterCallback(LINK_HANDLER.LINK_CLICKED_EVENT, function(...) self:OnLinkClicked(...) end)
    CALLBACK_MANAGER:RegisterCallback("AllDialogsHidden", function()
        if self.isShowingLinkConfirmation then
            self:ShowNextEULA()
            self.isShowingLinkConfirmation = false
        end
    end)
end

function ZO_EULA:OnLinkClicked(link, button, text, color, linkType, ...)
    if ZO_Dialogs_IsShowing("SHOW_EULA") then
        -- Need to release the EULA dialog so that the CONFIRM_OPEN_URL dialog will be shown
        ZO_Dialogs_ReleaseDialog("SHOW_EULA")
        self.isShowingLinkConfirmation = true
        return true
    end
end

function ZO_EULA:GetNextEulaType()
    for k, eulaType in ipairs(PREGAME_EULAS) do
        if ShouldShowEULA(eulaType) then
            return eulaType
        end
    end
end

function ZO_EULA:ShowNextEULA()
    self.eulaType = self:GetNextEulaType()
    if self.eulaType then
        if ZO_Dialogs_IsShowing("SHOW_EULA") then
            ZO_Dialogs_ReleaseDialog("SHOW_EULA")
        end
        local eulaText, agreeText, disagreeText, hasAgreed, eulaTitle, readCheckText = GetEULADetails(self.eulaType)
        if eulaTitle == "" then
            eulaTitle = SI_WINDOW_TITLE_EULA
        end
        self.titleEulaText = eulaTitle
        self.mainEulaText = eulaText
        self:SetupButtonTextData(agreeText, disagreeText)
        local notifyUpdatedText = GetString("SI_EULATYPE_NOTIFYUPDATED", self.eulaType)
        self.notifyUpdatedTextLabel:SetText(notifyUpdatedText)

        if readCheckText ~= "" then
            ZO_CheckButton_SetLabelText(self.readTextCheckBox, readCheckText)
            ZO_CheckButton_SetToggleFunction(self.readTextCheckBox, function() self:CheckEnableAgreeButton() end)
            self.readTextCheckContainer:SetHidden(false)
        else
            self.readTextCheckContainer:SetHidden(true)
        end
        

        self:ResetDialog()
        ZO_Dialogs_ShowDialog("SHOW_EULA")
    else
        SCENE_MANAGER:Hide("eula")
    end
end

function ZO_EULA:AcceptCurrentEULA()
    AgreeToEULA(self.eulaType)
end

function ZO_EULA:InitializeDialog(dialogControl)
    local function GetMainText()
        return self.mainEulaText
    end

    local function GetTitleText()
        return self.titleEulaText
    end

    self.dialogInfo =
    {
        customControl = dialogControl,
        canQueue = true,
        mustChoose = true,
        title =
        {
            text = GetTitleText
        },
        mainText =
        {
            text = GetMainText
        },
        buttons =
        {
            [1] =
            {
                control = GetControl(dialogControl, "Agree"),
                text = SI_EULA_BUTTON_AGREE,
                noReleaseOnClick = true, -- Don't release because the scene needs to fade out, will release later
                callback =  function(dialog)
                                self:AcceptCurrentEULA()
                                self:ShowNextEULA()
                            end,
            },

            [2] =
            {
                control =   GetControl(dialogControl, "Disagree"),
                text =      SI_EULA_BUTTON_DISAGREE,
                callback =  function(dialog)
                                PregameQuit()
                            end,
            }
        }
    }

    ZO_Dialogs_RegisterCustomDialog("SHOW_EULA", self.dialogInfo)
    
    self.control:GetNamedChild("Title"):SetDimensions(870, 32)

    local function OnDocumentScrollChanged(scrollControl, horizontalOffset, verticalOffset)
        self:CheckEnableAgreeButton(verticalOffset)
    end

    local function OnScrollExtentsChanged()
        ZO_Scroll_OnExtentsChanged(self.scroll:GetParent())
        self.extentsChanged = true
    end
    self.scroll:SetHandler("OnScrollOffsetChanged", OnDocumentScrollChanged)
    self.scroll:SetHandler("OnScrollExtentsChanged", OnScrollExtentsChanged)
end

function ZO_EULA:CheckEnableAgreeButton(verticalOffset)
    if not self.scrolledToBottomOnce then
        if(verticalOffset == nil) then
            local _
            _, verticalOffset = self.scroll:GetScrollOffsets()
        end

        local _, verticalExtent = self.scroll:GetScrollExtents()
        self.scrolledToBottomOnce = (verticalExtent == 0) or zo_floatsAreEqual(verticalOffset, verticalExtent, 0.01)
    end

    if self.scrolledToBottomOnce then
        if self.readTextCheckContainer:IsHidden() then
            self.agreeButton:SetEnabled(true)
        else
            ZO_CheckButton_SetEnableState(self.readTextCheckBox, true)
            self.agreeButton:SetEnabled(ZO_CheckButton_IsChecked(self.readTextCheckBox))
        end
    end
end

function ZO_EULA:ResetDialog()
    if not self.isShowingLinkConfirmation then
        ZO_Scroll_ResetToTop(self.scroll:GetParent())
    end
    self.extentsChanged = false

    local automaticEnableTime = GetFrameTimeMilliseconds() + 5000
    local function OnUpdate()
        local _, verticalExtent = self.scroll:GetScrollExtents()
        if verticalExtent ~= 0 and self.extentsChanged then
            self:CheckEnableAgreeButton()
            self.scroll:SetHandler("OnUpdate", nil)
        end

        if(GetFrameTimeMilliseconds() > automaticEnableTime) then
            if self.readTextCheckContainer:IsHidden() then
                self.agreeButton:SetEnabled(true)
            else
                ZO_CheckButton_SetEnableState(self.readTextCheckBox, true)
            end
            self.scroll:SetHandler("OnUpdate", nil)
        end
    end

    self.scrolledToBottomOnce = false
    self.agreeButton:SetEnabled(false)
    ZO_CheckButton_SetUnchecked(self.readTextCheckBox)
    ZO_CheckButton_SetEnableState(self.readTextCheckBox, false)
    self.scroll:SetHandler("OnUpdate", OnUpdate)
end

function ZO_EULA:SetupButtonTextData(agreeText, disagreeText)
    self.dialogInfo.buttons[1].text = (#agreeText > 0) and agreeText or SI_EULA_BUTTON_AGREE
    self.dialogInfo.buttons[2].text = (#disagreeText > 0) and disagreeText or SI_EULA_BUTTON_DISAGREE
end

function ZO_EULA:CreateEULAScene(control)
    local eulaScene = ZO_Scene:New("eula", SCENE_MANAGER)
    eulaScene:AddFragment(ZO_EULAFragment:New(control))
end

--[[
    Global Functions
--]]

function ZO_EULAInit(control)
    EULA_SCREEN = ZO_EULA:New(control)
end

function ZO_ShouldShowEULAScreen()
    if GetUIPlatform() ~= UI_PLATFORM_PC then
        return ShouldShowEULA(EULA_TYPE_PREGAME_EULA)
    else
        -- The PC loads its additional legal documents differently from console
        for k, eulaType in ipairs(PREGAME_EULAS) do
            if ShouldShowEULA(eulaType) then
                return true
            end
        end
        return false
    end
end