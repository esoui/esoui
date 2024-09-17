ZO_EMOTE_COLUMN_WIDTH = 400
ZO_EMOTE_ROW_HEIGHT = 70

local GAMEPAD_PLAYER_EMOTE_MENU_ENTRY_TEMPLATE = "ZO_GamepadItemSubEntryTemplate"

local MODE_CATEGORY_INACTIVE = 0
local MODE_CATEGORY_SELECTION = 1
local MODE_EMOTE_SELECTION = 2
local MODE_EMOTE_ASSIGNMENT = 3

local NUM_EMOTE_ENTRIES_IN_COLUMN = 9
local NUM_EMOTE_ENTRY_COLUMNS = 3
local NUM_EMOTES_ON_PAGE = NUM_EMOTE_ENTRY_COLUMNS * NUM_EMOTE_ENTRIES_IN_COLUMN

local EMOTE_GRID_MODE_EMOTES = 0
local EMOTE_GRID_MODE_QUICK_CHAT = 1

--
-- ZO_EmoteGridEntry class. These entries wrap the controls that make up the grid of emotes the user can select from
--
local EMOTE_GRID_ENTRY_TYPE_NONE = 0
local EMOTE_GRID_ENTRY_TYPE_EMOTE = 1
local EMOTE_GRID_ENTRY_TYPE_QUICK_CHAT = 2

ZO_EmoteGridEntry = ZO_InitializingObject:Subclass()

function ZO_EmoteGridEntry:Initialize(control)
    self.control = control
    self.title = control:GetNamedChild("Title")
    self.highlight = control:GetNamedChild("Highlight")
    self.entryType = EMOTE_GRID_ENTRY_TYPE_NONE
    self.id = 0
end

function ZO_EmoteGridEntry:SetAnchor(column, row)
    self.control:ClearAnchors()
    self.control:SetAnchor(TOPLEFT, nil, TOPLEFT, (column - 1) * ZO_EMOTE_COLUMN_WIDTH, (row - 1) * ZO_EMOTE_ROW_HEIGHT)
end

function ZO_EmoteGridEntry:SetVisible(visible)
    self.control:SetHidden(not visible)
end

function ZO_EmoteGridEntry:SetHighlightVisible(visible)
    self.highlight:SetHidden(not visible)
end

function ZO_EmoteGridEntry:Reset()
    self:SetVisible(false)
    self:SetHighlightVisible(false)
end

function ZO_EmoteGridEntry:SetEmoteInfo(emoteId)
    self.entryType = EMOTE_GRID_ENTRY_TYPE_EMOTE
    self.id = emoteId
    local emoteInfo = PLAYER_EMOTE_MANAGER:GetEmoteItemInfo(emoteId)

    if emoteInfo.isOverriddenByPersonality then
        self:SetName(ZO_PERSONALITY_EMOTES_COLOR:Colorize(emoteInfo.displayName))
    else
        self:SetName(emoteInfo.displayName)
    end
end

function ZO_EmoteGridEntry:SetQuickChatInfo(quickChatId)
    self.entryType = EMOTE_GRID_ENTRY_TYPE_QUICK_CHAT
    self.id = quickChatId
    self:SetName(QUICK_CHAT_MANAGER:GetFormattedQuickChatName(quickChatId))
end

function ZO_EmoteGridEntry:SetName(name)
    self.title:SetText(name)
    self.name = name
end

function ZO_EmoteGridEntry:GetName()
    return self.name
end

function ZO_EmoteGridEntry:GetId()
    return self.id
end

function ZO_EmoteGridEntry:GetEntryType()
    return self.entryType
end

--
-- ZO_GamepadEmoteGrid class. This class manages the full grid of emotes including page switching
--
ZO_GamepadEmoteGrid = ZO_GamepadPagedGrid:Subclass()

function ZO_GamepadEmoteGrid:Initialize(control, footerControl)
    local COLUMN_MAJOR = false
    ZO_GamepadPagedGrid.Initialize(self, control, COLUMN_MAJOR, footerControl)

    self.allowHighlight = true
    self.emoteEntries = {}
    self.visibleEmotes = {}
    self.mode = EMOTE_GRID_MODE_EMOTES
    self.emoteList = nil

    self:InitializeEmoteGridEntries()

    self:SetPageNumberFont("ZoFontGamepadBold54")
