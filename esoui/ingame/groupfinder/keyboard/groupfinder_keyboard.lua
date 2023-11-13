--------------------------------------------------------------
-- ZO_GroupFinder_Keyboard
--------------------------------------------------------------

ZO_GroupFinder_Keyboard = ZO_GroupFinder_Shared:Subclass()

-- ZO_GroupFinder_Shared overrides

function ZO_GroupFinder_Keyboard:Initialize(control)
    ZO_GroupFinder_Shared.Initialize(self, control)

    self:InitializeKeybindStripDescriptors()
end

function ZO_GroupFinder_Keyboard:InitializeControls()
    self.searchControl = self.control:GetNamedChild("SearchPanel")
    self.createGroupListingControl  = self.control:GetNamedChild("CreateGroupListingPanel")
    self.applicationsManagmentControl  = self.control:GetNamedChild("ApplicationsManagementPanel")
end

function ZO_GroupFinder_Keyboard:InitializeFragments()
    ZO_GroupFinder_Shared.InitializeFragments(self)

    self.searchContent = ZO_GroupFinder_SearchPanel_Keyboard:New(self.searchControl)
    self.createGroupListingContent = ZO_GroupFinder_CreateEditGroupListing_Keyboard:New(self.createGroupListingControl)
    self.applicationsManagementContent = ZO_GroupFinder_ApplicationsManagementPanel_Keyboard:New(self.applicationsManagmentControl)

    self.appliedToListingData = ZO_GroupListingUserTypeData:New(GROUP_FINDER_GROUP_LISTING_USER_TYPE_APPLIED_TO_GROUP_LISTING)

    local overviewControl = self.control:GetNamedChild("Overview")
    local overviewDescription = overviewControl:GetNamedChild("Description")
    self.overviewAppliedToGroupListingControl = overviewControl:GetNamedChild("AppliedToGroupListing")
    self.createGroupListingButton = overviewControl:GetNamedChild("CreateGroupButton")
    overviewDescription:SetText(ZO_GenerateParagraphSeparatedList( { GetString(SI_GROUP_FINDER_DESCRIPTION), GetString(SI_GROUP_FINDER_OVERVIEW_INSTRUCTIONS) } ))

    local function AppliedToListingOnMouseEnter(listingControl)
        InitializeTooltip(GroupFinderGroupListingTooltip, self.appliedToListingControl, RIGHT, -15, 0, LEFT)
        ZO_GroupFinderGroupListingTooltip_SetGroupFinderListing(GroupFinderGroupListingTooltip, self.appliedToListingData)
        KEYBIND_STRIP:AddKeybindButtonGroup(self.appliedToListingKeybindStripDescriptor)
    end

    local function AppliedToListingOnMouseExit(listingControl)
        ClearTooltip(GroupFinderGroupListingTooltip)
        KEYBIND_STRIP:RemoveKeybindButtonGroup(self.appliedToListingKeybindStripDescriptor)
    end

    local function AppliedToListingOnMouseUp(listingControl, button, upInside)
        if button == MOUSE_BUTTON_INDEX_RIGHT and upInside then
            ClearMenu()
            AddMenuItem(GetString(SI_GROUP_FINDER_RESCIND_KEYBIND), function() RequestResolveGroupListingApplication(RESOLVE_GROUP_LISTING_APPLICATION_REQUEST_RESCIND) end)
            AddMenuItem(GetString(SI_FRIEND_MENU_IGNORE), function() AddIgnore(self.appliedToListingData:GetOwnerDisplayName()) end)
            AddMenuItem(GetString(SI_GROUP_FINDER_REPORT_GROUP_LISTING_KEYBIND), function() ZO_HELP_GENERIC_TICKET_SUBMISSION_MANAGER:OpenReportGroupFinderListingTicketScene(self.appliedToListingData) end)
            ShowMenu(listingControl)
        end
    end

    self.overviewAppliedToGroupListingControl:SetHandler("OnMouseEnter", AppliedToListingOnMouseEnter)
    self.overviewAppliedToGroupListingControl:SetHandler("OnMouseExit", AppliedToListingOnMouseExit)
    self.overviewAppliedToGroupListingControl:SetHandler("OnMouseUp", AppliedToListingOnMouseUp)

    self.modeFragments =
    {
        [ZO_GROUP_FINDER_MODES.OVERVIEW] = ZO_SimpleSceneFragment:New(overviewControl),
        [ZO_GROUP_FINDER_MODES.SEARCH] = self.searchContent:GetFragment(),
        [ZO_GROUP_FINDER_MODES.CREATE_EDIT] = self.createGroupListingContent:GetFragment(),
        [ZO_GROUP_FINDER_MODES.MANAGE] = self.applicationsManagementContent:GetFragment(),
    }

    GROUP_FINDER_KEYBOARD_FRAGMENT = self.sceneFragment
    GROUP_FINDER_KEYBOARD_FRAGMENT:RegisterCallback("StateChange", function(oldState, newState)
        if newState == SCENE_FRAGMENT_SHOWING then
            local RESET_DIFFICULTY = true
            UpdateGroupFinderFilterOptions(RESET_DIFFICULTY)
            self:ApplyPendingMode()
            self:RefreshAppliedToListing()
            self.createGroupListingButton:SetEnabled(ZO_GroupFinder_CanDoCreateEdit())
            TriggerTutorial(TUTORIAL_TRIGGER_GROUP_FINDER_OPENED)
        elseif newState == SCENE_FRAGMENT_HIDING then
            --Only allow the exiting of the CREATE_EDIT mode via ExitCreateEditState
            if self.mode ~= ZO_GROUP_FINDER_MODES.CREATE_EDIT then
                self:SetMode(nil)
            end
        end
    end)

    KEYBOARD_GROUP_MENU_SCENE:RegisterCallback("StateChange", function(oldState, newState)
        if newState == SCENE_SHOWING then
            if self.mode == ZO_GROUP_FINDER_MODES.SEARCH then
                local selectedSubtreeNodeData = GROUP_MENU_KEYBOARD.navigationTree:GetSelectedData()
                local currentCategory = GetGroupFinderFilterCategory()
                if selectedSubtreeNodeData.searchCategory ~= currentCategory then
                    self.dirty = true
                end
            end
            if self.dirty then
                GROUP_MENU_KEYBOARD:RebuildCategories()
                self.dirty = false
            end
        elseif newState == SCENE_HIDING then
            --When the parent scene hides, store off the current mode so we remember it when we re-open
            self.pendingMode = self.mode
            --Calling self:SetMode at this point would set self.pendingMode instead, so we need to set self.mode manually here
            self.mode = nil
        end
    end)

    local function OnRefreshApplication()
        if self.modeFragments[ZO_GROUP_FINDER_MODES.OVERVIEW]:IsShowing() then
            self:RefreshAppliedToListing()
        end
    end

    EVENT_MANAGER:RegisterForEvent("GroupFinder_Keyboard", EVENT_GROUP_FINDER_APPLY_TO_GROUP_LISTING_RESULT, OnRefreshApplication)
    EVENT_MANAGER:RegisterForEvent("GroupFinder_Keyboard", EVENT_GROUP_FINDER_RESOLVE_GROUP_LISTING_APPLICATION_RESULT, OnRefreshApplication)
    EVENT_MANAGER:RegisterForEvent("GroupFinder_Keyboard", EVENT_GROUP_FINDER_REMOVE_GROUP_LISTING_APPLICATION, OnRefreshApplication)

    function OnApplicationsListUpdated()
        self.createGroupListingContent:UpdateCreateEditButton()
   end

    GROUP_FINDER_APPLICATIONS_LIST_MANAGER:RegisterCallback("ApplicationsListUpdated", OnApplicationsListUpdated)
