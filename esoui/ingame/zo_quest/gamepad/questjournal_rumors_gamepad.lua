local CATEGORY_TYPE_ACTIVE = "active"
local CATEGORY_TYPE_COMPLETE = "complete"

local MODE =
{
    RUMOR_CATEGORIES = "Categories",
    RUMOR_TYPES = "RumorTypes",
    RUMORS = "Rumors",
    CLUES = "Clues",
}

ZO_QuestJournal_Rumors_Gamepad = ZO_Gamepad_ParametricList_Screen:Subclass()

function ZO_QuestJournal_Rumors_Gamepad:Initialize(control, owner)
    self.owner = owner

    local DONT_ACTIVATE_ON_SHOW = false -- we'll manually set our list
    ZO_Gamepad_ParametricList_Screen.Initialize(self, control, ZO_GAMEPAD_HEADER_TABBAR_CREATE, DONT_ACTIVATE_ON_SHOW)

    self:GetHeaderFragment():SetAlwaysAnimate(false)

    local ALWAYS_ANIMATE = true
    self.fragment = ZO_FadeSceneFragment:New(control, ALWAYS_ANIMATE)
    self:SetParentFragment(self.fragment)
    QUEST_JOURNAL_RUMORS_FRAGMENT_GAMEPAD = self.fragment

    self.fragmentGroup =
    {
        self.fragment,
    }

    local tabBarEntries = self.owner:GetTabBarEntries()
    self.headerData =
    {
        tabBarEntries = tabBarEntries,
        titleText = GetString(SI_QUEST_JOURNAL_RUMORS_MODE),
        data1HeaderText = GetString(SI_GAMEPAD_QUEST_JOURNAL_RUMORS_CURRENT_MAX_LABEL),
        data1Text = function() return zo_strformat(SI_GAMEPAD_QUEST_JOURNAL_RUMORS_CURRENT_MAX, GetNumPendingRumors(), GetMaxPendingRumors()) end,
    }
end

function ZO_QuestJournal_Rumors_Gamepad:RegisterForEvents()
    local function Update()
        self:Update()
    end
    RUMOR_MANAGER:RegisterCallback("SingleRumorUpdated", Update)
    RUMOR_MANAGER:RegisterCallback("RumorsUpdated", Update)
end