end

function ZO_GamepadEmoteGrid:InitializeEmoteEntryPool()
    local function CreateEmote(objectPool)
        local emoteControl = ZO_ObjectPool_CreateControl("ZO_GamepadPlayerEmoteEntryTemplate", objectPool, self.control)
        return ZO_EmoteGridEntry:New(emoteControl)
    end

    self.emoteEntryPool = ZO_ObjectPool:New(CreateEmote, ZO_ObjectPool_DefaultResetObject)
end

function ZO_GamepadEmoteGrid:InitializeEmoteGridEntries()
    self:InitializeEmoteEntryPool()

    for column = 1, NUM_EMOTE_ENTRY_COLUMNS do
        self.emoteEntries[column] = {}

        for row = 1, NUM_EMOTE_ENTRIES_IN_COLUMN do
            local emoteEntry = self.emoteEntryPool:AcquireObject()
            emoteEntry:SetAnchor(column, row)
            self.emoteEntries[column][row] = emoteEntry
        end
    end
end

function ZO_GamepadEmoteGrid:ResetGridEntry(column, row, visible)
    local emoteEntry = self.emoteEntries[column][row]

    emoteEntry:SetHighlightVisible(false)
    emoteEntry:SetVisible(visible)
end

function ZO_GamepadEmoteGrid:ResetPageInfo()
    local FIRST_PAGE = 1
    local numPages = math.ceil(#self.emoteList / NUM_EMOTES_ON_PAGE)
    self:SetPageInfo(FIRST_PAGE, numPages)
end

local function ShouldEmoteShowInGamepadUI(emoteData)
    return emoteData.showInGamepadUI
end

function ZO_GamepadEmoteGrid:ChangeEmoteListForEmoteType(emoteType)
    self.mode = EMOTE_GRID_MODE_EMOTES
    self.emoteList = PLAYER_EMOTE_MANAGER:GetEmoteListForType(emoteType, ShouldEmoteShowInGamepadUI)

    self:ResetPageInfo()
end

function ZO_GamepadEmoteGrid:ChangeEmoteListForQuickChat()
    self.mode = EMOTE_GRID_MODE_QUICK_CHAT
    self.emoteList = QUICK_CHAT_MANAGER:BuildQuickChatList()

    self:ResetPageInfo()
end

function ZO_GamepadEmoteGrid:GetCurrentSelectedEmote()
    if self.currentHighlight then
        return self.emoteEntries[self.currentHighlight.column][self.currentHighlight.row]
    end

    return nil
end

function ZO_GamepadEmoteGrid:GetSelectedEmoteName()
    return self:GetCurrentSelectedEmote():GetName()
end

function ZO_GamepadEmoteGrid:GetSelectedEmoteId()
    return self:GetCurrentSelectedEmote():GetId()
end

function ZO_GamepadEmoteGrid:GetSelectedEmoteType()
    return self:GetCurrentSelectedEmote():GetEntryType()
end

function ZO_GamepadEmoteGrid:SetAllowHighlight(allow)
    self.allowHighlight = allow
    self:RefreshGridHighlight()
end

do
    local SHOW_GRID_ENTRY = true
    local HIDE_GRID_ENTRY = false
    function ZO_GamepadEmoteGrid:RefreshGrid()
        --[[
            Refresh the grid by resetting the visibleEmotes boolean array used by ZO_GamepadGrid and then setting controls
            Visible or Hidden based on how many entries are needed to be shown for the current list size on the current page
        --]]
        ZO_ClearNumericallyIndexedTable(self.visibleEmotes)
        local currentPage = self:GetCurrentPage()

        local emoteStartIndex = ((currentPage - 1) * NUM_EMOTES_ON_PAGE)
        local numEmotes = #self.emoteList
        local numEmotesToShow = numEmotes > 0 and zo_min(numEmotes - emoteStartIndex, NUM_EMOTES_ON_PAGE) or numEmotes

        local numShown = 0
        for column = 1, NUM_EMOTE_ENTRY_COLUMNS do
            if numShown < numEmotesToShow then
                self.visibleEmotes[column] = {}
            end

            for row = 1, NUM_EMOTE_ENTRIES_IN_COLUMN do
                if numShown < numEmotesToShow then
                    self:ResetGridEntry(column, row, SHOW_GRID_ENTRY)
                    self.visibleEmotes[column][row] = true
                    numShown = numShown + 1
                    if self.mode == EMOTE_GRID_MODE_EMOTES then
                        self.emoteEntries[column][row]:SetEmoteInfo(self.emoteList[emoteStartIndex + numShown])
                    elseif self.mode == EMOTE_GRID_MODE_QUICK_CHAT then
                        self.emoteEntries[column][row]:SetQuickChatInfo(self.emoteList[emoteStartIndex + numShown])
                    end
                else
                    self:ResetGridEntry(column, row, HIDE_GRID_ENTRY)
                end
            end
        end

        self:ResetGridPosition()
    end
end

function ZO_GamepadEmoteGrid:GetNumEmoteEntries()
    return self.emoteList and #self.emoteList or 0
end

-- functions overriden from base class

function ZO_GamepadEmoteGrid:GetGridItems()
    return self.visibleEmotes
end

function ZO_GamepadEmoteGrid:RefreshGridHighlight()
    if self.currentHighlight then
        self.emoteEntries[self.currentHighlight.column][self.currentHighlight.row]:SetHighlightVisible(false)
    end

    local column, row = self:GetGridPosition()
    if column > 0 and row > 0 then
        self.emoteEntries[column][row]:SetHighlightVisible(self.allowHighlight)
        self.currentHighlight = {row = row, column = column}
    end
end

function ZO_GamepadEmoteGrid:Activate()
    ZO_GamepadPagedGrid.Activate(self)
    self.footer.control:SetHidden(false)
end

function ZO_GamepadEmoteGrid:Deactivate()
    ZO_GamepadPagedGrid.Deactivate(self)
    self.footer.control:SetHidden(true)
end

function ZO_GamepadEmoteGrid:GetNarrationText()
    return SCREEN_NARRATION_MANAGER:CreateNarratableObject(self:GetSelectedEmoteName())
end

function ZO_GamepadEmoteGrid:GetHeaderNarration()
    return { GAMEPAD_PLAYER_EMOTE:GetContentHeaderNarrationText(), self:GetCurrentPageNarration() }
end

--
-- ZO_GamepadPlayerEmote class. This class creates our gamepad scene and emote category list and contains
-- a ZO_GamepadEmoteGrid object and quickslot radial menu

ZO_GamepadPlayerEmote = ZO_Gamepad_ParametricList_Screen:Subclass()

function ZO_GamepadPlayerEmote:Initialize(control)
    self.control = control
    self.emoteListGridControl = control:GetNamedChild("EmoteListGrid")

    local quickslotControl = control:GetNamedChild("Quickslot")
    self.wheelControl = quickslotControl:GetNamedChild("EmoteWheel")
    self.assignLabel = quickslotControl:GetNamedChild("Assign")
    self.selectedEmoteNameLabel = quickslotControl:GetNamedChild("SelectedEmoteName")

    GAMEPAD_PLAYER_EMOTE_SCENE = ZO_Scene:New("gamepad_player_emote", SCENE_MANAGER)
    local ACTIVATE_ON_SHOW = true
    ZO_Gamepad_ParametricList_Screen.Initialize(self, control, ZO_GAMEPAD_HEADER_TABBAR_DONT_CREATE, ACTIVATE_ON_SHOW, GAMEPAD_PLAYER_EMOTE_SCENE)
end

function ZO_GamepadPlayerEmote:OnDeferredInitialize()
    self:InitializeHeader()
    self:InitializeEmoteGrid()
    self:CreateCategoryList()
    self:InitializeRadialMenu()

    PLAYER_EMOTE_MANAGER:RegisterCallback("EmoteListUpdated", function()
        if GAMEPAD_PLAYER_EMOTE_SCENE:IsShowing() then
            self:CreateCategoryList()
        else
            self:MarkDirty()
        end
    end)
end

function ZO_GamepadPlayerEmote:OnSelectionChanged()
    local targetData = self.categoryList:GetTargetData()
    if targetData then
        self.currentData = targetData
        if targetData.type == ACTION_TYPE_EMOTE then
            self.emoteListGrid:ChangeEmoteListForEmoteType(targetData.emoteCategory)
        elseif targetData.type == ACTION_TYPE_QUICK_CHAT then
            self.emoteListGrid:ChangeEmoteListForQuickChat()
        end
    end
    KEYBIND_STRIP:UpdateCurrentKeybindButtonGroups()
end

function ZO_GamepadPlayerEmote:SetupList(list)
    local function IsEntryCategoryEqual(left, right)
        if left.type == right.type then
            if left.type == ACTION_TYPE_QUICK_CHAT then
                return true
            elseif left.type == ACTION_TYPE_EMOTE then
                return left.emoteCategory == right.emoteCategory
            end
        end

        return false
    end
    list:AddDataTemplate(GAMEPAD_PLAYER_EMOTE_MENU_ENTRY_TEMPLATE, ZO_SharedGamepadEntry_OnSetup, ZO_GamepadMenuEntryTemplateParametricListFunction, IsEntryCategoryEqual)
end

function ZO_GamepadPlayerEmote:ViewCategory(categoryData)
    if categoryData then
        local ANY_TEMPLATE = nil
        local index = self.categoryList:GetIndexForData(ANY_TEMPLATE, categoryData)
        if index then
            self.categoryList:SetSelectedIndexWithoutAnimation(index)
        else
            return internalassert(false, "Trying to view an invalid category")
        end
    end
end

function ZO_GamepadPlayerEmote:CreateCategoryList()
    self.categoryList = self:GetMainList()

    self.categoryList:Clear()

    local quickChatIcon = GetSharedQuickChatIcon()
    local data = ZO_GamepadEntryData:New(GetString(SI_QUICK_CHAT_EMOTE_MENU_ENTRY_NAME), quickChatIcon)
    data:SetModifyTextType(MODIFY_TEXT_TYPE_UPPERCASE)
    data:SetIconTintOnSelection(true)
    data.type = ACTION_TYPE_QUICK_CHAT
    self.categoryList:AddEntry(GAMEPAD_PLAYER_EMOTE_MENU_ENTRY_TEMPLATE, data)

    local categories = PLAYER_EMOTE_MANAGER:GetEmoteCategories()

    for _, category in ipairs(categories) do
        if category ~= EMOTE_CATEGORY_INVALID then
            local emoteIcon = PLAYER_EMOTE_MANAGER:GetSharedEmoteIconForCategory(category)
            local data = ZO_GamepadEntryData:New(GetString("SI_EMOTECATEGORY", category), emoteIcon)
            data:SetModifyTextType(MODIFY_TEXT_TYPE_UPPERCASE)
            data:SetIconTintOnSelection(true)
            data.type = ACTION_TYPE_EMOTE
            data.emoteCategory = category
            self.categoryList:AddEntry(GAMEPAD_PLAYER_EMOTE_MENU_ENTRY_TEMPLATE, data)
        end
    end

    self.categoryList:Commit()

    self.isDirty = false
end

function ZO_GamepadPlayerEmote:MarkDirty()
    self.isDirty = true
end

function ZO_GamepadPlayerEmote:InitializeHeader()
    self.headerData = { titleText = GetString(SI_GAMEPAD_MAIN_MENU_EMOTES) }

    local rightPane = self.control:GetNamedChild("RightPane")
    local contentContainer = rightPane:GetNamedChild("Container"):GetNamedChild("ContentHeader")
    self.contentHeader = contentContainer:GetNamedChild("Header")
    ZO_GamepadGenericHeader_Initialize(self.contentHeader, ZO_GAMEPAD_HEADER_TABBAR_DONT_CREATE, ZO_GAMEPAD_HEADER_LAYOUTS.DATA_PAIRS_TOGETHER)

    local titleControl = self.contentHeader:GetNamedChild("TitleContainerTitle")
    titleControl:SetFont("ZoFontGamepad54")

    self.contentHeaderData = 
    {
        titleText = function()
            if self.mode == MODE_CATEGORY_SELECTION or self.mode == MODE_EMOTE_SELECTION then
                local currentData = self.currentData
                if currentData then
                    if currentData.type == ACTION_TYPE_QUICK_CHAT then
                        return GetString(SI_QUICK_CHAT_EMOTE_MENU_ENTRY_NAME)
                    elseif currentData.type == ACTION_TYPE_EMOTE then
                        return GetString("SI_EMOTECATEGORY", currentData.emoteCategory)
                    end
                end
            end
        end,
    }
end

function ZO_GamepadPlayerEmote:InitializeEmoteGrid()
    self.emoteListGrid = ZO_GamepadEmoteGrid:New(self.emoteListGridControl, self.control:GetNamedChild("RightPaneContainerFooter"))
    self.emoteListGrid:SetPageChangedCallback(function() self:RefreshHeader() end)
end

function ZO_GamepadPlayerEmote:InitializeRadialMenu()
    local wheelData =
    {
        hotbarCategories = { HOTBAR_CATEGORY_EMOTE_WHEEL, HOTBAR_CATEGORY_QUICKSLOT_WHEEL },
        numSlots = ACTION_BAR_UTILITY_BAR_SIZE,
        showCategoryLabel = true,
        onSelectionChangedCallback = function()
            KEYBIND_STRIP:UpdateKeybindButtonGroup(self.emoteAssignmentKeybindStripDescriptor)
        end,
        customNarrationObjectName = "EmoteAssignableUtilityWheel",
        headerNarrationFunction = function()
            local narrations = {}
            ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(GetString(SI_GAMEPAD_EMOTE_ASSIGN_INSTRUCTIONS)))
            ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(self.emoteListGrid:GetSelectedEmoteName()))
            return narrations
        end,
    }
    self.wheel = ZO_AssignableUtilityWheel_Gamepad:New(self.wheelControl, wheelData)
