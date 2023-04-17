local CATEGORY_HEADER_TEMPLATE = "ZO_LeaderboardsNavigationHeader"
local CATEGORY_ENTRY_TEMPLATE = "ZO_LeaderboardsNavigationEntry"

ZO_LeaderboardsManager_Keyboard = ZO_Object.MultiSubclass(ZO_SortFilterList, ZO_LeaderboardsManager_Shared)

function ZO_LeaderboardsManager_Keyboard:Initialize(control, leaderboardControl)
    ZO_LeaderboardsManager_Shared.Initialize(self)
    ZO_SortFilterList.InitializeSortFilterList(self, control)

    self.activeLeaderboardLabel = GetControl(control, "ActiveLeaderboard")
    self.pointsHeaderLabel = GetControl(control, "HeadersPoints")
    self.classHeaderLabel = GetControl(control, "HeadersClass")
    self.allianceHeaderLabel = GetControl(control, "HeadersAlliance")
    self.emptyRow = GetControl(control, "EmptyRow")
    self.loadingIcon = self.control:GetNamedChild("LoadingIcon")

    self:InitializeFilters()
    self:InitializeCategoryList()
    self:InitializeLeaderboard()

    LEADERBOARDS_FRAGMENT = ZO_FadeSceneFragment:New(ZO_Leaderboards)
end

function ZO_LeaderboardsManager_Keyboard:InitializeFilters()
    self.filterComboBox = ZO_ComboBox_ObjectFromContainer(self.control:GetNamedChild("Filter"))
    self.filterComboBox:SetSortsItems(false)
    self.filterComboBox:SetFont("ZoFontWinT1")
    self.filterComboBox:SetSpacing(4)
end

function ZO_LeaderboardsManager_Keyboard:InitializeLeaderboard()
    ZO_ScrollList_AddDataType(self.list, ZO_LEADERBOARD_PLAYER_DATA, "ZO_LeaderboardsPlayerRow", 30, function(control, data) self:SetupLeaderboardPlayerEntry(control, data) end)
end

local function TreeEntrySetup(node, control, data, open)
    control:SetText(data.name)
end

local function TreeEntryEquality(left, right)
    return left.name == right.name
end

function ZO_LeaderboardsManager_Keyboard:InitializeCategoryList()
    self.navigationTree = ZO_Tree:New(self.control:GetNamedChild("NavigationContainerScrollChild"), 60, -10, 266)

    local function TreeHeaderSetup(node, control, data, open)
        control.text:SetModifyTextType(MODIFY_TEXT_TYPE_UPPERCASE)
        control.text:SetText(data.name)

        local iconTexture = (open and data.pressedIcon or data.normalIcon) or "EsoUI/Art/Icons/icon_missing.dds"
        local mouseoverTexture = data.mouseoverIcon or "EsoUI/Art/Icons/icon_missing.dds"
        
        control.icon:SetTexture(iconTexture)
        control.iconHighlight:SetTexture(mouseoverTexture)

        ZO_IconHeader_Setup(control, open)
    end

    local function TreeEntryOnSelected(control, data, selected, reselectingDuringRebuild)
        control:SetSelected(selected)
        if selected and not reselectingDuringRebuild then
            self:OnLeaderboardSelected(data)
        end
    end

    self.navigationTree:AddTemplate(CATEGORY_HEADER_TEMPLATE, TreeHeaderSetup, nil, nil, nil, 0)
    self.navigationTree:AddTemplate(CATEGORY_ENTRY_TEMPLATE, TreeEntrySetup, TreeEntryOnSelected, TreeEntryEquality)

    self.navigationTree:SetExclusive(true)
    self.navigationTree:SetOpenAnimation("ZO_TreeOpenAnimation")
end

function ZO_LeaderboardsManager_Keyboard:InitializeScenes()
    ZO_LeaderboardsManager_Shared.InitializeScenes(self, "leaderboards")

    LEADERBOARDS_SCENE = self:GetScene()
    LEADERBOARDS_SCENE:RegisterCallback("StateChange", function(oldState, newState)
        if newState == SCENE_SHOWING then
            self:UpdateCategories()
            if self.leaderboardObject then
                self:ActivateLeaderboard()
            end
        end
    end)
end

function ZO_LeaderboardsManager_Keyboard:AddCategory(name, normalIcon, pressedIcon, mouseoverIcon)
    local entryData = 
    {
        name = name,
        normalIcon = normalIcon, 
        pressedIcon = pressedIcon, 
        mouseoverIcon = mouseoverIcon,
    }

    return self.navigationTree:AddNode(CATEGORY_HEADER_TEMPLATE, entryData)
