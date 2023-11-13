--------------------------------------------------------------
-- ZO_GroupFinder_CreateEditGroupListing_Keyboard
--------------------------------------------------------------

ZO_GroupFinder_CreateEditGroupListing_Keyboard = ZO_Object.MultiSubclass(ZO_GroupFinder_BasePanel_Keyboard, ZO_GroupFinder_CreateEditGroupListing_Shared)

function ZO_GroupFinder_CreateEditGroupListing_Keyboard:Initialize(control)
    ZO_GroupFinder_CreateEditGroupListing_Shared.Initialize(self)
    ZO_GroupFinder_BasePanel_Keyboard.Initialize(self, control)

    ZO_ACTIVITY_FINDER_ROOT_MANAGER:RegisterCallback("OnActivityFinderStatusUpdate", function() self:UpdateCreateEditButton() end)
end

function ZO_GroupFinder_CreateEditGroupListing_Keyboard:InitializeControls()
    self.contentControl = self.control:GetNamedChild("Content")
    self.categoryDropdownControl = self.contentControl:GetNamedChild("CategoryDropdown")
    self.primaryOptionDropdownControl = self.contentControl:GetNamedChild("PrimaryDropdown")
    self.secondaryOptionDropdownControl = self.contentControl:GetNamedChild("SecondaryDropdown")
    self.difficultyRadioContainer = self.contentControl:GetNamedChild("DifficultyRadioContainer")
    self.sizeDropdownControl = self.contentControl:GetNamedChild("SizeDropdown")
    self.groupTitleEditControl = self.contentControl:GetNamedChild("GroupTitleBackdropEdit")
    self.descriptionEditControl = self.contentControl:GetNamedChild("DescriptionEdit")
    self.playstyleLabel = self.contentControl:GetNamedChild("PlaystyleLabel")
    self.playstyleDropdownControl = self.contentControl:GetNamedChild("PlaystyleDropdown")
    self.championCheckbox = self.contentControl:GetNamedChild("ChampionCheckButton")
    self.championCheckbox:SetText(zo_strformat(SI_GROUP_FINDER_CHAMPION_REQUIRED_TEXT, ZO_GetChampionIconMarkupString(ZO_GROUP_LISTING_CHAMPION_ICON_SIZE)))
    self.championPointsEditBox = self.contentControl:GetNamedChild("ChampionPointsEditBox")
    self.championPointsEditBoxControl = self.championPointsEditBox:GetNamedChild("BackdropEdit")
    self.voipCheckbox = self.contentControl:GetNamedChild("VOIPCheckButton")
    self.inviteCodeCheckbox = self.contentControl:GetNamedChild("InviteCodeCheckButton")
    self.inviteCodeEditBox = self.contentControl:GetNamedChild("InviteCodeEditBox")
    self.inviteCodeEditBoxControl = self.inviteCodeEditBox:GetNamedChild("BackdropEdit")
    self.autoAcceptCheckbox = self.contentControl:GetNamedChild("AutoAcceptCheckButton")
    self.enforceRolesCheckbox = self.contentControl:GetNamedChild("EnforceRolesCheckButton")
    self.createEditButton = self.contentControl:GetNamedChild("CreateEditGroupButton")

    self.categoryDropdown = ZO_ComboBox_ObjectFromContainer(self.categoryDropdownControl)
    self.categoryDropdown:SetSortsItems(false)
    self.categoryDropdown:SetFont("ZoFontWinT1")
    self.categoryDropdown:SetSpacing(4)
    self.categoryDropdown:SetHeight(400)

    self.primaryOptionDropdown = ZO_ComboBox_ObjectFromContainer(self.primaryOptionDropdownControl)
    self.primaryOptionDropdown:SetSortsItems(false)
    self.primaryOptionDropdown:SetFont("ZoFontWinT1")
    self.primaryOptionDropdown:SetSpacing(4)
    self.primaryOptionDropdown:SetHeight(400)

    self.secondaryOptionDropdown = ZO_ComboBox_ObjectFromContainer(self.secondaryOptionDropdownControl)
    self.secondaryOptionDropdown:SetSortsItems(false)
    self.secondaryOptionDropdown:SetFont("ZoFontWinT1")
    self.secondaryOptionDropdown:SetSpacing(4)
    self.secondaryOptionDropdown:SetHeight(400)

    self.difficultyButtons =
    {
        [DUNGEON_DIFFICULTY_NORMAL] = self.difficultyRadioContainer:GetNamedChild("NormalDifficulty"),
        [DUNGEON_DIFFICULTY_VETERAN] = self.difficultyRadioContainer:GetNamedChild("VeteranDifficulty"),
    }

    self.difficultyRadioButtonGroup = ZO_RadioButtonGroup:New()
    for index, difficultyButton in ipairs(self.difficultyButtons) do
        self.difficultyRadioButtonGroup:Add(difficultyButton)
    end

    self.sizeDropdown = ZO_ComboBox_ObjectFromContainer(self.sizeDropdownControl)
    self.sizeDropdown:SetSortsItems(false)
    self.sizeDropdown:SetFont("ZoFontWinT1")
    self.sizeDropdown:SetSpacing(4)
    self.sizeDropdown:SetHeight(400)

    self.playstyleDropdown = ZO_ComboBox_ObjectFromContainer(self.playstyleDropdownControl)
    self.playstyleDropdown:SetSortsItems(false)
    self.playstyleDropdown:SetFont("ZoFontWinT1")
    self.playstyleDropdown:SetSpacing(4)
    self.playstyleDropdown:SetHeight(400)

    ZO_CheckButton_SetLabelText(self.championCheckbox, zo_strformat(SI_GROUP_FINDER_CHAMPION_REQUIRED_TEXT, ZO_GetChampionIconMarkupString(ZO_GROUP_LISTING_CHAMPION_ICON_SIZE)))
    ZO_CheckButton_SetLabelText(self.voipCheckbox, GetString(SI_GROUP_FINDER_CREATE_VOIP_REQUIRED_TEXT))
    ZO_CheckButton_SetLabelText(self.inviteCodeCheckbox, GetString(SI_GROUP_FINDER_CREATE_INVITE_CODE_TEXT))
    ZO_CheckButton_SetLabelText(self.autoAcceptCheckbox, GetString(SI_GROUP_FINDER_CREATE_AUTO_ACCEPT_TEXT))
    ZO_CheckButton_SetLabelText(self.enforceRolesCheckbox, GetString(SI_GROUP_FINDER_CREATE_ENFORCE_ROLES_TEXT))

    local function ToggleChampionCheckbox(button, checked)
        self.userTypeData:SetGroupRequiresChampion(checked)
        self.championPointsEditBox:SetHidden(not checked)
        self:UpdateCreateEditButton()
    end

    local function ToggleRequiresVOIPCheckbox(button, checked)
        self.userTypeData:SetGroupRequiresVOIP(checked)
        self:UpdateCreateEditButton()
    end

    local function ToggleInviteCodeCheckbox(button, checked)
        self.userTypeData:SetGroupRequiresInviteCode(checked)
        self.inviteCodeEditBox:SetHidden(not checked)
        self:UpdateCreateEditButton()
    end

    local function ToggleAutoAcceptCheckbox(button, checked)
        self.userTypeData:SetGroupAutoAcceptRequests(checked)
        self:UpdateCreateEditButton()
    end

    local function ToggleEnforceRolesCheckbox(button, checked)
        self.userTypeData:SetGroupEnforceRoles(checked)
        self:UpdateCheckStateEnforceRoles()
        self:UpdateCreateEditButton()
    end

    ZO_CheckButton_SetToggleFunction(self.championCheckbox, ToggleChampionCheckbox)
    ZO_CheckButton_SetToggleFunction(self.voipCheckbox, ToggleRequiresVOIPCheckbox)
    ZO_CheckButton_SetToggleFunction(self.inviteCodeCheckbox, ToggleInviteCodeCheckbox)
    ZO_CheckButton_SetToggleFunction(self.autoAcceptCheckbox, ToggleAutoAcceptCheckbox)
    ZO_CheckButton_SetToggleFunction(self.enforceRolesCheckbox, ToggleEnforceRolesCheckbox)

    local championCheckboxLabel = self.championCheckbox:GetNamedChild("Label")
    self.championPointsEditBox:SetAnchor(LEFT, championCheckboxLabel, RIGHT, 5, 0)
    self.championPointsEditBox:SetHidden(not self.userTypeData:DoesGroupRequireChampion())

    local inviteCodeCheckboxLabel = self.inviteCodeCheckbox:GetNamedChild("Label")
    self.inviteCodeEditBox:SetAnchor(LEFT, inviteCodeCheckboxLabel, RIGHT, 5, 0)
    self.inviteCodeEditBox:SetHidden(not self.userTypeData:DoesGroupRequireInviteCode())

    self.roleContainerControl = self.contentControl:GetNamedChild("RoleContainer")
    self.roleSpinnerTable =
    {
        [LFG_ROLE_TANK] = self.roleContainerControl:GetNamedChild("Tank"),
        [LFG_ROLE_HEAL] = self.roleContainerControl:GetNamedChild("Heal"),
        [LFG_ROLE_DPS] = self.roleContainerControl:GetNamedChild("DPS"),
        [LFG_ROLE_INVALID] = self.roleContainerControl:GetNamedChild("Any"),
    }

    local function GetRoleMin(spinner)
        return self.userTypeData:GetAttainedRoleCountAtEdit(spinner.roleType)
    end

    local function GetRoleMax(spinner)
        if spinner.roleType == LFG_ROLE_INVALID then
            return self.userTypeData:GetNumRoles()
        else
            return self.userTypeData:GetDesiredRoleCountAtEdit(spinner.roleType) + self.userTypeData:GetDesiredRoleCountAtEdit(LFG_ROLE_INVALID)
        end
    end

    local function OnValueChanged(value, spinner)
        self.userTypeData:SetDesiredRoleCountAtEdit(spinner.roleType, value)
        self:UpdateRoles()
    end

    for roleType, control in pairs(self.roleSpinnerTable) do
        control.title:SetText(self:GetRoleLabelText(roleType))
        control.spinner.roleType = roleType
        control.spinner:SetMinMax(GetRoleMin, GetRoleMax)
        control.spinner:RegisterCallback("OnValueChanged", OnValueChanged)
    end

    self.roleSpinnerTable[LFG_ROLE_INVALID].spinner:SetButtonsHidden(true)
    self:UpdateRoles()

    self:PopulateCategoryDropdown()

    local function OnDifficultySelection(newButton, previousButton)
        if self.userTypeData:IsUserTypeActive() then
            local value = 0
            for key, control in ipairs(self.difficultyButtons) do
                if control == newButton.m_clickedButton then
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
                self.userTypeData:SetPrimaryOption(value)
                self:PopulateSecondaryDropdown()
            else
                internalassert(false, "No Difficulty button found to match button that was clicked.")
            end
        end
    end

    self.difficultyRadioButtonGroup:SetSelectionChangedCallback(OnDifficultySelection)

    local VALIDATOR_RULES =
    {
        NAME_RULE_TOO_SHORT,
        NAME_RULE_CANNOT_START_WITH_SPACE,
        NAME_RULE_MUST_END_WITH_LETTER,
        NAME_RULE_TOO_MANY_IDENTICAL_ADJACENT_CHARACTERS,
        NAME_RULE_NO_ADJACENT_PUNCTUATION_CHARACTERS,
        NAME_RULE_TOO_MANY_PUNCTUATION_CHARACTERS,
        NAME_RULE_INVALID_CHARACTERS,
        NAME_RULE_TOO_FEW_ALPHA_CHARACTERS,
    }
    local DEFAULT_TEMPLATE = nil
    self.groupTitleInstructions = ZO_ValidNameInstructions:New(self.contentControl:GetNamedChild("Instructions"), DEFAULT_TEMPLATE, VALIDATOR_RULES)

    self:Refresh()

    local unusedTitle = ""
    self:OnCategorySelection(self.categoryDropdown, unusedTitle, { value = self.userTypeData:GetCategory() })
