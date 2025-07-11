local CAMPAIGN_OVERVIEW_TYPE_SCORING = 1
local CAMPAIGN_OVERVIEW_TYPE_BONUSES = 2
local CAMPAIGN_OVERVIEW_TYPE_EMPEROR = 3

ZO_CAMPAIGN_OVERVIEW_TYPE_INFO =
{
    [CAMPAIGN_OVERVIEW_TYPE_SCORING] =
    {
        name = GetString(SI_CAMPAIGN_OVERVIEW_CATEGORY_SCORING),
        normalIcon = "EsoUI/Art/Campaign/overview_indexIcon_scoring_up.dds",
        pressedIcon = "EsoUI/Art/Campaign/overview_indexIcon_scoring_down.dds",
        mouseoverIcon = "EsoUI/Art/Campaign/overview_indexIcon_scoring_over.dds",
        priority = CAMPAIGN_OVERVIEW_TYPE_SCORING * 10,
        categoryFragmentFunction = function()
            CAMPAIGN_OVERVIEW:RemoveAllCategoryFragments()
            CAMPAIGN_OVERVIEW:ShowCampaignSelector()
            CAMPAIGN_OVERVIEW_SCENE:AddFragment(CAMPAIGN_SCORING_FRAGMENT)
        end,
    },
    [CAMPAIGN_OVERVIEW_TYPE_BONUSES] =
    {
        name = GetString(SI_CAMPAIGN_OVERVIEW_CATEGORY_BONUSES),
        normalIcon = "EsoUI/Art/Campaign/overview_indexIcon_bonus_up.dds",
        pressedIcon = "EsoUI/Art/Campaign/overview_indexIcon_bonus_down.dds",
        mouseoverIcon = "EsoUI/Art/Campaign/overview_indexIcon_bonus_over.dds",
        priority = CAMPAIGN_OVERVIEW_TYPE_BONUSES * 10,
        categoryFragmentFunction = function()
            CAMPAIGN_OVERVIEW:RemoveAllCategoryFragments()
            CAMPAIGN_OVERVIEW:ShowCampaignSelector()
            CAMPAIGN_OVERVIEW_SCENE:AddFragment(CAMPAIGN_BONUSES_FRAGMENT)
        end,
        visible = function() return GetAssignedCampaignId() ~= 0 end,
    },
    [CAMPAIGN_OVERVIEW_TYPE_EMPEROR] =
    {
        name = GetString(SI_CAMPAIGN_OVERVIEW_CATEGORY_EMPERORSHIP),
        normalIcon = "EsoUI/Art/Campaign/overview_indexIcon_emperor_up.dds",
        pressedIcon = "EsoUI/Art/Campaign/overview_indexIcon_emperor_down.dds",
        mouseoverIcon = "EsoUI/Art/Campaign/overview_indexIcon_emperor_over.dds",
        priority = CAMPAIGN_OVERVIEW_TYPE_EMPEROR * 10,
        categoryFragmentFunction = function()
            CAMPAIGN_OVERVIEW:RemoveAllCategoryFragments()
            CAMPAIGN_OVERVIEW:ShowCampaignSelector()
            CAMPAIGN_OVERVIEW_SCENE:AddFragment(CAMPAIGN_EMPEROR_FRAGMENT)
        end,
    },
}

ZO_CampaignOverviewManager = ZO_InitializingObject:Subclass()

function ZO_CampaignOverviewManager:Initialize(control)
    self.control = control

    local function OnStateChange(oldState, newState)
        if newState == ZO_STATE.SHOWING then
            if self.currentCategoryFragmentFunction then
                self.currentCategoryFragmentFunction()
            end

            if self.categoryFragmentToShow then
                self:SetCurrentCategory(self.categoryFragmentToShow)
                self.categoryFragmentToShow = nil
            end

            if self.categoryDataToShow then
                self:SetCurrentCategoryByData(self.categoryDataToShow)
                self.categoryDataToShow = nil
            end
        end
    end

    CAMPAIGN_OVERVIEW_SCENE = ZO_Scene:New("campaignOverview", SCENE_MANAGER)
    CAMPAIGN_OVERVIEW_SCENE:RegisterCallback("StateChange", OnStateChange)

    self.campaignName = self.control:GetNamedChild("CampaignName")
    self.campaignDivider = self.control:GetNamedChild("TopDivider")
    self:InitializeCategories()
end

function ZO_CampaignOverviewManager:UpdateCampaignName(campaignId)
    local campaignName = GetCampaignName(campaignId)
    self.campaignName:SetText(campaignName)
end

function ZO_CampaignOverviewManager:SetCampaignAndQueryType(campaignId, queryType)
    self:UpdateCampaignName(campaignId)
end

