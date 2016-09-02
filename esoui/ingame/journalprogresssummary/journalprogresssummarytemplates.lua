ZO_JOURNAL_PROGRESS_FAKED_SUBCATEGORY_INDEX = 0

ZO_JournalProgressBook_Common = ZO_Object:Subclass()

--[[ Initialization ]]--
------------------------
function ZO_JournalProgressBook_Common:New(...)
    local object = ZO_Object.New(self)
    object:Initialize(...)
    return object
end

function ZO_JournalProgressBook_Common:Initialize(control)
    control.owner = self
    self.control = control

    self:InitializeControls()
    self:InitializeEvents()
    self:InitializeCategoryTemplates()
	self:InitializeChildIndentAndSpacing()

    ZO_StatusBar_SetGradientColor(self.categoryProgress, ZO_XP_BAR_GRADIENT_COLORS)
    
    self:InitializeCategories(control)
end

function ZO_JournalProgressBook_Common:InitializeControls()
    self.contents = self.control:GetNamedChild("Contents")
    self.contentList = self.contents:GetNamedChild("ContentList")
    self.contentListScrollChild = self.contentList:GetNamedChild("ScrollChild")
    self.categoryInset = self.control:GetNamedChild("Category")
    self.categoryLabel = self.categoryInset:GetNamedChild("Title")
    self.categoryProgress = self.categoryInset:GetNamedChild("Progress")
    self.categoryFilter = self.categoryInset:GetNamedChild("Filter")
end

function ZO_JournalProgressBook_Common:InitializeEvents()
    --Stubbed, to be overriden
end

function ZO_JournalProgressBook_Common:InitializeCategoryTemplates()
    self.parentCategoryTemplate = "ZO_IconHeader"
    self.childlessCategoryTemplate = "ZO_IconChildlessHeader"
    self.subCategoryTemplate = "ZO_JournalSubCategory"
end

function ZO_JournalProgressBook_Common:InitializeChildIndentAndSpacing()
	self.childIndent = 60
	self.childSpacing = 0
end

function ZO_JournalProgressBook_Common:InitializeFilters(filterData, startingStringId)
    local comboBox = ZO_ComboBox_ObjectFromContainer(self.categoryFilter)
    comboBox:SetSortsItems(false)
    comboBox:SetFont("ZoFontWinT1")
    comboBox:SetSpacing(4)
    
    local function OnFilterChanged(comboBox, entryText, entry)
        self.categoryFilter.filterType = entry.filterType
        self:RefreshVisibleCategoryFilter()
    end

    local index = 1
    for i, stringId in ipairs(filterData) do
        local entry = comboBox:CreateItemEntry(GetString(stringId), OnFilterChanged)
        entry.filterType = stringId
        comboBox:AddItem(entry)
        if stringId == startingStringId then
            index = i
        end
    end

    comboBox:SelectItemByIndex(index)
end

function ZO_JournalProgressBook_Common:InitializeSummary(control, totalLabel, recentTitle)
    local function InitializeSummaryStatusBar(statusBar)
        ZO_StatusBar_SetGradientColor(statusBar, ZO_XP_BAR_GRADIENT_COLORS)
        statusBar.category = statusBar:GetNamedChild("Label")
        statusBar.progress = statusBar:GetNamedChild("Progress")
        statusBar:GetNamedChild("BG"):SetDrawLevel(1)
        
        return statusBar
    end
    
    self.summaryInset = control:GetNamedChild("ContentsSummaryInset")
    self.summaryTotal = InitializeSummaryStatusBar(self.summaryInset:GetNamedChild("Total"))
    self.summaryTotal.category:SetModifyTextType(MODIFY_TEXT_TYPE_UPPERCASE)
    self.summaryTotal.category:SetText(totalLabel)

    self.summaryStatusBarPool = ZO_ControlPool:New("ZO_JournalProgressStatusBar", self.summaryInset)
    self.summaryStatusBarPool:SetCustomFactoryBehavior( function(control)
                                                            InitializeSummaryStatusBar(control)
                                                        end)
    
    if recentTitle then
        self.summaryRecent = self.summaryInset:GetNamedChild("Recent")
        local summaryRecentTitle = self.summaryRecent:GetNamedChild("Title")
        summaryRecentTitle:SetModifyTextType(MODIFY_TEXT_TYPE_UPPERCASE)
        summaryRecentTitle:SetText(recentTitle)
        self.summaryRecent:SetHidden(false)
    end