function ZO_QuestJournal_Rumors_Gamepad:InitializeKeybindStripDescriptors()
    self.rumorCategoryKeybindStripDescriptor =
    {
        alignment = KEYBIND_STRIP_ALIGN_LEFT,

        -- Select
        {
            name = GetString(SI_GAMEPAD_SELECT_OPTION),
            keybind = "UI_SHORTCUT_PRIMARY",

            callback = function()
                self:SetMode(MODE.RUMOR_TYPES)
            end,
        },
    }

    ZO_Gamepad_AddBackNavigationKeybindDescriptors(self.rumorCategoryKeybindStripDescriptor, GAME_NAVIGATION_TYPE_BUTTON)

    self.rumorTypeKeybindStripDescriptor =
    {
        alignment = KEYBIND_STRIP_ALIGN_LEFT,

        -- Select
        {
            name = GetString(SI_GAMEPAD_SELECT_OPTION),
            keybind = "UI_SHORTCUT_PRIMARY",

            callback = function()
                self:SetMode(MODE.RUMORS)
            end,
        },
    }

    local function RumorTypeBackFunction()
        self:SetMode(MODE.RUMOR_CATEGORIES)
    end
    ZO_Gamepad_AddBackNavigationKeybindDescriptors(self.rumorTypeKeybindStripDescriptor, GAME_NAVIGATION_TYPE_BUTTON, RumorTypeBackFunction)

    self.rumorKeybindStripDescriptor =
    {
        alignment = KEYBIND_STRIP_ALIGN_LEFT,

        {
            name = GetString(SI_QUEST_JOURNAL_RUMORS_VIEW_CLUES_ACTION),
            keybind = "UI_SHORTCUT_PRIMARY",
            callback = function()
                self:SetMode(MODE.CLUES)
            end,
            visible = function()
                local selectedRumorData = self:GetSelectedRumorData()
                if selectedRumorData then
                    return selectedRumorData:IsPending()
                end
                return false
            end
        },

        {
            name = GetString(SI_QUEST_JOURNAL_RUMORS_ABANDON_ACTION),
            keybind = "UI_SHORTCUT_QUATERNARY",
            callback = function()
                local selectedRumorData = self:GetSelectedRumorData()
                local rumorId = selectedRumorData:GetId()
                RUMOR_MANAGER:ConfirmAbandonRumor(rumorId)
            end,
            visible = function()
                local selectedRumorData = self:GetSelectedRumorData()
                if selectedRumorData then
                    return selectedRumorData:IsPending()
                end
                return false
            end
        },
    }

    local function RumorBackFunction()
        self:SetMode(MODE.RUMOR_TYPES)
    end
    ZO_Gamepad_AddBackNavigationKeybindDescriptors(self.rumorKeybindStripDescriptor, GAME_NAVIGATION_TYPE_BUTTON, RumorBackFunction)

    self.cluesKeybindStripDescriptor =
    {
        alignment = KEYBIND_STRIP_ALIGN_LEFT,

        {
            name = GetString(SI_QUEST_JOURNAL_RUMORS_READ_BOOK_ACTION),
            keybind = "UI_SHORTCUT_PRIMARY",
            callback = function()
                local selectedClue = self.clueList:GetTargetData()
                local clueBookId = selectedClue.rumorData:GetHintBook(selectedClue.clueIndex)
                local categoryIndex, collectionIndex, bookIndex = GetLoreBookIndicesFromBookId(clueBookId)
                ZO_LoreLibrary_ReadBook(categoryIndex, collectionIndex, bookIndex)
            end,
            visible = function()
                local selectedClue = self.clueList:GetTargetData()
                if selectedClue then
                    local clueBookId = selectedClue.rumorData:GetHintBook(selectedClue.clueIndex)
                    return clueBookId > 0
                end
                return false
            end
        },
    }

    local function CluesBackFunction()
        self:SetMode(MODE.RUMORS)
    end
    ZO_Gamepad_AddBackNavigationKeybindDescriptors(self.cluesKeybindStripDescriptor, GAME_NAVIGATION_TYPE_BUTTON, CluesBackFunction)
end

function ZO_QuestJournal_Rumors_Gamepad:RemoveKeybinds()
    if self.keybindStripDescriptor then
        KEYBIND_STRIP:RemoveKeybindButtonGroup(self.keybindStripDescriptor)
    end
end

function ZO_QuestJournal_Rumors_Gamepad:AddKeybinds()
    if self.keybindStripDescriptor then
        KEYBIND_STRIP:AddKeybindButtonGroup(self.keybindStripDescriptor)
    end
end

function ZO_QuestJournal_Rumors_Gamepad:SetActiveKeybinds(keybindDescriptor)
    self:RemoveKeybinds()

    self.keybindStripDescriptor = keybindDescriptor

    self:AddKeybinds()
end

function ZO_QuestJournal_Rumors_Gamepad:GetFragmentGroup()
    return self.fragmentGroup
end

function ZO_QuestJournal_Rumors_Gamepad:UpdateHeader()
    local tabBarEntries = self.owner:GetTabBarEntries()
    self.headerData.tabBarEntries = tabBarEntries
    local BLOCK_CALLBACKS = true
    ZO_GamepadGenericHeader_Refresh(self.header, self.headerData, BLOCK_CALLBACKS)
end

