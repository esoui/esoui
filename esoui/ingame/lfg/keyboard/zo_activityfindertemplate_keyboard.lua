local GROUP_SIZE_ICON_FORMAT = zo_iconFormat("EsoUI/Art/LFG/LFG_icon_groupSize.dds", 32, 32)

ZO_TRIBUTE_REWARD_KEYBOARD_ROW_HEIGHT = 52

------------------
--Initialization--
------------------

ZO_ActivityFinderTemplate_Keyboard = ZO_ActivityFinderTemplate_Shared:Subclass()

function ZO_ActivityFinderTemplate_Keyboard:New(...)
    return ZO_ActivityFinderTemplate_Shared.New(self, ...)
end

function ZO_ActivityFinderTemplate_Keyboard:Initialize(dataManager, categoryData, categoryPriority)
    self.tributeProgressSegmentTemplate = "ZO_TributeFinder_ArrowStatusBarTemplate_Keyboard"
    local control = CreateControlFromVirtual(dataManager:GetName() .. "_Keyboard", GuiRoot, "ZO_ActivityFinderTemplateTopLevel_Keyboard")
    ZO_ActivityFinderTemplate_Shared.Initialize(self, control, dataManager, categoryData, categoryPriority)

    self.rewardsOffsetYDefault = -250
    self.rewardsOffsetYTribute = -300
end

function ZO_ActivityFinderTemplate_Keyboard:GetSystemName()
    return "ActivityFinder_Keyboard"
end

function ZO_ActivityFinderTemplate_Keyboard:InitializeControls()
    self.listSection = self.control:GetNamedChild("ListSection")
    self.lfmPromptSection = self.control:GetNamedChild("LFMPromptSection")
    self.lfmPromptBodyLabel = self.lfmPromptSection:GetNamedChild("Body")

    self.filterControl = self.control:GetNamedChild("Filter")

    self.clubRankControl = self.control:GetNamedChild("ClubRank")
    self.clubRankObject = ZO_TributeClubRank:New(self.clubRankControl)

    self.buttonContainer = self.control:GetNamedChild("ActionButtonContainer")
    self.joinQueueButton = self.buttonContainer:GetNamedChild("QueueButton")
    self.viewRewardsButton = self.buttonContainer:GetNamedChild("ViewRewards")
    self.acceptQuestButton = self.buttonContainer:GetNamedChild("AcceptQuest")
    self.unlockPermanentlyButton = self.buttonContainer:GetNamedChild("UnlockPermanently")
    self.chapterUpgradeButton = self.buttonContainer:GetNamedChild("ChapterUpgrade")
    self.lockReasonLabel = self.control:GetNamedChild("LockReason")

    local function OnLockReasonLabelUpdate()
        if self.lockReasonTextFunction then
            local lockReasonText = self.lockReasonTextFunction()
            if lockReasonText then
                self.lockReasonLabel:SetText(zo_iconTextFormat("EsoUI/Art/Miscellaneous/locked_disabled.dds", 16, 16, lockReasonText))
            else
                self.lockReasonLabel:SetText(zo_iconFormat("EsoUI/Art/Miscellaneous/locked_disabled.dds", 16, 16))
            end
        end
    end
    self.lockReasonLabel:SetHandler("OnUpdate", OnLockReasonLabelUpdate)

    self.shouldHideLockReason = false

    ZO_ActivityFinderTemplate_Shared.InitializeControls(self, "ZO_ActivityFinderTemplateRewardTemplate_Keyboard")
    
    self:InitializeNavigationList()
end

function ZO_ActivityFinderTemplate_Keyboard:InitializeFilters()
    local filterComboBox = ZO_ComboBox_ObjectFromContainer(self.filterControl)
    filterComboBox:SetSortsItems(false)
    filterComboBox:SetFont("ZoFontWinT1")
    filterComboBox:SetSpacing(4)
    self.filterComboBox = filterComboBox
    self:RefreshFilters()
end