end

function ZO_GamepadPlayerEmote:PerformUpdate()
    self:RefreshHeader()
end

function ZO_GamepadPlayerEmote:RefreshHeader()
    local personalityId = GetActiveCollectibleByType(COLLECTIBLE_CATEGORY_TYPE_PERSONALITY, GAMEPLAY_ACTOR_CATEGORY_PLAYER)
    local collectibleData = ZO_COLLECTIBLE_DATA_MANAGER:GetCollectibleDataById(personalityId)
    if collectibleData then
        self.headerData.data1HeaderText = GetString(SI_GAMEPAD_EMOTE_PERSONALITY_OVERRIDE_HEADER)
        self.headerData.data1Text = ZO_PERSONALITY_EMOTES_COLOR:Colorize(zo_strformat(SI_GAMEPAD_SOCIAL_PERSONALITY, collectibleData:GetName()))
    else
        self.headerData.data1HeaderText = nil
        self.headerData.data1Text = nil
    end

    ZO_GamepadGenericHeader_Refresh(self.header, self.headerData)
    ZO_GamepadGenericHeader_Refresh(self.contentHeader, self.contentHeaderData)
end

function ZO_GamepadPlayerEmote:GetContentHeaderNarrationText()
    return ZO_GamepadGenericHeader_GetNarrationText(self.contentHeader, self.contentHeaderData)
