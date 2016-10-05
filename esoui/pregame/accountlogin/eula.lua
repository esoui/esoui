
local PREGAME_EULAS = {
    EULA_TYPE_PREGAME_EULA,
    EULA_TYPE_TERMS_OF_SERVICE,
    EULA_TYPE_PRIVACY_POLICY,
    EULA_TYPE_CODE_OF_CONDUCT,
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
    self.agreeButton = self.control:GetNamedChild("Agree")
    self.scroll = self.control:GetNamedChild("ContainerScroll")
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
        if not HasAgreedToEULA(eulaType) then
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
        local eulaText, agreeText, disagreeText, hasAgreed, eulaTitle = GetEULADetails(self.eulaType)
        if eulaTitle == "" then
            eulaTitle = SI_WINDOW_TITLE_EULA
        end
        self.titleEulaText = eulaTitle
        self.mainEulaText = eulaText
        self:SetupButtonTextData(agreeText, disagreeText)
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

    self.scroll:SetHandler("OnScrollOffsetChanged", OnDocumentScrollChanged)
end

function ZO_EULA:CheckEnableAgreeButton(verticalOffset)
    if(not self.agreeButton.enabledOnce) then
        if(verticalOffset == nil) then
            local _
            _, verticalOffset = self.scroll:GetScrollOffsets()
        end

        local _, verticalExtent = self.scroll:GetScrollExtents()
        self.agreeButton.enabledOnce = (verticalExtent == 0) or zo_floatsAreEqual(verticalOffset, verticalExtent, 0.01)
        self.agreeButton:SetEnabled(self.agreeButton.enabledOnce)
    end
end

function ZO_EULA:ResetDialog()
    if not self.isShowingLinkConfirmation then
        ZO_Scroll_ResetToTop(self.scroll:GetParent())
    end

    local automaticEnableTime = GetFrameTimeMilliseconds() + 5000

    local function OnUpdate()
        local _, verticalExtent = self.scroll:GetScrollExtents()
        if(verticalExtent ~= 0) then
            self:CheckEnableAgreeButton()
            self.scroll:SetHandler("OnUpdate", nil)
        end

        if(GetFrameTimeMilliseconds() > automaticEnableTime) then
            self.agreeButton:SetEnabled(true)
            self.scroll:SetHandler("OnUpdate", nil)            
        end
    end

    self.agreeButton.enabledOnce = false
    self.agreeButton:SetEnabled(false)
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

function ZO_HasAgreedToEULA()
    if GetUIPlatform() ~= UI_PLATFORM_PC then
        return HasAgreedToEULA(EULA_TYPE_PREGAME_EULA)
    else
        -- The PC loads its additional legal documents differently from console
        for k, eulaType in ipairs(PREGAME_EULAS) do
            if not HasAgreedToEULA(eulaType) then
                return false
            end
        end
        return true
    end
end