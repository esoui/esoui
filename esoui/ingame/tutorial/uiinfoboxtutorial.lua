ZO_UiInfoBoxTutorial = ZO_TutorialHandlerBase:Subclass()

local TUTORIAL_SEEN = true
local TUTORIAL_NOT_SEEN = false

--Allow extra space for icons and keybind backgrounds that can extend above and below the top and bottom lines.
ZO_TUTORIAL_DIALOG_DESCRIPTION_EDGE_PADDING_Y = 6
ZO_TUTORIAL_DIALOG_DESCRIPTION_TOTAL_PADDING_Y = ZO_TUTORIAL_DIALOG_DESCRIPTION_EDGE_PADDING_Y * 2
ZO_TUTORIAL_DIALOG_SOFT_MAX_HEIGHT = 350
ZO_TUTORIAL_DIALOG_HARD_MAX_HEIGHT = 360

function ZO_UiInfoBoxTutorial:Initialize()
    self:ClearAll()
        
    local dialog = ZO_TutorialDialog
    self.dialogPane = dialog:GetNamedChild("Pane")
    self.dialogScrollChild = self.dialogPane:GetNamedChild("ScrollChild")
    self.dialogDescription = self.dialogScrollChild:GetNamedChild("Description")
    self.dialogInfo =
    {
        title = {},
        customControl = dialog,
        noChoiceCallback = function(dialog)
                           dialog.data.owner:RemoveTutorial(dialog.data.tutorialIndex, TUTORIAL_SEEN)
                       end,
        buttons =
        {
            [1] =
            {
                control = dialog:GetNamedChild("Cancel"),
                text = SI_EXIT_BUTTON,
                keybind = "DIALOG_NEGATIVE",
                clickSound = SOUNDS.DIALOG_ACCEPT,
                callback =  function(dialog)
                                dialog.data.owner:RemoveTutorial(dialog.data.tutorialIndex, TUTORIAL_SEEN)
                            end,
            },
        }
    }

    ZO_Dialogs_RegisterCustomDialog("UI_TUTORIAL", self.dialogInfo)

    ZO_Dialogs_RegisterCustomDialog("UI_TUTORIAL_GAMEPAD", 
        {
            canQueue = true,
            setup = function(dialog)
                dialog:setupFunc()
            end,
            gamepadInfo =
            {
                dialogType = GAMEPAD_DIALOGS.CENTERED,
            },
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
                    --Ethereal binds show no text, the name field is used to help identify the keybind when debugging. This text does not have to be localized.
                    name = "Gamepad Tutorial Accept",
                    ethereal = true,
                    keybind =    "DIALOG_PRIMARY",
                    clickSound = SOUNDS.DIALOG_ACCEPT,
                    callback =  function(dialog)
                                    dialog.data.owner:RemoveTutorial(dialog.data.tutorialIndex, TUTORIAL_SEEN)
                                end,
                }
            },
            noChoiceCallback = function(dialog)
                               if dialog.data then
                                    dialog.data.owner:RemoveTutorial(dialog.data.tutorialIndex, TUTORIAL_SEEN)
                               end
                           end,
            finishedCallback = function(dialog)
                                if dialog.data then
                                    FireTutorialHiddenEvent(dialog.data.tutorialIndex)
                                end
                            end,
            removedFromQueueCallback = function(data)
                               if data then
                                    data.owner:RemoveTutorial(data.tutorialIndex, TUTORIAL_NOT_SEEN)
                               end
                           end,
        }
    )

    self.gamepadMode = false

end

function ZO_UiInfoBoxTutorial:GetDialog()
    return self.dialogs[self.gamepadMode]
end

function ZO_UiInfoBoxTutorial:SuppressTutorials(suppress, reason)
    -- Suppression is disabled in ZO_UiInfoBoxTutorial
end

function ZO_UiInfoBoxTutorial:GetTutorialType()
    return TUTORIAL_TYPE_UI_INFO_BOX
end

--Additional spacing to account for the backdrop behind a key label if there's one in the last line or the first line
function ZO_UiInfoBoxTutorial:DisplayTutorial(tutorialIndex)
    self.title, self.description = GetTutorialInfo(tutorialIndex)

    self.title = zo_strformat(SI_TUTORIAL_FORMATTER, self.title)
    self.description = zo_strformat(SI_TUTORIAL_FORMATTER, self.description)

    self:SetCurrentlyDisplayedTutorialIndex(tutorialIndex)
    self.gamepadMode = IsInGamepadPreferredMode()

    if self.gamepadMode then
        ZO_Dialogs_ShowGamepadDialog("UI_TUTORIAL_GAMEPAD", { tutorialIndex = tutorialIndex, owner = self })
    else
        self.dialogInfo.title.text = self.title
        self.dialogDescription:SetText(self.description)
        local descriptionHeight = self.dialogDescription:GetTextHeight() + ZO_TUTORIAL_DIALOG_DESCRIPTION_TOTAL_PADDING_Y
        self.dialogScrollChild:SetHeight(descriptionHeight)

        --To prevent having this pane scroll over a tiny amount of space we only force it to scroll if it hits the hard max height. This guarentees that it will scroll at least (hard - soft UI units).
        local paneHeight = descriptionHeight
        if paneHeight > ZO_TUTORIAL_DIALOG_HARD_MAX_HEIGHT then
            paneHeight = ZO_TUTORIAL_DIALOG_SOFT_MAX_HEIGHT
        end
        self.dialogPane:SetHeight(paneHeight)

        ZO_Scroll_ResetToTop(self.dialogPane)    
        ZO_Dialogs_ShowDialog("UI_TUTORIAL", { tutorialIndex = tutorialIndex, owner = self })
    end
end

function ZO_UiInfoBoxTutorial:OnDisplayTutorial(tutorialIndex, priority)
    if not IsGameCameraActive() or SCENE_MANAGER:IsInUIMode() then
        if not self:IsTutorialDisplayedOrQueued(tutorialIndex) then
            if self:CanShowTutorial() then
                self:DisplayTutorial(tutorialIndex)
            end
        end
    end
end

function ZO_UiInfoBoxTutorial:OnRemoveTutorial(tutorialIndex)
    self:RemoveTutorial(tutorialIndex, TUTORIAL_SEEN)
end

function ZO_UiInfoBoxTutorial:RemoveTutorial(tutorialIndex, seen)
    if self:GetCurrentlyDisplayedTutorialIndex() == tutorialIndex then
        if seen then
            SetTutorialSeen(tutorialIndex)
        end

        self:SetCurrentlyDisplayedTutorialIndex(nil)
        ZO_Dialogs_ReleaseDialog("UI_TUTORIAL")
        ZO_Dialogs_ReleaseDialog("UI_TUTORIAL_GAMEPAD")
    else
        self:RemoveFromQueue(self.queue, tutorialIndex)
    end
end

function ZO_UiInfoBoxTutorial:ClearAll()
    self:SetCurrentlyDisplayedTutorialIndex(nil)
    self.queue = {}
end
