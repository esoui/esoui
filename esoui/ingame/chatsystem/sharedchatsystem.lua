CHAT_SYSTEM = nil

--[[ Essentially there are three main types of controls

* Chat Container
    This container holds all of the text buffers and tabs.
    By default there is a single Chat Container, but players can create more by dragging a tab off of another Chat Container.
    
* Chat Window
    This is the actual text buffer (and anything special like filters in the combat log) where chat messages are added to.
    A chat container always contains at least one of these.
    
* Chat Tab
    Each Chat Window has a tab. The tab is the primary place for mouse manipulation.
    Dragging a tab pulls off a Chat Window and consequently create a new Chat Container.
    Unless the tab is the first tab, then it drags the entire Chat Container.
    When the tab is clicked the associated Chat Window is shown.
    
Lastly, there is the chat system that coordinates dragging across containers, pooling, and so on
]]--

--Named constants
local DONT_FREE = true
local FREE = false

--Constants
local TAB_STARTING_X = 16
local TAB_STARTING_Y = 4

local FADE_ANIMATION_DURATION = 350
local FADE_ANIMATION_DELAY = 3000

local NUM_COMMAND_HISTORY_TO_SAVE = 50

local TAB_ALERT_TEXT_COLOR = ZO_SECOND_CONTRAST_TEXT

local ChannelInfo = ZO_ChatSystem_GetChannelInfo()
local ChatEventFormatters = ZO_ChatSystem_GetEventHandlers()
local MultiLevelEventToCategoryMappings, SimpleEventToCategoryMappings = ZO_ChatSystem_GetEventCategoryMappings()

function GetChannelName(channelId)
    local channelInfo = ChannelInfo[channelId]
    if channelInfo then
        return channelInfo.dynamicName and GetDynamicChatChannelName(channelInfo.id) or channelInfo.name
    end
end

--[[ ChannelTarget ]]--
local ChannelTarget = ZO_Object:Subclass()

function ChannelTarget:New(...)
    local target = ZO_Object.New(self)
    target:Initialize(...)
    
    return target
end

function ChannelTarget:Initialize()
    self.currentTargetIndex = 1
    self.targets = {}
end

function ChannelTarget:GetLastTarget()
    return self.lastTarget
end