function ZO_QuestJournal_Rumors_Gamepad:BuildRumorCategoryList()
    self.rumorCategoryList:Clear()

    local activeCategoryString = GetString(SI_QUEST_JOURNAL_RUMORS_ACTIVE_CATEGORY)
    local activeCategoryEntry = ZO_GamepadEntryData:New(activeCategoryString)
    activeCategoryEntry.categoryType = CATEGORY_TYPE_ACTIVE
    self.rumorCategoryList:AddEntry("ZO_GamepadMenuEntryTemplate", activeCategoryEntry)

    if GetNumCompleteRumors() > 0 then
        local completedCategoryString = GetString(SI_QUEST_JOURNAL_RUMORS_COMPLETED_CATEGORY)
        local completedCategoryEntry = ZO_GamepadEntryData:New(completedCategoryString)
        completedCategoryEntry.categoryType = CATEGORY_TYPE_COMPLETE
        self.rumorCategoryList:AddEntry("ZO_GamepadMenuEntryTemplate", completedCategoryEntry)
    end

    self.rumorCategoryList:Commit()
end

function ZO_QuestJournal_Rumors_Gamepad:BuildRumorTypeList()
    self.rumorTypeList:Clear()

    for rumorType = RUMOR_TYPE_ITERATION_BEGIN, RUMOR_TYPE_ITERATION_END do
        local shouldAddType = true
        if self:GetSelectedRumorCategory() == CATEGORY_TYPE_COMPLETE then
            shouldAddType = RUMOR_MANAGER:DoesRumorTypeHaveMatchingRumor(rumorType, {ZO_RumorData.IsComplete})
        end
        if shouldAddType then
            local rumorTypeName = GetString("SI_RUMORTYPE_JOURNALCATEGORY", rumorType)
            local rumorTypeEntry = ZO_GamepadEntryData:New(rumorTypeName)
            rumorTypeEntry.rumorType = rumorType
            self.rumorTypeList:AddEntry("ZO_GamepadMenuEntryTemplate", rumorTypeEntry)
        end
    end

    self.rumorTypeList:Commit()
end

do
    local function GetRumorEntryNarrationText(entryData, entryControl)
        local narrations = {}
        ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(entryData.text))
        ZO_AppendNarration(narrations, ZO_GetSharedGamepadEntrySubLabelNarrationText(entryData, entryControl))
        ZO_AppendNarration(narrations, ZO_QUEST_JOURNAL_RUMORS_GAMEPAD:GetRumorDetailsNarrationText())
        return narrations
    end

    function ZO_QuestJournal_Rumors_Gamepad:BuildRumorList()
        self.rumorList:Clear()

        local rumorType = self:GetSelectedRumorType()

        local rumorCategoryString = ZO_SELECTED_TEXT:Colorize(GetString("SI_RUMORTYPE_JOURNALCATEGORY", rumorType))
        local emptyText = zo_strformat(SI_QUEST_JOURNAL_RUMORS_NO_PENDING_RUMORS, rumorCategoryString)
        self.rumorList:SetNoItemText(emptyText)

        local rumors
        if self:GetSelectedRumorCategory() == CATEGORY_TYPE_ACTIVE then
            rumors = RUMOR_MANAGER:GetActiveRumorListForRumorType(rumorType)
        else -- CATEGORY_TYPE_COMPLETE
            rumors = RUMOR_MANAGER:GetCompletedRumorListForRumorType(rumorType)
        end

        for index, rumorData in ipairs(rumors) do
            local rumorName = rumorData:GetFormattedDisplayName()
            local rumorEntry = ZO_GamepadEntryData:New(rumorName)
            rumorEntry.rumorData = rumorData
            rumorEntry.narrationText = GetRumorEntryNarrationText
            self.rumorList:AddEntry("ZO_GamepadMenuEntryTemplate", rumorEntry)
        end

        self.rumorList:Commit()
    end
end