end

function ZO_GroupFinder_CreateEditGroupListing_Keyboard:OnPlaystyleSelection(comboBox, selectedDataName, selectedData, selectionChanged, oldData)
    ZO_GroupFinder_CreateEditGroupListing_Shared.OnPlaystyleSelection(self, comboBox, selectedDataName, selectedData, selectionChanged, oldData)
    self:UpdateCreateEditButton()
end

function ZO_GroupFinder_CreateEditGroupListing_Keyboard:PopulatePrimaryDropdown()
    ZO_GroupFinder_CreateEditGroupListing_Shared.PopulatePrimaryDropdown(self)

    local userType = self.userTypeData:GetUserType()
    local category = self.userTypeData:GetCategory()
    local secondaryOptionAnchorParent
    local showDifficultyAsPrimaryOption = category == GROUP_FINDER_CATEGORY_DUNGEON or category == GROUP_FINDER_CATEGORY_ARENA or category == GROUP_FINDER_CATEGORY_TRIAL
    local dontShowPrimaryOrSecondary = category == GROUP_FINDER_CATEGORY_ENDLESS_DUNGEON or category == GROUP_FINDER_CATEGORY_CUSTOM
    local isUserTypeDraft = userType == GROUP_FINDER_GROUP_LISTING_USER_TYPE_GROUP_LISTING_DRAFT

    self.primaryOptionDropdownControl:SetHidden(showDifficultyAsPrimaryOption or dontShowPrimaryOrSecondary)
    self.primaryOptionDropdown:SetEnabled(isUserTypeDraft)

    self.difficultyRadioContainer:SetHidden(not showDifficultyAsPrimaryOption or dontShowPrimaryOrSecondary)
    if showDifficultyAsPrimaryOption then
        local totalDifficulties = #self.difficultyButtons
        local availableDifficulties = self.userTypeData:GetNumPrimaryOptions()
        self.difficultyRadioButtonGroup:SetEnabled(isUserTypeDraft)
        for i = 1, totalDifficulties do
            if i <= availableDifficulties then
                local _, isSet = self.userTypeData:GetPrimaryOptionByIndex(i)
                self.difficultyRadioButtonGroup:SetButtonIsValidOption(self.difficultyButtons[i], true)
                if isSet then
                    self.difficultyRadioButtonGroup:SetClickedButton(self.difficultyButtons[i])
                end
            else
                self.difficultyRadioButtonGroup:SetButtonIsValidOption(self.difficultyButtons[i], false)
            end
            self.difficultyButtons[i]:SetHidden(false)
        end
        secondaryOptionAnchorParent = self.difficultyRadioContainer
    else
        secondaryOptionAnchorParent = self.primaryOptionDropdownControl
    end
    self.secondaryOptionDropdownControl:ClearAnchors()
    self.secondaryOptionDropdownControl:SetAnchor(LEFT, secondaryOptionAnchorParent, RIGHT, 5, 0)

    self.secondaryOptionDropdownControl:SetHidden(dontShowPrimaryOrSecondary)
    self.secondaryOptionDropdown:SetEnabled(isUserTypeDraft)