end

function ZO_GamepadPlayerEmote:InitializeKeybindStripDescriptors()
    -- keybinds when a category is selected
    self.categoryKeybindStripDescriptor = 
    {
        {
            name = GetString(SI_PLAYER_EMOTE_USE_EMOTE),
            keybind = "UI_SHORTCUT_PRIMARY",
            alignment = KEYBIND_STRIP_ALIGN_LEFT,
            visible = function() 
                return self.emoteListGrid:GetCurrentSelectedEmote() ~= nil 
            end,
            callback = function()
                SCENE_MANAGER:ShowBaseScene()
                local emoteId = self.emoteListGrid:GetSelectedEmoteId()
                if self.currentData.type == ACTION_TYPE_QUICK_CHAT then
                    QUICK_CHAT_MANAGER:PlayQuickChat(emoteId)
                elseif self.currentData.type == ACTION_TYPE_EMOTE then
                    local emoteIndex = PLAYER_EMOTE_MANAGER:GetEmoteItemInfo(emoteId).emoteIndex
                    PlayEmoteByIndex(emoteIndex)
                end
            end,
        },

        {
            name = GetString(SI_PLAYER_EMOTE_ASSIGN_EMOTE),
            keybind = "UI_SHORTCUT_SECONDARY",
            alignment = KEYBIND_STRIP_ALIGN_LEFT,
            visible = function() 
                return self.emoteListGrid:GetCurrentSelectedEmote() ~= nil 
            end,
            callback = function()
                self:ChangeCurrentMode(MODE_EMOTE_ASSIGNMENT)
            end,
        },
    }

    ZO_Gamepad_AddBackNavigationKeybindDescriptorsWithSound(self.categoryKeybindStripDescriptor,
                                                            GAME_NAVIGATION_TYPE_BUTTON,
                                                            function() self:ChangeCurrentMode(MODE_CATEGORY_SELECTION) end)

    -- keybinds when assigning emotes
    self.emoteAssignmentKeybindStripDescriptor = {}

    local function OnAssignPendingData()
        self.wheel:TryAssignPendingToSelectedEntry()
    end

    local function ShouldShowAssignKeybind()
        return self.wheel:GetSelectedRadialEntry() ~= nil
    end

    ZO_Gamepad_AddForwardNavigationKeybindDescriptors(self.emoteAssignmentKeybindStripDescriptor,
                                            GAME_NAVIGATION_TYPE_BUTTON, 
                                            OnAssignPendingData,
                                            GetString(SI_GAMEPAD_ITEM_ACTION_QUICKSLOT_ASSIGN),
                                            ShouldShowAssignKeybind)

    ZO_Gamepad_AddBackNavigationKeybindDescriptors(self.emoteAssignmentKeybindStripDescriptor,
                                                GAME_NAVIGATION_TYPE_BUTTON,
                                                function() self:ChangeCurrentMode(MODE_EMOTE_SELECTION) end)

    -- keybinds when selecting a category
    self.keybindStripDescriptor = {}
    ZO_Gamepad_AddForwardNavigationKeybindDescriptorsWithSound(self.keybindStripDescriptor,
                                                GAME_NAVIGATION_TYPE_BUTTON,
                                                function() self:ChangeCurrentMode(MODE_EMOTE_SELECTION) end,
                                                GetString(SI_GAMEPAD_SELECT_OPTION),
                                                function() return self.emoteListGrid:GetNumEmoteEntries() > 0 end)

    ZO_Gamepad_AddBackNavigationKeybindDescriptors(self.keybindStripDescriptor, GAME_NAVIGATION_TYPE_BUTTON)

    self:SetListsUseTriggerKeybinds(true)