end

function ZO_JournalProgressBook_Common:InitializeCategories(control)
    self.categories = control:GetNamedChild("ContentsCategories")
    self.categoryTree = ZO_Tree:New(self.categories:GetNamedChild("ScrollChild"), 60, -10, 300)

    local function BaseTreeHeaderIconSetup(control, data, open)
        local iconTexture = (open and data.pressedIcon or data.normalIcon) or ZO_NO_TEXTURE_FILE
        local mouseoverTexture = data.mouseoverIcon or ZO_NO_TEXTURE_FILE
        
        control.icon:SetTexture(iconTexture)
        control.iconHighlight:SetTexture(mouseoverTexture)

        ZO_IconHeader_Setup(control, open)
    end

    local function BaseTreeHeaderSetup(node, control, data, open)
        control.text:SetModifyTextType(MODIFY_TEXT_TYPE_UPPERCASE)
        control.text:SetText(data.name)
        BaseTreeHeaderIconSetup(control, data, open)
    end

    local function TreeHeaderSetup_Child(node, control, data, open, userRequested)
        BaseTreeHeaderSetup(node, control, data, open)

        if(open and userRequested) then
            self.categoryTree:SelectFirstChild(node)
        end
    end

    local function TreeHeaderSetup_Childless(node, control, data, open)
        BaseTreeHeaderSetup(node, control, data, open)
    end

    local function TreeEntryOnSelected(control, data, selected, reselectingDuringRebuild)
        control:SetSelected(selected)

        if selected and not reselectingDuringRebuild then
            self:OnCategorySelected(data)
        end
    end

    local function TreeEntryOnSelected_Childless(control, data, selected, reselectingDuringRebuild)
        TreeEntryOnSelected(control, data, selected, reselectingDuringRebuild)
        BaseTreeHeaderIconSetup(control, data, selected)
    end

    local function TreeEntrySetup(node, control, data, open)
        control:SetSelected(false)
        control:SetText(data.name)
    end

    self.categoryTree:AddTemplate(self.parentCategoryTemplate, TreeHeaderSetup_Child, nil, nil, self.childIndent, self.childSpacing)
    self.categoryTree:AddTemplate(self.childlessCategoryTemplate, TreeHeaderSetup_Childless, TreeEntryOnSelected_Childless)
    self.categoryTree:AddTemplate(self.subCategoryTemplate, TreeEntrySetup, TreeEntryOnSelected)

    self.categoryTree:SetExclusive(true)
    self.categoryTree:SetOpenAnimation("ZO_TreeOpenAnimation")
end

function ZO_JournalProgressBook_Common:ResetFilters() 
    ZO_ComboBox_ObjectFromContainer(self.categoryFilter):SelectFirstItem()
end

--[[ Summary ]]--
-----------------
function ZO_JournalProgressBook_Common:UpdateSummary()
    -- Stub to be overridden
end

function ZO_JournalProgressBook_Common:ShowSummary()
    self.contentList:SetHidden(true)
    self.summaryInset:SetHidden(false)
    self.categoryLabel:SetText(GetString(SI_JOURNAL_PROGRESS_SUMMARY))
    self.categoryProgress:SetHidden(true)
    self.categoryFilter:SetHidden(true)
    
    self:UpdateSummary()
end

function ZO_JournalProgressBook_Common:HideSummary()
    self.contentList:SetHidden(false)
    self.summaryInset:SetHidden(true)
end

function ZO_JournalProgressBook_Common:IsSummaryOpen()
    local data = self.categoryTree:GetSelectedData()
    return data and data.summary
end

