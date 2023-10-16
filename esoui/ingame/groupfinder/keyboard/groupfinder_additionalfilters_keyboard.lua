--------------------------------------------------------------
-- ZO_GroupFinder_AdditionalFilters_Keyboard
--------------------------------------------------------------

ZO_GroupFinder_AdditionalFilters_Keyboard = ZO_GroupFinder_AdditionalFilters_Shared:Subclass()

function ZO_GroupFinder_AdditionalFilters_Keyboard:Initialize(control)
    self.control = control
    ZO_GroupFinder_AdditionalFilters_Shared.Initialize(self)
    self:InitializeControls()
    self:InitializeDialog()
end

function ZO_GroupFinder_AdditionalFilters_Keyboard:InitializeControls()
    self.cancelButton = self.control:GetNamedChild("Cancel")
    self.confirmButton = self.control:GetNamedChild("Confirm")
    self.resetButton = self.control:GetNamedChild("Reset")

    self.searchStringEditControl = self.control:GetNamedChild("SearchBoxBackdropEdit")

    self.categoryDropdownControl = self.control:GetNamedChild("CategorySelector")
    self.categoryDropdown = ZO_ComboBox_ObjectFromContainer(self.categoryDropdownControl)
    self.categoryDropdown:SetSortsItems(false)
    self.categoryDropdown:SetFont("ZoFontWinT1")
    self.categoryDropdown:SetSpacing(4)
    self.categoryDropdown:SetHeight(400)
    self:PopulateCategoryDropdown()

    self.primaryOptionDropdownControl = self.control:GetNamedChild("PrimaryFilterSelector")
    self.primaryOptionDropdown = ZO_ComboBox_ObjectFromContainer(self.primaryOptionDropdownControl)
    self.primaryOptionDropdown:SetSortsItems(false)
    self.primaryOptionDropdown:EnableMultiSelect()
    self.primaryOptionDropdown:SetMaxSelections(GROUP_FINDER_MAX_SEARCHABLE_SELECTIONS)
    self.primaryOptionDropdown:SetFont("ZoFontWinT1")
    self.primaryOptionDropdown:SetSpacing(4)
    self.primaryOptionDropdown:SetHeight(400)

    self.primaryOptionDropdownSingleSelectControl = self.control:GetNamedChild("PrimaryFilterSelectorSingleSelect")
    self.primaryOptionDropdownSingleSelect = ZO_ComboBox_ObjectFromContainer(self.primaryOptionDropdownSingleSelectControl)
    self.primaryOptionDropdownSingleSelect:SetSortsItems(false)
    self.primaryOptionDropdownSingleSelect:SetFont("ZoFontWinT1")
    self.primaryOptionDropdownSingleSelect:SetSpacing(4)
    self.primaryOptionDropdownSingleSelect:SetHeight(400)

    self.secondaryOptionDropdownControl = self.control:GetNamedChild("SecondaryFilterSelector")
    self.secondaryOptionDropdown = ZO_ComboBox_ObjectFromContainer(self.secondaryOptionDropdownControl)
    self.secondaryOptionDropdown:SetSortsItems(false)
    self.secondaryOptionDropdown:EnableMultiSelect()
    self.secondaryOptionDropdown:SetMaxSelections(GROUP_FINDER_MAX_SEARCHABLE_SELECTIONS)
    self.secondaryOptionDropdown:SetFont("ZoFontWinT1")
    self.secondaryOptionDropdown:SetSpacing(4)
    self.secondaryOptionDropdown:SetHeight(400)

    local function OnSelectionBlockedCallback(item)
        if item.value == 1 then
            SetGroupFinderFilterSecondaryOptionByIndex(item.value, self.secondaryOptionDropdown:IsItemSelected(item))
            self.secondaryOptionDropdown:ClearAllSelections()
            self.secondaryOptionDropdown:SetSelected(item.value, IGNORE_CALLBACK)
            return true
        end
        return false
    end
    self.secondaryOptionDropdown:SetOnSelectionBlockedCallback(OnSelectionBlockedCallback)

    self.difficultyContainer = self.control:GetNamedChild("DifficultyContainer")
    self.difficultyButtons =
    {
        [DUNGEON_DIFFICULTY_NORMAL] = self.difficultyContainer:GetNamedChild("NormalDifficulty"),
        [DUNGEON_DIFFICULTY_VETERAN] = self.difficultyContainer:GetNamedChild("VeteranDifficulty"),
    }

    self.difficultyRadioButtonGroup = ZO_RadioButtonGroup:New()
    for index, difficultyButton in ipairs(self.difficultyButtons) do
        self.difficultyRadioButtonGroup:Add(difficultyButton)
    end

    local function OnDifficultySelection(newButton, previousButton)
        local value
        for key, buttonControl in ipairs(self.difficultyButtons) do
            if buttonControl == newButton.m_clickedButton then
                value = key

                if newButton ~= previousButton then
                    if key == DUNGEON_DIFFICULTY_NORMAL then
                        PlaySound(SOUNDS.DUNGEON_DIFFICULTY_NORMAL)
                    else
                        PlaySound(SOUNDS.DUNGEON_DIFFICULTY_VETERAN)
                    end
                end
            end
        end
        if value then
            SetGroupFinderFilterPrimaryOptionByIndex(value, true)
            self:PopulateSecondaryDropdown()
        else
            internalassert(false, "No Difficulty button found to match button that was clicked.")
        end
    end

    self.difficultyRadioButtonGroup:SetSelectionChangedCallback(OnDifficultySelection)

    self.sizeDropdownControl = self.control:GetNamedChild("SizeSelector")
    self.sizeDropdown = ZO_ComboBox_ObjectFromContainer(self.sizeDropdownControl)
    self.sizeDropdown:SetSortsItems(false)
    self.sizeDropdown:EnableMultiSelect()
    self.sizeDropdown:SetMaxSelections(GROUP_FINDER_MAX_SEARCHABLE_SELECTIONS)
    self.sizeDropdown:SetFont("ZoFontWinT1")
    self.sizeDropdown:SetSpacing(4)
    self.sizeDropdown:SetHeight(400)

    self.playstyleLabel = self.control:GetNamedChild("PlaystyleLabel")

    self.playstyleDropdownControl = self.control:GetNamedChild("PlaystyleSelector")
    self.playstyleDropdown = ZO_ComboBox_ObjectFromContainer(self.playstyleDropdownControl)
    self.playstyleDropdown:SetSortsItems(false)
    self.playstyleDropdown:EnableMultiSelect()
    self.playstyleDropdown:SetMaxSelections(GROUP_FINDER_MAX_SEARCHABLE_SELECTIONS)
    self.playstyleDropdown:SetFont("ZoFontWinT1")
    self.playstyleDropdown:SetSpacing(4)
    self.playstyleDropdown:SetHeight(400)

    -- Set up check button labels
    self.championCheckbox = self.control:GetNamedChild("ChampionCheckButton")
    ZO_CheckButton_SetLabelText(self.championCheckbox, zo_strformat(SI_GROUP_FINDER_CHAMPION_REQUIRED_TEXT, ZO_GetChampionIconMarkupString(ZO_GROUP_LISTING_CHAMPION_ICON_SIZE)))
    self.championTextBox = self.control:GetNamedChild("ChampionTextBox")
    self.championTextBoxControl = self.championTextBox:GetNamedChild("BackdropEdit")
    self.championTextBox:ClearAnchors()
    self.championTextBox:SetAnchor(LEFT, self.championCheckbox.label, RIGHT, 5)
    local function ToggleChampionCheckbox(button, checked)
        SetGroupFinderFilterRequiresChampion(checked)
        self.championTextBox:SetHidden(not checked)
    end
    ZO_CheckButton_SetToggleFunction(self.championCheckbox, ToggleChampionCheckbox)

    self.voipCheckbox = self.control:GetNamedChild("VOIPCheckButton")
    ZO_CheckButton_SetLabelText(self.voipCheckbox, GetString(SI_GROUP_FINDER_FILTERS_VOIP))
    ZO_CheckButton_SetToggleFunction(self.voipCheckbox, function(button, checked) SetGroupFinderFilterRequiresVOIP(checked) end)

    self.inviteCodeCheckbox = self.control:GetNamedChild("InviteCodeCheckButton")
    ZO_CheckButton_SetLabelText(self.inviteCodeCheckbox, GetString(SI_GROUP_FINDER_FILTERS_INVITE_CODE))
    ZO_CheckButton_SetToggleFunction(self.inviteCodeCheckbox, function(button, checked) SetGroupFinderFilterRequiresInviteCode(checked) end)

    self.autoAcceptCheckbox = self.control:GetNamedChild("AutoAcceptCheckButton")
    ZO_CheckButton_SetLabelText(self.autoAcceptCheckbox, GetString(SI_GROUP_FINDER_FILTERS_AUTO_ACCEPT))
    ZO_CheckButton_SetToggleFunction(self.autoAcceptCheckbox, function(button, checked) SetGroupFinderFilterAutoAcceptRequests(checked) end)

    self.ownRoleOnlyCheckbox = self.control:GetNamedChild("OwnRoleOnlyCheckButton")
    ZO_CheckButton_SetLabelText(self.ownRoleOnlyCheckbox, GetString(SI_GROUP_FINDER_FILTERS_OWN_ROLE))
    ZO_CheckButton_SetToggleFunction(self.ownRoleOnlyCheckbox, function(button, checked) SetGroupFinderFilterEnforceRoles(checked) end)