end

function ZO_GamepadPlayerEmote:DeselectCurrentMode()
    if self.mode == MODE_CATEGORY_SELECTION then
        KEYBIND_STRIP:RemoveKeybindButtonGroup(self.keybindStripDescriptor)
        self:DeactivateCurrentList()
    elseif self.mode == MODE_EMOTE_SELECTION then
        KEYBIND_STRIP:RemoveKeybindButtonGroup(self.categoryKeybindStripDescriptor)
        self.emoteListGrid:Deactivate()
        self.emoteListGrid:SetAllowHighlight(false)
    elseif self.mode == MODE_EMOTE_ASSIGNMENT then
        self:HideAssignableUtilityWheel()
        self.emoteListGridControl:SetHidden(false)
        KEYBIND_STRIP:RemoveKeybindButtonGroup(self.emoteAssignmentKeybindStripDescriptor)
    end
    self.mode = MODE_CATEGORY_INACTIVE
end

function ZO_GamepadPlayerEmote:SelectMode(mode)
    self.mode = mode

    if self.mode == MODE_CATEGORY_SELECTION then
        KEYBIND_STRIP:AddKeybindButtonGroup(self.keybindStripDescriptor)
        self:ActivateCurrentList()
        self.emoteListGrid:SetAllowHighlight(false)
    elseif self.mode == MODE_EMOTE_SELECTION then
        KEYBIND_STRIP:AddKeybindButtonGroup(self.categoryKeybindStripDescriptor)
        self.emoteListGrid:SetAllowHighlight(true)
        self.emoteListGrid:Activate()
    elseif self.mode == MODE_EMOTE_ASSIGNMENT then
        self:ShowAssignableUtilityWheel()
    end