end

function ZO_GroupFinder_CreateEditGroupListing_Keyboard:UpdateCheckStateEnforceRoles()
    ZO_GroupFinder_CreateEditGroupListing_Shared.UpdateCheckStateEnforceRoles(self)
    local isHidden = not ZO_CheckButton_IsEnabled(self.enforceRolesCheckbox) or not ZO_CheckButton_IsChecked(self.enforceRolesCheckbox)
    self.roleContainerControl:SetHidden(isHidden)
    if not isHidden then
        self:UpdateRoles()
    end
end

function ZO_GroupFinder_CreateEditGroupListing_Keyboard:UpdateRoles()
    for roleType, control in pairs(self.roleSpinnerTable) do
        if not control.spinner:SetValue(self.userTypeData:GetDesiredRoleCountAtEdit(roleType)) then
            control.spinner:UpdateButtons()
        end
    end

    self:UpdateCreateEditButton()
end

--Overridden from base
function ZO_GroupFinder_CreateEditGroupListing_Keyboard:UpdateCheckStateRequireChampion()
    ZO_GroupFinder_CreateEditGroupListing_Shared.UpdateCheckStateRequireChampion(self)
    self.championPointsEditBox:SetHidden(not self.userTypeData:DoesGroupRequireChampion())
end

--Overridden from base
function ZO_GroupFinder_CreateEditGroupListing_Keyboard:UpdateCheckStateInviteCode()
    ZO_GroupFinder_CreateEditGroupListing_Shared.UpdateCheckStateInviteCode(self)
    self.inviteCodeEditBox:SetHidden(not self.userTypeData:DoesGroupRequireInviteCode())