function ChannelTarget:AddTarget(target)
    if not self.targets[target] then
        self.targets[#self.targets + 1] = target
        self.targets[target] = #self.targets
    end

    -- Always save this off as the last target, we just got a tell from it.
    self.lastTarget = target
end

function ChannelTarget:GetNextTarget()
    local target = self.targets[self.currentTargetIndex]
    self.currentTargetIndex = self.currentTargetIndex + 1
    if self.currentTargetIndex > #self.targets then
        self.currentTargetIndex = 1
    end
    return target
end

function ChannelTarget:GetPreviousTarget()
    local target = self.targets[self.currentTargetIndex]
    self.currentTargetIndex = self.currentTargetIndex - 1
    if self.currentTargetIndex < 1 then
        self.currentTargetIndex = 1
    end
    return target
end

--[[ Text Entry ]]--
local MAX_AUTO_COMPLETION_RESULTS = 10

local TextEntry = ZO_Object:Subclass()

function TextEntry:New(...)
    local entry = ZO_Object.New(self)
    entry:Initialize(...)
    
    return entry
end

local TEXT_ENTRY_DURATION = 500
local TEXT_ENTRY_MIN_ALPHA = .25
local TEXT_ENTRY_MAX_ALPHA = 1.0

function TextEntry:Initialize(system, control, chatEditBufferTop, chatEditBufferBottom)
    self.control = control
    self.system = system
    self.chatEditBufferTop = chatEditBufferTop
    self.chatEditBufferBottom = chatEditBufferBottom
    control.system = system
    control.owner = self

    self.editBg = control:GetNamedChild("Edit")
    self.editControl = control:GetNamedChild("EditBox")
    self.channelLabel = control:GetNamedChild("Label")

    self.commandHistory = ZO_CircularBuffer:New(NUM_COMMAND_HISTORY_TO_SAVE)
    
    self.commandHistoryCursor = 1
    self.autoComplete = ZO_AutoComplete:New(self.editControl, { AUTO_COMPLETE_FLAG_ALL }, { AUTO_COMPLETE_FLAG_GUILD_NAMES }, AUTO_COMPLETION_ONLINE_ONLY, MAX_AUTO_COMPLETION_RESULTS, AUTO_COMPLETION_MANUAL_MODE)

    self.autoComplete:SetUseCallbacks(true)
    self.autoComplete:SetAnchorStyle(AUTO_COMPLETION_ANCHOR_BOTTOM)

    local function OnAutoCompleteEntrySelected(name, selectionMethod)
        self.system.suppressAutoCompleteClear = true
        self.editControl:SetText("")
        self.system:OnAutoCompleteEntrySelected(name)
        self.autoComplete:Hide()
    end
    self.autoComplete:RegisterCallback(ZO_AutoComplete.ON_ENTRY_SELECTED, OnAutoCompleteEntrySelected)

    self.control:SetAlpha(TEXT_ENTRY_MIN_ALPHA)
end

function TextEntry:GetEditControl()
    return self.editControl
end

function TextEntry:GetControl()
    return self.control
end

function TextEntry:StartCommandAtIndex(index)
    local command = self.commandHistory:At(index)
    if command then
        self.system:StartTextEntry(command)
        self.commandHistoryCursor = index
    end
end

function TextEntry:AutoCompleteTarget(target)
    self.autoComplete:Show(target)
end

function TextEntry:NextCommand()
    self:StartCommandAtIndex(self.commandHistoryCursor + 1)
end

function TextEntry:PreviousCommand()
    self:StartCommandAtIndex(self.commandHistoryCursor - 1)
end

function TextEntry:AddCommandHistory(text)
    self.commandHistory:Add(text)
    self.commandHistoryCursor = self.commandHistory:Size() + 1
end

local function CreateFadeAnimations(self)
    if not self.fadeAnim then
        self.fadeAnim = ZO_AlphaAnimation:New(self.control)
    end
end

function TextEntry:FadeOut(delay)
    CreateFadeAnimations(self)

    self.fadeAnim:SetMinMaxAlpha(TEXT_ENTRY_MIN_ALPHA, TEXT_ENTRY_MAX_ALPHA)
    self.fadeAnim:FadeOut(0, TEXT_ENTRY_DURATION)
end

function TextEntry:FadeIn()
    CreateFadeAnimations(self)

    self.fadeAnim:SetMinMaxAlpha(TEXT_ENTRY_MIN_ALPHA, TEXT_ENTRY_MAX_ALPHA)
    self.fadeAnim:FadeIn(0, TEXT_ENTRY_DURATION)
end

function TextEntry:Open(text)
    if text and text ~= "" then
        self:SetText(text)
    end

    if not self.open then
        self:FadeIn()
        self.editControl:TakeFocus()
        self.open = true
        SCENE_MANAGER:OnChatInputStart()
    end
end

function TextEntry:Close(keepText)
    if not keepText then
        self.editControl:Clear()
    end

    if self.open then
        self.editControl:LoseFocus()
        self:FadeOut()
        self.open = false
        SCENE_MANAGER:OnChatInputEnd()
    end
end

function TextEntry:IsOpen()
    return self.open
end

function TextEntry:GetText()
    return self.editControl:GetText()
end

function TextEntry:SetText(text)
    self.editControl:SetText(text)
end

function TextEntry:InsertText(text)
    self.editControl:InsertText(text)
end

function TextEntry:SetCursorPosition(pos)
    self.editControl:SetCursorPosition(pos)
end
function TextEntry:GetCursorPosition(offset)
    return self.editControl:GetCursorPosition()
end

function TextEntry:SetChannel(channelData, target)
    local oldChannelText = self.channelLabel:GetText()
    if target then
        if IsDecoratedDisplayName(target) then
            target = ZO_FormatUserFacingDisplayName(target)
        end
        self.channelLabel:SetText(zo_strformat(SI_CHAT_ENTRY_TARGET_FORMAT, GetChannelName(channelData.id), target))
    else
        self.channelLabel:SetText(zo_strformat(SI_CHAT_ENTRY_GENERAL_FORMAT, GetChannelName(channelData.id)))
    end

    return (self.channelLabel:GetText() ~= oldChannelText)
end

function TextEntry:SetColor(r, g, b)
    self.channelLabel:SetColor(r, g, b, 1)
    self.editControl:SetColor(r, g, b, 1)
end

-- As a convenience, this function always starts chat input when trying to link an item.
-- Except on consoles.
function TextEntry:InsertLink(link)
    if not self.editControl:HasFocus() then
        StartChatInput()
    end

    self.editControl:InsertText(link)
    return true
end

function TextEntry:SetFont(font)
    self.editControl:SetFont(font)
    self.channelLabel:SetFont(font)

    ZO_EditContainerSizer.ForceRefreshSize(self.editBg, self.chatEditBufferTop, self.chatEditBufferBottom)
    self.control:SetHeight(self.editBg:GetHeight())
end

function TextEntry:IsAutoCompleteOpen()
    return self.autoComplete:IsOpen()
end

function TextEntry:CloseAutoComplete()
    self.autoComplete:Hide()
end

--[[ Chat Container ]]--
SharedChatContainer = ZO_Object:Subclass()

function SharedChatContainer:New(chatSystem, control, windowPool, tabPool)
    local container = ZO_Object.New(self)
    container.system = chatSystem
    container:Initialize(control, windowPool, tabPool)
    
    return container
end

function SharedChatContainer:Initialize(control, windowPool, tabPool)
    self.control = control
    self.backdrop = control:GetNamedChild("Bg")
    control.container = self

    self.visualData = {}
    self.overflowTab = control:GetNamedChild("OverflowTab")
    ZO_CreateUniformIconTabData(self.visualData, nil, 32, 32, "EsoUI/Art/ChatWindow/chat_overflowArrow_down.dds", "EsoUI/Art/ChatWindow/chat_overflowArrow_up.dds", "EsoUI/Art/ChatWindow/chat_overflowArrow_over.dds")
    ZO_TabButton_Icon_Initialize(self.overflowTab, "SimpleIconHighlight", self.visualData)
    self.overflowTab:SetHandler("OnMouseUp", function(tab, button, isUpInside) if isUpInside then self:ShowOverflowedTabsDropdown() end ZO_TabButton_Unselect(tab) end)
    self.overflowTab.container = self

    self.fadeInReferences = 0
end

function SharedChatContainer:ShowOverflowedTabsDropdown()
    if self.hiddenTabStartIndex <= #self.windows then
        ClearMenu()
        
        for i=self.hiddenTabStartIndex, #self.windows do
            AddMenuItem(self:GetTabName(i), function() self:ForceWindowIntoView(i) end)
        end
   
        ShowMenu(self.overflowTab)
    end
end

function SharedChatContainer:LoadWindowSettings(window)
    local tabIndex = window.tab.index

    local _, locked, interactable, _, areTimestampsEnabled = GetChatContainerTabInfo(self.id, tabIndex)
    local fontSize = CHAT_SYSTEM:GetFontSizeFromSetting()

    self:SetLocked(tabIndex, locked)
    self:SetInteractivity(tabIndex, interactable)
    self:SetTimestampsEnabled(tabIndex, areTimestampsEnabled)
    self:SetFontSize(tabIndex, fontSize)
end

function SharedChatContainer:SetTimestampsEnabled(tabIndex, areTimestampsEnabled)
    local window = self.windows[tabIndex]
    if window and window.combatLog and window.combatLog:AreTimestampsEnabled() ~= areTimestampsEnabled then
        window.combatLog:SetTimestampsEnabled(areTimestampsEnabled)
        self:SaveWindowSettings(tabIndex)
    end
end

function SharedChatContainer:AreTimestampsEnabled(tabIndex)
    local window = self.windows[tabIndex]
    if window and window.combatLog then
        return window.combatLog:AreTimestampsEnabled()
    end
end

function SharedChatContainer:SetLocked(tabIndex, locked)
    local window = self.windows[tabIndex]
    if window and window.locked ~= locked then
        window.locked = locked
        self:SaveWindowSettings(tabIndex)
    end
end

function SharedChatContainer:IsLocked(tabIndex)
    local window = self.windows[tabIndex]
    if window then
        return window.locked
    end
end
function SharedChatContainer:AddFadeInReference()
    self.fadeInReferences = self.fadeInReferences + 1
    self:FadeIn()
end

function SharedChatContainer:RemoveFadeInReference()
    self.fadeInReferences = self.fadeInReferences - 1
    if self.fadeInReferences == 0 then
        self:FadeOut()
    end
end

function SharedChatContainer:SetBackgroundColor(r, g, b, minAlpha, maxAlpha)
    self.backdrop:SetCenterColor(r, g, b, 1)
    self.minAlpha, self.maxAlpha = minAlpha, maxAlpha
    if self.currentBuffer then
        if self.control:GetAlpha() < self.minAlpha then
            self:FadeIn(0)
        else
            self:FadeOut(0)
        end
    end
    self:SaveSettings()
end

function SharedChatContainer:GetBackgroundColor()
    local r, g, b = self.backdrop:GetCenterColor()
    return r, g, b, self.minAlpha, self.maxAlpha
end

function SharedChatContainer:SetMinAlpha(minAlpha)
    local r, g, b, _, maxAlpha = self:GetBackgroundColor()
    self:SetBackgroundColor(r, g, b, minAlpha, zo_max(maxAlpha, minAlpha))
end

function SharedChatContainer:GetMinAlpha()
    return self.minAlpha
end

function SharedChatContainer:ResetMinAlphaToDefault()
    local r, g, b, _, maxAlpha = self:GetBackgroundColor()
    ResetChatContainerColorsToDefault(self.id)
    local _, _, _, bgMinAlpha = GetChatContainerColors(self.id)
    self:SetBackgroundColor(r, g, b, bgMinAlpha, maxAlpha)
end

function SharedChatContainer:UpdateInteractivity(isInteractive)
    if isInteractive then
        self:SyncScrollToBuffer()
    end

    local window = self.currentBuffer:GetParent()
    if window.combatLog then
        window.filterSelf:SetHidden(not isInteractive)
        window.filterIncoming:SetHidden(not isInteractive)
        window.filterAll:SetHidden(not isInteractive)
    end
end

function SharedChatContainer:IsInteractive(tabIndex)
    local window = self.windows[tabIndex]
    if window then
        return window.buffer:IsMouseEnabled()
    end
end

function SharedChatContainer:ForceWindowIntoView(tabIndex)
    local window = self.windows[tabIndex]
    if window and self.hiddenTabStartIndex > 2 and self.windows[self.hiddenTabStartIndex] then
        local idealPosition = self.hiddenTabStartIndex
        local tabWidth = window.tab:GetDesiredWidth()
        local foundWidth = 0

        repeat
            idealPosition = idealPosition - 1
            foundWidth = foundWidth + self.windows[idealPosition].tab:GetDesiredWidth()
        until idealPosition <= 2 or foundWidth >= tabWidth

        table.remove(self.windows, tabIndex)
        table.insert(self.windows, idealPosition, window)
        TransferChatContainerTab(self.id, tabIndex, self.id, idealPosition)

        self:UpdateTabIndices(idealPosition)
        self:PerformLayout()
        self.tabGroup:SetClickedButton(window.tab)
    end
end

function SharedChatContainer:SetInteractivity(tabIndex, isInteractive)
    local window = self.windows[tabIndex]
    if window and window.buffer:IsMouseEnabled() ~= isInteractive then
        window.buffer:SetMouseEnabled(isInteractive)
        if window.buffer == self.currentBuffer then
            self:UpdateInteractivity(isInteractive)
        end
        self:SaveWindowSettings(tabIndex)
    end
end

function SharedChatContainer:GetTabName(tabIndex)
    local window = self.windows[tabIndex]
    if window then
        return ZO_TabButton_Text_GetText(window.tab)
    end
end

function SharedChatContainer:SetTabName(tabIndex, name)
    local window = self.windows[tabIndex]
    if window and ZO_TabButton_Text_GetText(window.tab) ~= name then
        ZO_TabButton_Text_SetText(window.tab, name)
        self:SaveWindowSettings(tabIndex)
    end
end

function SharedChatContainer:SetFontSize(tabIndex, fontSize)
    local window = self.windows[tabIndex]
    if window and fontSize ~= window.fontSize then
        window.fontSize = fontSize

        local font = self:GetChatFontFormatString(fontSize)

        window.buffer:SetFont(font)
    end
end

function SharedChatContainer:IsCombatLog(tabIndex)
    local window = self.windows[tabIndex]
    return window and window.combatLog ~= nil
end

function SharedChatContainer:GetChatSystem()
    return self.system
end

function SharedChatContainer:SetBufferColor(categoryId, red, green, blue)
    for i=1, #self.windows do
        self.windows[i].buffer:SetColorById(categoryId, red, green, blue)
    end
end

function SharedChatContainer:ResetToDefaults(tabIndex)
    local window = self.windows[tabIndex]
    if window then
        self:UnregisterCategoriesForWindow(tabIndex)
        ResetChatContainerColorsToDefault(self.id)
        local bgR, bgG, bgB, bgMinAlpha, bgMaxAlpha = GetChatContainerColors(self.id)
        self:SetBackgroundColor(bgR, bgG, bgB, bgMinAlpha, bgMaxAlpha)

        ResetChatContainerTabToDefault(self.id, tabIndex)
        
        self:LoadWindowSettings(window)

        self:RegisterCategoriesForWindow(tabIndex)

        self:FadeOut(0)
    end

    self:GetChatSystem():SetupFonts()
end

function SharedChatContainer:ShowOptions(tabIndex)
    self:AddFadeInReference()

    CHAT_OPTIONS:Show(self, tabIndex)
end

function SharedChatContainer:LoadSettings(settings)
    self.settings = settings

    local bgR, bgG, bgB, bgMinAlpha, bgMaxAlpha = GetChatContainerColors(self.id)

    self:SetBackgroundColor(bgR, bgG, bgB, bgMinAlpha, bgMaxAlpha)

    for i=1, GetNumChatContainerTabs(self.id) do
        local name, _, _, isCombatLog = GetChatContainerTabInfo(self.id, i)
        if not self.windows[i] then
            if isCombatLog and self.system.combatLogObject then
                self:AddCombatWindow(name)
            else
                self:AddWindow(name)
            end
        end
    end

    self:FadeOut(0)

end

function SharedChatContainer:SetAllowSaveSettings(saveSettings)
    self.allowSettingsSave = saveSettings
end

function SharedChatContainer:SaveWindowSettings(tabIndex)
    if self.allowSettingsSave and self.system:CanSaveSettings() then
        local name = self:GetTabName(tabIndex)
        local locked = self:IsLocked(tabIndex)
        local interactable = self:IsInteractive(tabIndex)
        local areTimestampsEnabled = self:AreTimestampsEnabled(tabIndex)
        SetChatContainerTabInfo(self.id, tabIndex, name, locked, interactable, areTimestampsEnabled)
    end
end

function SharedChatContainer:SaveSettings()
    if self.allowSettingsSave and self.system:CanSaveSettings() then
        self.system:SaveLocalContainerSettings(self, self.control)
        local bgR, bgG, bgB = self.backdrop:GetCenterColor()
        SetChatContainerColors(self.id, bgR, bgG, bgB, self.minAlpha, self.maxAlpha)
    end
end

function SharedChatContainer:ShowContextMenu(tabIndex)
    tabIndex = tabIndex or (self.currentBuffer and self.currentBuffer:GetParent() and self.currentBuffer:GetParent().tab and self.currentBuffer:GetParent().tab.index)
    local window = self.windows[tabIndex]
    if window then
        ClearMenu()

        if not ZO_Dialogs_IsShowingDialog() then
            AddMenuItem(GetString(SI_CHAT_CONFIG_CREATE_NEW), function() self.system:CreateNewChatTab(self) end)
        end

        if not ZO_Dialogs_IsShowingDialog() and not window.combatLog and (not self:IsPrimary() or tabIndex ~= 1) then
            AddMenuItem(GetString(SI_CHAT_CONFIG_REMOVE), function() self:ShowRemoveTabDialog(tabIndex) end)
        end

        if not ZO_Dialogs_IsShowingDialog() then
            AddMenuItem(GetString(SI_CHAT_CONFIG_OPTIONS), function() self:ShowOptions(tabIndex) end)
        end

        if self:IsPrimary() and tabIndex == 1 then
            if self:IsLocked(tabIndex) then
                AddMenuItem(GetString(SI_CHAT_CONFIG_UNLOCK), function() self:SetLocked(tabIndex, false) end)
            else
                AddMenuItem(GetString(SI_CHAT_CONFIG_LOCK), function() self:SetLocked(tabIndex, true) end)
            end
        end

        if window.combatLog then
            if self:AreTimestampsEnabled(tabIndex) then
                AddMenuItem(GetString(SI_CHAT_CONFIG_HIDE_TIMESTAMP), function() self:SetTimestampsEnabled(tabIndex, false) end)
            else
                AddMenuItem(GetString(SI_CHAT_CONFIG_SHOW_TIMESTAMP), function() self:SetTimestampsEnabled(tabIndex, true) end)
            end
        end
        
        ShowMenu(window.tab)
    end
end

function SharedChatContainer:InitializeWindowManagement(control, windowPool, tabPool)
    self.windows = {}
    
    function self.MonitorTabMovementOnUpdate()
        self:MonitorTabMovement()
    end

    self.tabPool = tabPool
    self.windowPool = windowPool
    
    self.tabGroup = ZO_TabButtonGroup:New()
    self.windowContainer = control:GetNamedChild("WindowContainer")
end

function SharedChatContainer:OnDestroy()
    self.control:SetHidden(true)
    self.settings = nil
end

function SharedChatContainer:OnResizeStart()
    self.OnResizeUpdateFunc = self.OnResizeUpdateFunc or function()
        self:PerformLayout()
    end
    
    self.control:SetHandler("OnUpdate", self.OnResizeUpdateFunc)
    self.resizing = true
    self:FadeIn()
end

function SharedChatContainer:OnResizeStop()
    self:UpdateScrollVisibility()
    self.control:SetHandler("OnUpdate", nil)
    self.resizing = false
    self:SaveSettings()
    self:FadeOut()
end

function SharedChatContainer:OnMoveStop()
    self:SaveSettings()
end

function SharedChatContainer:OnMouseEnter()
    self:FadeIn()
end

function SharedChatContainer:IsMouseInside()
    if MouseIsOver(self.control) or MouseIsOver(self.overflowTab) then
        return true
    end
    
    for i=1, #self.windows do
        if MouseIsOver(self.windows[i].tab) then
            return true
        end
    end
    
    return false
end

function SharedChatContainer:MonitorForMouseExit()
    self.FadeOutCheckOnUpdate = self.FadeOutCheckOnUpdate or function()
        if not self:IsMouseInside() and not self.resizing and not self.fadeAnim:IsPlaying() and not self.isDragging then
            if not self:IsPrimary() or not self.system:IsTextEntryOpen() then
                if not self.monitoredControl then
                    self:FadeOut()
                    self.windowContainer:SetHandler("OnUpdate", nil)
                end
            end
        end
    end

    self.windowContainer:SetHandler("OnUpdate", self.FadeOutCheckOnUpdate)
end

function SharedChatContainer:FadeOut(delay)
    if self.fadeInReferences > 0 or not IsChatSystemAvailableForCurrentPlatform() then 
        return
    end

    if not self.fadeAnim then
        self.fadeAnim = ZO_AlphaAnimation:New(self.control)
    end

    self.fadeAnim:SetMinMaxAlpha(self.minAlpha, self.maxAlpha)
    self.fadeAnim:FadeOut(delay or FADE_ANIMATION_DELAY, FADE_ANIMATION_DURATION)
end

function SharedChatContainer:FadeIn(delay, fadeOption)
    if not IsChatSystemAvailableForCurrentPlatform() then
        return
    end

    if not self.fadeAnim then
        self.fadeAnim = ZO_AlphaAnimation:New(self.control)
    end

    self.fadeAnim:SetMinMaxAlpha(self.minAlpha, self.maxAlpha)
    self.fadeAnim:FadeIn(delay or 0, FADE_ANIMATION_DURATION, fadeOption)
    self:MonitorForMouseExit()

    self.currentBuffer:ShowFadedLines()
end

local OVER_FLOW_TAB_SIZE = 40
local NEW_WINDOW_TAB_SIZE = 40
local ADDITIONAL_TABS_TOTAL_SIZE = OVER_FLOW_TAB_SIZE + NEW_WINDOW_TAB_SIZE

--Lays out tabs and optionally leaves additional spacing at an index for tab dropping
function SharedChatContainer:PerformLayout(insertIndex, xOffset)
    local widthSum = TAB_STARTING_X
    local containerWidth = self.control:GetDesiredWidth()
    local numWindows = #self.windows

    self:CalculateConstraints(xOffset)
    
    self.hiddenTabStartIndex = numWindows + 1
    
    for i=1, numWindows do
        local tab = self.windows[i].tab
        local tabWidth = tab:GetDesiredWidth()
        
        tab:ClearAnchors()

        local offset = insertIndex == i and xOffset or 0
        local overflowSize = i == numWindows and 0 or ADDITIONAL_TABS_TOTAL_SIZE
        if widthSum + tabWidth + offset + overflowSize > containerWidth or i > self.hiddenTabStartIndex then
            --this tab can't fit
            if i < self.hiddenTabStartIndex then
                self.hiddenTabStartIndex = i
            end
            
            tab:SetHidden(true)
        else
            tab:SetHidden(false)
            tab:SetAnchor(BOTTOMLEFT, nil, TOPLEFT, widthSum + offset, TAB_STARTING_Y)
        end
        
        widthSum = widthSum + tabWidth + offset
    end
end

do
    local function GetTabWidth(window)
        if window and window.tab then
            return window.tab:GetWidth() + TAB_STARTING_X
        end
        return 0
    end
    function SharedChatContainer:CalculateConstraints(secondWidth)
        local width = GetTabWidth(self.windows[1]) + (secondWidth or GetTabWidth(self.windows[2])) + ADDITIONAL_TABS_TOTAL_SIZE
        local minWidth = zo_max(width, self.system.minContainerWidth)
        local maxWidth = zo_max(width + 70, self.system.maxContainerWidth)

        self.control:SetDimensionConstraints(minWidth, self.system.minContainerHeight, maxWidth, self.system.maxContainerHeight)
    end
end

function SharedChatContainer:ApplyInsertIndicator(insertIndex)
    if insertIndex and insertIndex <= self.hiddenTabStartIndex then
        local tab = self.windows[insertIndex - 1].tab
        local insertIndicator = self.system:AcquireInsertIndicator(self)
        insertIndicator:SetAnchor(CENTER, tab, RIGHT, 0, 0)
    else
        self.system:ReleaseInsertIndicator(self)
    end
end

function SharedChatContainer:UpdateOverflowArrow()
    if self.hiddenTabStartIndex <= #self.windows then
        self.overflowTab:SetHidden(false)
    else
        self.overflowTab:SetHidden(true)
    end
end

function SharedChatContainer:ShowRemoveTabDialog(index, dialogName)
    local window = self.windows[index]
    local name = ZO_TabButton_Text_GetText(window.tab)

    ZO_Dialogs_ShowDialog(dialogName, {container = self, index = index}, {mainTextParams = {name}} )
end

function SharedChatContainer:HandleTabClick(tab)
    local clickedIndex = tab.index
    local window = self.windows[clickedIndex]

    for i=1, #self.windows do
        self.windows[i]:SetHidden(clickedIndex ~= i)
    end

    self.currentBuffer = self.windows[clickedIndex].buffer
    self:UpdateInteractivity(self.currentBuffer:IsMouseEnabled())

    if(window.markedForNotification) then
        window.markedForNotification = false
        ZO_TabButton_Text_RestoreDefaultColors(window.tab)
    end
end

function SharedChatContainer:AddRawTabForWindow(window, name, index, tab)
    if not tab then
        local key
        tab, key = self.tabPool:AcquireObject()
        tab.key = key
    end
    
    tab.index = index
    tab.container = self
    
    self.tabGroup:Add(tab)
    tab:SetParent(self.control)

    local function OnTabSelected(tab)
        self:HandleTabClick(tab)
    end

    local function OnTabSizeChanged(tab)
         --Only relayout if the window has actually completed being added
        if self.currentBuffer and self.windows[tab.index] and self.windows[tab.index].tab == tab then
            if not self.monitoredControl then --Don't do any changes while monitoring for a tab drop
                self:PerformLayout()
            end
        end
    end

    ZO_TabButton_Text_Initialize(tab, "SimpleText", name, OnTabSelected, nil, OnTabSizeChanged)

    return tab
end

do
    local function SetAnchor(control, additionalXOffset, valid, point, relativeTo, relativePoint, offsetX, offsetY)
        if valid then
            control:SetAnchor(point, relativeTo, relativePoint, offsetX + additionalXOffset, offsetY)
        end
    end
    function SharedChatContainer:CopyAnchors(from, offsetX)
        self.control:ClearAnchors()
        self.control:SetDimensions(from:GetDimensions())
        SetAnchor(self.control, offsetX, from:GetAnchor(0))
        SetAnchor(self.control, offsetX, from:GetAnchor(1))
    end
end

function SharedChatContainer:TakeWindow(window, previousContainer)
    if #self.windows == 0 then
        --This container was just created due to dragging from another container
        local offsetX = window.tab:GetLeft() - previousContainer.control:GetLeft()
        self:AddRawWindow(window, ZO_TabButton_Text_GetText(window.tab), window.tab)
            
        self:CopyAnchors(previousContainer.control, offsetX)
        
        self:StartDraggingTab(1)
        self:FadeIn()
    else
        --This container already existed and this window is being dropped into it
        self:AddRawWindow(window, ZO_TabButton_Text_GetText(window.tab), window.tab, self.insertIndex)
        self.tabGroup:SetClickedButton(window.tab)
        self.insertIndex = nil
    end
    return window.tab.index
end

function SharedChatContainer:FinalizeWindowTransfer(window)
    self:RegisterCategoriesForWindow(window.tab.index)
end

function SharedChatContainer:AddRawWindow(window, name, tab, insertIndex, isCombatLog)
    if insertIndex then
        table.insert(self.windows, insertIndex, window)
        self:UpdateTabIndices(insertIndex)
    else
        self.windows[#self.windows + 1] = window
    end
        
    tab = self:AddRawTabForWindow(window, name, insertIndex or #self.windows, tab)
    
    window.buffer.container = self
    
    window:SetParent(self.windowContainer)
    window:ClearAnchors()
    window:SetAnchorFill()
    
    window.tab = tab
    tab.window = window
    
    if #self.windows == 1 then
        self.tabGroup:SetClickedButton(tab)
    end
    
    self:PerformLayout()

    self.system:OnRawWindowCreated(self, name, isCombatLog)

    if not self.system.isTransferring then
        --Must delay this until the tab is fully transferred to this container and its settings are available
        self:RegisterCategoriesForWindow(tab.index)
    end
    
    return window
end

function SharedChatContainer:RegisterCategoriesForWindow(tabIndex)
    for i=1, GetNumChatCategories() do
        if IsChatContainerTabCategoryEnabled(self.id, tabIndex, i) then
            self.system:RegisterForCategory(self, i)
        end
    end
end

function SharedChatContainer:UnregisterCategoriesForWindow(tabIndex)
    for i=1, GetNumChatCategories() do
        if IsChatContainerTabCategoryEnabled(self.id, tabIndex, i) then
            self.system:UnregisterFromCategory(self, i)
        end
    end
end

function SharedChatContainer:SetWindowFilterEnabled(tabIndex, category, enabled)
    if self.windows[tabIndex] then
        if IsChatContainerTabCategoryEnabled(self.id, tabIndex, category) ~= enabled then
            SetChatContainerTabCategoryEnabled(self.id, tabIndex, category, enabled)

            if enabled then
                self.system:RegisterForCategory(self, category)
            else
                self.system:UnregisterFromCategory(self, category)
            end
        end
    end
end

function SharedChatContainer:IsScrolledUp()
    local scrollMin, scrollMax = self.scrollbar:GetMinMax()
    local scrollCurrent = self.scrollbar:GetValue()
    if(scrollCurrent < scrollMax) then
        return true
    else
        return false
    end
end

function SharedChatContainer:OnChatEvent(event, formattedEvent, category)
    for i=1, #self.windows do
        if IsChatContainerTabCategoryEnabled(self.id, i, category) then
            self:AddEventMessageToWindow(self.windows[i], formattedEvent, category)
        end
    end
end

function SharedChatContainer:AddMessageToWindow(window, message, r, g, b, category)
    window.buffer:AddMessage(message, r, g, b, category)
    if self.currentBuffer == window.buffer then
        self:SyncScrollToBuffer()
    end

    -- Handle callout colors and flashes as needed
    if(self.system:IsMinimized()) then
        if(category == CHAT_CATEGORY_WHISPER_INCOMING) then
            self.system:StartNewChatNotification()
        end
    else
        if self.currentBuffer == window.buffer then
            if(self:IsScrolledUp()) then
                ZO_TabButton_Text_SetTextColor(window.tab, TAB_ALERT_TEXT_COLOR)
                ZO_TabButton_Text_AllowColorChanges(window.tab, false)
            end
        else
            if(category == CHAT_CATEGORY_WHISPER_INCOMING) then
                ZO_TabButton_Text_SetTextColor(window.tab, TAB_ALERT_TEXT_COLOR)
                ZO_TabButton_Text_AllowColorChanges(window.tab, false)
                window.markedForNotification = true            
            end
        end
    end
end

function SharedChatContainer:AddEventMessageToWindow(window, message, category)
    local r, g, b = GetChatCategoryColor(category)
    self:AddMessageToWindow(window, message, r, g, b, category)
end

function SharedChatContainer:AddDebugMessage(formattedEventText)
    self:AddEventMessageToWindow(self.windows[1], formattedEventText, CHAT_CATEGORY_SYSTEM)
    CALLBACK_MANAGER:FireCallbacks("OnFormattedChatEvent", formattedEventText, CHAT_CATEGORY_SYSTEM)
end

function SharedChatContainer:AddWindow(name)
    local window, key = self.windowPool:AcquireObject()
    window.key = key
    
    self:AddRawWindow(window, name)
    self:LoadWindowSettings(window)

    return window
end

function SharedChatContainer:AddCombatWindow(name)
    if self.system.combatLogObject then
        local combatLog = self.system.combatLogObject:New()
    
        local combatWindow = CreateControlFromVirtual(self.windowContainer:GetName(), self.windowContainer, combatLog:GetWindowTemplate(), "Combat")
        combatWindow.buffer = combatWindow:GetNamedChild("Buffer")
    
        local isCombatLog = true
        self:AddRawWindow(combatWindow, name, nil, nil, isCombatLog)
    
        combatLog:OnAddedToContainer(self, combatWindow)

        combatWindow.combatLog = combatLog
    
        self:LoadWindowSettings(combatWindow)

        return combatWindow, combatLog
    end
end

function SharedChatContainer:SetAsPrimary()
    self.primary = true

    self.windowContainer:ClearAnchors()
    self.windowContainer:SetAnchor(TOPRIGHT, self.scrollUpButton, TOPLEFT, 0, 0)
    self.windowContainer:SetAnchor(BOTTOMLEFT, self.system.textEntry:GetControl(), TOPLEFT, 0, -3)
end

function SharedChatContainer:IsPrimary()
    return self.primary
end

function SharedChatContainer:UpdateTabIndices(from)
    for i=from, #self.windows do
        self.windows[i].tab.index = i
    end
end

function SharedChatContainer:RemoveWindow(index, freeOption)
    local window = self.windows[index]
    
    if window then
        table.remove(self.windows, index)
        self:UpdateTabIndices(index)
        
        if self.tabGroup:GetClickedButton() == window.tab and #self.windows > 0 then
            self.tabGroup:SetClickedButton(self.windows[1].tab)
        end
        self.tabGroup:Remove(window.tab)
        self:UnregisterCategoriesForWindow(index)
        
        if freeOption == nil or freeOption == FREE then
            self.tabPool:ReleaseObject(window.tab.key)
            self.windowPool:ReleaseObject(window.key)
            if #self.windows == 0 then
                self.system:DestroyContainer(self)
            else
                self:PerformLayout()
            end

            self.system:OnRawWindowDestroyed(self, index)
        else
            self:PerformLayout()
            return window
        end
    end
end

function SharedChatContainer:TransferWindow(index, targetContainer)
    local window = self:RemoveWindow(index, DONT_FREE)
    if window then
        self.system:TransferWindow(window, self, targetContainer)
        if #self.windows == 0 then
            self.system:DestroyContainer(self)
        end
    end
end

function SharedChatContainer:StartDraggingTab(index)
    local window = self.windows[index]
    if not window or window.locked then
        return
    end

    self.isDragging = true

    if index == 1 or not self.system:MultipleContainersAllowed() then
        --this is the primary tab, just start moving it
        self.control:SetMovable(true)
        self.control:StartMoving()
        
        if not self.primary then
            self.system:PrepareContainersTabDrop(self, self.windows[index].tab)
        end
    else
        --this tab is being pulled off of the chat container
        self:TransferWindow(index)
    end
end

do
    local function FindInsertPosition(self, controlToInsert, mouseX)
        for i=2, #self.windows do
            local tab = self.windows[i].tab
            if tab:GetLeft() + tab:GetWidth() / 2 > mouseX then
                return i
            end
        end
        
        return #self.windows + 1
    end
    
    local function Contains(x, y, left, right, bottom, top)
        return left <= x 
            and x < right 
            and top <= y 
            and y < bottom
    end
    
    local function GetTabDropArea(control, tab)
        return tab:GetLeft(), control:GetRight(), tab:GetBottom(), tab:GetTop()
    end
    
    function SharedChatContainer:MonitorTabMovement()
        local monitoredControl = self.monitoredControl
        
        local x, y = GetUIMousePosition()
        if Contains(x, y, GetTabDropArea(self.control, self.windows[1].tab)) then
            self.insertIndex = FindInsertPosition(self, monitoredControl, x)
            
            --peform a layout with extra space for the potential tab
            self:PerformLayout(self.insertIndex, monitoredControl:GetWidth())
        elseif self.insertIndex then
            --reset the layout
            self:PerformLayout()
            self.insertIndex = nil
        end
    end
end

function SharedChatContainer:PrepareTabDrop(controlToMonitor)
    self.monitoredControl = controlToMonitor
    self:FadeIn()
    
    self.MonitorTabMovementOnUpdate = self.MonitorTabMovementOnUpdate or function()
        self:MonitorTabMovement() 
    end
    
    self.control:SetHandler("OnUpdate", self.MonitorTabMovementOnUpdate)
    self:MonitorTabMovement()
end

function SharedChatContainer:StopTabDrop()
    self.monitoredControl = nil
    self.control:SetHandler("OnUpdate", nil)
    self:PerformLayout()
end

function SharedChatContainer:CanTakeTabDrop()
    return self.insertIndex ~= nil
end

function SharedChatContainer:StopDraggingTab()
    self.control:StopMovingOrResizing()
    self.control:SetMovable(false)
    self.isDragging = false

    self.system:StopContainersTabDrop(self)
end

--[[ Scroll bar handling ]]--
function SharedChatContainer:InitializeScrolling(control)
    self.scrollbar = control:GetNamedChild("Scrollbar")
    self.scrollUpButton = self.scrollbar:GetNamedChild("ScrollUp")
    self.scrollDownButton = self.scrollbar:GetNamedChild("ScrollDown")
    self.scrollEndButton = self.scrollbar:GetNamedChild("ScrollEnd")
    
    self.scrollbar.container = self
end

function SharedChatContainer:SetScroll(value)
    local max = self:GetCurrentMaxScroll()
   
    self.scrollbar:SetValue(value)
    self.currentBuffer:SetScrollPosition(max - value)

    self:UpdateScrollButtons()

    if(not self:IsScrolledUp()) then
        local window = self.currentBuffer:GetParent()
        ZO_TabButton_Text_RestoreDefaultColors(window.tab)
    end
end

function SharedChatContainer:ScrollByOffset(offset)
    self:SetScroll(self.scrollbar:GetValue() + offset)
end

function SharedChatContainer:ScrollToBottom()
    self:SetScroll(self:GetCurrentMaxScroll())
end

function SharedChatContainer:GetCurrentMaxScroll()
    return self.currentBuffer:GetNumHistoryLines()
end

function SharedChatContainer:UpdateScrollVisibility()
    local visible = self.currentBuffer:GetNumVisibleLines()
    local history = self.currentBuffer:GetNumHistoryLines()
    local hide = history <= visible or self.system.platformSettings.hideScrollBar

    self.scrollbar:SetHidden(hide)
    self.scrollUpButton:SetHidden(hide)
    self.scrollDownButton:SetHidden(hide)
    self.scrollEndButton:SetHidden(hide)
end

function SharedChatContainer:SyncScrollToBuffer()
    local max = self:GetCurrentMaxScroll()

    self.scrollbar:SetMinMax(1, max)
    self.scrollbar:SetValue(max - self.currentBuffer:GetScrollPosition())

    self:UpdateScrollVisibility()    
    self:UpdateScrollButtons()
end

local function GetNewScrollButtonState(scrollButton, disabled)
    if disabled then
        return BSTATE_DISABLED, disabled
    end

    local currentState = scrollButton:GetState()
    if currentState == BSTATE_DISABLED or currentState == BSTATE_DISABLED_PRESSED then
        return BSTATE_NORMAL, disabled
    end

    return currentState, disabled
end

function SharedChatContainer:UpdateScrollButtons()
    local max = self:GetCurrentMaxScroll()
    local value = zo_round(self.scrollbar:GetValue())

    local enabled = max > 1

    if not enabled then
        --force the scroll bar to look like its at the bottom
        self.scrollbar:SetMinMax(0, 1)
        self.scrollbar:SetValue(1)
    end

    self.scrollbar:SetEnabled(enabled)
    
    local upDisabled = not enabled or value == 1
    self.scrollUpButton:SetState(GetNewScrollButtonState(self.scrollUpButton, upDisabled))
    
    local downDisabled = not enabled or value == max
    self.scrollDownButton:SetState(GetNewScrollButtonState(self.scrollDownButton, downDisabled))
    self.scrollEndButton:SetState(GetNewScrollButtonState(self.scrollEndButton, downDisabled))
end

function SharedChatContainer:GetChatFontFormatString(fontSize)
    local face = self:GetChatFont():GetFontInfo()
    local shadowStyle = "soft-shadow-thick"
    if fontSize <= 14 then
        shadowStyle = "soft-shadow-thin"
    end

    local fontSizeString = CHAT_SYSTEM:GetFontSizeString(fontSize)
    return ("%s|%s|%s"):format(face, fontSizeString, shadowStyle)
end

function SharedChatContainer:GetChatFont()
    -- Should be overridden
end

--
--[[ Chat System ]]--
--

SharedChatSystem = ZO_Object:Subclass()

function SharedChatSystem:New(...)
    local chat = ZO_Object.New(self)
    chat:Initialize(...)
    
    return chat
end

function SharedChatSystem:Initialize(control, platformSettings)
    self.control = control
    self.platformSettings = platformSettings

    self.textEntry = TextEntry:New(self, control:GetNamedChild("TextEntry"), platformSettings.chatEditBufferTop, platformSettings.chatEditBufferBottom)

    local fontSize = self:GetFontSizeFromSetting()
    local textEntryFont = self:GetTextEntryFontString(fontSize)
    self:SetTextEntryFont(textEntryFont)

    self:CreateChannelData()

    self:InitializeSharedControlManagement(control)
    self:InitializeEventManagement()

    self.commandPrefixes = {}
    self.currentNumNotifications = 0
    self.numUnreadMails = 0
    self:OnNumUnreadMailChanged(GetNumUnreadMail())
    self.isAgentChatActive = false
    self:OnAgentChatActiveChanged()
    self.isMinimized = false
    self.allowMultipleContainers = false

    self.minContainerWidth = 300
    self.maxContainerWidth = 550
    self.minContainerHeight = 170
    self.maxContainerHeight = 380

    if IsChatSystemAvailableForCurrentPlatform() then
        LINK_HANDLER:RegisterCallback(LINK_HANDLER.INSERT_LINK_EVENT, self.HandleTryInsertLink, self)
        LINK_HANDLER:RegisterCallback(LINK_HANDLER.LINK_CLICKED_EVENT, self.OnLinkClicked, self)
        LINK_HANDLER:RegisterCallback(LINK_HANDLER.LINK_MOUSE_UP_EVENT, self.OnLinkClicked, self)
    end
end

function SharedChatSystem:CreateChannelData()
    self.switchLookup = {}
    self.targets = {}

    self.channelData = {}
    for channel, data in pairs(ChannelInfo) do
        data.id = channel

        self.channelData[channel] = data

        if data.switches then
            for switchArg in data.switches:gmatch("%S+") do
                switchArg = switchArg:lower()
                self.switchLookup[switchArg] = data
                if not self.switchLookup[channel] then
                    self.switchLookup[channel] = switchArg
                end
            end
        end

        if data.targetSwitches then
            local targetData = ZO_ShallowTableCopy(data)
            targetData.target = channel
            for switchArg in data.targetSwitches:gmatch("%S+") do
                switchArg = switchArg:lower()
                self.switchLookup[switchArg] = targetData
                if not self.switchLookup[channel] then
                    self.switchLookup[channel] = switchArg
                end
            end
        end
    end
end

function SharedChatSystem:InitializeSharedControlManagement(control, newContainerFn)
    local function TabFactoryFunc(tabControl)
        tabControl:GetNamedChild("Text"):SetHidden(self.platformSettings.hideTabs)
    end

    self.containers = {}
        
    self.tabPool = ZO_ControlPool:New("ZO_ChatWindowTabTemplate")
    self.tabPool:SetCustomFactoryBehavior(TabFactoryFunc)
    
    local function CreateWindow(objectPool) 
        local window = ZO_ObjectPool_CreateControl("ZO_ChatWindowTemplate", objectPool, GuiRoot)
        window.buffer = window:GetNamedChild("Buffer")
        window.buffer:SetHorizontalAlignment(self.platformSettings.horizontalAlignment)
        window.buffer:SetLinesInheritAlpha(self.platformSettings.linesInheritAlpha)
        return window
    end

    local function ResetWindowControl(windowControl)
        ZO_ObjectPool_DefaultResetControl(windowControl)
        windowControl.buffer:Clear()
    end
    
    self.windowPool = ZO_ObjectPool:New(CreateWindow, ResetWindowControl)
    self.insertIndicator = control:GetNamedChild("InsertIndicator")
    self.agentChatButton = control:GetNamedChild("AgentChat")
    self.agentChatGlow = self.agentChatButton:GetNamedChild("Glow")

    local agentChatBurst = self.agentChatButton:GetNamedChild("Burst")
    self.agentChatBurstTimeline = ANIMATION_MANAGER:CreateTimelineFromVirtual("NotificationAddedBurst", agentChatBurst)
    self.agentChatBurstTimeline:SetHandler("OnStop", function() agentChatBurst:SetAlpha(0) end)

    local agentChatEcho = self.agentChatButton:GetNamedChild("Echo")
    self.agentChatPulseTimeline = ANIMATION_MANAGER:CreateTimelineFromVirtual("NotificationPulse", agentChatEcho)
    self.agentChatPulseTimeline:SetHandler("OnStop", function() agentChatEcho:SetAlpha(0) end)

    local function CreateContainer(objectPool)
        local containerControl = ZO_ObjectPool_CreateControl("ZO_ChatContainerTemplate", objectPool, GuiRoot) 
        return newContainerFn(self, containerControl, self.windowPool, self.tabPool)
    end
    
    self.containerPool = ZO_ObjectPool:New(CreateContainer, function(container) container:OnDestroy() end)
end

function SharedChatSystem:InitializeEventManagement()
    self.categories = {}

    local savedVariablesReady = false
    local playerActivated = false
    self.loaded = false

    local function TryLoadingSettings()
        if savedVariablesReady and playerActivated and not self.loaded then
            self:LoadChatFromSettings()
        end
    end

    local function OnAddOnLoaded(event, name)
        if name == "ZO_Ingame" then
            savedVariablesReady = true
            TryLoadingSettings()
        end
    end

    local function OnPlayerActivated()
        playerActivated = true
        TryLoadingSettings()

        if IsChatSystemAvailableForCurrentPlatform() then
            if(not self.allowMultipleContainers) then
                self:RedockContainersToPrimary()
            end

            self:TryNotificationAndMailBursts()

            if(self.isAgentChatActive) then
                self.agentChatBurstTimeline:PlayFromStart()
            end
        else
            self.control:SetHidden(true)
        end
    end
    
    EVENT_MANAGER:RegisterForEvent("ChatSystem_OnAddOnLoaded", EVENT_ADD_ON_LOADED, OnAddOnLoaded)
    EVENT_MANAGER:RegisterForEvent("ChatSystem", EVENT_PLAYER_ACTIVATED, OnPlayerActivated)

    if IsChatSystemAvailableForCurrentPlatform() then
        local function OnChatEvent(...)
            self:OnChatEvent(...)
        end

        --Special events (dialogs etc)
        local function OnChannelInvite(eventCode, channelName, playerName)
            ZO_Dialogs_ShowDialog("CHANNEL_INVITE", {channelName = channelName}, {mainTextParams = {channelName, playerName}})
        end

        local function OnZoneChannelChanged()
            self:UpdateTextEntryChannel()
        end

        local function OnAgentChatActiveChanged()
            self:OnAgentChatActiveChanged()
        end
        
        EVENT_MANAGER:RegisterForEvent("ChatSystem", EVENT_CHAT_CHANNEL_INVITE, OnChannelInvite)
        EVENT_MANAGER:RegisterForEvent("ChatSystem", EVENT_ZONE_CHANNEL_CHANGED, OnZoneChannelChanged)
        EVENT_MANAGER:RegisterForEvent("ChatSystem", EVENT_GUILD_DATA_LOADED, function() self:ValidateChatChannel() end)
        EVENT_MANAGER:RegisterForEvent("ChatSystem", EVENT_GUILD_RANK_CHANGED, function() self:ValidateChatChannel() end)
        EVENT_MANAGER:RegisterForEvent("ChatSystem", EVENT_GUILD_RANKS_CHANGED, function() self:ValidateChatChannel() end)
        EVENT_MANAGER:RegisterForEvent("ChatSystem", EVENT_GUILD_MEMBER_RANK_CHANGED, function() self:ValidateChatChannel() end)
        EVENT_MANAGER:RegisterForEvent("ChatSystem", EVENT_MAIL_NUM_UNREAD_CHANGED, function(_, numUnread) self:OnNumUnreadMailChanged(numUnread) end)
        EVENT_MANAGER:RegisterForEvent("ChatSystem", EVENT_AGENT_CHAT_REQUESTED, OnAgentChatActiveChanged)
        EVENT_MANAGER:RegisterForEvent("ChatSystem", EVENT_AGENT_CHAT_FORCED, OnAgentChatActiveChanged)
        EVENT_MANAGER:RegisterForEvent("ChatSystem", EVENT_AGENT_CHAT_TERMINATED, OnAgentChatActiveChanged)

        for event in pairs(ChatEventFormatters) do
            EVENT_MANAGER:RegisterForEvent("ChatSystem_OnEventId" .. event, event, OnChatEvent)
        end
    end
end

function SharedChatSystem:TryNotificationAndMailBursts()
    -- Overridden if applicable
end

function SharedChatSystem:LoadChatFromSettings(newContainerFn, defaults)
    self.suppressSave = true

    self:SetupSavedVars(defaults)

    self.primaryContainer = self:CreateChatContainer(newContainerFn(self, self.control, self.windowPool, self.tabPool))
    self.primaryContainer:SetAsPrimary()

    for i=2, GetNumChatContainers() do
        self:CreateChatContainer()
    end

    self.suppressSave = false

    self:SetChannel(CHAT_CHANNEL_SAY)
    self.loaded = true
end

function SharedChatSystem:SetupSavedVars(defaults)
    -- Overridden if applicable
end

function SharedChatSystem:RedockContainersToPrimary()
    for i=2, #self.containers do
        -- Grab the second container, the first is always the primary
        local container = self.containers[2]
        -- move all tabs to the primary container
        for j=1, #container.windows do
            container:TransferWindow(1, self.primaryContainer)
        end
    end
end


function SharedChatSystem:CanSaveSettings()
    return not self.suppressSave
end

function SharedChatSystem:SaveLocalContainerSettings(container, containerControl)
    -- Overridden if applicable
end

function SharedChatSystem:AcquireInsertIndicator(container)
    self.insertIndicator.owner = container
    self.insertIndicator:SetHidden(false)
    self.insertIndicator:ClearAnchors()
    return self.insertIndicator
end

function SharedChatSystem:ReleaseInsertIndicator(container)
    if self.insertIndicator.owner == container then
        self.insertIndicator.owner = nil
        self.insertIndicator:SetHidden(true)
    end
end

function SharedChatSystem:RegisterForCategory(container, category)
    if not self.categories[category] then
        self.categories[category] = {}
    end
    
    self.categories[category][container] = (self.categories[category][container] or 0) + 1
end

function SharedChatSystem:StartNewChatNotification()
    local platformSettings = self.platformSettings
    self.newChatFadeAnim:PingPong(platformSettings.initialFadeAlpha, platformSettings.finalFadeAlpha, platformSettings.fadeTransitionTime, platformSettings.numBlinks)
end

function SharedChatSystem:UnregisterFromCategory(container, category)
    local categories = self.categories[category]
    if categories then
        if categories[container] then
            if categories[container] == 1 then
                categories[container] = nil
            else
                categories[container] = categories[container] - 1
            end
            
            if not next(categories) then
                self.categories[category] = nil
            end
        end
    end
end

function SharedChatSystem:HandleNewTargetOnChannel(event, targetChannel, _, target)
    if not self.targets[targetChannel] then
        self.targets[targetChannel] = ChannelTarget:New()
    end
    self.targets[targetChannel]:AddTarget(zo_strformat(SI_UNIT_NAME, target))
end

function SharedChatSystem:GetCategoryFromEvent(event, messageType)
    if SimpleEventToCategoryMappings[event] then
        return SimpleEventToCategoryMappings[event]
    end
    if MultiLevelEventToCategoryMappings[event] then
        return MultiLevelEventToCategoryMappings[event][messageType]
    end
end

function SharedChatSystem:OnChatEvent(event, ...)
    local category = self:GetCategoryFromEvent(event, ...)
    if self.categories[category] then
        local formatter = ChatEventFormatters[event]
        if formatter then
            local formattedEventText, targetChannel, fromDisplayName, rawMessageText = formatter(...)
            if formattedEventText then
                if targetChannel then
                    self:HandleNewTargetOnChannel(event, targetChannel, ...)
                end
                for container in pairs(self.categories[category]) do
                    container:OnChatEvent(event, formattedEventText, category)
                end

                CALLBACK_MANAGER:FireCallbacks("OnFormattedChatEvent", formattedEventText, category, targetChannel, fromDisplayName, rawMessageText)
            end
        end
    end
end

function SharedChatSystem:UpdateContainerIndices(start)
    for i=start, #self.containers do
        self.containers[i].id = i
    end
end

function SharedChatSystem:DestroyContainer(container)
    --invalid state, can't destroy a container with windows
    assert(#container.windows == 0)
    --invalid state, primary containers should never be destroyed
    assert(not container:IsPrimary())
    
    if not self.suppressSave then
        RemoveChatContainer(container.id)
    end
    table.remove(self.containers, container.id)
    self:RemoveSavedContainer(container)
    self:UpdateContainerIndices(container.id)
    self.containerPool:ReleaseObject(container.key)
end

function SharedChatSystem:RemoveSavedContainer(container)
    -- Overridden if applicable
end

function SharedChatSystem:TransferWindow(window, previousContainer, targetContainer)
    local container = targetContainer or self:CreateChatContainer()
    
    self.isTransferring = true
    local tabIndex = window.tab.index
    local newTabIndex = container:TakeWindow(window, previousContainer)

    if not self.suppressSave then
        TransferChatContainerTab(previousContainer.id, tabIndex, container.id, newTabIndex)
    end

    container:FinalizeWindowTransfer(window)

    self.isTransferring = false
end

function SharedChatSystem:OnRawWindowCreated(container, name, isCombatLog)
    self.hasCombatLog = self.hasCombatLog or isCombatLog
    if not self.suppressSave and not self.isTransferring then
        AddChatContainerTab(container.id, name, isCombatLog)
    end
end

function SharedChatSystem:OnRawWindowDestroyed(container, tabIndex)
    if not self.suppressSave then
        RemoveChatContainerTab(container.id, tabIndex)
    end
end

function SharedChatSystem:AddCombatLog(name)
    if not self.hasCombatLog then
        return self.primaryContainer:AddCombatWindow(name)
    end
    return false
end

function SharedChatSystem:SetCombatLogObject(combatLogObject)
    self.combatLogObject = combatLogObject
end

function SharedChatSystem:PrepareContainersTabDrop(initiator, controlToMonitor)
    for i, container in ipairs(self.containers) do
        if container ~= initiator then
            container:PrepareTabDrop(controlToMonitor)
        end
    end
end

function SharedChatSystem:StopContainersTabDrop(initiator)
    local tabDropContainer
    for i, container in ipairs(self.containers) do
        if container ~= initiator then
            if not tabDropContainer and container:CanTakeTabDrop() then
                tabDropContainer = container
            end
            container:StopTabDrop()
        end
    end
    
    if tabDropContainer then
        --It's always the first window since that's the only draggable tab
        initiator:TransferWindow(1, tabDropContainer)
    end
end

function SharedChatSystem:SetAllowMultipleContainers(allow)
    self.allowMultipleContainers = allow
end

function SharedChatSystem:MultipleContainersAllowed()
    return self.allowMultipleContainers
end

function SharedChatSystem:CreateChatContainer(container)
    if not container then
        local key
        container, key = self.containerPool:AcquireObject()
        container.key = key
        container.control:SetHidden(false)
    end

    local id = #self.containers + 1
    self.containers[id] = container
    container.id = id

    if not self.suppressSave then
        AddChatContainer()
    end
    container:LoadSettings(self.sv and self.sv.containers[id])

    return container
end

function SharedChatSystem:ResetContainerPositionAndSize(container)
    -- Should be overridden
end

function SharedChatSystem:HandleTryInsertLink(link)
    return self.textEntry:InsertLink(link)
end

function SharedChatSystem:AddMessage(text)
    if IsChatSystemAvailableForCurrentPlatform() and self.primaryContainer then
        self.primaryContainer:AddDebugMessage(text)
    end
end

function SharedChatSystem:IsTextEntryOpen()
    return self.textEntry:IsOpen()
end

function SharedChatSystem:ValidateChatChannel()
    --Check the requirement again, just incase something has changed since the switch was activated
    if self.channelRequirement and not self.channelRequirement(self.currentChannel) then
        --if it isn't valid, try to revert to the last valid channel
        local lastChannelData = self.channelData[self.lastValidChannel]
        if(not lastChannelData.requires or lastChannelData.requires(lastChannelData.id)) then
            self:SetChannel(self.lastValidChannel, self.lastValidTarget)
        else
            --if that doesn't work, just revert to say
            self:SetChannel(CHAT_CHANNEL_SAY)
            self.lastValidChannel = CHAT_CHANNEL_SAY
            self.lastValidTarget = nil
        end
        
        if self.requirementErrorMessage then
            if type(self.requirementErrorMessage) == "string" then
                self:AddMessage(self.requirementErrorMessage)
            elseif type(self.requirementErrorMessage) == "function" then
                self:AddMessage(self.requirementErrorMessage())
            end
        end

        return false
    else
        --even if the chat channel is still valid, its name may have changed
        local channelData = self.channelData[self.currentChannel]
        if channelData then
            --if it did change, don't send this
            if(self.textEntry:SetChannel(channelData, self.currentTarget)) then
                return false
            end
        end
    end

    return true --appears to be valid
end

function SharedChatSystem:SubmitTextEntry()
    local text = self.textEntry:GetText()
    self.textEntry:Close()
    
    if IsChatSystemAvailableForCurrentPlatform() and #text > 0 then
        self.textEntry:AddCommandHistory(text)

        local switch, valid, switchArg, deferredError = self:TextToSwitchData(text, false)
        if switch and valid then
            self:SetChannel(switch.id, switchArg)
            if deferredError then
                -- Validate immediately to run the custom error
                self.requirementErrorMessage = switch.requirementErrorMessage
                self:ValidateChatChannel()
            else
                self.requirementErrorMessage = nil
            end
        else
            local prefix = text:byte(1)
            if self.commandPrefixes[prefix] then
                self.commandPrefixes[prefix](text)
            else
                if self:ValidateChatChannel() then
                    ZO_Menu_SetLastCommandWasFromMenu(false)
                    SendChatMessage(text, self.currentChannel, self.currentTarget)
                end
            end
        end
    else
        self:ValidateChatChannel()
    end
end

function SharedChatSystem:CloseTextEntry(keepText)
    self.textEntry:Close(keepText)

    if(self.shouldMinimizeAfterEntry) then
        self:Minimize()
    end
end

function SharedChatSystem:OnAutoCompleteEntrySelected(target)
    if self.pendingChannel then
        self:SetChannel(self.pendingChannel, target)
    end
end

function SharedChatSystem:ValidateTargetName(name)
    return (name:match("^%S+$") ~= nil)
end

function SharedChatSystem:ValidateSwitch(switch, text, firstSpaceStart, inferTargetEnd)
    if switch then
        if switch.target then
            -- Either get the arguments from the text or from an channel target
            local switchArg
            local finalSpace
            if switch.target == true then
                if not firstSpaceStart then
                    -- No space means we can't have a target specified
                    return false
                end

                self.pendingChannel = switch.id
                --No channel, just a target requirement
                local doAutoComplete = true
                local secondWordStart = firstSpaceStart + 1
                local isDisplayName = text:byte(secondWordStart) == DISPLAY_NAME_PREFIX_BYTE
                if inferTargetEnd then
                    -- Don't look for a second space if the target begins with a display name flag char
                    if isDisplayName then
                        local secondSpaceStart, secondSpaceEnd = zo_strfind(text, " ", secondWordStart, true)
                        if secondSpaceStart and secondSpaceStart > 1 then
                            finalSpace = secondSpaceStart
                            if(self:ValidateTargetName(zo_strsub(text, secondWordStart + 1, secondSpaceStart - 1))) then 
                                switchArg = zo_strsub(text, secondWordStart, secondSpaceStart - 1)
                                doAutoComplete = false
                            end
                        end
                    else
                        -- Look for the comma as the final delimiter (character names can have multiple spaces)
                        local commaStart, commaEnd = zo_strfind(text, ",", secondWordStart + 1, true)
                        if commaStart and commaStart > 1 then
                            finalSpace = commaEnd
                            switchArg = zo_strsub(text, secondWordStart, commaStart - 1)
                            doAutoComplete = false
                        end
                    end
                else
                    local potentialSwitchArg = zo_strsub(text, secondWordStart)
                    if potentialSwitchArg ~= "" then
                        if isDisplayName and not self:ValidateTargetName(zo_strsub(potentialSwitchArg, 2)) then
                            potentialSwitchArg = nil
                        end

                        if potentialSwitchArg ~= nil then
                            finalSpace = zo_strlen(text)
                            switchArg = potentialSwitchArg
                            doAutoComplete = false
                        end
                    end
                end

                if doAutoComplete then
                    self.textEntry:AutoCompleteTarget(zo_strsub(text, secondWordStart))
                end
            elseif self.targets[switch.target] then
                --Channel target
                switchArg = self.targets[switch.target]:GetLastTarget()
            end
                
            if switchArg and switchArg ~= "" then 
                --Valid, Channel Argument, No errors, Override the beginning of the switch
                return true, switchArg, false, finalSpace
            end
        elseif switch.requires then
            if switch.requires(switch.id) then
                --Valid, no args, no errors
                return true
            else
                --Only valid if the requirement is getting deferred, no args, deferred if the channel defers the error
                return switch.deferRequirement, nil, switch.deferRequirement
            end
        else
            --No requirements to meet, the switch is valid
            return true
        end
    end

    --No valid switch
    return false
end

function SharedChatSystem:TextToSwitchData(text, inferTargetEnd)
    local lowerText = text:lower()
    local switch = self.switchLookup[lowerText]
    local isValid = false
    local switchArg = nil
    local deferredError = nil
    local spaceStart = nil
    if not switch then
        spaceStart = zo_strfind(lowerText, " ", 1, true)
        if spaceStart and spaceStart > 1 then
            local potentialSwitch = zo_strsub(lowerText, 1, spaceStart - 1)
            switch = self.switchLookup[potentialSwitch:lower()]
        end
    end

    if switch then
        local spaceStartOverride = nil
        isValid, switchArg, deferredError, spaceStartOverride = self:ValidateSwitch(switch, text, spaceStart, inferTargetEnd)
        spaceStart = spaceStartOverride or spaceStart
    end

    return switch, isValid, switchArg, deferredError, spaceStart
end

function SharedChatSystem:OnTextEntryChanged(newText)
    if self.ignoreTextEntryChangedEvent then return end
    self.ignoreTextEntryChangedEvent = true
    
    local switch, valid, switchArg, deferredError, spaceStart = self:TextToSwitchData(newText, true)

    if spaceStart and spaceStart > 1 then
        if switch and valid then
            if(deferredError) then
                self.requirementErrorMessage = switch.requirementErrorMessage
            else
                self.requirementErrorMessage = nil
            end

            self:SetChannel(switch.id, switchArg)

            local oldCursorPos = self.textEntry:GetCursorPosition()

            self.textEntry:SetText(zo_strsub(newText, spaceStart + 1))
            self.textEntry:SetCursorPosition(oldCursorPos - spaceStart)
        end
    else
        if self.suppressAutoCompleteClear then
            self.suppressAutoCompleteClear = false
        else
            self.textEntry:CloseAutoComplete()
        end
    end
    
    self.ignoreTextEntryChangedEvent = false
end

function SharedChatSystem:FindNextTargetForCurrentChannel()
    if self.targets[self.currentChannel] then
        local target = self.targets[self.currentChannel]:GetNextTarget()
        if target and target ~= "" then
            self:SetChannel(self.currentChannel, target)
        end
    end
end

function SharedChatSystem:FindPreviousTargetForCurrentChannel()
    if self.targets[self.currentChannel] then
        local target = self.targets[self.currentChannel]:GetPreviousTarget()
        if target and target ~= "" then
            self:SetChannel(self.currentChannel, target)
        end
    end
end

STUB_SETTING_KEEP_MINIMIZED = false

ZO_CHAT_BLOCKING_SCENE_NAMES =
{
    ["gamepad_market_pre_scene"] = true,
    ["gamepad_market"] = true,
    ["gamepad_market_preview"] = true,
}

function SharedChatSystem:StartTextEntry(text, channel, target, dontShowHUDWindow)
    --Don't allow text entry to start if the ingame gui is hidden. This fixes an issue where users could no longer enter text if "]" or "/" were pressed while the ingame gui was hidden.
    if GetGuiHidden("ingame") then
        return
    end

    if IsPlayerActivated() then
        local currentSceneName = SCENE_MANAGER:GetCurrentSceneName()
        if currentSceneName and ZO_CHAT_BLOCKING_SCENE_NAMES[currentSceneName] then
            return
        end

        if not self.currentChannel or channel then
            self:SetChannel(channel or CHAT_CHANNEL_SAY, target)   
        end

        self.textEntry:Open(text)

        if not dontShowHUDWindow then
            if(self.isMinimized) then
                self:Maximize()
                self.shouldMinimizeAfterEntry = STUB_SETTING_KEEP_MINIMIZED
            else
                self.primaryContainer:FadeIn()
                self.shouldMinimizeAfterEntry = false
            end
        end
    end
end

function SharedChatSystem:AutoSendTextEntry(text, channel, target, dontShowHUDWindow)
    self:StartTextEntry(text, channel, target, dontShowHUDWindow)
    self:SubmitTextEntry()
end

function SharedChatSystem:ReplyToLastTarget(channelType)
    if self.targets[channelType] then
        local target = self.targets[channelType]:GetLastTarget()
        if target and target ~= "" then
            self:StartTextEntry("", channelType, target)
        end
    end
end

function SharedChatSystem:GetCategoryColorFromChannel(channel)
    return GetChatCategoryColor(MultiLevelEventToCategoryMappings[EVENT_CHAT_MESSAGE_CHANNEL][channel])
end

function SharedChatSystem:SetChannel(newChannel, channelTarget)
    newChannel = newChannel or CHAT_CHANNEL_SAY
    local channelData = self.channelData[newChannel]

    if(self.currentChannel) then
        if(self.textEntry:IsOpen()) then
            self.textEntry:GetEditControl():TakeFocus()
        else
            self.textEntry:Close()
        end
    end

    if channelData and (newChannel ~= self.currentChannel or channelTarget ~= self.currentTarget) then
        self.lastValidChannel = self.currentChannel
        self.lastValidTarget = self.currentTarget    
                    
        self.channelRequirement = channelData.requires
        self.currentChannel = newChannel
        self.currentTarget = channelTarget

        self:UpdateTextEntryChannel()
    end

    --Check for trial limitations
    GetTrialChatIsRestrictedAndWarn(newChannel, channelTarget)
    CALLBACK_MANAGER:FireCallbacks("OnChatSetChannel")
end

function SharedChatSystem:GetCurrentChannelData()
    if not self.currentChannel then
        self:SetChannel(CHAT_CHANNEL_SAY)
    end
    local channelData = self.channelData[self.currentChannel]
    return channelData, self.currentTarget
end

function SharedChatSystem:SetContainerExtents(minWidth, maxWidth, minHeight, maxHeight)
    self.minContainerWidth = minWidth
    self.maxContainerWidth = maxWidth
    self.minContainerHeight = minHeight
    self.maxContainerHeight = maxHeight
end

function SharedChatSystem:UpdateTextEntryChannel()
    local channelData = self.channelData[self.currentChannel]
    if channelData then
        self.textEntry:SetChannel(channelData, self.currentTarget)
        self.textEntry:SetColor(self:GetCategoryColorFromChannel(self.currentChannel))
    end
end

function SharedChatSystem:AddCommandPrefix(prefixCharacter, callback)
    local characterByte = (prefixCharacter or ""):byte(1)
    if characterByte then
        self.commandPrefixes[characterByte] = callback
    end
end

-- playerName is a decorated display name or a formatted character name
-- rawName is the unformatted/undecorated version of playerName
function SharedChatSystem:ShowPlayerContextMenu(playerName, rawName)
    ClearMenu()

    -- Add to/Remove from Group
    if IsGroupModificationAvailable() then
        local localPlayerIsGrouped = IsUnitGrouped("player")
        local localPlayerIsGroupLeader = IsUnitGroupLeader("player")
        local otherPlayerIsInPlayersGroup = IsPlayerInGroup(rawName)
        if not localPlayerIsGrouped or (localPlayerIsGroupLeader and not otherPlayerIsInPlayersGroup) then
            AddMenuItem(GetString(SI_CHAT_PLAYER_CONTEXT_ADD_GROUP), function()
            local SENT_FROM_CHAT = false
            local DISPLAY_INVITED_MESSAGE = true
            TryGroupInviteByName(playerName, SENT_FROM_CHAT, DISPLAY_INVITED_MESSAGE) end)
        elseif otherPlayerIsInPlayersGroup and localPlayerIsGroupLeader then
            AddMenuItem(GetString(SI_CHAT_PLAYER_CONTEXT_REMOVE_GROUP), function() GroupKickByName(rawName) end)
        end
    end

    -- Whisper
    AddMenuItem(GetString(SI_CHAT_PLAYER_CONTEXT_WHISPER), function() self:StartTextEntry(nil, CHAT_CHANNEL_WHISPER, playerName) end)

    -- Ignore
    local function IgnoreSelectedPlayer()
        if not IsIgnored(playerName) then
            AddIgnore(playerName)
        end
    end

    if not IsIgnored(playerName) then
        AddMenuItem(GetString(SI_CHAT_PLAYER_CONTEXT_ADD_IGNORE), IgnoreSelectedPlayer)
    end

    -- Add Friend
    if not IsFriend(playerName) then
        AddMenuItem(GetString(SI_CHAT_PLAYER_CONTEXT_ADD_FRIEND), function() ZO_Dialogs_ShowDialog("REQUEST_FRIEND", { name = playerName }) end)
    end

    -- Report player
    AddMenuItem(zo_strformat(SI_CHAT_PLAYER_CONTEXT_REPORT, rawName), function()
        ZO_HELP_GENERIC_TICKET_SUBMISSION_MANAGER:OpenReportPlayerTicketScene(playerName, IgnoreSelectedPlayer)
    end)

    if ZO_Menu_GetNumMenuItems() > 0 then
        ShowMenu()
    end
end

function SharedChatSystem:OnLinkClicked(link, button, text, color, linkType, ...)
    if linkType == CHARACTER_LINK_TYPE then
        local rawName = select(1, ...)
        local characterName = zo_strformat(SI_UNIT_NAME, rawName)
        if characterName ~= GetUnitName("player") then
            if button == MOUSE_BUTTON_INDEX_LEFT then
                IgnoreMouseDownEditFocusLoss()
                self:StartTextEntry(nil, CHAT_CHANNEL_WHISPER, characterName)
            elseif button == MOUSE_BUTTON_INDEX_RIGHT then
                self:ShowPlayerContextMenu(characterName, rawName)
            end
        end
        return true
    elseif linkType == DISPLAY_NAME_LINK_TYPE then
        local displayName = ...
        local decoratedDisplayName = zo_strformat("<<1>>", DecorateDisplayName(displayName))
        if decoratedDisplayName ~= GetDisplayName() then
            if button == MOUSE_BUTTON_INDEX_LEFT then
                IgnoreMouseDownEditFocusLoss()
                self:StartTextEntry(nil, CHAT_CHANNEL_WHISPER, decoratedDisplayName)
            elseif button == MOUSE_BUTTON_INDEX_RIGHT then
                self:ShowPlayerContextMenu(decoratedDisplayName, displayName)
            end
        end
        return true
    elseif linkType == CHANNEL_LINK_TYPE then
        local channelName = ...
        local channelId = GetChatChannelId(channelName)
        if button == MOUSE_BUTTON_INDEX_LEFT then
            IgnoreMouseDownEditFocusLoss()
            self:StartTextEntry(nil, channelId)
        end
        return true
    end
end

function SharedChatSystem:CreateNewChatTab(container)
    local newTab = container:AddWindow(GetString(SI_CHAT_DIALOG_NEW_TAB))
    container:ShowOptions(newTab.tab.index)
end

function SharedChatSystem:SetTextEntryFont(font)
    self.textEntry:SetFont(font)
end

function SharedChatSystem:SetChannelCategoryColor(categoryId, red, green, blue)
    local textEntryCategoryId = MultiLevelEventToCategoryMappings[EVENT_CHAT_MESSAGE_CHANNEL][self.currentChannel]

    if textEntryCategoryId == categoryId then
        self.textEntry:SetColor(red, green, blue)
    end

    for i=1, #self.containers do
        self.containers[i]:SetBufferColor(categoryId, red, green, blue)
    end
end

function SharedChatSystem:ResetAllColorsToDefault()
    for i=1, GetNumChatCategories() do
        ResetChatCategoryColorToDefault(i)
        local r, g, b = GetChatCategoryColor(i)
        self:SetChannelCategoryColor(i, r, g, b)
    end
end

function SharedChatSystem:ResetChannelCategoryToDefault(categoryId)
    ResetChatCategoryColorToDefault(categoryId)
    local r, g, b = GetChatCategoryColor(categoryId)
    self:SetChannelCategoryColor(categoryId, r, g, b)
end

function SharedChatSystem:SetFontSize(fontSize)
    for containerIndex=1, #self.containers do
        local container = self.containers[containerIndex]
        for tabIndex = 1, #container.windows do
            container:SetFontSize(tabIndex, fontSize)
        end
    end

    local textEntryFont = self:GetTextEntryFontString(fontSize)
    self:SetTextEntryFont(textEntryFont)
end

function SharedChatSystem:ResetFontSizeToDefault()
    ResetChatFontSizeToDefault()
    local fontSize = self:GetFontSizeFromSetting()
    self:SetFontSize(fontSize)
end

function SharedChatSystem:SetMinAlpha(minAlpha)
    for containerIndex=1, #self.containers do
        local container = self.containers[containerIndex]
        container:SetMinAlpha(minAlpha)
    end
end

function SharedChatSystem:GetMinAlpha()
    return self.primaryContainer:GetMinAlpha()
end

function SharedChatSystem:ResetMinAlphaToDefault()
    for containerIndex=1, #self.containers do
        local container = self.containers[containerIndex]
        container:ResetMinAlphaToDefault()
    end
end

function SharedChatSystem:ShowTextEntryMenu()
    ClearMenu()
    
    --Prepare switches for sorting
    local switches = {}
    for channel in pairs(self.channelData) do
        local switch = self.switchLookup[channel]
        if switch then
            switches[#switches + 1] = switch
        end
    end

    table.sort(switches)

    --Display sorted switches
    for i=1, #switches do
        local switch = switches[i]
        local data = self.switchLookup[switch]
        if data and (not data.requires or data.requires(data.id)) then
            local r, g, b = self:GetCategoryColorFromChannel(data.id)
            local itemColor = ZO_ColorDef:New(r, g, b)

            if data.target then
                AddMenuItem(switch, function() self:StartTextEntry(switch .. " ") end, nil, nil, itemColor)
            else
                AddMenuItem(switch, function() self:StartTextEntry(self.textEntry:GetText(), data.id) end, nil, nil, itemColor)
            end
        end
    end

    ShowMenu(self.textEntry:GetControl())
end

function SharedChatSystem:IsAutoCompleteOpen()
    return self.textEntry:IsAutoCompleteOpen()
end

function SharedChatSystem:CloseAutoComplete()
    self.textEntry:CloseAutoComplete()
end

function SharedChatSystem:GetEditControl()
    return self.textEntry:GetEditControl()
end

function SharedChatSystem:OnNumNotificationsChanged(numNotifications)
    if(numNotifications > self.currentNumNotifications and IsPlayerActivated()) then
        PlaySound(SOUNDS.NEW_NOTIFICATION)
    end

    self.currentNumNotifications = numNotifications
end

function SharedChatSystem:HasUnreadMail()
    return self.numUnreadMails ~= 0
end

function SharedChatSystem:OnNumUnreadMailChanged(numUnread)
    if(numUnread > self.numUnreadMails and IsPlayerActivated()) then
        PlaySound(SOUNDS.NEW_MAIL)
    end
    self.numUnreadMails = numUnread
end

function SharedChatSystem:OnAgentChatActiveChanged()
    local isActive = IsAgentChatActive()

    if(isActive ~= self.isAgentChatActive) then
        self.isAgentChatActive = isActive

        if(isActive and IsPlayerActivated()) then
            self.agentChatBurstTimeline:PlayFromStart()
            PlaySound(SOUNDS.AGENT_CHAT_ACTIVE)
        end

        if(isActive) then
            self.agentChatPulseTimeline:PlayFromStart()
        else
            self.agentChatPulseTimeline:Stop()
        end

        self.agentChatButton:SetHidden(not isActive)
    end
end

function SharedChatSystem:GetTextEntryFontString(fontSize)
    local face, _, options = self:GetFont():GetFontInfo()
    local fontSizeString = self:GetFontSizeString(fontSize)
    if options ~= "" then
        return ("%s|%s|%s"):format(face, fontSizeString, options)
    end
    return ("%s|%s"):format(face, fontSizeString)
end

function SharedChatSystem:OnNumOnlineFriendsChanged()
    -- Overridden if applicable
end

function SharedChatSystem:Minimize()
    -- Should be overridden
end

function SharedChatSystem:Maximize()
    -- Should be overridden
end

function SharedChatSystem:IsMinimized()
    return self.isMinimized
end

function SharedChatSystem:IsPinnable()
    -- intended to be overriden in subclasses if necessary
    return false
end

function SharedChatSystem:SetupFonts()
    -- intended to be overriden in subclasses if necessary
end

function SharedChatSystem:GetFont()
    -- Should  be overridden
end

function SharedChatSystem:GetFontSizeString()
    -- Should  be overridden
end

function SharedChatSystem:GetFontSizeFromSetting()
    -- Should  be overridden
end

function StartChatInput(text, channel, target)
    if IsChatSystemAvailableForCurrentPlatform() then
        CHAT_SYSTEM:StartTextEntry(text, channel, target)
    end
end

function AutoSendChatInput(text, channel, target, dontShowHUDWindow)
    if IsChatSystemAvailableForCurrentPlatform() then
        CHAT_SYSTEM:AutoSendTextEntry(text, channel, target, dontShowHUDWindow)
    end
end

function ChatReplyToLastWhisper()
    CHAT_SYSTEM:ReplyToLastTarget(CHAT_CHANNEL_WHISPER)
end

function ZO_ChatSystem_OnMouseWheel(control, delta, ctrl, alt, shift)
    local container = control.container
    local buffer = container.currentBuffer
    
    if shift then
        delta = delta * buffer:GetNumVisibleLines()
    elseif ctrl then
        delta = delta * buffer:GetNumHistoryLines()
    end

    container:ScrollByOffset(delta)
end

function ZO_ChatSystem_SetScroll(control, value)
    control.container:SetScroll(value)
end

function ZO_ChatSystem_ScrollByOffset(control, offset)
    control.container:ScrollByOffset(offset)
end

function ZO_ChatSystem_ScrollToBottom(control)
    control.container:ScrollToBottom()
end

function ZO_ChatSystem_OnDragStart(control)
    control.container:StartDraggingTab(control.index)
end

function ZO_ChatSystem_OnDragStop(control)
    control.container:StopDraggingTab()
end

function ZO_ChatSystem_OnResizeStart(control)
    control.container:OnResizeStart()
end

function ZO_ChatSystem_OnResizeStop(control)
    control.container:OnResizeStop()
end

function ZO_ChatSystem_OnMoveStop(control)
    control.container:OnMoveStop()
end

function ZO_ChatSystem_OnMouseEnter(control)
    control.container:OnMouseEnter()
end

function ZO_ChatSystem_ShowOptions(control)
    control.container:ShowContextMenu()
end

function ZO_ChatSystem_OnFriendsEnter(control)
    FRIENDS_LIST:FriendsButton_OnMouseEnter(control)
end

function ZO_ChatSystem_OnFriendsExit(control)
    FRIENDS_LIST:FriendsButton_OnMouseExit(control)
end

function ZO_ChatSystem_OnFriendsClicked(control)
    if(IsInGamepadPreferredMode()) then
        SCENE_MANAGER:Show("gamepad_friends")
    else
        FRIENDS_LIST:FriendsButton_OnClicked(control)
    end
end

function ZO_ChatSystem_OnMailEnter(control)
    local numUnreadMail = GetNumUnreadMail()
    InitializeTooltip(InformationTooltip, control, TOPLEFT, 0, 0, BOTTOMRIGHT)
    if(numUnreadMail == 0) then
        SetTooltipText(InformationTooltip, GetString(SI_MAIL_NO_UNREAD_MAIL))
    else
        SetTooltipText(InformationTooltip, zo_strformat(SI_MAIL_UNREAD_MAIL, numUnreadMail))
    end
end

function ZO_ChatSystem_OnMailExit(control)
    ClearTooltip(InformationTooltip)
end

function ZO_ChatSystem_OnMailClicked(control)
    SYSTEMS:GetObject("mainMenu"):ToggleCategory(MENU_CATEGORY_MAIL)
end

function ZO_ChatSystem_OnAgentChatEnter(control)
    InitializeTooltip(InformationTooltip, control, TOPLEFT, 0, 0, BOTTOMRIGHT)
    SetTooltipText(InformationTooltip, GetString(SI_AGENT_CHAT_ACTIVE_TOOLTIP))
end

function ZO_ChatSystem_OnAgentChatExit(control)
    ClearTooltip(InformationTooltip)
end

function ZO_ChatSystem_OnAgentChatClicked()
    local isChatRequested = GetAgentChatRequestInfo()
    if isChatRequested then
        AcceptAgentChat()
    end
end

function ZO_ChatSystem_OnNotificationsClicked(control)
    SYSTEMS:GetObject("mainMenu"):ToggleCategory(MENU_CATEGORY_NOTIFICATIONS)
end

function ZO_ChatSystem_OnNotificationsEnter(control)
    NOTIFICATIONS:OnNotificationsChatButtonEnter(control)
end

function ZO_ChatSystem_OnNotificationsExit(control)
    NOTIFICATIONS:OnNotificationsChatButtonExit(control)
end

function ZO_ChatWindow_OpenContextMenu(control)
    control.container:ShowContextMenu(control.index)
end

function ZO_ChatTextEntry_PreviousCommand(control)
    if not control.system:IsAutoCompleteOpen() then
        control.owner:PreviousCommand()
    end
end

function ZO_ChatTextEntry_NextCommand(control)
    if not control.system:IsAutoCompleteOpen() then
        control.owner:NextCommand()
    end
end

function ZO_ChatTextEntry_TextChanged(control, newText)
    control.system:OnTextEntryChanged(newText)
end

function ZO_ChatTextEntry_Tab(control)
    if not control.system:IsAutoCompleteOpen() then
        if IsShiftKeyDown() then
            control.system:FindPreviousTargetForCurrentChannel()
        else
            control.system:FindNextTargetForCurrentChannel()
        end
    end
end

function ZO_ChatTextEntry_Escape(control)
    control.system:CloseTextEntry()
end

function ZO_ChatTextEntry_FocusLost(control)
    local KEEP_TEXT = true
    control.system:CloseTextEntry(KEEP_TEXT)
end

function ZO_ChatTextEntry_Execute(control)
    if control.system:IsAutoCompleteOpen() then
        control.system:CloseAutoComplete()
    else
        control.system:SubmitTextEntry()
    end
end

function ZO_ChannelLabel_MouseUp(control)
    control.system:ShowTextEntryMenu()
end