function ZO_JournalProgressBook_Common:UpdateStatusBar(statusBar, category, earned, total, numEntries, hidesUnearned, hideProgressText)
    if category then
        statusBar.category:SetModifyTextType(MODIFY_TEXT_TYPE_UPPERCASE)
        statusBar.category:SetText(category)
    end

    statusBar:SetMinMax(0, zo_max(hidesPoints and 1 or total, 1))
    statusBar:SetValue(earned)

    if hideProgressText then
        if hidesUnearned then
            if numEntries > 0 then
                statusBar.progress:SetText(numEntries)
            else
                statusBar.progress:SetHidden(true)
            end
        else
            statusBar.progress:SetText(zo_strformat(SI_JOURNAL_PROGRESS_POINTS, earned, total))
        end
    else
        statusBar.progress:SetHidden(true)
    end    

    statusBar:SetHidden(false)
end

--[[ Categories ]]--
--------------------
function ZO_JournalProgressBook_Common:GetNumCategories()
    --Stubbed for override
end

function ZO_JournalProgressBook_Common:GetCategoryInfo(categoryIndex)
    --Stubbed for override
end

function ZO_JournalProgressBook_Common:GetCategoryIcons(categoryIndex)
    --Stubbed for override
end

function ZO_JournalProgressBook_Common:GetSubCategoryInfo(categoryIndex, i)
    --Stubbed for override
end

function ZO_JournalProgressBook_Common:GetCategoryIndicesFromData(data)
    if not data.isFakedSubcategory and data.parentData then
        return data.parentData.categoryIndex, data.categoryIndex
    end
        
    return data.categoryIndex
end

function ZO_JournalProgressBook_Common:GetCategoryInfoFromData(data, parentData)
    if not data.isFakedSubcategory and parentData then
        return select(2, self:GetSubCategoryInfo(parentData.categoryIndex, data.categoryIndex))
    else
        return select(3, self:GetCategoryInfo(data.categoryIndex))
    end
end

function ZO_JournalProgressBook_Common:GetLookupNodeByCategory(categoryIndex, subcategoryIndex)
    if self.nodeLookupData then
        local node = self.nodeLookupData[categoryIndex]
        if node then
            local subNode = node.subCategories[subcategoryIndex or ZO_JOURNAL_PROGRESS_FAKED_SUBCATEGORY_INDEX]
            return subNode or node.node
        end
    end
    return nil
end

function ZO_JournalProgressBook_Common:BuildCategories()
    self.categoryTree:Reset()
    self.nodeLookupData = {}

    --Special summary blade
    self:AddTopLevelCategory(nil, GetString(SI_JOURNAL_PROGRESS_SUMMARY), 0)
    

    for i = 1, self:GetNumCategories() do
        local name, numSubCategories, _, _, _, hidesUnearned = self:GetCategoryInfo(i)
        local normalIcon, pressedIcon, mouseoverIcon = self:GetCategoryIcons(i)
        self:AddTopLevelCategory(i, name, numSubCategories, hidesUnearned, normalIcon, pressedIcon, mouseoverIcon)
    end
    
    self.categoryTree:Commit()
end

function ZO_JournalProgressBook_Common:UpdateCategoryLabels(data)
    local parentData = data.parentData
    
    if parentData then
        self.categoryLabel:SetText(zo_strformat(SI_JOURNAL_PROGRESS_CATEGORY_SUBCATEGORY, parentData.name, data.name))
    else
        self.categoryLabel:SetText(zo_strformat(SI_JOURNAL_PROGRESS_CATEGORY, data.name))
    end

    self.categoryFilter:SetHidden(false)
end

function ZO_JournalProgressBook_Common:BuildContentList(data)
    --Stubbed for override
end

function ZO_JournalProgressBook_Common:OnCategorySelected(data)
    if data.summary then
        self:ShowSummary()
    else
        self:HideSummary()
        self:UpdateCategoryLabels(data)
    end
end

function ZO_JournalProgressBook_Common:RefreshVisibleCategoryFilter()
    local data = self.categoryTree:GetSelectedData()
    if(data ~= nil) then
        self:OnCategorySelected(data)
    end