end

function ZO_GroupFinder_CreateEditGroupListing_Keyboard:OnSizeSelection(comboBox, selectedDataName, selectedData, selectionChanged, oldData)
    ZO_GroupFinder_CreateEditGroupListing_Shared.OnSizeSelection(self, comboBox, selectedDataName, selectedData, selectionChanged, oldData)
    self:UpdateCheckStateEnforceRoles()
end

function ZO_GroupFinder_CreateEditGroupListing_Keyboard:Refresh()
    ZO_GroupFinder_CreateEditGroupListing_Shared.Refresh(self)

    local IGNORE_CALLBACK = true
    local secondaryOptionAnchorParent
    local userType = self.userTypeData:GetUserType()
    local category = self.userTypeData:GetCategory()
    local categoryIndex = category + 1 -- Category Enum starts at 0 so index will always be one greater than value.
    local showDifficultyAsPrimaryOption = category == GROUP_FINDER_CATEGORY_DUNGEON or category == GROUP_FINDER_CATEGORY_ARENA or category == GROUP_FINDER_CATEGORY_TRIAL
    local isUserTypeDraft = userType == GROUP_FINDER_GROUP_LISTING_USER_TYPE_GROUP_LISTING_DRAFT

    local IS_EDITING = true
    local canDoCreateEdit = ZO_GroupFinder_CanDoCreateEdit(self.userTypeData, self.groupTitleEditControl, IS_EDITING)
    self.createEditButton:SetEnabled(canDoCreateEdit)

    self.categoryDropdown:SelectItemByIndex(categoryIndex, IGNORE_CALLBACK)
    self.categoryDropdown:SetEnabled(isUserTypeDraft)

    self:PopulatePrimaryDropdown()

    self:PopulateSizeDropdown()
    self.sizeDropdown:SetEnabled(isUserTypeDraft)

    self:UpdateEditBoxGroupListingTitle()
    self:UpdateEditBoxGroupListingDescription()

    self:PopulatePlaystyleDropdown()
    self.playstyleLabel:SetHidden(not showDifficultyAsPrimaryOption)
    self.playstyleDropdownControl:SetHidden(not showDifficultyAsPrimaryOption)

    self:UpdateCheckStateRequireChampion()
    self:UpdateCheckStateRequireVOIP()
    self:UpdateCheckStateInviteCode()
    self:UpdateCheckStateAutoAcceptRequests()
    self:UpdateCheckStateEnforceRoles()

    self.championCheckbox:ClearAnchors()
    if showDifficultyAsPrimaryOption then
        self.championCheckbox:SetAnchor(TOPLEFT, self.playstyleDropdownControl, BOTTOMLEFT, 0, 10)
    else
        self.championCheckbox:SetAnchor(TOPLEFT, self.descriptionEditControl, BOTTOMLEFT, -6, 20)
    end

    if self.userTypeData:GetUserType() == GROUP_FINDER_GROUP_LISTING_USER_TYPE_CREATED_GROUP_LISTING then
        self.createEditButton:SetText(GetString(SI_GROUP_FINDER_CONFIRM_EDIT_GROUP))
    else
        self.createEditButton:SetText(GetString(SI_GROUP_FINDER_CREATE_GROUP))
    end