end

function ZO_GroupFinder_Keyboard:InitializeKeybindStripDescriptors()
    self.appliedToListingKeybindStripDescriptor =
    {
        -- Rescind
        {
            name = GetString(SI_GROUP_FINDER_RESCIND_KEYBIND),
            keybind = "UI_SHORTCUT_NEGATIVE",
            callback = function()
                RequestResolveGroupListingApplication(RESOLVE_GROUP_LISTING_APPLICATION_REQUEST_RESCIND)
            end,
        },
        -- Report Listing
        {
            name = GetString(SI_GROUP_FINDER_REPORT_GROUP_LISTING_KEYBIND),
            keybind = "UI_SHORTCUT_REPORT_PLAYER",
            callback = function()
                ZO_HELP_GENERIC_TICKET_SUBMISSION_MANAGER:OpenReportGroupFinderListingTicketScene(self.appliedToListingData)
            end,
        },
    }
end

function ZO_GroupFinder_Keyboard:RefreshAppliedToListing()
    if self.appliedToListingData:IsUserTypeActive() then
        self.searchContent.roleControlPool:ReleaseAllObjects()
        ZO_GroupFinder_Shared.SetUpGroupListingFromData(self.overviewAppliedToGroupListingControl, self.searchContent.roleControlPool, self.appliedToListingData, ZO_GROUP_LISTING_ROLE_CONTROL_PADDING)

        self.overviewAppliedToGroupListingControl:SetHidden(false)
    else
        self.overviewAppliedToGroupListingControl:SetHidden(true)
    end