end

do
    local function AddNodeLookup(lookup, node, parent, categoryIndex)
        if(categoryIndex ~= nil) then
            local parentCategory = categoryIndex
            local subCategory

            if(parent) then
                parentCategory = parent.data.categoryIndex
                subCategory = categoryIndex
            end

            local categoryTable = lookup[parentCategory]
            
            if(categoryTable == nil) then
                categoryTable = { subCategories = {} }
                lookup[parentCategory] = categoryTable
            end

            if(subCategory) then
                categoryTable.subCategories[subCategory] = node
            else
                categoryTable.node = node
            end
        end
    end

    function ZO_JournalProgressBook_Common:AddCategory(lookup, tree, nodeTemplate, parent, categoryIndex, name, hidesUnearned, normalIcon, pressedIcon, mouseoverIcon, isSummary, isFakedSubcategory)
        local entryData = 
        {
            isFakedSubcategory = isFakedSubcategory,
            categoryIndex = categoryIndex, 
            name = name, 
            hidesUnearned = hidesUnearned,
            summary = isSummary,
            parentData = parent and parent.data or nil,
            normalIcon = normalIcon, 
            pressedIcon = pressedIcon, 
            mouseoverIcon = mouseoverIcon,
        }

        local soundId = parent and SOUNDS.JOURNAL_PROGRESS_SUB_CATEGORY_SELECTED or SOUNDS.JOURNAL_PROGRESS_CATEGORY_SELECTED
        local node = tree:AddNode(nodeTemplate, entryData, parent, soundId)
        entryData.node = node

        local finalCategoryIndex = isFakedSubcategory and ZO_JOURNAL_PROGRESS_FAKED_SUBCATEGORY_INDEX or categoryIndex
        AddNodeLookup(lookup, node, parent, finalCategoryIndex)
        return node
    end

    local SUMMARY_ICONS =
    {
        "esoui/art/treeicons/achievements_indexicon_summary_up.dds",
        "esoui/art/treeicons/achievements_indexicon_summary_down.dds",
        "esoui/art/treeicons/achievements_indexicon_summary_over.dds",
    }

    function ZO_JournalProgressBook_Common:AddTopLevelCategory(categoryIndex, name, numSubCategories, hidesUnearned, normalIcon, pressedIcon, mouseoverIcon)
        local isSummary = categoryIndex == nil
        local tree = self.categoryTree
        local lookup = self.nodeLookupData

        local nodeTemplate = self.childlessCategoryTemplate
        local hasChildren = not isSummary and (numSubCategories > 0)
        local numEntries = select(3, self:GetCategoryInfo(categoryIndex))
        if(hasChildren) then
            nodeTemplate = self.parentCategoryTemplate
        end

        if(isSummary) then
            normalIcon, pressedIcon, mouseoverIcon = unpack(SUMMARY_ICONS)
        end

        local parent = self:AddCategory(lookup, tree, nodeTemplate, nil, categoryIndex, name, hidesUnearned, normalIcon, pressedIcon, mouseoverIcon, isSummary)

        --We only want to add a general subcategory if we have any subcategories and we have any entries in the main category
        --Otherwise we'd have an emtpy general category
        if(hasChildren and numEntries > 0) then
            local isFakedSubcategory = true
            self:AddCategory(lookup, tree, self.subCategoryTemplate, parent, categoryIndex, GetString(SI_JOURNAL_PROGRESS_CATEGORY_GENERAL), hidesUnearned, normalIcon, pressedIcon, mouseoverIcon, isSummary, isFakedSubcategory)
        end
        
        for i = 1, numSubCategories do
            local subCategoryName, subCategoryEntries, _, _, hidesUnearned = self:GetSubCategoryInfo(categoryIndex, i)
            self:AddCategory(lookup, tree, self.subCategoryTemplate, parent, i, subCategoryName, hidesUnearned, normalIcon, pressedIcon, mouseoverIcon)
        end

        return parent
    end
end