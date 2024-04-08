ZO_GUILD_HISTORY_KEYBOARD_CATEGORY_TREE_WIDTH = 270
ZO_GUILD_HISTORY_KEYBOARD_ROW_HEIGHT = 60

ZO_GuildHistory_Keyboard = ZO_GuildHistory_Shared:MultiSubclass(ZO_SortFilterList)

function ZO_GuildHistory_Keyboard:Initialize(control)
    ZO_GuildHistory_Shared.Initialize(self, control)
    GUILD_HISTORY_KEYBOARD_SCENE = ZO_Scene:New("guildHistory", SCENE_MANAGER)
    GUILD_HISTORY_KEYBOARD_FRAGMENT = self:GetFragment()
end

function ZO_GuildHistory_Keyboard:OnDeferredInitialize()
    ZO_SortFilterList.Initialize(self, self.control)
    ZO_GuildHistory_Shared.OnDeferredInitialize(self)
end

function ZO_GuildHistory_Keyboard:InitializeSortFilterList(...)
    ZO_SortFilterList.InitializeSortFilterList(self, ...)
    ZO_GuildHistory_Shared.InitializeSortFilterList(self, "ZO_GuildHistoryRow_Keyboard", ZO_GUILD_HISTORY_KEYBOARD_ROW_HEIGHT)

    self:SetAlternateRowBackgrounds(true)
    self:SetAutomaticallyColorRows(false)
end

function ZO_GuildHistory_Keyboard:InitializeControls()
    ZO_GuildHistory_Shared.InitializeControls(self)

    self.footer.previousButton:SetHandler("OnClicked", function()
        self:ShowPreviousPage()
    end)
    self.footer.nextButton:SetHandler("OnClicked", function()
        self:ShowNextPage()
    end)
    self:InitializeCategoryTree()
end

