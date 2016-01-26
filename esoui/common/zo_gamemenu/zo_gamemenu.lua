local outsideEntries = {}

ZO_GameMenuManager = ZO_Object:Subclass()

function ZO_GameMenuManager:New(...)
    local gameMenu = ZO_Object.New(self)
    gameMenu:Initialize(...)
    return gameMenu
end

function ZO_GameMenuManager:Initialize(control)
    self.control = control
    control.owner = self

    self:InitializeTree()
    self.headerControls = {}
end

function ZO_GameMenuManager:InitializeTree()
    self.navigationTree = ZO_Tree:New(GetControl(self.control, "NavigationContainerScrollChild"), 30, 8, 285)

    local function BaseTreeHeaderSetup(node, control, data, open)
        control:SetModifyTextType(MODIFY_TEXT_TYPE_UPPERCASE)
        control:SetText(data.name)

        ZO_LabelHeader_Setup(control, open)
    end

    local function TreeHeaderSetup_Child(node, control, data, open, userRequested)
        BaseTreeHeaderSetup(node, control, data, open)

        if(open and userRequested) then
            self.navigationTree:SelectFirstChild(node)
        end
    end

    local function TreeHeaderSetup_Childless(node, control, data, open)
        control.callback = data.callback
        BaseTreeHeaderSetup(node, control, data, open)
    end

    local function TreeEntrySetup(node, control, data, open)
        control:SetSelected(false)
        control:SetText(data.name)
    end

    local function TreeEntryOnSelected(control, data, selected, reselectingDuringRebuild)
        control:SetSelected(selected)
        if not reselectingDuringRebuild then
            if selected then
                if data.callback then
                    data.callback(control)
                end
            else
                if data.unselectedCallback then
                    data.unselectedCallback(control)
                end
            end
        end
    end

    self.navigationTree:AddTemplate("ZO_GameMenu_LabelHeader", TreeHeaderSetup_Child, nil, nil, nil, 5)
    self.navigationTree:AddTemplate("ZO_GameMenu_ChildlessHeader", TreeHeaderSetup_Childless)
    self.navigationTree:AddTemplate("ZO_GameMenu_ChildlessHeader_WithSelectedState", TreeHeaderSetup_Childless, TreeEntryOnSelected)
    self.navigationTree:AddTemplate("ZO_GameMenu_SubCategory", TreeEntrySetup, TreeEntryOnSelected)

    self.navigationTree:SetExclusive(true)
    self.navigationTree:SetOpenAnimation("ZO_TreeOpenAnimation")

    self.navigationTree:Reset()
end

function ZO_GameMenuManager:SubmitLists(...)
    self.navigationTree:Reset()
    self.headerControls = {}

    for i = 1, select("#", ...) do
        local entries = select(i, ...)
        for j = 1, #entries do
            self:AddEntry(entries[j])
        end
    end

    for i = 1, #outsideEntries do
        self:AddEntry(outsideEntries[i])
    end

    self.navigationTree:Commit()
    self:RefreshNewStates()
end

function ZO_GameMenuManager:AddEntry(data)
    if data.categoryName then
        -- It's not a header...add the header if needed
        local parent
        if not self.headerControls[data.categoryName] then
            local headerData = {name = data.categoryName}
            parent = self:AddEntry(headerData)
        else
            parent = self.headerControls[data.categoryName]
        end

        -- Then add the child
        if parent then
            self.navigationTree:AddNode("ZO_GameMenu_SubCategory", data, parent, SOUNDS.MENU_SUBCATEGORY_SELECTION)
        end
    else
        -- It's a header...determine what type
        if not self.headerControls[data.name] then
            if data.callback then
                -- No children...does it have a selected state?
                if data.hasSelectedState then
                    self.headerControls[data.name] = self.navigationTree:AddNode("ZO_GameMenu_ChildlessHeader_WithSelectedState", data, nil, SOUNDS.MENU_HEADER_SELECTION)
                else
                    self.headerControls[data.name] = self.navigationTree:AddNode("ZO_GameMenu_ChildlessHeader", data, nil, SOUNDS.MENU_HEADER_SELECTION)
                end
            else
                -- It will have children
                self.headerControls[data.name] = self.navigationTree:AddNode("ZO_GameMenu_LabelHeader", data, nil, SOUNDS.MENU_HEADER_SELECTION)
            end
            return self.headerControls[data.name]
        end
    end
end

do
    local function RefreshNewStates(treeNode)
        local data = treeNode.data
        local newStateCallback = data.showNewIconCallback
        local isNew = newStateCallback and newStateCallback()
        local newStatusControl = treeNode.control.newStatusControl

        if(isNew) then
            if(not newStatusControl) then
                newStatusControl = CreateControlFromVirtual(treeNode.control:GetName() .. "NewStatus", treeNode.control, "ZO_GameMenu_NewStatus")
                newStatusControl:SetAnchor(LEFT, treeNode.control, RIGHT, 10, 0)
                treeNode.control.newStatusControl = newStatusControl -- treenodes and data are transient, need to hang this off the control
            end
        end
        
        if(newStatusControl) then
            newStatusControl:SetHidden(not isNew)
        end
    end

    function ZO_GameMenuManager:RefreshNewStates()
        self.navigationTree:ExecuteOnSubTree(nil, RefreshNewStates)
    end
end

function ZO_GameMenu_ChildlessHeader_OnMouseUp(self, upInside)
    if upInside then
        if self.callback then
            self.callback(self)
        end
    end
end

function ZO_GameMenu_OnShow(control)
    if control.OnShow then
        control.OnShow(control.gameMenu)
    end
end

function ZO_GameMenu_OnHide(control)
    if control.OnHide then
        control.OnHide(control.gameMenu)
    end
end

function ZO_GameMenu_AddSettingPanel(data)
    data.categoryName = GetString(SI_GAME_MENU_SETTINGS)
    table.insert(outsideEntries, data)
end

function ZO_GameMenu_AddControlsPanel(data)
    data.categoryName = GetString(SI_GAME_MENU_CONTROLS)
    table.insert(outsideEntries, data)
end

function ZO_GameMenu_Initialize(control, onShowFunction, onHideFunction)
    local gameMenu = ZO_GameMenuManager:New(control)
    control.OnShow = onShowFunction
    control.OnHide = onHideFunction
    control.gameMenu = gameMenu
    return gameMenu
end