function ZO_ActivityFinderTemplate_Keyboard:InitializeNavigationList()
    self.navigationTree = ZO_Tree:New(self.listSection:GetNamedChild("ScrollChild"), 60, -10, 600)

    local openTexture = "EsoUI/Art/Buttons/tree_open_up.dds"
    local closedTexture = "EsoUI/Art/Buttons/tree_closed_up.dds"
    local overOpenTexture = "EsoUI/Art/Buttons/tree_open_over.dds"
    local overClosedTexture = "EsoUI/Art/Buttons/tree_closed_over.dds"

    local function TreeHeaderSetup(node, control, name, open)
        control.text:SetModifyTextType(MODIFY_TEXT_TYPE_UPPERCASE)
        control.text:SetText(name)

        control.icon:SetTexture(open and openTexture or closedTexture)
        control.iconHighlight:SetTexture(open and overOpenTexture or overClosedTexture)

        local ENABLED = true
        local DISABLE_SCALING = true
        ZO_IconHeader_Setup(control, open, ENABLED, DISABLE_SCALING)
    end
    
    local function TreeEntrySetup(node, control, data, open)
        control.text:SetText(data:GetNameKeyboard())
        local isLocked = data:IsLocked()
        control.enabled = not isLocked and not IsCurrentlySearchingForGroup()
        control.check:SetHidden(isLocked)
        control.lockIcon:SetHidden(not isLocked)
        control.text:SetEnabled(control.enabled)

        if not isLocked then
            ZO_CheckButton_SetCheckState(control.check, data:IsSelected())
        end
    end

    self.navigationTree:AddTemplate("ZO_ActivityFinderTemplateNavigationHeader_Keyboard", TreeHeaderSetup, nil, nil, nil, 0)

    local function TreeEntryEquality(left, right)
        return left.name == right.name
    end

    self.navigationTree:AddTemplate("ZO_ActivityFinderTemplateNavigationEntry_Keyboard", TreeEntrySetup, nil, TreeEntryEquality)
    self.navigationTree:SetOpenAnimation("ZO_TreeOpenAnimation")
end

function ZO_ActivityFinderTemplate_Keyboard:InitializeFragment()
    local function OnStateChange(oldState, newState)
        if newState == SCENE_FRAGMENT_SHOWN then
            -- refresh the filters first since that can cause the primary controls
            -- to be shown, which we want to hide when we show the LFM prompt
            if self.filtersDirty then
                self:RefreshFilters()
            end

            local isTribute = false
            local isCompetitive = false
            local selectedData = self.filterComboBox:GetSelectedItemData()
            if selectedData then
                local filterData = selectedData.data
                isTribute = filterData.isTribute
                isCompetitive = filterData.isCompetitive
            end

            if isTribute then
                if RequestTributeClubData() == TRIBUTE_PLAYER_INITIALIZATION_STATE_SUCCESS then
                    self:OnTributeClubDataInitialized()
                end

                if isCompetitive and RequestActiveTributeCampaignData() == TRIBUTE_PLAYER_INITIALIZATION_STATE_SUCCESS then
                    self:OnTributeCampaignDataInitialized()
                end

                TriggerTutorial(TUTORIAL_TRIGGER_TRIBUTE_FINDER_OPENED)
            end

            self.clubRankControl:SetHidden(not isTribute)

            if selectedData then
                local filterData = selectedData.data
                self.singularSection:SetHidden(not filterData.singular)
            end

            local shouldShowLFMPrompt, lfmPromptActivityName = self:GetLFMPromptInfo()
            if shouldShowLFMPrompt then
                self.lfmPromptBodyLabel:SetText(zo_strformat(GetString(SI_LFG_FIND_REPLACEMENT_TEXT), lfmPromptActivityName))
                self.lfmPromptSection:SetHidden(false)
                self:HidePrimaryControls()
            end

            self:RefreshMMR()
            self:RefreshView()
        end
    end
    self.fragment = ZO_FadeSceneFragment:New(self.control)
    self.fragment:RegisterCallback("StateChange", OnStateChange)
    self.categoryData.categoryFragment = self.fragment

    GROUP_MENU_KEYBOARD:AddCategory(self.categoryData)
end