end

function ZO_GamepadPlayerEmote:ChangeCurrentMode(mode)
    if self.mode ~= mode then
        self:DeselectCurrentMode()
        self:SelectMode(mode)
        self:RefreshHeader()
    end
end

function ZO_GamepadPlayerEmote:ShowAssignableUtilityWheel()
    local useAccessibleWheel = GetSetting_Bool(SETTING_TYPE_ACCESSIBILITY, ACCESSIBILITY_SETTING_ACCESSIBLE_QUICKWHEELS)
    local actionId = self.emoteListGrid:GetSelectedEmoteId()
    local slotType = nil
    local activeEntryType = self.emoteListGrid:GetSelectedEmoteType()

    if activeEntryType == EMOTE_GRID_ENTRY_TYPE_EMOTE then
        slotType = ACTION_TYPE_EMOTE
    elseif activeEntryType == EMOTE_GRID_ENTRY_TYPE_QUICK_CHAT then
        slotType = ACTION_TYPE_QUICK_CHAT
    end

    if useAccessibleWheel then
        ACCESSIBLE_ASSIGNABLE_UTILITY_WHEEL_GAMEPAD:SetPendingSimpleAction(slotType, actionId)
        ACCESSIBLE_ASSIGNABLE_UTILITY_WHEEL_GAMEPAD:Show({ HOTBAR_CATEGORY_EMOTE_WHEEL, HOTBAR_CATEGORY_QUICKSLOT_WHEEL })
    else
        self.emoteListGridControl:SetHidden(true)
        KEYBIND_STRIP:AddKeybindButtonGroup(self.emoteAssignmentKeybindStripDescriptor)
        self.wheel:SetPendingSimpleAction(slotType, actionId)
        self.assignLabel:SetHidden(false)
        self.selectedEmoteNameLabel:SetHidden(false)
        self.selectedEmoteNameLabel:SetText(self.emoteListGrid:GetSelectedEmoteName())

        -- This will Activate the menu and show it
        self.wheel:Show()
    end
end

function ZO_GamepadPlayerEmote:HideAssignableUtilityWheel()
    self.assignLabel:SetHidden(true)
    self.selectedEmoteNameLabel:SetHidden(true)

    -- This will deactivate the menu and hide it
    self.wheel:Hide()
end

function ZO_GamepadPlayerEmote:OnShowing()
    if self.isDirty then
        self:CreateCategoryList()
    end

    if self.queuedBrowseToCategoryData then
        self:ViewCategory(self.queuedBrowseToCategoryData)
        self.queuedBrowseToCategoryData = nil
    end

    self:ChangeCurrentMode(MODE_CATEGORY_SELECTION)
    TriggerTutorial(TUTORIAL_TRIGGER_EMOTES_MENU_OPENED)
end

function ZO_GamepadPlayerEmote:OnHiding()
    self:ChangeCurrentMode(MODE_CATEGORY_INACTIVE)
end

function ZO_GamepadPlayerEmote:QueueBrowseToCategoryData(categoryData)
    self.queuedBrowseToCategoryData = categoryData
end

--Global XML Handlers
-----------------------

function ZO_GamepadPlayerEmote_OnInitialized(control)
    GAMEPAD_PLAYER_EMOTE = ZO_GamepadPlayerEmote:New(control)
end