ZO_GUILD_FINDER_KEYBOARD_OPTIONS_TREE_WIDTH = 240
ZO_GUILD_FINDER_KEYBOARD_OPTIONS_TREE_LABEL_WIDTH = ZO_GUILD_FINDER_KEYBOARD_OPTIONS_TREE_WIDTH - 64

ZO_GuildFinder_Keyboard_Base = ZO_Object:Subclass()

function ZO_GuildFinder_Keyboard_Base:New(...)
    local object = ZO_Object.New(self)
    object:Initialize(...)
    return object
end

function ZO_GuildFinder_Keyboard_Base:Initialize(control)
    self.hasDeferredInitialized = false
    self.listContainer = control:GetNamedChild("List")

    self.categoryTree = ZO_Tree:New(self.listContainer, 60, -10, ZO_GUILD_FINDER_KEYBOARD_OPTIONS_TREE_WIDTH)

    self.iconChildlessHeaderTemplateName = self.iconChildlessHeaderTemplateName or "ZO_IconChildlessHeader"

    local function SetupControlIcon(control, categoryInfo, open)
        control.icon:SetTexture(open and categoryInfo.down or categoryInfo.up)
        control.iconHighlight:SetTexture(categoryInfo.over)

        ZO_IconHeader_Setup(control, open)
    end

    local function TreeHeaderSetup_Childless(node, control, categoryInfo, open)
        control.text:SetModifyTextType(MODIFY_TEXT_TYPE_UPPERCASE)
        control.text:SetText(categoryInfo.name)

        SetupControlIcon(control, categoryInfo, open)
    end

    local function TreeHeaderSelected_Childless(control, categoryInfo, selected, reselectingDuringRebuild)
        SetupControlIcon(control, categoryInfo, selected)
        if selected then
            self:SetSelectedCategory(categoryInfo)
        end
    end

    local function TreeHeaderSetup_Child(node, control, data, open, userRequested)
        control.text:SetModifyTextType(MODIFY_TEXT_TYPE_UPPERCASE)
        control.text:SetText(data.name)

        SetupControlIcon(control, data, open)

        if open and userRequested then
            self.categoryTree:SelectFirstChild(node)
        end
    end

    self.onSetupChildHeader = self.onSetupChildHeader or TreeHeaderSetup_Child

    local function TreeEntryOnSelected(control, data, selected, reselectingDuringRebuild)
        control:SetSelected(selected)

        if selected and not reselectingDuringRebuild then
            self:SetSelectedCategory(data.data, data.subCategoryData.value)
        end
    end

    local function TreeEntrySetup(node, control, data, open)
        control:SetSelected(false)
        control:SetText(data.subCategoryData.name)
    end

    local NO_EQUALITY_FUNCTION = nil
    local NO_SELECTION_FUNCTION = nil
    local DEFAULT_CHILD_INDENT = nil
    local CHILD_INDENT = 60
    local CHILD_SPACING = 0
    self.categoryTree:AddTemplate(self.iconChildlessHeaderTemplateName, TreeHeaderSetup_Childless, TreeHeaderSelected_Childless, NO_EQUALITY_FUNCTION, DEFAULT_CHILD_INDENT, CHILD_SPACING)
    self.categoryTree:AddTemplate("ZO_GuildFinder_IconHeader", self.onSetupChildHeader, NO_SELECTION_FUNCTION, NO_EQUALITY_FUNCTION, CHILD_INDENT, CHILD_SPACING)
    self.categoryTree:AddTemplate("ZO_GuildFinder_Tree_SubCategory", TreeEntrySetup, TreeEntryOnSelected)
end

function ZO_GuildFinder_Keyboard_Base:SetupData(categoryData)
    self.categoryTree:Reset()
    self.categoryData = categoryData
    self.nodeLookupTable = {}
    
    for i, data in ipairs(categoryData) do
        local visible = data.visible or true
        if type(data.visible) == "function" then
            visible = data.visible(self)
        end

        if visible then
            if data.subCategories then
                local parentNode = self.categoryTree:AddNode("ZO_GuildFinder_IconHeader", data)
                local nodeLookupData = { node = parentNode }
                table.insert(self.nodeLookupTable, nodeLookupData)
                for j, subCategoryData in ipairs(data.subCategories) do
                    local node = self.categoryTree:AddNode("ZO_GuildFinder_Tree_SubCategory", { data = data, subCategoryData = subCategoryData }, parentNode)
                    if not nodeLookupData.subCategories then
                        nodeLookupData.subCategories = {}
                    end
                    table.insert(nodeLookupData.subCategories, node)
                end
            else
                local node = self.categoryTree:AddNode(self.iconChildlessHeaderTemplateName, data)
                local nodeLookupData = { node = node }
                table.insert(self.nodeLookupTable, nodeLookupData)
            end
        end
    end
    
    self.categoryTree:SetExclusive(true)
    self.categoryTree:SetOpenAnimation("ZO_TreeOpenAnimation")
    self.categoryTree:Commit()
end

function ZO_GuildFinder_Keyboard_Base:IsSceneShown()
    assert(false) -- must be overridden
end

function ZO_GuildFinder_Keyboard_Base:SetSelectedCategory(newCategory, newValue)
    if self.selectedCategory ~= newCategory then
        self.subcategoryValue = nil
        self:HideSelectedCategory()
        self.selectedCategory = newCategory
        self:ShowSelectedCategory()
    end

    if self.subcategoryValue ~= newValue then
        self.subcategoryValue = newValue
        if self.hasDeferredInitialized then -- managers are not set until deferred initialize
            self.selectedCategory.manager:SetSubcategoryValue(newValue)
        end
    end
end

function ZO_GuildFinder_Keyboard_Base:HideSelectedCategory()
    if self:IsSceneShown() then
        local manager = self.selectedCategory.manager
        manager:HideCategory()
    end
end

function ZO_GuildFinder_Keyboard_Base:ShowSelectedCategory()
    if self:IsSceneShown() then
        local manager = self.selectedCategory.manager
        if self.subcategoryValue then
            manager:SetSubcategoryValue(self.subcategoryValue)
        end
        manager:ShowCategory()
    end
end