function ZO_ActivityFinderTemplate_Keyboard:RegisterEvents()
    ZO_ActivityFinderTemplate_Shared.RegisterEvents(self)
    ZO_ACTIVITY_FINDER_ROOT_MANAGER:RegisterCallback("OnSelectionsChanged", function(...) self:RefreshButtons(...) end)
end

-----------
--Updates--
-----------

function ZO_ActivityFinderTemplate_Keyboard:RefreshView()
    if not self.fragment:IsShowing() then
        return
    end

    local shouldShowLFMPrompt = self:GetLFMPromptInfo()
    if not shouldShowLFMPrompt then
        self:ResetLFMPrompt()
    end

    self.tributeSeasonProgressControl:SetHidden(true)
    self.clubRankObject:Refresh()

    local lockReasonText
    
    self.viewRewardsButton:SetHidden(true)
    self.acceptQuestButton:SetHidden(true)
    self.unlockPermanentlyButton:SetHidden(true)
    self.chapterUpgradeButton:SetHidden(true)

    local selectedData = self.filterComboBox:GetSelectedItemData()
    if selectedData then
        local filterData = selectedData.data
        if filterData.singular then
            ZO_ACTIVITY_FINDER_ROOT_MANAGER:SetLocationSelected(filterData, true)
            self:RefreshRewards(filterData)
            if filterData:IsLocked() then
                lockReasonText = filterData:GetLockReasonText()

                local lockingCollectibleId = filterData:GetFirstLockingCollectible()
                if lockingCollectibleId ~= 0 then
                    local collectibleData = ZO_COLLECTIBLE_DATA_MANAGER:GetCollectibleDataById(lockingCollectibleId)
                    local categoryType = collectibleData:GetCategoryType()
                    if categoryType == COLLECTIBLE_CATEGORY_TYPE_CHAPTER then
                        self.chapterUpgradeButton:SetHidden(false)
                    elseif categoryType == COLLECTIBLE_CATEGORY_TYPE_DLC then
                        self.unlockPermanentlyButton.searchTerm = collectibleData:GetName()
                        self.unlockPermanentlyButton:SetHidden(false)
                    end
                else
                    self.acceptQuestButton.questId = filterData:GetQuestToUnlock()
                    self.acceptQuestButton:SetHidden(self.acceptQuestButton.questId == 0)
                end
            end

            local HIDE_IF_NOT_COMPETITIVE = not filterData.isCompetitive
            self:RefreshTributeSeasonData(HIDE_IF_NOT_COMPETITIVE)

            self.viewRewardsButton:SetHidden(HIDE_IF_NOT_COMPETITIVE)
        else
            self.navigationTree:Reset()

            ZO_ACTIVITY_FINDER_ROOT_MANAGER:RebuildSelections(filterData.activityTypes)

            local modes = self.dataManager:GetFilterModeData()

            local NO_PARENT_NODE = nil
            local NO_OVERRIDE_SOUND = nil
            local HEADER_OPEN = true
            for _, activityType in ipairs(filterData.activityTypes) do
                if ZO_ACTIVITY_FINDER_ROOT_MANAGER:GetNumLocationsByActivity(activityType, modes:GetVisibleEntryTypes()) > 0 then
                    local isLocked = self:GetLevelLockInfoByActivity(activityType)
                    if not isLocked then
                        local locationData = ZO_ACTIVITY_FINDER_ROOT_MANAGER:GetLocationsData(activityType)
                        local headerText = GetString("SI_LFGACTIVITY", activityType)
                        local headerNode = self.navigationTree:AddNode("ZO_ActivityFinderTemplateNavigationHeader_Keyboard", headerText, NO_PARENT_NODE, NO_OVERRIDE_SOUND, HEADER_OPEN)

                        for _, location in ipairs(locationData) do
                            if modes:IsEntryTypeVisible(location:GetEntryType()) and location:IsActive() and not location:ShouldForceFullPanelKeyboard() then
                                self.navigationTree:AddNode("ZO_ActivityFinderTemplateNavigationEntry_Keyboard", location, headerNode)
                            end
                        end
                    end
                end
            end

            self.navigationTree:Commit()
        end
    end

    local globalLockReasonText = self:GetGlobalLockText()

    if globalLockReasonText then
        lockReasonText = globalLockReasonText
    end

    self.shouldHideLockReason = lockReasonText == nil

    if not self.shouldHideLockReason then
        --if the text is a function, that means there's a timer involved that we want to refresh on update
        if type(lockReasonText) == "function" then
            self.lockReasonTextFunction = lockReasonText
        else
            self.lockReasonLabel:SetText(zo_iconTextFormat("EsoUI/Art/Miscellaneous/locked_disabled.dds", 16, 16, lockReasonText))
            self.lockReasonTextFunction = nil
        end
    end

    self.lockReasonLabel:SetHidden(self.shouldHideLockReason)

    self:RefreshButtons()
