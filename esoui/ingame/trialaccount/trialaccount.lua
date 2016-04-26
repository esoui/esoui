--Splash Dialog
---------------

local TrialAccountSplashDialog = ZO_Object:Subclass()

function TrialAccountSplashDialog:New(...)
    local trialDialog = ZO_Object.New(self)
    trialDialog:Initialize(...)
    return trialDialog
end

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
            [1] =
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
                [1] =
                {
                    ethereal = true,
                    keybind = "DIALOG_PRIMARY",
                    clickSound = SOUNDS.DIALOG_ACCEPT,
                    callback =  CloseDialog,
                },
                [2] =
                {
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

    local function OnPlayerActivated()
        if self.seenVersion < self.version then
            if IsInGamepadPreferredMode() then
                ZO_Dialogs_ShowGamepadDialog("TRIAL_ACCOUNT_SPLASH_GAMEPAD")
            else
                self.dialogInfo.title.text = self.title
                self.dialogDescription:SetText(self.description)
                local descriptionWidth, descriptionHeight = self.dialogDescription:GetTextDimensions()
                local contentHeight = descriptionHeight + 6
                self.dialogPane:SetHeight(contentHeight)
                self.dialogScrollChild:SetHeight(contentHeight)
                ZO_Dialogs_ShowDialog("TRIAL_ACCOUNT_SPLASH_KEYBOARD")
            end
        end
    end

    control:RegisterForEvent(EVENT_ADD_ON_LOADED, OnAddOnLoaded)
    control:RegisterForEvent(EVENT_PLAYER_ACTIVATED, OnPlayerActivated)
end

function TrialAccountSplashDialog:RemoveSplash()
    self.seenVersion = self.version
    ZO_TrialAccount_SetSeenVersion(self.accountTypeId, self.seenVersion)
    ZO_SavePlayerConsoleProfile()
end

function ZO_TrialAccountSplashDialog_OnInitialized(control)
    TRIAL_ACCOUNT_SPLASH_DIALOG = TrialAccountSplashDialog:New(control)
end