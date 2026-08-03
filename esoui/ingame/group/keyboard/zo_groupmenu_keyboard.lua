ZO_GROUP_MENU_KEYBOARD_TREE_WIDTH = 300
-- 75 is the inset from the multiIcon plus the icon and spacing from ZO_IconHeader
local scrollBarOffset = 16
ZO_GROUP_MENU_KEYBOARD_TREE_LABEL_WIDTH = ZO_GROUP_MENU_KEYBOARD_TREE_WIDTH - 75 - scrollBarOffset
ZO_GROUP_MENU_KEYBOARD_TREE_SUBCATEGORY_INDENT = 75
ZO_GROUP_MENU_KEYBOARD_TREE_SUBCATEGORY_LABEL_WIDTH = ZO_GROUP_MENU_KEYBOARD_TREE_WIDTH - ZO_GROUP_MENU_KEYBOARD_TREE_SUBCATEGORY_INDENT - scrollBarOffset

local GroupMenu_Keyboard = ZO_InitializingObject:Subclass()

function GroupMenu_Keyboard:Initialize(control)
    self.control = control
    self.headerControl = self.control:GetNamedChild("Header")
    self.categoriesControl = self.control:GetNamedChild("Categories")

    local function OnStateChange(oldState, newState)
        if newState == ZO_STATE.SHOWING then
            if self.currentCategoryFragment then
                SCENE_MANAGER:AddFragment(self.currentCategoryFragment)
            end

            PREFERRED_ROLES:RefreshRoles()

            if self.categoryFragmentToShow then
                self:SetCurrentCategory(self.categoryFragmentToShow)
                self.categoryFragmentToShow = nil
            end

            self.categoriesRefreshGroup:TryClean()

            --Order matters. Do this AFTER we clean the refresh group so that this isn't overwritten
            if self.categoryDataToShow then
                -- We have a categoryDataToShow because we couldn't show it when we set it.
                local FORCE_SELECT_NODE = true
                self:SetCurrentCategoryByData(self.categoryDataToShow, FORCE_SELECT_NODE)
                self.categoryDataToShow = nil
            end
        elseif newState == ZO_STATE.HIDDEN then
            PROMOTIONAL_EVENTS_KEYBOARD:RefreshCampaignList()
        end
    end

    KEYBOARD_GROUP_MENU_SCENE = ZO_Scene:New("groupMenuKeyboard", SCENE_MANAGER)
    KEYBOARD_GROUP_MENU_SCENE:RegisterCallback("StateChange", OnStateChange)

    self:InitializeCategories()

    local function RefreshCategories()
        self.categoriesRefreshGroup:MarkDirty("List")
    end

    local function RebuildCategories()
        self:RebuildCategories()
    end

    ZO_ACTIVITY_FINDER_ROOT_MANAGER:RegisterCallback("OnLevelUpdate", RefreshCategories)
    ZO_COLLECTIBLE_DATA_MANAGER:RegisterCallback("OnCollectionUpdated", RefreshCategories)
    PROMOTIONAL_EVENT_MANAGER:RegisterCallback("CampaignSeenStateChanged", RefreshCategories)
    PROMOTIONAL_EVENT_MANAGER:RegisterCallback("CampaignsUpdated", RebuildCategories)
    PROMOTIONAL_EVENT_MANAGER:RegisterCallback("RewardsClaimed", RefreshCategories)
    PROMOTIONAL_EVENT_MANAGER:RegisterCallback("ActivityProgressUpdated", RefreshCategories)

    self.control:RegisterForEvent(EVENT_PLAYER_ACTIVATED, RefreshCategories)
    self.control:RegisterForEvent(EVENT_QUEST_COMPLETE, RefreshCategories)
    self.control:RegisterForEvent(EVENT_GROUP_FINDER_STATUS_UPDATED, RefreshCategories)
    self.control:RegisterForEvent(EVENT_GROUP_FINDER_APPLICATION_RECEIVED, RefreshCategories)
    self.control:RegisterForEvent(EVENT_HOUSE_TOURS_STATUS_UPDATED, RefreshCategories)
    self.control:RegisterForEvent(EVENT_SPECTACLE_EVENT_UPDATED, RebuildCategories)
end