end

function ZO_GroupFinder_Keyboard:ApplyPendingMode()
    if GROUP_FINDER_KEYBOARD_FRAGMENT:IsShowing() and self.pendingMode then
        self:SetMode(self.pendingMode)
        self.pendingMode = nil
    end
end

function ZO_GroupFinder_Keyboard:InitializeGroupFinderCategories()
    local CATEGORY_PRIORITY = ZO_ACTIVITY_FINDER_SORT_PRIORITY.GROUP_FINDER

    local function OnTreeEntrySelected(categoryData)
        --Only allow the exiting of the CREATE_EDIT mode via ExitCreateEditState
        if self.mode ~= ZO_GROUP_FINDER_MODES.CREATE_EDIT then
            if categoryData.searchCategory then
                self:SetSearchCategory(categoryData.searchCategory)
            end
            self:SetMode(categoryData.mode)
        end
    end

    self.categoryData = {}

    internalassert(GROUP_FINDER_CATEGORY_MAX_VALUE < 10, "The category priority algorithm does not support this number of categories, please re-evaluate the priority algorithm.")
    for index = GROUP_FINDER_CATEGORY_ITERATION_BEGIN, GROUP_FINDER_CATEGORY_ITERATION_END do
        local category =
        {
        -- Increment index by 1 to account for the overview.
            priority = CATEGORY_PRIORITY + (index + 1) * 10,
            name = GetString("SI_GROUPFINDERCATEGORY", index),
            searchCategory = index,
            categoryFragment = self.sceneFragment,
            onTreeEntrySelected = OnTreeEntrySelected,
            mode = ZO_GROUP_FINDER_MODES.SEARCH,
        }
        table.insert(self.categoryData, category)
    end

    local function GetCategoryListData()
        local categories = {}
        --This entry will be selected by default when navigating to the Group Finder category
        --Because it does not have a name, it will not be visible in the category list and will not be selectable by the player
        local overview =
        {
            priority = CATEGORY_PRIORITY + 1,
            categoryFragment = self.sceneFragment,
            onTreeEntrySelected = OnTreeEntrySelected,
            mode = ZO_GROUP_FINDER_MODES.OVERVIEW,
        }
        table.insert(categories, overview)

        for _, category in ipairs(self.categoryData) do
            table.insert(categories, category)
        end

        return categories
    end

    local function GetManageListingCategoryListData()
        return {
            {
                priority = CATEGORY_PRIORITY + 10,
                name = GetString(SI_GROUP_FINDER_MY_GROUP_LISTING),
                categoryFragment = self.sceneFragment,
                onTreeEntrySelected = OnTreeEntrySelected,
                mode = ZO_GROUP_FINDER_MODES.MANAGE,
            }
        }
    end

    local groupFinderCategoryData =
    {
        priority = CATEGORY_PRIORITY,
        name = GetString(SI_ACTIVITY_FINDER_CATEGORY_GROUP_FINDER),
        normalIcon = "EsoUI/Art/LFG/LFG_indexIcon_groupFinder_up.dds",
        pressedIcon = "EsoUI/Art/LFG/LFG_indexIcon_groupFinder_down.dds",
        mouseoverIcon = "EsoUI/Art/LFG/LFG_indexIcon_groupFinder_over.dds",
        disabledIcon = "EsoUI/Art/LFG/LFG_indexIcon_groupFinder_disabled.dds",
        getChildrenFunction = function()
            if HasGroupListingForUserType(GROUP_FINDER_GROUP_LISTING_USER_TYPE_CREATED_GROUP_LISTING) then
                return GetManageListingCategoryListData()
            else
                return GetCategoryListData()
            end
        end,
        isGroupFinder = true,
    }
    GROUP_MENU_KEYBOARD:AddCategory(groupFinderCategoryData)