function ZO_CampaignOverviewManager:InitializeCategories()
    self.navigationTree = ZO_Tree:New(self.control:GetNamedChild("Categories"), 60, -10, 280)
    self.categoryFragmentToNodeLookup = {}
    self.nodeList = {}

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

        local selected = node.selected or open
        RefreshNode(control, categoryData, selected, not disabled)
    end

    local function SetupParentNode(node, control, categoryData, open, userRequested)
        SetupNode(node, control, categoryData, open)

        if node.enabled and open and userRequested then
            local selectedNode = self.navigationTree:GetSelectedNode()
            if not selectedNode or selectedNode.parentNode ~= node then
                self.navigationTree:SelectFirstChild(node)
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
            if CAMPAIGN_OVERVIEW_SCENE:IsShowing() then
                -- Order matters:

                local hasCategoryChanged = self.currentCategoryFragmentFunction ~= categoryData.categoryFragmentFunction
                self.currentCategoryFragmentFunction = categoryData.categoryFragmentFunction
                if categoryData.onTreeEntrySelected then
                    categoryData.onTreeEntrySelected(categoryData)
                end

                if hasCategoryChanged and self.currentCategoryFragmentFunction then
                    self.currentCategoryFragmentFunction()
                end
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

    self:RefreshCategories()

    self.control:RegisterForEvent(EVENT_ASSIGNED_CAMPAIGN_CHANGED, function() self:RefreshCategories() end)
end

function ZO_CampaignOverviewManager:GetTreeNodeByCategoryData(categoryData)
    local node = self.navigationTree:GetTreeNodeByData(categoryData)
    return node
end

-- Queue the specified category fragment to show.
function ZO_CampaignOverviewManager:SetCategoryOnShow(categoryFragment)
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
function ZO_CampaignOverviewManager:SetCategoryOnShowByData(categoryData)
    local node = self:GetTreeNodeByCategoryData(categoryData)
    if node then
        -- categoryDataToShow and categoryFragmentToShow are mutually exclusive.
        self.categoryDataToShow = categoryData
        self.categoryFragmentToShow = nil
        return true
    end
    return false
end

-- Show the specified category fragment, if the Campaign Overview is showing, or queue it to show.
function ZO_CampaignOverviewManager:SetCurrentCategory(categoryFragment)
    if CAMPAIGN_OVERVIEW_SCENE:IsShowing() then
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

-- Show the specified category data, if the Campaign Overview is showing, or queue it to show.
function ZO_CampaignOverviewManager:SetCurrentCategoryByData(categoryData)
    if CAMPAIGN_OVERVIEW_SCENE:IsShowing() then
        -- Look up the tree node associated with the queued category data and select it.
        local node = self:GetTreeNodeByCategoryData(categoryData)
        if node then
            local nodeIsSelected = node == self.navigationTree:GetSelectedNode()
            if nodeIsSelected then
                if not self.currentCategoryFragment or self.currentCategoryFragment ~= categoryData.categoryFragment then
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

    function ZO_CampaignOverviewManager:RefreshCategories()
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

        self:AddCategoryTreeNodes(ZO_CAMPAIGN_OVERVIEW_TYPE_INFO)

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

    function ZO_CampaignOverviewManager:AddCategoryTreeNodes(nodeDataList, parentNode)
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

    function ZO_CampaignOverviewManager:AddCategoryTreeNode(nodeData, parentNode)
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

        return node
    end
end

function ZO_CampaignOverviewManager:RemoveAllCategoryFragments()
    CAMPAIGN_OVERVIEW_SCENE:RemoveFragment(CAMPAIGN_SCORING_FRAGMENT)
    CAMPAIGN_OVERVIEW_SCENE:RemoveFragment(CAMPAIGN_BONUSES_FRAGMENT)
    CAMPAIGN_OVERVIEW_SCENE:RemoveFragment(CAMPAIGN_EMPEROR_FRAGMENT)
end

function ZO_CampaignOverviewManager:ShowCampaignSelector()
    self.campaignName:SetHidden(false)
    self.campaignDivider:SetHidden(false)
    CAMPAIGN_OVERVIEW_SCENE:AddFragment(CAMPAIGN_SELECTOR_FRAGMENT)
end

function ZO_CampaignOverviewManager:HideCampaignSelector()
    self.campaignName:SetHidden(true)
    self.campaignDivider:SetHidden(true)
    CAMPAIGN_OVERVIEW_SCENE:RemoveFragment(CAMPAIGN_SELECTOR_FRAGMENT)
end

-----------------------------
-- Global XML Functions
-----------------------------

function ZO_CampaignOverview_OnInitialized(self)
    CAMPAIGN_OVERVIEW = ZO_CampaignOverviewManager:New(self)
end