function GroupMenu_Keyboard:InitializeCategories()
    self.navigationTree = ZO_Tree:New(self.categoriesControl:GetNamedChild("ScrollChild"), 60, -10, ZO_GROUP_MENU_KEYBOARD_TREE_WIDTH)
    self.categoryFragmentToNodeLookup = {}
    self.nodeList = {}

    -- Categories refresh group
    local categoriesRefreshGroup = ZO_OrderedRefreshGroup:New(ZO_ORDERED_REFRESH_GROUP_AUTO_CLEAN_PER_FRAME)
    categoriesRefreshGroup:AddDirtyState("List", function()
        self:RefreshCategories()
    end)

    categoriesRefreshGroup:SetActive(function()
        return self:IsCategoriesRefreshGroupActive()
    end)

    categoriesRefreshGroup:MarkDirty("List")
    self.categoriesRefreshGroup = categoriesRefreshGroup

    local function GetPromotionalEventTextColor(control)
        if not control.enabled then
            return ZO_DISABLED_TEXT:UnpackRGBA()
        elseif control.mouseover and not control.selected then
            return ZO_PROMOTIONAL_EVENT_HIGHLIGHT_COLOR:UnpackRGBA()
        else
            return ZO_PROMOTIONAL_EVENT_SELECTED_COLOR:UnpackRGBA()
        end
    end

    local function RefreshNode(control, categoryData, open, enabled)
        if control.icon then
            local iconTexture = open and categoryData.pressedIcon or categoryData.normalIcon
            iconTexture = not enabled and categoryData.disabledIcon or iconTexture
            if type(iconTexture) == "function" then
                iconTexture = iconTexture()
            end
            control.icon:SetTexture(iconTexture)
            local mouseoverIcon = categoryData.mouseoverIcon
            if type(mouseoverIcon) == "function" then
                mouseoverIcon = mouseoverIcon()
            end
            control.iconHighlight:SetTexture(mouseoverIcon)

            if categoryData.isPromotionalEvent and PROMOTIONAL_EVENT_MANAGER:HasAnyUnclaimedRewards() then
                control.text.GetTextColor = GetPromotionalEventTextColor
            else
                ZO_SelectableLabel_ResetColorFunctionToDefault(control.text)
            end

            local statusIcon = control.statusIcon or control:GetNamedChild("StatusIcon")
            control.statusIcon = statusIcon
            statusIcon:ClearIcons()

            if ZO_Eval(categoryData.isNew) then
                statusIcon:AddIcon(ZO_KEYBOARD_NEW_ICON)
            end

            statusIcon:Show()

            ZO_IconHeader_Setup(control, open, enabled)
        end
    end

    local function SetupNode(node, control, categoryData, open)
        control.text:SetText(categoryData.name)
        control.text:SetModifyTextType(MODIFY_TEXT_TYPE_UPPERCASE)

        local disabled = false
        if categoryData then
            local statusResult = GetGroupFinderStatusReason()
            local houseToursEnabled = ZO_IsHouseToursEnabled()
            disabled = categoryData.activityFinderObject and (categoryData.activityFinderObject:GetLevelLockInfo() or categoryData.activityFinderObject:GetNumLocations() == 0) or false
            disabled = disabled or ZO_Eval(categoryData.isLocked)
            disabled = disabled or (categoryData.isAccountRestricted and categoryData.isAccountRestricted() or false)
        end

        if disabled and node:IsOpen() then
            local tree = node:GetTree()
            if tree:GetSelectedNode() and tree:GetSelectedNode():GetParent() == node then
                tree:ClearSelectedNode()
            end
            node:SetOpen(false)
        end

        local selected = node.selected or open
        RefreshNode(control, categoryData, selected, not disabled)
    end

    local function SetupParentNode(node, control, categoryData, open, userRequested)
        SetupNode(node, control, categoryData, open)

        if node.enabled and open and userRequested then
            local selectedNode = self.navigationTree:GetSelectedNode()
            if not selectedNode or selectedNode.parentNode ~= node then
                if categoryData.isPromotionalEvent and PROMOTIONAL_EVENT_PERSONAL_CAMPAIGN_MANAGER:IsReturningPlayer() then
                    local children = node:GetChildren()
                    if children then
                        local firstCampaign = children[2]
                        if firstCampaign then
                            self.navigationTree:SelectNode(firstCampaign)
                        else
                            self.navigationTree:SelectFirstChild(node)
                        end
                    end
                else
                    self.navigationTree:SelectFirstChild(node)
                end
            end
        end

        local statusIcon = control.statusIcon or control:GetNamedChild("StatusIcon")
        control.statusIcon = statusIcon
        statusIcon:ClearIcons()

        if ZO_Eval(categoryData.isNew) then
            statusIcon:AddIcon(ZO_KEYBOARD_NEW_ICON)
        end

        statusIcon:Show()
    end

    local function SetupChildNode(node, control, categoryData, open)
        local selected = node:IsSelected()
        control:SetSelected(selected)
        control:SetText(categoryData.name)
        if categoryData.onSetup then
            categoryData.onSetup(node, control, categoryData, open)
        end
    end

    local function OnNodeSelected(control, categoryData, selected, reselectingDuringRebuild)
        control:SetSelected(selected)

        if selected then
            if categoryData.activityFinderObject then
                ZO_ACTIVITY_FINDER_ROOT_MANAGER:ClearSelections()
            end

            if KEYBOARD_GROUP_MENU_SCENE:IsShowing() then
                -- Order matters:

                local hasCategoryChanged = self.currentCategoryFragment ~= categoryData.categoryFragment
                if hasCategoryChanged and self.currentCategoryFragment then
                    SCENE_MANAGER:RemoveFragment(self.currentCategoryFragment)
                end

                self.currentCategoryFragment = categoryData.categoryFragment
                if categoryData.onTreeEntrySelected then
                    categoryData.onTreeEntrySelected(categoryData)
                end
                SCENE_MANAGER:AddFragment(categoryData.categoryFragment)
            else
                -- Queue the category to show by category data,
                -- if possible, or by category fragment otherwise.
                if not self:SetCategoryOnShowByData(categoryData) then
                    self:SetCategoryOnShow(categoryData.categoryFragment)
                end
            end
        end

        RefreshNode(control, categoryData, selected, control.enabled)
    end

    local CHILD_SPACING = 0
    local NO_SELECTION_FUNCTION = nil
    local NO_EQUALITY_FUNCTION = nil
    local function EqualityFunction(left, right)
        if left.equalityFunction then
            return left:equalityFunction(right)
        elseif right.equalityFunction then
            return right:equalityFunction(left)
        end
        return left == right
    end
    self.navigationTree:AddTemplate("ZO_GroupMenuKeyboard_StatusIconHeader", SetupParentNode, NO_SELECTION_FUNCTION, NO_EQUALITY_FUNCTION, ZO_GROUP_MENU_KEYBOARD_TREE_SUBCATEGORY_INDENT, CHILD_SPACING)
    self.navigationTree:AddTemplate("ZO_GroupMenuKeyboard_StatusIconChildlessHeader", SetupNode, OnNodeSelected, EqualityFunction)
    self.navigationTree:AddTemplate("ZO_GroupMenuKeyboard_Subcategory", SetupChildNode, OnNodeSelected, EqualityFunction)
    self.navigationTree:SetExclusive(true)
    self.navigationTree:SetOpenAnimation("ZO_TreeOpenAnimation")