end

function ZO_GroupFinder_Keyboard:GetSystemName()
    return "GroupFinder_Keyboard"
end

function ZO_GroupFinder_Keyboard:OnGroupListingRequestCreateResult(result)
    if self.createGroupListingContent:GetFragment():IsShowing() then
        if result == GROUP_FINDER_ACTION_RESULT_SUCCESS then
            if self.mode == ZO_GROUP_FINDER_MODES.CREATE_EDIT then
                self:ExitCreateEditState()
            else
                GROUP_MENU_KEYBOARD:RebuildCategories()
            end
        else
            local NO_DATA = nil
            ZO_Dialogs_ShowPlatformDialog("GROUP_FINDER_CREATE_EDIT_FAILED", NO_DATA, { mainTextParams = { result } })
        end
    elseif result == GROUP_FINDER_ACTION_RESULT_SUCCESS then
        self.dirty = true
    end
    PlaySound(SOUNDS.GROUP_FINDER_GROUP_LISTING_CREATE_EDIT)
end

function ZO_GroupFinder_Keyboard:OnGroupListingRequestEditResult(result)
    if self.createGroupListingContent:GetFragment():IsShowing() then
        if result == GROUP_FINDER_ACTION_RESULT_SUCCESS then
            if self.mode == ZO_GROUP_FINDER_MODES.CREATE_EDIT then
                self:ExitCreateEditState()
            end
        else
            ZO_Dialogs_ShowPlatformDialog("GROUP_FINDER_CREATE_EDIT_FAILED", { isEdit = true }, { mainTextParams = { result } })
        end
    end
    PlaySound(SOUNDS.GROUP_FINDER_GROUP_LISTING_CREATE_EDIT)
end

function ZO_GroupFinder_Keyboard:OnGroupListingAttainedRolesChanged()
    self.applicationsManagementContent:RefreshListing()
    self.createGroupListingContent:OnGroupMemberRoleChanged()
end

function ZO_GroupFinder_Keyboard:OnGroupListingRemoved(result)
    if self.mode == ZO_GROUP_FINDER_MODES.CREATE_EDIT then
        self:ExitCreateEditState()
    else
        if KEYBOARD_GROUP_MENU_SCENE:IsShowing() then
            GROUP_MENU_KEYBOARD:RebuildCategories()
        else
            self.dirty = true
        end
    end
end

function ZO_GroupFinder_Keyboard:SetSearchCategory(category)
    self.searchContent:SetSearchCategory(category)
end

function ZO_GroupFinder_Keyboard:GetSearchCategory()
    return self.searchContent:GetSearchCategory()
end

function ZO_GroupFinder_Keyboard:RefreshFilterOptions()
    self.searchContent:RefreshFilterOptions()
end

function ZO_GroupFinder_Keyboard:RefreshCurrentRoleLabel()
    self.searchContent:RefreshCurrentRoleLabel()
end

function ZO_GroupFinder_Keyboard:SetEditCreateCategory(category)
    self.createGroupListingContent:SetCategory(category)
end

-- End ZO_GroupFinder_Shared overrides

function ZO_GroupFinder_Keyboard:GetCreateGroupListingContent()
    return self.createGroupListingContent
end

function ZO_GroupFinder_Keyboard:OnDescriptionTextChanged(control)
    self.createGroupListingContent:ChangeGroupListingDescription(control:GetText())
end

do
    local MAX_CP_ALLOWED = GetMaxSpendableChampionPointsInAttribute() * GetNumChampionDisciplines()

    function ZO_GroupFinder_Keyboard:OnChampionPointsTextChanged(control)
        local championPointsText = control:GetText()
        if championPointsText ~= "" then
            local championPoints = tonumber(championPointsText)
            if championPoints > MAX_CP_ALLOWED then
                championPoints = MAX_CP_ALLOWED
                control:SetText(championPoints)
            end
        end
        self.createGroupListingContent.userTypeData:SetChampionPoints(championPoints)
        self.createGroupListingContent:UpdateCreateEditButton()
    end
end