end

-- NOTE: Adding a maxRankFunction will require that all data is loaded up right away, instead of as-needed. Use a maxRankFunction ONLY when you want/need that behavior.
function ZO_LeaderboardsManager_Keyboard:AddEntry(leaderboardObject, name, titleName, parent, subType, countFunction, maxRankFunction, infoFunction, pointsFormatFunction, pointsHeaderString, consoleIdRequestParamsFunction, iconPath, leaderboardRankType, playerInfoUpdateFunction)
    local entryData = 
    {
        leaderboardObject = leaderboardObject,
        name = name,
        titleName = titleName or name,
        subType = subType,
        countFunction = countFunction,
        maxRankFunction = maxRankFunction,
        infoFunction = infoFunction,
        pointsFormatFunction = pointsFormatFunction,
        pointsHeaderString = pointsHeaderString,
        leaderboardRankType = leaderboardRankType,
        playerInfoUpdateFunction = playerInfoUpdateFunction,
    }

    local node = self.navigationTree:AddNode(CATEGORY_ENTRY_TEMPLATE, entryData, parent)
    
    local previouslySelectedData = self.previouslySelectedData
    if previouslySelectedData then
        if name == previouslySelectedData.name then
            local previouslySelectedSubType = previouslySelectedData.subType
            local subTypeFormat = type(subType)
            if subTypeFormat == type(previouslySelectedSubType) then
                if subTypeFormat == "table" then
                    --Assume it's a match until proven otherwise in the below loop
                    self.nodeToReselect = node
                    for k, v in pairs(subType) do
                        if v ~= previouslySelectedSubType[k] then
                            self.nodeToReselect = nil
                            break
                        end
                    end
                elseif subType == previouslySelectedSubType then
                    self.nodeToReselect = node
                end
            end
        end
    end

    return node
end

function ZO_LeaderboardsManager_Keyboard:GetSelectedLeaderboardData()
    return self.navigationTree:GetSelectedData()
end

function ZO_LeaderboardsManager_Keyboard:UpdateCategories()
    self.previouslySelectedData = self.navigationTree:GetSelectedData()
    self.nodeToReselect = nil
    self.navigationTree:Reset()

    local campaignLeaderboards = SYSTEMS:GetKeyboardObject(ZO_CAMPAIGN_LEADERBOARD_SYSTEM_NAME)
    if campaignLeaderboards then
        campaignLeaderboards:AddCategoriesToParentSystem()
    end

    local raidLeaderboards = SYSTEMS:GetKeyboardObject(ZO_RAID_LEADERBOARD_SYSTEM_NAME)
    if raidLeaderboards then
        raidLeaderboards:AddCategoriesToParentSystem()
    end

    local battlegroundLeaderboards = SYSTEMS:GetKeyboardObject(ZO_BATTLEGROUND_LEADERBOARD_SYSTEM_NAME)
    if battlegroundLeaderboards then
        battlegroundLeaderboards:AddCategoriesToParentSystem()
    end

    local tributeLeaderboards = SYSTEMS:GetKeyboardObject(ZO_TRIBUTE_LEADERBOARD_SYSTEM_NAME)
    if tributeLeaderboards then
        tributeLeaderboards:AddCategoriesToParentSystem()
    end

    self.navigationTree:Commit(self.nodeToReselect)
end

function ZO_LeaderboardsManager_Keyboard:RefreshLeaderboardType(leaderboardType)
    local isBattlegroundLeaderboard = leaderboardType == LEADERBOARD_TYPE_BATTLEGROUND
    local isTributeLeaderboard = leaderboardType == LEADERBOARD_TYPE_TRIBUTE
    local shouldHideClassAndAlliance = isBattlegroundLeaderboard or isTributeLeaderboard
    self.classHeaderLabel:SetHidden(shouldHideClassAndAlliance)
    self.allianceHeaderLabel:SetHidden(shouldHideClassAndAlliance)
end

function ZO_LeaderboardsManager_Keyboard:SetSelectedLeaderboardObject(leaderboardObject, subType)
    if self.leaderboardObject ~= leaderboardObject then
        if self.leaderboardObject then
            self:DeactivateLeaderboard()
        end

        self.leaderboardObject = leaderboardObject

        if leaderboardObject then
            self:ActivateLeaderboard()
        end
    end

    if self.leaderboardObject then
        self.leaderboardObject:OnSubtypeSelected(subType)
    end
end