end

function GroupMenu_Keyboard:GetTreeNodeByCategoryFragment(categoryFragment)
    local node = self.categoryFragmentToNodeLookup[categoryFragment]
    return node
end

function GroupMenu_Keyboard:GetTreeNodeByCategoryData(categoryData)
    local node = self.navigationTree:GetTreeNodeByData(categoryData)
    return node
end

-- Queue the specified category fragment to show.
function GroupMenu_Keyboard:SetCategoryOnShow(categoryFragment)
    local node = self:GetTreeNodeByCategoryFragment(categoryFragment)
    if node then
        -- categoryDataToShow and categoryFragmentToShow are mutually exclusive.
        self.categoryFragmentToShow = categoryFragment
        self.categoryDataToShow = nil
        return true
    end
    return false
end

-- Queue the specified category data to show.
function GroupMenu_Keyboard:SetCategoryOnShowByData(categoryData)
    local node = self:GetTreeNodeByCategoryData(categoryData)
    if node then
        -- categoryDataToShow and categoryFragmentToShow are mutually exclusive.
        self.categoryDataToShow = categoryData
        self.categoryFragmentToShow = nil
        return true
    end
    return false
end

-- Show the specified category fragment, if the Group Menu is showing, or queue it to show.
function GroupMenu_Keyboard:SetCurrentCategory(categoryFragment)
    if KEYBOARD_GROUP_MENU_SCENE:IsShowing() then
        -- Look up the tree node associated with the queued category fragment and select it.
        local node = self:GetTreeNodeByCategoryFragment(categoryFragment)
        if node then
            self.navigationTree:SelectNode(node)
        end
    else
        -- Queue the category fragment to show.
        self:SetCategoryOnShow(categoryFragment)
    end