end

do
    local function IsEntryNotLocked(entry)
        return (not entry.data.singular) or (not entry.data:IsLocked())
    end

    local function ShouldAutoSelectEntry(entry)
        if not entry.data.singular then
            -- don't autoselect list views
            return false
        end

        if entry.data:IsLocked() then
            -- don't autoselect locked locations
            return false
        end

        return true
    end

    function ZO_ActivityFinderTemplate_Keyboard:RefreshFilters()
        if not self.fragment:IsShowing() then
            self.filtersDirty = true
            return
        end

        local function OnFilterChanged(...)
            self:OnFilterChanged(...)
        end

        local previousSelection = self.filterComboBox:GetSelectedItemData()
        local reselectedEntry = nil
        self.filterComboBox:ClearItems()

        local modes = self.dataManager:GetFilterModeData()
        local activityTypes = modes:GetActivityTypes()

        local addListViewSubmenuEntry = false

        -- Add singular panel entries
        for _, activityType in ipairs(activityTypes) do
            if ZO_ACTIVITY_FINDER_ROOT_MANAGER:GetNumLocationsByActivity(activityType, modes:GetVisibleEntryTypes()) > 0 then
                local isActivityLocked = self:GetLevelLockInfoByActivity(activityType)
                if not isActivityLocked then
                    local locationsData = ZO_ACTIVITY_FINDER_ROOT_MANAGER:GetLocationsData(activityType)
                    for _, location in ipairs(locationsData) do
                        if modes:IsEntryTypeVisible(location:GetEntryType()) and location:IsActive() and location:DoesPlayerMeetLevelRequirements() then
                            if location:ShouldForceFullPanelKeyboard() then
                                local entry = self.filterComboBox:CreateItemEntry(location:GetNameKeyboard(), OnFilterChanged)
                                if activityType == LFG_ACTIVITY_TRIBUTE_COMPETITIVE or activityType == LFG_ACTIVITY_TRIBUTE_CASUAL then
                                    location.isTribute = true
                                    if activityType == LFG_ACTIVITY_TRIBUTE_COMPETITIVE then
                                        location.isCompetitive = true
                                    end
                                end
                                location.singular = true
                                entry.data = location

                                if previousSelection and previousSelection.name == entry.name and IsEntryNotLocked(previousSelection) then
                                    reselectedEntry = entry
                                end

                                self.filterComboBox:AddItem(entry, ZO_COMBOBOX_SUPPRESS_UPDATE)
                            else
                                addListViewSubmenuEntry = true
                            end
                        end
                    end
                end
            end
        end

        -- Add list view submenu entry
        if addListViewSubmenuEntry then
            local entry = self.filterComboBox:CreateItemEntry(modes:GetSpecificFilterName(), OnFilterChanged)
            entry.data =
            {
                singular = false,
                isTribute = false,
                isCompetitive = false,
                activityTypes = activityTypes,
            }

            if previousSelection and previousSelection.name == entry.name and IsEntryNotLocked(previousSelection) then
                reselectedEntry = entry
            end

            self.filterComboBox:AddItem(entry, ZO_COMBOBOX_SUPPRESS_UPDATE)
        end

        if reselectedEntry then
            self.filterComboBox:SelectItem(reselectedEntry)
        else
            if not self.filterComboBox:SetSelectedItemByEval(ShouldAutoSelectEntry) then
                self.filterComboBox:SelectFirstItem()
            end
        end

        self.filterControl:SetHidden(self.filterComboBox:GetNumItems() <= 1)

        self.filtersDirty = false
    end
