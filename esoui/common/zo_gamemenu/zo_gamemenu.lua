---------------------------
-- ZO_GameMenu_Base
--
-- Base Game Menu for structuring a keyboard tree menu like settings
---------------------------

ZO_GameMenu_Base = ZO_Object:Subclass()

function ZO_GameMenu_Base:New(...)
    local object = ZO_Object.New(self)
    object:Initialize(...)
    return object
end

function ZO_GameMenu_Base:Initialize(control)
    self.control = control
    control.owner = self

    self:InitializeTree()
    self.headerControls = {}
end

function ZO_GameMenu_Base:InitializeTree()
    self.navigationTree = ZO_Tree:New(GetControl(self.control, "NavigationContainerScrollChild"), 30, 8, 285)

    local function BaseTreeHeaderSetup(node, control, data, open)
        control:SetModifyTextType(MODIFY_TEXT_TYPE_UPPERCASE)
        control:SetText(data.name)

        ZO_LabelHeader_Setup(control, open)
    end

    local function TreeHeaderSetup_Child(node, control, data, open, userRequested)
        BaseTreeHeaderSetup(node, control, data, open)

        if open and userRequested then
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
    self.navigationTree:AddTemplate("ZO_GameMenu_Subcategory", TreeEntrySetup, TreeEntryOnSelected)

    self.navigationTree:SetExclusive(true)
    self.navigationTree:SetOpenAnimation("ZO_TreeOpenAnimation")

    self.navigationTree:Reset()
end

function ZO_GameMenu_Base:GetControl()
    return self.control
end

function ZO_GameMenu_Base:SubmitLists(...)
    self.navigationTree:Reset()
    self.headerControls = {}

    for i = 1, select("#", ...) do
        local entries = select(i, ...)
        for j, entry in ipairs(entries) do
            self:AddEntry(entry)
        end
    end

    for i, entry in ipairs(ZO_GameMenuManager_GetSubcategoriesEntries()) do
        local visible = entry.visible == nil or entry.visible
        if type(visible) == "function" then
            visible = visible()
        end
        if visible then
            self:AddEntry(entry)
        end
    end

    self.navigationTree:Commit()
    self:RefreshNewStates()
end

function ZO_GameMenu_Base:AddEntry(data)
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
            self.navigationTree:AddNode("ZO_GameMenu_Subcategory", data, parent)
        end
    else
        -- It's a header...determine what type
        if not self.headerControls[data.name] then
            if data.callback then
                -- No children...does it have a selected state?
                if data.hasSelectedState then
                    self.headerControls[data.name] = self.navigationTree:AddNode("ZO_GameMenu_ChildlessHeader_WithSelectedState", data)
                else
                    self.headerControls[data.name] = self.navigationTree:AddNode("ZO_GameMenu_ChildlessHeader", data)
                end
            else
                -- It will have children
                self.headerControls[data.name] = self.navigationTree:AddNode("ZO_GameMenu_LabelHeader", data)
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

        if isNew then
            if not newStatusControl then
                newStatusControl = CreateControlFromVirtual(treeNode.control:GetName() .. "NewStatus", treeNode.control, "ZO_GameMenu_NewStatus")
                newStatusControl:SetAnchor(LEFT, treeNode.control, RIGHT, 10, 0)
                treeNode.control.newStatusControl = newStatusControl -- treenodes and data are transient, need to hang this off the control
            end
        end

        if newStatusControl then
            newStatusControl:SetHidden(not isNew)
        end
    end

    function ZO_GameMenu_Base:RefreshNewStates()
        self.navigationTree:ExecuteOnSubTree(nil, RefreshNewStates)
    end
end

function ZO_GameMenu_ChildlessHeader_OnMouseUp(self, upInside)
    if upInside and self.callback then
        self.callback(self)
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

function ZO_GameMenu_Initialize(control, onShowFunction, onHideFunction)
    local gameMenu = ZO_GameMenu_Base:New(control)
    control.OnShow = onShowFunction
    control.OnHide = onHideFunction
    control.gameMenu = gameMenu
    return gameMenu
end