function ZO_QuestJournal_Rumors_Gamepad:BuildClueList()
    self.clueList:Clear()

    local rumorData = self:GetSelectedRumorData()
    local numClues = rumorData:GetNumHints()
    for clueIndex = 1, numClues do
        if rumorData:HasDiscoveredHint(clueIndex) then
            local clueIcon = rumorData:GetHintIcon(clueIndex)
            local clueName = rumorData:GetHintDisplayName(clueIndex)
            local clueEntry = ZO_GamepadEntryData:New(clueName, clueIcon)
            clueEntry.rumorData = rumorData
            clueEntry.clueIndex = clueIndex
            local clueBookId = rumorData:GetHintBook(clueIndex)
            clueEntry.hasBook = clueBookId > 0
            self.clueList:AddEntry("ZO_GamepadNewMenuEntryTemplate", clueEntry)
        end
    end

    self.clueList:Commit()
end

-- Start ZO_Gamepad_ParametricList_Screen overrides

function ZO_QuestJournal_Rumors_Gamepad:OnDeferredInitialize()
    self.rumorCategoryList = self:GetMainList()
    self.rumorTypeList = self:AddList("RumorTypes")
    self.rumorList = self:AddList("Rumors")

    self.clueList = self:AddList("Clues")
    self.clueList:AddDataTemplate("ZO_GamepadNewMenuEntryTemplate", ZO_SharedGamepadEntry_OnSetup, ZO_GamepadMenuEntryTemplateParametricListFunction)
    self.clueList:AddDataTemplateWithHeader("ZO_GamepadNewMenuEntryTemplate", ZO_SharedGamepadEntry_OnSetup, ZO_GamepadMenuEntryTemplateParametricListFunction, nil, "ZO_GamepadMenuEntryHeaderTemplate")

    -- Middle Pane
    self.middlePane = self.control:GetNamedChild("MiddlePane")
    local middlePaneContainer = self.middlePane:GetNamedChild("Container")

    self.contentHeader = middlePaneContainer.header
    ZO_GamepadGenericHeader_Initialize(self.contentHeader, ZO_GAMEPAD_HEADER_TABBAR_DONT_CREATE, ZO_GAMEPAD_HEADER_LAYOUTS.CONTENT_HEADER_DATA_PAIRS_LINKED)
    self.contentHeaderData =
    {
        titleText = function()
            local rumorData = self:GetSelectedRumorData()
            if rumorData then
                return rumorData:GetFormattedDisplayName()
            end
        end,
    }

    local middlePaneContent = middlePaneContainer:GetNamedChild("Content")
    self.rumorInfoContainer = middlePaneContent:GetNamedChild("RumorInfoContainer")

    self.rumorInfoContainerScroll = self.rumorInfoContainer:GetNamedChild("Scroll")
    local rumorInfoContainerScrollChild = self.rumorInfoContainerScroll:GetNamedChild("Child")
    self.rumorBackgroundTitlelabel = rumorInfoContainerScrollChild:GetNamedChild("BGTitle")
    self.rumorBackgroundTextlabel = rumorInfoContainerScrollChild:GetNamedChild("BGText")
    self.rumorOutcomeTitlelabel = rumorInfoContainerScrollChild:GetNamedChild("OutcomeTitle")
    self.rumorOutcomeTextlabel = rumorInfoContainerScrollChild:GetNamedChild("OutcomeText")

    self.middlePaneFragment = ZO_FadeSceneFragment:New(self.middlePane)

    self.rumorInfoFragmentGroup =
    {
        GAMEPAD_NAV_QUADRANT_2_3_BACKGROUND_FRAGMENT,
        self.middlePaneFragment,
    }

    self:SetMode(MODE.RUMOR_CATEGORIES)

    self:RegisterForEvents()
end

