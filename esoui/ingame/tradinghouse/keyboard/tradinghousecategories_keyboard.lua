ZO_TradingHouseSearchCategoryFeature_Keyboard = ZO_TradingHouseSearchCategoryFeature_Shared:Subclass()

function ZO_TradingHouseSearchCategoryFeature_Keyboard:New(...)
    return ZO_TradingHouseSearchCategoryFeature_Shared.New(self, ...)
end

function ZO_TradingHouseSearchCategoryFeature_Keyboard:AttachToControl(categoryControl, subcategoryControl, featuresParentControl)
    self:InitializeFeatures(featuresParentControl)
    self:InitializeSubcategoryTabs(subcategoryControl)
    self:InitializeCategoryList(categoryControl)
    self:PopulateCategoryList()
end

function ZO_TradingHouseSearchCategoryFeature_Keyboard:InitializeFeatures(featuresParentControl)
    self.featureKeyToFeatureObjectMap = {}
    for _, categoryParams in ipairs(ZO_TRADING_HOUSE_CATEGORY_PARAMS_LIST) do
        for _, featureKey in categoryParams:FeatureKeyIterator() do
            if self.featureKeyToFeatureObjectMap[featureKey] == nil then
                local feature = ZO_TradingHouse_CreateKeyboardFeature(featureKey)
                feature:CreateControl(featuresParentControl)
                self.featureKeyToFeatureObjectMap[featureKey] = feature
            end
        end
    end
end

function ZO_TradingHouseSearchCategoryFeature_Keyboard:InitializeSubcategoryTabs(subcategoryControl)
    self.tabs = subcategoryControl
    self.activeTabLabel = subcategoryControl:GetNamedChild("Active")
    self.currentTabDescriptor = nil
end

function ZO_TradingHouseSearchCategoryFeature_Keyboard:InitializeCategoryList(container)
    local SHARED_INDENT = 55
    local HEADER_SPACING = -10
    local CATEGORY_SPACING = 0

    self.categoryListTree = ZO_Tree:New(container:GetNamedChild("ScrollChild"), SHARED_INDENT, HEADER_SPACING, container:GetWidth())
    self.categoryListTree:SetExclusive(true)
    self.categoryListTree:SetOpenAnimation("ZO_TreeOpenAnimation")

    -- Template helpers
    local function SelectCategoryParams(control, categoryParams, selected, reselectingDuringRebuild)
        local oldCategoryParams = self.selectedCategoryParams
        control:SetSelected(selected)
        self.selectedCategoryParams = categoryParams
        if selected and not reselectingDuringRebuild then
            self:OnCategorySelected(categoryParams, oldCategoryParams)
        end
    end

    -- Search Header Data
    local function SetupIconHeader(control, header, open)
        control.text:SetModifyTextType(MODIFY_TEXT_TYPE_UPPERCASE)
        control.text:SetText(GetString("SI_TRADINGHOUSECATEGORYHEADER", header))

        local icons = internalassert(ZO_ItemFilterUtils.GetTradingHouseCategoryHeaderIcons(header), string.format("missing icon for header(%d)", header))
        control.icon:SetTexture(open and icons.down or icons.up)
        control.iconHighlight:SetTexture(icons.over)
        ZO_IconHeader_Setup(control, open)
    end

    -- Top-level header. Used to group categories
    local function TreeHeaderSetup(node, control, header, open, userRequested)
        SetupIconHeader(control, header, open)

        if open and userRequested then
            self.categoryListTree:SelectFirstChild(node)
        end
    end

    local NO_SELECTION_FUNCTION, NO_EQUALITY_FUNCTION = nil, nil
    self.categoryListTree:AddTemplate("ZO_IconHeader", TreeHeaderSetup, NO_SELECTION_FUNCTION, NO_EQUALITY_FUNCTION, SHARED_INDENT, CATEGORY_SPACING)

    -- Category. Represents a specific categoryParams object.
    local function TreeCategorySetup(node, control, categoryParams, open)
        control:SetText(categoryParams:GetFormattedName())
    end

    local function TreeCategoryOnSelected(control, categoryParams, selected, reselectingDuringRebuild)
        SelectCategoryParams(control, categoryParams, selected, reselectingDuringRebuild)
    end

    self.categoryListTree:AddTemplate("ZO_TradingHouse_CategoryLabel", TreeCategorySetup, TreeCategoryOnSelected)

    -- Childless header. Used when a header has only one category, and behaves like a category.
    local function ChildlessTreeHeaderSetup(node, control, categoryParams, open, userRequested)
        SetupIconHeader(control, categoryParams:GetHeader(), open)
    end

    local function ChildlessTreeHeaderOnSelected(control, categoryParams, selected, reselectingDuringRebuild)
        SetupIconHeader(control, categoryParams:GetHeader(), selected)
        SelectCategoryParams(control, categoryParams, selected, reselectingDuringRebuild)
    end

    self.categoryListTree:AddTemplate("ZO_IconChildlessHeader", ChildlessTreeHeaderSetup, ChildlessTreeHeaderOnSelected)
end