end

-- Show the specified category data, if the Group Menu is showing, or queue it to show.
function GroupMenu_Keyboard:SetCurrentCategoryByData(categoryData, forceNodeSelect)
    if KEYBOARD_GROUP_MENU_SCENE:IsShowing() then
        -- Look up the tree node associated with the queued category data and select it.
        local node = self:GetTreeNodeByCategoryData(categoryData)
        if node then
            local nodeIsSelected = node == self.navigationTree:GetSelectedNode()
            if nodeIsSelected then
                if forceNodeSelect or not self.currentCategoryFragment or self.currentCategoryFragment ~= categoryData.categoryFragment then
                    -- In this case the node was auto-selected while hidden or on selection
                    -- was not called before the screen was hidden we need to force the node's
                    -- selection function to run again so it runs it's on showing code.
                    node:OnSelected()
                end
            else
                self.navigationTree:SelectNode(node)
            end
        end
    else
        -- Queue the category data to show.
        self:SetCategoryOnShowByData(categoryData)
    end
end

-- Show the specified category fragment immediately.
function GroupMenu_Keyboard:ShowCategory(categoryFragment)
    if KEYBOARD_GROUP_MENU_SCENE:IsShowing() then
        self:SetCurrentCategory(categoryFragment)
    else
        self:SetCategoryOnShow(categoryFragment)
        MAIN_MENU_KEYBOARD:RefreshCategoryBar()
        MAIN_MENU_KEYBOARD:ShowScene("groupMenuKeyboard")
    end
end

-- Show the specified category data immediately.
function GroupMenu_Keyboard:ShowCategoryByData(categoryData)
    if KEYBOARD_GROUP_MENU_SCENE:IsShowing() then
        self:SetCurrentCategoryByData(categoryData)
    else
        self:SetCategoryOnShowByData(categoryData)
        MAIN_MENU_KEYBOARD:RefreshCategoryBar()
        MAIN_MENU_KEYBOARD:ShowScene("groupMenuKeyboard")
    end
end

function GroupMenu_Keyboard:IsCategoriesRefreshGroupActive()
    return KEYBOARD_GROUP_MENU_SCENE:IsShowing()
end

do
    local CHAMPION_ICON = zo_iconFormat(ZO_GetChampionPointsIcon(), "100%", "100%")

    function GroupMenu_Keyboard:OnActivityCategoryMouseEnter(control, data)
        ZO_IconHeader_OnMouseEnter(control)
        if not control.enabled then
            local isLevelLocked, lowestLevelLimit, lowestRankLimit = data.activityFinderObject:GetLevelLockInfo()
            local lockedText
            if isLevelLocked then
                if lowestLevelLimit then
                    lockedText = zo_strformat(SI_ACTIVITY_FINDER_TOOLTIP_LEVEL_LOCK, lowestLevelLimit)
                elseif lowestRankLimit then
                    lockedText = zo_strformat(SI_ACTIVITY_FINDER_TOOLTIP_CHAMPION_LOCK, CHAMPION_ICON, lowestRankLimit)
                end
            else
                local numLocations = data.activityFinderObject:GetNumLocations()
                if numLocations == 0 then
                    lockedText = GetString(SI_ACTIVITY_FINDER_TOOLTIP_NO_ACTIVITIES_LOCK)
                elseif data.isAccountRestricted and data.isAccountRestricted() then
                    lockedText = GetString(SI_ACTIVITY_FINDER_TOOLTIP_ACCOUNT_LOCK)
                end
            end

            if lockedText then
                self:ShowLockedTooltip(control, lockedText)
            end
        end
    end
end

function GroupMenu_Keyboard:OnLockableCategoryMouseEnter(control, data)
    ZO_IconHeader_OnMouseEnter(control)
    if not control.enabled then
        local isLocked = data.isLocked()
        if isLocked then
            local lockedText = ZO_Eval(data.lockedText)
            self:ShowLockedTooltip(control, lockedText)
        end
    end
end