function ZO_QuestJournal_Rumors_Gamepad:PerformUpdate()
    self.dirty = false

    local mode = self.mode
    if mode == MODE.RUMOR_CATEGORIES then
        self:BuildRumorCategoryList()
    elseif mode == MODE.RUMOR_TYPES then
        self:BuildRumorTypeList()
    elseif mode == MODE.RUMORS then
        self:BuildRumorList()
    else -- MODE.CLUES
        self:BuildClueList()
    end

    self:UpdateHeader()
    self:UpdateTooltips()
    self:RefreshRumorDetails()
end

function ZO_QuestJournal_Rumors_Gamepad:OnShowing()
    ZO_Gamepad_ParametricList_Screen.OnShowing(self)

    local mode = MODE.RUMOR_CATEGORIES
    if SCENE_MANAGER:GetPreviousSceneName() == "loreReaderCustomGamepad" then
        mode = MODE.CLUES
    end

    -- we need to set our mode in order to make sure we set and activate our list
    self:SetMode(mode)

    local DEFAULT_ALLOW_IF_DISABLED = nil
    local BLOCK_CALLBACKS = true
    ZO_GamepadGenericHeader_SetActiveTabIndex(self.header, self.owner:GetMode(), DEFAULT_ALLOW_IF_DISABLED, BLOCK_CALLBACKS)
    ZO_GamepadGenericHeader_Activate(self.header)
end

function ZO_QuestJournal_Rumors_Gamepad:OnHiding()
    ZO_GamepadGenericHeader_Deactivate(self.header)
end

function ZO_QuestJournal_Rumors_Gamepad:OnSelectionChanged(list, selectedData, oldSelectedData)
    ZO_Gamepad_ParametricList_Screen.OnSelectionChanged(self, list, selectedData, oldSelectedData)

    self:UpdateTooltips()
    self:RefreshRumorDetails()
end

-- End ZO_Gamepad_ParametricList_Screen overrides

function ZO_QuestJournal_Rumors_Gamepad:SetMode(mode)
    self.mode = mode
    if mode == MODE.RUMOR_CATEGORIES then
        self:SetCurrentList(self.rumorCategoryList)
        self:SetActiveKeybinds(self.rumorCategoryKeybindStripDescriptor)
    elseif mode == MODE.RUMOR_TYPES then
        self:SetCurrentList(self.rumorTypeList)
        self:SetActiveKeybinds(self.rumorTypeKeybindStripDescriptor)
    elseif mode == MODE.RUMORS then
        self:SetCurrentList(self.rumorList)
        self:SetActiveKeybinds(self.rumorKeybindStripDescriptor)
    else -- MODE.CLUES
        self:SetCurrentList(self.clueList)
        self:SetActiveKeybinds(self.cluesKeybindStripDescriptor)
    end

    self:Update()
end

function ZO_QuestJournal_Rumors_Gamepad:GetSelectedRumorCategory()
    local selectedCategory = self.rumorCategoryList:GetTargetData()
    return selectedCategory.categoryType
end

function ZO_QuestJournal_Rumors_Gamepad:GetSelectedRumorType()
    local selectedType = self.rumorTypeList:GetTargetData()
    return selectedType.rumorType
end

function ZO_QuestJournal_Rumors_Gamepad:GetSelectedRumorData()
    local selectedRumor = self.rumorList:GetTargetData()
    if selectedRumor then
        return selectedRumor.rumorData
    end

    return nil
end