function ZO_LeaderboardsManager_Keyboard:SetActiveLeaderboardTitle(titleName)
    self.activeLeaderboardLabel:SetText(titleName)
end

function ZO_LeaderboardsManager_Keyboard:ActivateLeaderboard()
    self.leaderboardObject:OnSelected()
end

function ZO_LeaderboardsManager_Keyboard:DeactivateLeaderboard()
    self.leaderboardObject:OnUnselected()
end

function ZO_LeaderboardsManager_Keyboard:SelectNode(node)
    self.navigationTree:SelectNode(node)
end

function ZO_LeaderboardsManager_Keyboard:SetupLeaderboardPlayerEntry(control, data)
    self:SetupRow(control, data)

    ZO_LeaderboardsManager_Shared.SetupLeaderboardPlayerEntry(self, control, data)
end

function ZO_LeaderboardsManager_Keyboard:SortScrollList()
    -- No sorting...just leave in rank order
end

function ZO_LeaderboardsManager_Keyboard:BuildMasterList()
    -- We previously counted on the LEADERBOARD_LIST_MANAGER to build the list, but the on-demand queries now require manual building here
    LEADERBOARD_LIST_MANAGER:BuildMasterList()
end

function ZO_LeaderboardsManager_Keyboard:FilterScrollList()
    local selectedData = self.filterComboBox:GetSelectedItemData()
    if selectedData then
        local playerName = GetUnitName("player")
        local index = 0
        local function PreAddCallback(data)
            index = index + 1
            data.index = index
            data.recolorName = data.characterName == playerName
        end

        local filteredClass = self:GetSelectedClassFilter()
        LEADERBOARD_LIST_MANAGER:FilterScrollList(self.list, filteredClass, PreAddCallback)

        self.emptyRow:SetHidden(index > 0)
    end
end

function ZO_LeaderboardsManager_Keyboard:ColorRow(control, data)
    local nameColor = data.recolorName and ZO_SELECTED_TEXT or ZO_SECOND_CONTRAST_TEXT
    control.nameLabel:SetColor(nameColor:UnpackRGBA())
end

function ZO_LeaderboardsManager_Keyboard:RepopulateFilterDropdown()
    local function OnFilterChanged(comboBox, entryText, entry)
        local leaderboard = self:GetSelectedLeaderboardData()
        if not leaderboard.leaderboardObject:HandleFilterDropdownChanged() then
            self:RefreshFilters()
        end
    end

    ZO_Leaderboards_PopulateDropdownFilter(self.filterComboBox, OnFilterChanged, LEADERBOARD_LIST_MANAGER.leaderboardRankType)
end

function ZO_LeaderboardsManager_Keyboard:GetSelectedClassFilter()
    local selectedData = self.filterComboBox:GetSelectedItemData()
    if selectedData then
        return selectedData.classId
    end
    
    return 0
end

function ZO_LeaderboardsManager_Keyboard:SetLoadingSpinnerVisibility(show)
    self.list:SetHidden(show)
    if show then
        self.loadingIcon:Show()
        self.emptyRow:SetHidden(true)
    else
        self.loadingIcon:Hide()
    end
end

function ZO_LeaderboardsManager_Keyboard:RefreshPointsHeader()
    self.pointsHeaderLabel:SetText(self.headerPointsText)
end

--Global XML Handlers
-----------------------

function ZO_LeaderboardsRowName_OnMouseEnter(control)
    ZO_SocialListKeyboard.CharacterName_OnMouseEnter(LEADERBOARDS, control)
end

function ZO_LeaderboardsRowName_OnMouseExit(control)
     ZO_SocialListKeyboard.CharacterName_OnMouseExit(LEADERBOARDS, control)
end

function ZO_LeaderboardsRowClass_OnMouseEnter(control)
    ZO_SocialListKeyboard.Class_OnMouseEnter(LEADERBOARDS, control)
end

function ZO_LeaderboardsRowClass_OnMouseExit(control)
    ZO_SocialListKeyboard.Class_OnMouseExit(LEADERBOARDS, control)
end

function ZO_LeaderboardsRowAlliance_OnMouseEnter(control)
    ZO_SocialListKeyboard.Alliance_OnMouseEnter(LEADERBOARDS, control)
end

function ZO_LeaderboardsRowAlliance_OnMouseExit(control)
    ZO_SocialListKeyboard.Alliance_OnMouseExit(LEADERBOARDS, control)
end

function ZO_Leaderboards_OnInitialized(self)
    LEADERBOARDS = ZO_LeaderboardsManager_Keyboard:New(self)
end