function ZO_GroupFinder_Keyboard:OnInviteCodeTextChanged(control)
    local inviteCode = control:GetText()
    self.createGroupListingContent.userTypeData:SetInviteCode(tonumber(inviteCode))
    self.createGroupListingContent:UpdateCreateEditButton()
end

function ZO_GroupFinder_Keyboard:ExitCreateEditState()
    CancelEditGroupListing()
    if HasGroupListingForUserType(GROUP_FINDER_GROUP_LISTING_USER_TYPE_CREATED_GROUP_LISTING) then
        self:SetMode(ZO_GROUP_FINDER_MODES.MANAGE)
    else
        self:SetMode(ZO_GROUP_FINDER_MODES.OVERVIEW)
    end
    GROUP_MENU_KEYBOARD:ShowTree()
    GROUP_MENU_KEYBOARD:RebuildCategories()
    PREFERRED_ROLES:RefreshRoles()
end

function ZO_GroupFinder_Keyboard:SetMode(newMode)
    if self.sceneFragment:IsShowing() or newMode == nil then
        if self.mode ~= newMode then
            local previousMode = self.mode
            if previousMode then
                SCENE_MANAGER:RemoveFragment(self.modeFragments[previousMode])
            end

            self.mode = newMode

            if newMode then
                --If we are going into the create edit state, we need to hide the group menu navigation tree
                if newMode == ZO_GROUP_FINDER_MODES.CREATE_EDIT then
                    local editCreateCategory
                    if previousMode == ZO_GROUP_FINDER_MODES.OVERVIEW then
                        editCreateCategory = GROUP_FINDER_CATEGORY_DUNGEON
                    elseif previousMode == ZO_GROUP_FINDER_MODES.MANAGE then
                        editCreateCategory = GetGroupFinderUserTypeGroupListingCategory(GROUP_FINDER_GROUP_LISTING_USER_TYPE_CREATED_GROUP_LISTING)
                    else
                        editCreateCategory = self:GetSearchCategory()
                    end
                    self:SetEditCreateCategory(editCreateCategory)
                    GROUP_MENU_KEYBOARD:HideTree()
                    PREFERRED_ROLES:RefreshRoles()
                end
                SCENE_MANAGER:AddFragment(self.modeFragments[newMode])
            end
        end
    else
        self.pendingMode = newMode
    end
end

function ZO_GroupFinder_Keyboard:ExecuteSearchForCategory(category)
    if KEYBOARD_GROUP_MENU_SCENE:IsShowing() then
        local tree = GROUP_MENU_KEYBOARD:GetTree()
        local node = tree:GetTreeNodeByData(self.categoryData[category + 1])
        -- Selecting a new node will automatically call ExecuteSearch().
        if node ~= tree:GetSelectedNode() then
            tree:SelectNode(node)
        else -- But if our category isn't actually changing, we need to call it ourselves.
            GROUP_FINDER_SEARCH_MANAGER:ExecuteSearch()
        end
    end
end

-- Global XML

function ZO_GroupFinder_Keyboard_OnInitialized(control)
    GROUP_FINDER_KEYBOARD = ZO_GroupFinder_Keyboard:New(control)
end

function ZO_CreateEditGroupListingButton_OnMouseEnter(control)
    local createGroupListingButton = GROUP_FINDER_KEYBOARD.createGroupListingButton
    local canDoCreateEdit, disabledString = ZO_GroupFinder_CanDoCreateEdit()
    if not canDoCreateEdit then
        InitializeTooltip(InformationTooltip, createGroupListingButton, BOTTOMLEFT, 0, 0, TOPLEFT)
        SetTooltipText(InformationTooltip, disabledString)
    else
        ClearTooltip(InformationTooltip)
    end
end

function ZO_CreateEditGroupListingButton_OnMouseExit(control)
    ClearTooltip(InformationTooltip)
end

function ZO_CreateEditGroupListingButton_OnClicked(control)
    if HasGroupListingForUserType(GROUP_FINDER_GROUP_LISTING_USER_TYPE_APPLIED_TO_GROUP_LISTING) then
        ZO_Dialogs_ShowPlatformDialog("GROUP_FINDER_CREATE_RESCIND_APPLICATION")
    else
        GROUP_FINDER_KEYBOARD:SetMode(ZO_GROUP_FINDER_MODES.CREATE_EDIT)
    end
end