function ZO_QuestJournal_Rumors_Gamepad:UpdateTooltips()
    GAMEPAD_TOOLTIPS:ClearTooltip(GAMEPAD_LEFT_TOOLTIP)
    GAMEPAD_TOOLTIPS:ClearTooltip(GAMEPAD_RIGHT_TOOLTIP)

    if self.mode == MODE.RUMOR_CATEGORIES then
        GAMEPAD_TOOLTIPS:LayoutTextBlockTooltip(GAMEPAD_LEFT_TOOLTIP, GetString(SI_QUEST_JOURNAL_RUMORS_ACTIVE_RUMORS_DESCRIPTION))
    elseif self.mode == MODE.RUMOR_TYPES then
        if self:GetSelectedRumorCategory() == CATEGORY_TYPE_ACTIVE then
            GAMEPAD_TOOLTIPS:LayoutTextBlockTooltip(GAMEPAD_LEFT_TOOLTIP, GetString(SI_QUEST_JOURNAL_RUMORS_ACTIVE_RUMORS_DESCRIPTION))
        end
    elseif self.mode == MODE.RUMORS then
        local rumorData = self:GetSelectedRumorData()

        if rumorData then
            if rumorData:IsNotStarted() then
                local starterHint = rumorData:GetStarterHint()
                if starterHint ~= "" then
                    GAMEPAD_TOOLTIPS:LayoutTextBlockTooltip(GAMEPAD_LEFT_TOOLTIP, starterHint)
                end
            elseif rumorData:IsPending() then
                GAMEPAD_TOOLTIPS:LayoutRumorClues(GAMEPAD_RIGHT_TOOLTIP, rumorData)
            end
        end
    else -- MODE.CLUES
        local selectedClue = self.clueList:GetTargetData()
        if selectedClue then
            GAMEPAD_TOOLTIPS:LayoutRumorClue(GAMEPAD_RIGHT_TOOLTIP, selectedClue.rumorData, selectedClue.clueIndex)
        end
    end
end

function ZO_QuestJournal_Rumors_Gamepad:RefreshRumorDetails()
    local rumorData = self:GetSelectedRumorData()
    if not rumorData or rumorData:IsNotStarted() or (self.mode ~= MODE.RUMORS and self.mode ~= MODE.CLUES) then
        SCENE_MANAGER:RemoveFragmentGroup(self.rumorInfoFragmentGroup)
        return
    end

    SCENE_MANAGER:AddFragmentGroup(self.rumorInfoFragmentGroup)

    ZO_GamepadGenericHeader_Refresh(self.contentHeader, self.contentHeaderData)

    local isRumorPending = rumorData:IsPending()
    self.rumorOutcomeTitlelabel:SetHidden(isRumorPending)
    self.rumorOutcomeTextlabel:SetHidden(isRumorPending)

    self.rumorBackgroundTitlelabel:ClearAnchors()
    if isRumorPending then
        self.rumorBackgroundTitlelabel:SetAnchor(TOPLEFT)
        self.rumorBackgroundTitlelabel:SetAnchor(TOPRIGHT, self.rumorInfoContainerScroll, TOPRIGHT, 0, 0, ANCHOR_CONSTRAINS_X)
        self.rumorOutcomeTextlabel:SetText("")
    else
        self.rumorBackgroundTitlelabel:SetAnchor(TOPLEFT, self.rumorOutcomeTextlabel, BOTTOMLEFT, 0, 20)
        self.rumorBackgroundTitlelabel:SetAnchor(TOPRIGHT, self.rumorOutcomeTextlabel, BOTTOMRIGHT, 0, 20)
        self.rumorOutcomeTextlabel:SetText(rumorData:GetCompleteText())
    end

    self.rumorBackgroundTextlabel:SetText(rumorData:GetBackgroundText())
end

function ZO_QuestJournal_Rumors_Gamepad:GetRumorDetailsNarrationText()
    local rumorData = self:GetSelectedRumorData()
    if not rumorData or not self.middlePaneFragment:IsShowing() then
        return {}
    end

    local narrations = {}

    ZO_AppendNarration(narrations, ZO_GamepadGenericHeader_GetNarrationText(self.contentHeader, self.contentHeaderData))

    if not self.rumorOutcomeTitlelabel:IsHidden() then
        ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(self.rumorOutcomeTitlelabel:GetText()))
        ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(self.rumorOutcomeTextlabel:GetText()))
    end

    ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(self.rumorBackgroundTitlelabel:GetText()))
    ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(self.rumorBackgroundTextlabel:GetText()))

    return narrations
end
