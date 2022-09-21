--Splash Dialog
---------------

local TrialAccountSplashDialog = ZO_InitializingObject:Subclass()

function TrialAccountSplashDialog:Initialize(control)
    self.control = control
    self.dialogPane = control:GetNamedChild("Pane")
    self.dialogScrollChild = self.dialogPane:GetNamedChild("ScrollChild")
    self.dialogDescription = self.dialogPane:GetNamedChild("Description")

    local function CloseDialog()
        self:RemoveSplash()
    end

    self.dialogInfo =
    {
        customControl = control,
        title = {},
        noChoiceCallback = CloseDialog,
        buttons =
        {
            {
                control = control:GetNamedChild("Cancel"),
                text = SI_DIALOG_EXIT,
                keybind = "DIALOG_NEGATIVE",
                clickSound = SOUNDS.DIALOG_ACCEPT,
                callback =  CloseDialog,
            },
        }
    }

    ZO_Dialogs_RegisterCustomDialog("TRIAL_ACCOUNT_SPLASH_KEYBOARD", self.dialogInfo)

    ZO_Dialogs_RegisterCustomDialog("TRIAL_ACCOUNT_SPLASH_GAMEPAD", 
        {
            setup = function(dialog)
                dialog:setupFunc()
            end,
            gamepadInfo =
            {
                dialogType = GAMEPAD_DIALOGS.CENTERED,
            },
            canQueue = true,
            title =
            {
                text = function()
                    return self.title
                end,
            },
            mainText =
            {
                text = function()
                    return self.description
                end,
            },
            buttons =
            {
                {
                    -- Even though this is an ethereal keybind, the name will still be shown as the centered dialogs interact keybind and read during screen narration
                    name = GetString(SI_TUTORIAL_CONTINUE),
                    ethereal = true,
                    narrateEthereal = true,
                    keybind = "DIALOG_PRIMARY",
                    clickSound = SOUNDS.DIALOG_ACCEPT,
                    callback =  CloseDialog,
                },
                {
                    --Ethereal binds show no text, the name field is used to help identify the keybind when debugging. This text does not have to be localized.
                    name = "Free Trial Close Dialog 2",
                    ethereal = true,
                    keybind = "DIALOG_NEGATIVE",
                    clickSound = SOUNDS.DIALOG_ACCEPT,
                    callback =  CloseDialog,
                },
            },
            noChoiceCallback = CloseDialog,
            finishedCallback = CloseDialog,
            removedFromQueueCallback = CloseDialog,
        }
    )

    local function OnAddOnLoaded()
        self.accountTypeId, self.title, self.description, self.version, self.seenVersion = ZO_TrialAccount_GetInfo()
        self.control:UnregisterForEvent(EVENT_ADD_ON_LOADED)
    end

    control:RegisterForEvent(EVENT_ADD_ON_LOADED, OnAddOnLoaded)
end

function TrialAccountSplashDialog:HasPlayerSeenCurrentVersion()
    return self.seenVersion >= self.version
end

function TrialAccountSplashDialog:ShouldShowSplash()
    return not self:HasPlayerSeenCurrentVersion()
end

function TrialAccountSplashDialog:ShowSplash()
    if IsInGamepadPreferredMode() then
        ZO_Dialogs_ShowGamepadDialog("TRIAL_ACCOUNT_SPLASH_GAMEPAD")
    else
        self.dialogInfo.title.text = self.title
        self.dialogDescription:SetText(self.description)
        local descriptionHeight = self.dialogDescription:GetTextHeight()
        local contentHeight = descriptionHeight + 6
        self.dialogPane:SetHeight(contentHeight)
        self.dialogScrollChild:SetHeight(contentHeight)
        ZO_Dialogs_ShowDialog("TRIAL_ACCOUNT_SPLASH_KEYBOARD")
    end
end

function TrialAccountSplashDialog:RemoveSplash()
    self.seenVersion = self.version
    ZO_TrialAccount_SetSeenVersion(self.accountTypeId, self.seenVersion)
    ZO_SavePlayerConsoleProfile()
end

----
-- Global functions
----

do
    local SETTING_FORMAT = "TrialAccountType%iSeenVersion"

    function ZO_TrialAccount_GetInfo()
        local accountTypeId, title, description, currentVersion = GetTrialInfo()
        local seenVersion = 0
        if accountTypeId > 0 then
            local settingName = string.format(SETTING_FORMAT, accountTypeId)
            seenVersion = GetCVar(settingName)

            --If the setting has not been created in GameSettings.xml, we must add it if we want to be able to see the pop-up
            --Otherwise we just pretend like we've seen it
            if seenVersion == "" then
                seenVersion = currentVersion
            else
                seenVersion = tonumber(seenVersion)
            end
        end
        return accountTypeId, title, description, currentVersion, seenVersion
    end

    function ZO_TrialAccount_SetSeenVersion(accountTypeId, seenVersion)
        local settingName = string.format(SETTING_FORMAT, accountTypeId)
        SetCVar(settingName, seenVersion)
    end
end

function ZO_TrialAccountSplashDialog_OnInitialized(control)
    TRIAL_ACCOUNT_SPLASH_DIALOG = TrialAccountSplashDialog:New(control)
end