do
    local LOCK_TEXTURE = zo_iconFormatInheritColor(ZO_KEYBOARD_LOCKED_ICON, "100%", "100%")

    function GroupMenu_Keyboard:ShowLockedTooltip(control, lockedText)
        lockedText = string.format("%s %s", LOCK_TEXTURE, lockedText)
        InitializeTooltip(InformationTooltip, control, RIGHT, -10)
        SetTooltipText(InformationTooltip, lockedText)
    end
end

do
    local function PrioritySort(item1, item2)
        local priority1, priority2 = item1.priority, item2.priority
        if priority1 == priority2 then
            return item1.name < item2.name
        elseif priority1 and priority2 then
            return priority1 < priority2
        else
            return priority1 ~= nil
        end
    end

    function GroupMenu_Keyboard:AddCategoryTreeNode(nodeData, parentNode)
        local nodeTemplate
        if parentNode then
            nodeTemplate = "ZO_GroupMenuKeyboard_Subcategory"
        elseif nodeData.children or (nodeData.getChildrenFunction and #(nodeData.getChildrenFunction()) > 0) then
            nodeTemplate = "ZO_GroupMenuKeyboard_StatusIconHeader"
        else
            nodeTemplate = "ZO_GroupMenuKeyboard_StatusIconChildlessHeader"
        end

        local node = self.navigationTree:AddNode(nodeTemplate, nodeData, parentNode)
        if nodeData.categoryFragment then
            local existingFragmentNode = self.categoryFragmentToNodeLookup[nodeData.categoryFragment]
            if not existingFragmentNode or nodeData.priority < existingFragmentNode:GetData().priority then
                self.categoryFragmentToNodeLookup[nodeData.categoryFragment] = node
            end
        end
        if nodeData.getChildrenFunction then
            node.getChildrenFunction = nodeData.getChildrenFunction
        end

        if nodeData.activityFinderObject then
            node.control.OnMouseEnter = function(control) self:OnActivityCategoryMouseEnter(control, nodeData) end
        elseif nodeData.isLocked then
            node.control.OnMouseEnter = function(control) self:OnLockableCategoryMouseEnter(control, nodeData) end
        end

        return node
    end

    function GroupMenu_Keyboard:AddCategoryTreeNodes(nodeDataList, parentNode)
        table.sort(nodeDataList, PrioritySort)

        for index, nodeData in ipairs(nodeDataList) do
            local isVisible = true
            if nodeData.visible ~= nil then
                isVisible = nodeData.visible
                if type(isVisible) == "function" then
                    isVisible = isVisible()
                end
            end

            if isVisible then
                local node = self:AddCategoryTreeNode(nodeData, parentNode)

                local children = nodeData.children
                if nodeData.getChildrenFunction then
                    children = nodeData.getChildrenFunction()
                end

                if children and #children > 0 then
                    self:AddCategoryTreeNodes(children, node)
                end
            end
        end
    end

    function GroupMenu_Keyboard:AddCategory(data)
        self.navigationTree:Reset()
        ZO_ClearTable(self.categoryFragmentToNodeLookup)

        table.insert(self.nodeList, data)
        self:AddCategoryTreeNodes(self.nodeList)

        self.navigationTree:Commit()
    end
end

function GroupMenu_Keyboard:RebuildCategories()
    local selectedParentData = nil
    local selectedNode = self.navigationTree:GetSelectedNode()
    if selectedNode then
        local parentNode = selectedNode:GetParent()
        if parentNode then
            selectedParentData = parentNode:GetData()
        end
    end

    self.navigationTree:Reset()
    ZO_ClearTable(self.categoryFragmentToNodeLookup)

    self:AddCategoryTreeNodes(self.nodeList)

    --Order matters: Do this after the category nodes have been added
    local nodeToSelect
    if selectedParentData then
        local parentNode = self.navigationTree:GetTreeNodeByData(selectedParentData)
        if parentNode then
            nodeToSelect = parentNode:GetChild(1)
        end
    end

    self.navigationTree:Commit(nodeToSelect)
end

function GroupMenu_Keyboard:GetTree()
    return self.navigationTree
end

function GroupMenu_Keyboard:HideTree()
    self.categoriesControl:SetHidden(true)
end

function GroupMenu_Keyboard:ShowTree()
    self.categoriesControl:SetHidden(false)
end

function GroupMenu_Keyboard:RefreshCategories()
    self.navigationTree:RefreshVisible()
    self.navigationTree:Commit()
end

function ZO_GroupMenuKeyboard_OnInitialized(control)
    GROUP_MENU_KEYBOARD = GroupMenu_Keyboard:New(control)
end