end

function ZO_ActivityFinderTemplate_Keyboard:IsShowingTributeFinder()
    local selectedData = self.filterComboBox:GetSelectedItemData()
    if selectedData then
        local filterData = selectedData.data
        return filterData.isTribute
    end
    return false
end

do
    local optionalButtons = {}
    function ZO_ActivityFinderTemplate_Keyboard:RefreshButtons()
        local isAnyLocationSelected = ZO_ACTIVITY_FINDER_ROOT_MANAGER:IsAnyLocationSelected()
        local isGroupFinderInUse = ZO_GroupFinder_IsGroupFinderInUse()
        local isJoinButtonEnabled = isAnyLocationSelected and not ZO_ACTIVITY_FINDER_ROOT_MANAGER:GetIsCurrentlyInQueue() and not isGroupFinderInUse
        self.joinQueueButton:SetEnabled(isJoinButtonEnabled)

        local acceptQuestButtonShown = not self.acceptQuestButton:IsControlHidden()
        local viewRewardsButtonShown = not self.viewRewardsButton:IsControlHidden()
        local unlockPermanentlyButtonShown = not self.unlockPermanentlyButton:IsControlHidden()
        local chapterUpgradeButtonShown = not self.chapterUpgradeButton:IsControlHidden()
        if acceptQuestButtonShown or viewRewardsButtonShown or unlockPermanentlyButtonShown or chapterUpgradeButtonShown then
            ZO_ClearNumericallyIndexedTable(optionalButtons)
            if chapterUpgradeButtonShown then
                table.insert(optionalButtons, self.chapterUpgradeButton)
            elseif unlockPermanentlyButtonShown then
                table.insert(optionalButtons, self.unlockPermanentlyButton)
            elseif acceptQuestButtonShown then
                self.acceptQuestButton:SetEnabled(not HasQuest(self.acceptQuestButton.questId))
                table.insert(optionalButtons, self.acceptQuestButton)
            end

            if viewRewardsButtonShown then
                self.viewRewardsButton:SetEnabled(HasActiveCampaignStarted())
                table.insert(optionalButtons, self.viewRewardsButton)
            end
            for index, button in ipairs(optionalButtons) do
                local anchorTo = index == 1 and self.joinQueueButton or optionalButtons[index - 1]
                button:SetAnchor(TOPLEFT, anchorTo, TOPRIGHT, 30, 0)
            end
        end
    end
end

----------
--Events--
----------

function ZO_ActivityFinderTemplate_Keyboard:OnFilterChanged(comboBox, entryText, entry)
    ZO_ACTIVITY_FINDER_ROOT_MANAGER:ClearSelections()

    local data = entry.data
    self.singularSection:SetHidden(not data.singular)
    self.listSection:SetHidden(data.singular)

    if data.singular then
        self.titleLabel:SetText(data:GetNameKeyboard())
        self.backgroundTexture:SetTexture(data:GetDescriptionTextureLargeKeyboard())

        if not data.isTribute then
            data:SetGroupSizeRangeText(self.groupSizeRangeLabel, GROUP_SIZE_ICON_FORMAT)

            -- Add game mode text into battlegrounds info
            local hideSetControls = true
            local setTypeListControl = self.setTypesSectionControl:GetNamedChild("List")

            if data:IsSetEntryType() then
                local setTypesHeaderText = data:GetSetTypesHeaderText()
                local setTypesListText = data:GetSetTypesListText()
                if setTypesHeaderText ~= "" and setTypesListText ~= "" then
                    setTypeListControl:SetText(zo_strformat(SI_BATTLEGROUND_GAME_MODE_FORMATTER_KEYBOARD, setTypesHeaderText, setTypesListText))
                    hideSetControls = false
                end
            end

            setTypeListControl:SetHidden(hideSetControls)
        end

        self:RefreshRewards(data)
    end

    self:RefreshMMR()
    self:RefreshView()
end