end

function ZO_GroupFinder_AdditionalFilters_Keyboard:OnSecondarySelection(dropdown, selectedDataName, selectedData)
    ZO_GroupFinder_AdditionalFilters_Shared.OnSecondarySelection(self, dropdown, selectedDataName, selectedData)

    local IGNORE_CALLBACK = true
    dropdown:ClearAllSelections()
    for i = 1, GetGroupFinderFilterNumSecondaryOptions() do
        local _, isSet = GetGroupFinderFilterSecondaryOptionByIndex(i)
        if isSet then
            dropdown:SetSelected(i, IGNORE_CALLBACK)
        end
    end
end

function ZO_GroupFinder_AdditionalFilters_Keyboard:InitializeDialog()
    ZO_Dialogs_RegisterCustomDialog("GROUP_FINDER_ADDITIONAL_FILTERS_KEYBOARD",
    {
        customControl = self.control,
        canQueue = true,
        title =
        {
            text = SI_GROUP_FINDER_FILTERS_TITLE,
        },
        setup = function(dialog, data)
            self:Refresh()
        end,
        finishedCallback = function()
            GROUP_FINDER_KEYBOARD:RefreshFilterOptions()
            GROUP_FINDER_KEYBOARD:RefreshCurrentRoleLabel()
        end,
        buttons =
        {
            {
                keybind = "DIALOG_NEGATIVE",
                control = self.cancelButton,
                text = SI_DIALOG_CANCEL,
                callback = function(dialog)
                    CancelGroupFinderFilterOptionsChanges()
                    ZO_Dialogs_ReleaseDialogOnButtonPress("GROUP_FINDER_ADDITIONAL_FILTERS_GAMEPAD")
                end,
            },
            {
                keybind = "DIALOG_PRIMARY",
                control = self.confirmButton,
                text = SI_DIALOG_CONFIRM,
                callback = function(dialog)
                    GROUP_FINDER_KEYBOARD:ExecuteSearchForCategory(GetGroupFinderFilterCategory())
                end,
            },
            {
                keybind = "DIALOG_RESET",
                control = self.resetButton,
                text = SI_GROUP_FINDER_FILTERS_RESET,
                noReleaseOnClick = true,
                enabled = function(dialog)
                    -- TODO GroupFinder: Check to see if filters are already default
                    return true
                end,
                callback = function(dialog)
                    ResetGroupFinderFilterOptionsToDefault()
                    self:Refresh()
                end,
            },
        },
    })