end

function ZO_GroupFinder_CreateEditGroupListing_Keyboard:Show()
    ZO_GroupFinder_BasePanel_Keyboard.Show(self)
    self:UpdateUserType()
    self:Refresh()

    --Reset the visibility of the text in the invite code edit box
    local SHOW_PASSWORD = false
    ZO_EditBoxKeyboard_SetAsPassword(self.inviteCodeEditBoxControl, SHOW_PASSWORD, self.inviteCodeEditBoxControl:GetNamedChild("TogglePasswordButton"))
end

function ZO_GroupFinder_CreateEditGroupListing_Keyboard:Hide()
    ZO_GroupFinder_BasePanel_Keyboard.Hide(self)
    GROUP_FINDER_KEYBOARD:ExitCreateEditState()
    self:HideGroupTitleViolations()
end

function ZO_GroupFinder_CreateEditGroupListing_Keyboard:UpdateCreateEditButton()
    if self:GetFragment():IsShowing() then
        local IS_EDITING = true
        self.createEditButton:SetEnabled(ZO_GroupFinder_CanDoCreateEdit(self.userTypeData, self.groupTitleEditControl, IS_EDITING))
    end
end

function ZO_GroupFinder_CreateEditGroupListing_Keyboard:UpdateGroupTitleViolations()
    if self:GetFragment():IsShowing() and self.groupTitleEditControl:HasFocus() then
        local violations = { IsValidGroupFinderListingTitle(self.groupTitleEditControl:GetText()) }
        self.groupTitleInstructions:Show(self.groupTitleEditControl, violations)
    end
end

function ZO_GroupFinder_CreateEditGroupListing_Keyboard:HideGroupTitleViolations()
    self.groupTitleInstructions:Hide()