function ZO_TradingHouseSearchCategoryFeature_Keyboard:PopulateCategoryList()
    self.categoryListTree:Reset()

    local numCategoriesForHeader = {}
    for _, categoryParams in ipairs(ZO_TRADING_HOUSE_CATEGORY_PARAMS_LIST) do
        local header = categoryParams:GetHeader()
        numCategoriesForHeader[header] = (numCategoriesForHeader[header] or 0) + 1
    end

    local NO_PARENT = nil
    local currentHeaderNode, lastHeader = nil, nil
    for _, categoryParams in ipairs(ZO_TRADING_HOUSE_CATEGORY_PARAMS_LIST) do
        local header = categoryParams:GetHeader()
        if numCategoriesForHeader[header] == 1 then
            self.categoryListTree:AddNode("ZO_IconChildlessHeader", categoryParams)
        else
            if lastHeader ~= header then
                currentHeaderNode = self.categoryListTree:AddNode("ZO_IconHeader", header)
            end

            self.categoryListTree:AddNode("ZO_TradingHouse_CategoryLabel", categoryParams, currentHeaderNode)
        end
        lastHeader = header
    end
    self.categoryListTree:Commit()
end

function ZO_TradingHouseSearchCategoryFeature_Keyboard:PopulateSubcategoryTabs(categoryParams, oldSubcategoryKey)
    local function OnTabSelected(tabData)
        self.activeTabLabel:SetText(tabData.activeTabText)
        self.selectedSubcategoryKey = tabData.descriptor
        TRADING_HOUSE_SEARCH:HandleSearchCriteriaChanged(self)
    end

    local nextSubcategoryKey = "AllSubcategories"
    ZO_MenuBar_ClearButtons(self.tabs)
    -- Menubars expect buttons to be added from right to left
    for subcategoryIndex = categoryParams:GetNumSubcategories(), 1, -1 do
        local key = categoryParams:GetSubcategoryKey(subcategoryIndex)
        local name = categoryParams:GetSubcategoryName(subcategoryIndex)
        local icons = categoryParams:GetSubcategoryIcons(subcategoryIndex)

        if key == "AllSubcategories" then
            -- Gamepad needs more descriptive names, but we want a generic "all" menu option across category types.
            name = GetString(SI_TRADING_HOUSE_BROWSE_ITEM_TYPE_ALL)
        end

        local tabData =
        {
            activeTabText = name,
            tooltipText = name,

            descriptor = key,
            normal = icons.up,
            pressed = icons.down,
            highlight = icons.over,
            disabled = icons.disabled,
            visible = nil,
            callback = OnTabSelected,
        }
        ZO_MenuBar_AddButton(self.tabs, tabData)

        if key == oldSubcategoryKey then
            nextSubcategoryKey = key
        end
    end

    ZO_MenuBar_SelectDescriptor(self.tabs, nextSubcategoryKey)
end

function ZO_TradingHouseSearchCategoryFeature_Keyboard:OnCategorySelected(categoryParams, oldCategoryParams)
    local oldSubcategoryKey = nil 
    local oldFeatureSet = {}

    if oldCategoryParams then
        for _, featureKey in oldCategoryParams:FeatureKeyIterator() do
            local feature = self:GetFeatureForKey(featureKey)
            feature:Hide()
            oldFeatureSet[featureKey] = true
        end
        oldSubcategoryKey = self.selectedSubcategoryKey
    end

    self:PopulateSubcategoryTabs(categoryParams, oldSubcategoryKey)

    local lastControl = nil
    -- We parent from right to left
    for _, featureKey in categoryParams:FeatureKeyReverseIterator() do
        local feature = self:GetFeatureForKey(featureKey)
        feature:Show()
        -- We should reset state unless this feature was previously visible, in which case that state is probably still good
        if not oldFeatureSet[featureKey] then
            feature:ResetSearch()
        end

        local control = feature:GetControl()
        if not lastControl then
            control:SetAnchor(TOPRIGHT, nil, TOPRIGHT, -5, 9)
        else
            control:SetAnchor(TOPRIGHT, lastControl, TOPLEFT, -5, 0)
        end
        lastControl = control
    end

    if oldCategoryParams ~= categoryParams then
        TRADING_HOUSE_SEARCH:HandleSearchCriteriaChanged(self)
    end
end

-- Override
function ZO_TradingHouseSearchCategoryFeature_Keyboard:SelectCategoryParams(categoryParams, subcategoryKey)
    if categoryParams then
        local node = self.categoryListTree:GetTreeNodeByData(categoryParams)
        self.categoryListTree:SelectNode(node)

        if subcategoryKey then
            ZO_MenuBar_SelectDescriptor(self.tabs, subcategoryKey)
        end
    end
end

-- Override
function ZO_TradingHouseSearchCategoryFeature_Keyboard:GetCategoryParams()
    return self.selectedCategoryParams
end

-- Override
function ZO_TradingHouseSearchCategoryFeature_Keyboard:GetSubcategoryKey()
    return self.selectedSubcategoryKey
end

-- Override
function ZO_TradingHouseSearchCategoryFeature_Keyboard:GetFeatureForKey(featureKey)
    return self.featureKeyToFeatureObjectMap[featureKey]
end