function ZO_GuildHistory_Keyboard:InitializeCategoryTree()
    local DEFAULT_INDENT = 60
    local DEFAULT_SPACING = -10
    local NO_SELECTION_FUNCTION = nil
    local NO_EQUALITY_FUNCTION = nil
    local DEFAULT_CHILD_INDENT = nil
    local CHILD_SPACING = 0
    local TREE_WIDTH = ZO_GUILD_HISTORY_KEYBOARD_CATEGORY_TREE_WIDTH - ZO_SCROLL_BAR_WIDTH
    local TEXT_LABEL_MAX_WIDTH = TREE_WIDTH - ZO_TREE_ENTRY_ICON_HEADER_TEXT_OFFSET_X

    self.categoryTree = ZO_Tree:New(self.control:GetNamedChild("Categories"), DEFAULT_INDENT, DEFAULT_SPACING, TREE_WIDTH)

    local function BaseTreeHeaderIconSetup(control, data, open)
        local categoryInfo = ZO_GuildHistory_Manager.GetEventCategoryInfo(data.eventCategory)
        control.icon:SetTexture(open and categoryInfo.down or categoryInfo.up)
        control.iconHighlight:SetTexture(categoryInfo.over)

        ZO_IconHeader_Setup(control, open)
    end

    local function BaseTreeHeaderSetup(control, data, open)
        control.text:SetDimensionConstraints(0, 0, TEXT_LABEL_MAX_WIDTH, 0)
        control.text:SetModifyTextType(MODIFY_TEXT_TYPE_UPPERCASE)
        control.text:SetText(GetString("SI_GUILDHISTORYEVENTCATEGORY", data.eventCategory))
        BaseTreeHeaderIconSetup(control, data, open)
    end

    local function TreeEntrySelected(control, data, selected, reselectingDuringRebuild)
        control:SetSelected(selected)
        if selected then
            self:SetSelectedEventCategory(data.eventCategory, data.subcategoryIndex)
        end
    end
    
    local function TreeEntrySelected_Childless(control, data, selected, reselectingDuringRebuild)
        TreeEntrySelected(control, data, selected, reselectingDuringRebuild)
        BaseTreeHeaderIconSetup(control, data, selected)
    end

    -- Childless Category Header
    local function CategoryHeaderSetup_Childless(node, control, data, open)
        BaseTreeHeaderSetup(control, data, open)
    end

    local function EqualityFunc(left, right)
        return left.eventCategory == right.eventCategory and left.subcategoryIndex == right.subcategoryIndex
    end

    self.categoryTree:AddTemplate("ZO_IconChildlessHeader", CategoryHeaderSetup_Childless, TreeEntrySelected_Childless, EqualityFunc, DEFAULT_CHILD_INDENT, CHILD_SPACING)

    -- Parent Category Header
    local function CategoryHeaderSetup_Parent(node, control, data, open, userRequested)
        BaseTreeHeaderSetup(control, data, open)

        if open and userRequested then
            self.categoryTree:SelectFirstChild(node)
        end
    end

    self.categoryTree:AddTemplate("ZO_IconHeader", CategoryHeaderSetup_Parent, NO_SELECTION_FUNCTION, EqualityFunc, DEFAULT_CHILD_INDENT, CHILD_SPACING)

    --Subcategory Entry
    local function SubcategoryEntrySetup(node, control, data, open)
        control:SetSelected(false)
        control:SetText(data.name)
    end

    self.categoryTree:AddTemplate("ZO_GuildHistorySubcategoryEntry", SubcategoryEntrySetup, TreeEntrySelected, EqualityFunc)

    --Build Tree
    for eventCategory = GUILD_HISTORY_EVENT_CATEGORY_ITERATION_BEGIN, GUILD_HISTORY_EVENT_CATEGORY_ITERATION_END do
        local categoryInfo = ZO_GuildHistory_Manager.GetEventCategoryInfo(eventCategory)
        if categoryInfo then
            local categoryData = { eventCategory = eventCategory }
            if #categoryInfo.subcategories > 1 then
                local categoryNode = self.categoryTree:AddNode("ZO_IconHeader", categoryData)

                for subcategoryIndex, subcategoryInfo in ipairs(categoryInfo.subcategories) do
                    local name = GetString("SI_GUILDHISTORYEVENTSUBCATEGORY", subcategoryInfo.subcategoryType)
                    local subcategoryData = { name = name, eventCategory = eventCategory, subcategoryIndex = subcategoryIndex }
                    self.categoryTree:AddNode("ZO_GuildHistorySubcategoryEntry", subcategoryData, categoryNode)
                end
            else
                -- Don't show a subcategory when there's only the one
                assert(#categoryInfo.subcategories == 1)
                categoryData.subcategoryIndex = 1
                self.categoryTree:AddNode("ZO_IconChildlessHeader", categoryData)
            end
        end
    end

    self.categoryTree:SetExclusive(true)
    self.categoryTree:SetOpenAnimation("ZO_TreeOpenAnimation")
    self.categoryTree:Commit()
end

function ZO_GuildHistory_Keyboard:InitializeKeybindDescriptors()
    self:SetKeybindStripDescriptor(
    {
        alignment = KEYBIND_STRIP_ALIGN_RIGHT,

        -- Show More
        {
            name = GetString(SI_GUILD_HISTORY_SHOW_MORE),
            keybind = "UI_SHORTCUT_PRIMARY",
            visible = function()
                return self:CanShowMore()
            end,
            callback = function()
                self:TryShowMore()
            end,
        },
    })
end

function ZO_GuildHistory_Keyboard:OnShowing()
    ZO_GuildHistory_Shared.OnShowing(self)

    self:AddKeybinds()
end

function ZO_GuildHistory_Keyboard:SelectNodeForEventCategory(eventCategory, subcategoryIndex, suppressAutoRequest)
    local node = self.categoryTree:GetTreeNodeByData({ eventCategory = eventCategory, subcategoryIndex = subcategoryIndex or 1 })
    if node then
        local wasAutoRequestEnabled = self.autoRequestEnabled
        self.autoRequestEnabled = self.autoRequestEnabled and not suppressAutoRequest

        self.categoryTree:SelectNode(node)

        self.autoRequestEnabled = wasAutoRequestEnabled
    end
end

-- Helper function to allow switching to a guild without triggering an auto request
function ZO_GuildHistory_Keyboard:SwapToGuildIndexWithoutAutoRequest(guildIndex)
    local wasAutoRequestEnabled = self.autoRequestEnabled
    self.autoRequestEnabled = false

    GUILD_SELECTOR:SelectGuildByIndex(guildIndex)

    self.autoRequestEnabled = wasAutoRequestEnabled
end

-- Called from the GUILD_SELECTOR that controls which guild is currently selected for all guild screens
function ZO_GuildHistory_Keyboard:SetGuildId(guildId)
    if ZO_GuildHistory_Shared.SetGuildId(self, guildId) then
        self:UpdateKeybinds()
    end
end

function ZO_GuildHistory_Keyboard:ResetToTop()
    ZO_ScrollList_ResetToTop(self.list)
end
    
do
    local function SetButtonStateEnabled(button, enabled)
        if enabled then
            button:SetState(BSTATE_NORMAL, false)
        else
            button:SetState(BSTATE_DISABLED, true)
        end
    end

    function ZO_GuildHistory_Keyboard:FilterScrollList()
        ZO_GuildHistory_Shared.FilterScrollList(self)

        local enablePrevious = self.currentPage > 1
        local enableNext = self.hasNextPage
        SetButtonStateEnabled(self.footer.previousButton, enablePrevious)
        SetButtonStateEnabled(self.footer.nextButton, enableNext)
        self.footer:SetHidden(not (enablePrevious or enableNext))

        self:UpdateKeybinds()
    end
end

function ZO_GuildHistory_Keyboard:SetupEventRow(control, eventData)
    ZO_SortFilterList.SetupRowBG(self, control, eventData)

    local IS_KEYBOARD = false
    ZO_GuildHistory_Shared.SetupEventRow(self, control, eventData, IS_KEYBOARD)
end

function ZO_GuildHistory_Keyboard:SetShowLoadingSpinner(showLoadingSpinner)
    if showLoadingSpinner then
        self.loadingIcon:Show()
    else
        self.loadingIcon:Hide()
    end
end

function ZO_GuildHistory_Keyboard.OnControlInitialized(control)
    GUILD_HISTORY_KEYBOARD = ZO_GuildHistory_Keyboard:New(control)
end