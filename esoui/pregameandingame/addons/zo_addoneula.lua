local g_dialogInfo
local g_addOnEULAFragment

local function AddOnEULADialogInitialize(dialogControl , eulaText, agreeText, disagreeText)
    g_dialogInfo =
    {
        customControl = dialogControl,
        mustChoose = true,
        title =
        {
            text = SI_WINDOW_TITLE_ADDON_EULA,
        },
        mainText =
        {
            text = eulaText,
        },
        buttons =
        {
            [1] =
            {
                control = GetControl(dialogControl, "Agree"),
                text = (#agreeText > 0) and agreeText or SI_EULA_BUTTON_AGREE,
                callback =  function(dialog)
                                AgreeToEULA(EULA_TYPE_ADDON_EULA)
                                SCENE_MANAGER:RemoveFragment(g_addOnEULAFragment)
                            end,
            },
        
            [2] =
            {
                control =   GetControl(dialogControl, "Disagree"),
                text =      (#disagreeText > 0) and disagreeText or SI_EULA_BUTTON_DISAGREE,
                callback =  function(dialog)
                                SCENE_MANAGER:RemoveFragment(g_addOnEULAFragment)
                            end,
            }
        }
    }

    ZO_Dialogs_RegisterCustomDialog("SHOW_ADDON_EULA", g_dialogInfo)
end

local function CheckEnableAgreeButton(agreeButton, scroll, verticalOffset)
    if(not agreeButton.enabledOnce) then
        if(verticalOffset == nil) then
            local _
            _, verticalOffset = scroll:GetScrollOffsets()
        end

        local _, verticalExtent = scroll:GetScrollExtents()
        agreeButton.enabledOnce = (verticalExtent == 0) or zo_floatsAreEqual(verticalOffset, verticalExtent, 0.01)
        agreeButton:SetEnabled(agreeButton.enabledOnce)
    end
end

local function DoInitialUpdate(agreeButton, scroll)
    local automaticEnableTime = GetFrameTimeMilliseconds() + 5000

    local function OnUpdate()
        local _, verticalExtent = scroll:GetScrollExtents()
        if(verticalExtent ~= 0) then
            CheckEnableAgreeButton(agreeButton, scroll)
            scroll:SetHandler("OnUpdate", nil)
        end

        if(GetFrameTimeMilliseconds() > automaticEnableTime) then
            agreeButton:SetEnabled(true)
            scroll:SetHandler("OnUpdate", nil)            
        end
    end

    agreeButton.enabledOnce = false
    agreeButton:SetEnabled(false)
    scroll:SetHandler("OnUpdate", OnUpdate)
end

--[[
    Fragment Creation
--]]
local ZO_AddOnEULAFragment
do
    ZO_AddOnEULAFragment = ZO_FadeSceneFragment:Subclass()

    function ZO_AddOnEULAFragment:New(control)
        local fragment = ZO_FadeSceneFragment.New(self, control, 1500)
        fragment.dialog = control
        return fragment
    end

    function ZO_AddOnEULAFragment:Show()
        local dialog = self.dialog

        MarkEULAAsViewed(EULA_TYPE_ADDON_EULA)
        ZO_Dialogs_ShowDialog("SHOW_ADDON_EULA")
        dialog:GetNamedChild("ModalUnderlay"):SetColor(0, 0, 0, .55)
        DoInitialUpdate(GetControl(dialog, "Agree"), GetControl(dialog, "ContainerScroll"))

        -- Call base class for animations after everything has been tweaked
        ZO_FadeSceneFragment.Show(self)
    end

    function ZO_AddOnEULAFragment:OnHidden()
        ZO_Scroll_ScrollAbsolute(GetControl(self.dialog, "Container"), 0)
        
        ZO_FadeSceneFragment.OnHidden(self)
        CALLBACK_MANAGER:FireCallbacks("AddOnEULAHidden")
    end

    local function DisplayAddOnEULAIfNecessary()
        if not IsInGamepadPreferredMode() then
            if not HasAgreedToEULA(EULA_TYPE_ADDON_EULA) then
                if not ZO_AddOnEula then
                    CreateControlFromVirtual("ZO_AddOnEula", GuiRoot, "ZO_AddOnEulaTemplate")
                end

                SCENE_MANAGER:AddFragment(g_addOnEULAFragment)
            end
        end
    end

    CALLBACK_MANAGER:RegisterCallback("ShowAddOnEULAIfNecessary", DisplayAddOnEULAIfNecessary)
end

--[[
    Global Functions
--]]

function ZO_AddOnEulaInit(self)
    local eulaText, agreeText, disagreeText = GetEULADetails(EULA_TYPE_ADDON_EULA)

    if(not HasAgreedToEULA(EULA_TYPE_ADDON_EULA)) then
        local eulaDialog = self
        AddOnEULADialogInitialize(eulaDialog, eulaText, agreeText, disagreeText)

        eulaDialog:GetNamedChild("Title"):SetDimensions(870, 32)
                
        local function OnDocumentScrollChanged(self, horizontalOffset, verticalOffset)
            CheckEnableAgreeButton(eulaDialog:GetNamedChild("Agree"), self, verticalOffset)
        end

        local scroll = eulaDialog:GetNamedChild("ContainerScroll")
        scroll:SetHandler("OnScrollOffsetChanged", OnDocumentScrollChanged)

        g_addOnEULAFragment = ZO_AddOnEULAFragment:New(eulaDialog)
    else
        AgreeToEULA(EULA_TYPE_ADDON_EULA) -- cleanup
    end
end