end

function ZO_GroupFinder_CreateEditGroupListing_Keyboard:OnGroupMemberRoleChanged()
    self:UpdateCreateEditButton()
end

function ZO_GroupFinder_CreateEditGroupListing_Keyboard:OnGroupTitleTextChanged()
    if self:GetFragment():IsShowing() then
        self.userTypeData:SetTitle(self.groupTitleEditControl:GetText())
        self:UpdateCreateEditButton()
        self:UpdateGroupTitleViolations()
    end
end

function ZO_GroupFinder_CreateEditGroupListing_Keyboard:OnGroupTitleFocusGained()
    self:UpdateGroupTitleViolations()
    if WINDOW_MANAGER:IsHandlingHardwareEvent() then
        PlaySound(SOUNDS.EDIT_CLICK)
    end
end

function ZO_GroupFinder_CreateEditGroupListing_Keyboard:OnGroupTitleFocusLost()
    if self:GetFragment():IsShowing() then
        self.userTypeData:SetTitle(self.groupTitleEditControl:GetText())
        self:UpdateCreateEditButton()
        self:HideGroupTitleViolations()
    end
end

function ZO_GroupFinder_CreateEditGroupListing_Keyboard:ChangeGroupListingDescription(description)
    self.userTypeData:SetDescription(description)
    self:UpdateCreateEditButton()
end

function ZO_GroupFinder_CreateEditGroupListing_Keyboard:CreateEditButton_OnClicked(control)
    if self:GetFragment():IsShowing() then
        self:DoCreateEdit()
    end
end

function ZO_GroupFinder_CreateEditGroupListing_Keyboard:CreateEditButton_OnMouseEnter(control)
    if self:GetFragment():IsShowing() and control:GetState() == BSTATE_DISABLED then
        local IS_EDITING = true
        local canDoCreateEdit, disabledString = ZO_GroupFinder_CanDoCreateEdit(self.userTypeData, self.groupTitleEditControl, IS_EDITING)
        if not canDoCreateEdit then
            InitializeTooltip(InformationTooltip, control, BOTTOMLEFT, 0, 0, TOPLEFT)
            SetTooltipText(InformationTooltip, ZO_ERROR_COLOR:Colorize(disabledString))
        end
    end
end

function ZO_GroupFinder_CreateEditGroupListing_Keyboard:CreateEditButton_OnMouseExit(control)
    ClearTooltip(InformationTooltip)
end

-- Global XML

function ZO_GroupFinder_RoleSpinner_OnInitialized(control)
    control.title = control:GetNamedChild("Title")
    control.spinner = ZO_Spinner:New(control:GetNamedChild("Spinner"))
end

function ZO_CreateEditGroupListing_OnGroupTitleTextChanged()
    -- GROUP_FINDER_KEYBOARD isn't yet defined when we initially set text on the group title
    if GROUP_FINDER_KEYBOARD then
        GROUP_FINDER_KEYBOARD:GetCreateGroupListingContent():OnGroupTitleTextChanged()
    end
end

function ZO_CreateEditGroupListing_OnGroupTitleFocusGained()
    GROUP_FINDER_KEYBOARD:GetCreateGroupListingContent():OnGroupTitleFocusGained()
end

function ZO_CreateEditGroupListing_OnGroupTitleFocusLost()
    GROUP_FINDER_KEYBOARD:GetCreateGroupListingContent():OnGroupTitleFocusLost()
end

function ZO_CreateEditGroupListing_OnDescriptionTextChanged(control)
    -- GROUP_FINDER_KEYBOARD isn't yet defined when we initially set text on the group description
    if GROUP_FINDER_KEYBOARD then
        GROUP_FINDER_KEYBOARD:OnDescriptionTextChanged(control)
    end
end

function ZO_CreateEditGroupListing_OnChampionPointsTextChanged(control)
    GROUP_FINDER_KEYBOARD:OnChampionPointsTextChanged(control)
end

function ZO_CreateEditGroupListing_OnInviteCodeTextChanged(control)
    GROUP_FINDER_KEYBOARD:OnInviteCodeTextChanged(control)
end

function ZO_CancelCreateEditGroupListingButton_OnClicked(control)
    GROUP_FINDER_KEYBOARD:ExitCreateEditState()
    PlaySound(SOUNDS.TREE_SUBCATEGORY_CLICK)
end