end

function ZO_GroupFinder_AdditionalFilters_Keyboard:Refresh()
    local IGNORE_CALLBACK = true
    local secondaryOptionAnchorParent
    local category = GetGroupFinderFilterCategory()
    local categoryIndex = category + 1 -- Category Enum starts at 0 so index will always be one greater than value.
    local showDifficultyAsPrimaryOption = category == GROUP_FINDER_CATEGORY_DUNGEON or category == GROUP_FINDER_CATEGORY_ARENA or category == GROUP_FINDER_CATEGORY_TRIAL
    local showSingleSelectAsPrimaryOption = category == GROUP_FINDER_CATEGORY_PVP
    local dontShowPrimaryOrSecondary = category == GROUP_FINDER_CATEGORY_ENDLESS_DUNGEON or category == GROUP_FINDER_CATEGORY_CUSTOM

    UpdateGroupFinderFilterOptions()

    self.searchStringEditControl:SetText(GetGroupFinderGroupFilterSearchString())

    self.categoryDropdown:SelectItemByIndex(categoryIndex, IGNORE_CALLBACK)

    -- TODO GroupFinder: Consider using a single dropdown that switches between multi-select and single select
    self:PopulatePrimaryDropdown()
    self:PopulatePrimaryDropdownSingleSelect()
    self.primaryOptionDropdownControl:SetHidden(showDifficultyAsPrimaryOption or showSingleSelectAsPrimaryOption or dontShowPrimaryOrSecondary)
    self.primaryOptionDropdownSingleSelectControl:SetHidden(not showSingleSelectAsPrimaryOption or dontShowPrimaryOrSecondary)

    self.difficultyContainer:SetHidden(not showDifficultyAsPrimaryOption or dontShowPrimaryOrSecondary)
    if showDifficultyAsPrimaryOption then
        local totalDifficulties = #self.difficultyButtons
        local availableDifficulties = GetGroupFinderFilterNumPrimaryOptions()
        for i = 1, totalDifficulties do
            if i <= availableDifficulties then
                local _, isSet = GetGroupFinderFilterPrimaryOptionByIndex(i)
                self.difficultyRadioButtonGroup:SetButtonIsValidOption(self.difficultyButtons[i], true)
                if isSet then
                    self.difficultyRadioButtonGroup:SetClickedButton(self.difficultyButtons[i])
                end
            else
                self.difficultyRadioButtonGroup:SetButtonIsValidOption(self.difficultyButtons[i], false)
            end
            self.difficultyButtons[i]:SetHidden(false)
        end
        secondaryOptionAnchorParent = self.difficultyContainer
    else
        secondaryOptionAnchorParent = self.primaryOptionDropdownControl
    end
    self.secondaryOptionDropdownControl:ClearAnchors()
    self.secondaryOptionDropdownControl:SetAnchor(LEFT, secondaryOptionAnchorParent, RIGHT, 5, 0)

    self:PopulateSecondaryDropdown()
    self.secondaryOptionDropdownControl:SetHidden(dontShowPrimaryOrSecondary)

    self:PopulateSizeDropdown()

    self.championCheckbox:ClearAnchors()
    if showDifficultyAsPrimaryOption then
        self:PopulatePlaystyleDropdown()
        self.championCheckbox:SetAnchor(TOPLEFT, self.playstyleDropdownControl, BOTTOMLEFT, 0, 10)
        self.playstyleLabel:SetHidden(false)
        self.playstyleDropdownControl:SetHidden(false)
    else
        local dividerControl = self.control:GetNamedChild("SecondaryDivider")
        self.championCheckbox:SetAnchor(TOP, dividerControl, BOTTOM, 0, 4, ANCHOR_CONSTRAINS_Y)
        self.championCheckbox:SetAnchor(LEFT, self.sizeDropdownControl, LEFT, 0, 4, ANCHOR_CONSTRAINS_X)
        self.playstyleLabel:SetHidden(true)
        self.playstyleDropdownControl:SetHidden(true)
    end

    self:UpdateCheckStateRequireChampion()
    self:UpdateCheckStateRequireVOIP()
    self:UpdateCheckStateInviteCode()
    self:UpdateCheckStateAutoAcceptRequests()
    self:UpdateCheckStateOwnRoles()
end

--Overridden from base
function ZO_GroupFinder_AdditionalFilters_Keyboard:UpdateCheckStateRequireChampion()
    ZO_GroupFinder_AdditionalFilters_Shared.UpdateCheckStateRequireChampion(self)
    self.championTextBox:SetHidden(not DoesGroupFinderFilterRequireChampion())
end

---------------------------------
-- Global .xml
---------------------------------

function ZO_GroupFinder_AdditionalFilters_OnInitialized(control)
    GROUPFINDER_ADDITIONAL_FILTERS_KEYBOARD = ZO_GroupFinder_AdditionalFilters_Keyboard:New(control)
end

function ZO_GroupFinder_AdditionalFilters_OnSearchEditControlFocusLost(control)
    SetGroupFinderGroupFilterSearchString(control:GetText())
end

function ZO_GroupFinder_AdditionalFilters_OnChampionPointsFocusLost(control)
    local championPoints = control:GetText()
    SetGroupFinderFilterChampionPoints(tonumber(championPoints))
end