function ZO_ActivityFinderTemplate_Keyboard:RefreshMMR()
    local selectedData = self.filterComboBox:GetSelectedItemData()
    if selectedData then
        local filterData = selectedData.data
        if filterData.singular and not filterData.isTribute then
            local hideMMRControls = true
            local mmrListControl = self.ratingSectionControl:GetNamedChild("List")

            if filterData:IsSetEntryType() and filterData:HasMMR() then
                local rating = filterData:GetMMR()
                mmrListControl:SetText(zo_strformat(SI_BATTLEGROUND_MMR_FORMATTER_KEYBOARD, ZO_SELECTED_TEXT:Colorize(rating)))
                hideMMRControls = false
            end

            mmrListControl:SetHidden(hideMMRControls)
        end
    end
end

function ZO_ActivityFinderTemplate_Keyboard:OnActivityFinderStatusUpdate()
    self:RefreshView()
end

function ZO_ActivityFinderTemplate_Keyboard:OnCooldownsUpdate()
    local selectedData = self.filterComboBox:GetSelectedItemData()
    if selectedData then
        local filterData = selectedData.data
        if filterData.singular then
            self:RefreshRewards(filterData)
        end
    end
end

function ZO_ActivityFinderTemplate_Keyboard:OnTributeClubRankDataChanged()
    ZO_ActivityFinderTemplate_Shared.OnTributeClubRankDataChanged(self)
    self.clubRankObject:Refresh()
end

function ZO_ActivityFinderTemplate_Keyboard:OnTributeCampaignDataInitialized()
    ZO_ActivityFinderTemplate_Shared.OnTributeCampaignDataInitialized(self)
    self:RefreshView()
end

function ZO_ActivityFinderTemplate_Keyboard:OnTributeCampaignDataChanged()
    ZO_ActivityFinderTemplate_Shared.OnTributeCampaignDataChanged(self)

    local hideIfNotCompetitive = true
    local selectedData = self.filterComboBox:GetSelectedItemData()
    if selectedData then
        local filterData = selectedData.data
        if filterData.isCompetitive then
            hideIfNotCompetitive = false
        end
    end
    self:RefreshTributeSeasonData(hideIfNotCompetitive)
end

function ZO_ActivityFinderTemplate_Keyboard:ShowPrimaryControls()
    self.filterControl:SetHidden(false)
    self.joinQueueButton:SetHidden(false)
    local filterData = self.filterComboBox:GetSelectedItemData().data
    if filterData.singular then
        self.singularSection:SetHidden(false)
        self.lockReasonLabel:SetHidden(self.shouldHideLockReason)
    else
        self.listSection:SetHidden(false)
    end
end

function ZO_ActivityFinderTemplate_Keyboard:HidePrimaryControls()
    self.singularSection:SetHidden(true)
    self.listSection:SetHidden(true)
    self.filterControl:SetHidden(true)
    self.joinQueueButton:SetHidden(true)
    self.lockReasonLabel:SetHidden(true)
end

function ZO_ActivityFinderTemplate_Keyboard:ResetLFMPrompt()
    if not self.lfmPromptSection:IsHidden() then
        self.lfmPromptSection:SetHidden(true)
        self:ShowPrimaryControls()
    end
end

function ZO_ActivityFinderTemplate_Keyboard:OnHandleLFMPromptResponse()
    if self.fragment:IsShowing() then
        self:ResetLFMPrompt()
    end
end

function ZO_ActivityFinderTemplate_Keyboard:OnViewRewardsButtonClicked()
    ZO_Dialogs_ShowPlatformDialog("TRIBUTE_REWARDS_VIEW")
end

function ZO_ActivityFinderTemplate_Keyboard:OnAcceptQuestButtonClicked()
    -- Can't get here without filterData existing and being singular
    local filterData = self.filterComboBox:GetSelectedItemData().data
    BestowActivityTypeGatingQuest(filterData:GetActivityType())
end

-------------
--Accessors--
-------------

function ZO_ActivityFinderTemplate_Keyboard:GetFragment()
    return self.fragment
end

----------
--Layout--
----------

function ZO_ActivityFinderTemplate_Keyboard.ShowActivityTooltip(control)
    local data = control.node.data
    local tooltip = ZO_ActivityFinderTemplateTooltip_Keyboard
    InitializeTooltip(tooltip, control, TOPRIGHT, -70, 0, TOPLEFT)

    local tooltipContents = tooltip:GetNamedChild("Contents")
    local groupSizeLabel = tooltipContents:GetNamedChild("GroupSizeLabel")
    data:SetGroupSizeRangeText(groupSizeLabel, GROUP_SIZE_ICON_FORMAT)

    local nameLabel = tooltipContents:GetNamedChild("NameLabel")
    nameLabel:SetText(data.nameKeyboard)

    local artTexture = tooltip:GetNamedChild("ArtTexture")
    artTexture:SetTexture(data.descriptionTextureSmallKeyboard)

    local lockedInfoLabel = tooltipContents:GetNamedChild("LockedInfoLabel")
    if data.isLocked then
        lockedInfoLabel:SetHidden(false)
        lockedInfoLabel:SetColor(ZO_ERROR_COLOR:UnpackRGBA())
        lockedInfoLabel:SetText(zo_iconTextFormat("EsoUI/Art/Miscellaneous/locked_disabled.dds", 16, 16, data.lockReasonText))
    else
        lockedInfoLabel:SetHidden(true)
    end

    local setTypesSectionControl = tooltipContents:GetNamedChild("SetTypesSection")
    ZO_ActivityFinderTemplate_Shared.AppendSetDataToControl(setTypesSectionControl, data)
end

function ZO_ActivityFinderTemplate_Keyboard.HideActivityTooltip()
    ClearTooltip(ZO_ActivityFinderTemplateTooltip_Keyboard)
end

----------------
--Global Hooks--
----------------

function ZO_ActivityFinderTemplateNavigationEntryKeyboard_OnClicked(control, button)
    if control.enabled then
        ZO_CheckButton_OnClicked(control.check)
        ZO_ACTIVITY_FINDER_ROOT_MANAGER:ToggleLocationSelected(control.node.data)
    end
end

function ZO_ActivityFinderTemplateNavigationEntryKeyboard_OnMouseEnter(control)
    if control.enabled then
        ZO_SelectableLabel_OnMouseEnter(control.text)
        control.check:SetShowingHighlight(true)
    end
    ZO_ActivityFinderTemplate_Keyboard.ShowActivityTooltip(control)
end

function ZO_ActivityFinderTemplateNavigationEntryKeyboard_OnMouseExit(control)
    if control.enabled then
        ZO_SelectableLabel_OnMouseExit(control.text, false)
        control.check:SetShowingHighlight(false)
    end
    ZO_ActivityFinderTemplate_Keyboard.HideActivityTooltip()
end

function ZO_ActivityFinderTemplateQueueButtonKeyboard_OnClicked(control)
    if not IsCurrentlySearchingForGroup() then
        ZO_ACTIVITY_FINDER_ROOT_MANAGER:StartSearch()
    end
end

function ZO_ActivityFinderTemplateViewRewardsKeyboard_OnClicked(control)
    local topLevelControl = control:GetParent():GetParent()
    local finderObjectKeyboard = topLevelControl.object
    finderObjectKeyboard:OnViewRewardsButtonClicked()
end

function ZO_ActivityFinderTemplateAcceptQuestKeyboard_OnClicked(control)
    local topLevelControl = control:GetParent():GetParent()
    local finderObjectKeyboard = topLevelControl.object
    finderObjectKeyboard:OnAcceptQuestButtonClicked()
end

function ZO_ActivityFinderTemplateUnlockPermanentlyKeyboard_OnClicked(control)
    local searchTerm = zo_strformat(SI_CROWN_STORE_SEARCH_FORMAT_STRING, control.searchTerm)
    ShowMarketAndSearch(searchTerm, MARKET_OPEN_OPERATION_ACTIVITY_FINDER)
end

function ZO_ActivityFinderTemplateNavigationEntryKeyboard_OnInitialized(control)
    control.lockIcon = control:GetNamedChild("LockIcon")
    control.check = control:GetNamedChild("Check")
    control.text = control:GetNamedChild("Text")
    local fontHeight = control.text:GetFontHeight()
    control:SetDimensionConstraints(0, fontHeight, 0, 0)
end