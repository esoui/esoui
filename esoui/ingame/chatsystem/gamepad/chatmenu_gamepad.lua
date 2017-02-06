ZO_ChatMenu_Gamepad = ZO_Object.MultiSubclass(ZO_Gamepad_ParametricList_Screen, ZO_SocialOptionsDialogGamepad)

ZO_CHAT_MENU_GAMEPAD_LOG_MAX_SIZE = 200
ZO_CHAT_MENU_GAMEPAD_COLOR_MODIFIER = .7
ZO_CHAT_MENU_GAMEPAD_DESATURATION_MODIFIER = .1
ZO_CHAT_MENU_GAMEPAD_LOG_LINE_WIDTH = ZO_GAMEPAD_QUADRANT_1_2_3_CONTAINER_WIDTH - (ZO_GAMEPAD_INTERACTIVE_FILTER_HIGHLIGHT_PADDING * 2) --We squeeze in for the highlighting

------------------
--Initialization--
------------------

function ZO_ChatMenu_Gamepad:New(...)
    local obj = ZO_Object.New(self)
    obj:Initialize(...)
    return obj
end

function ZO_ChatMenu_Gamepad:Initialize(control)
    CHAT_MENU_GAMEPAD_SCENE = ZO_Scene:New("gamepadChatMenu", SCENE_MANAGER)

    local ACTIVATE_ON_SHOW = true
    ZO_Gamepad_ParametricList_Screen.Initialize(self, control, ZO_GAMEPAD_HEADER_TABBAR_DONT_CREATE, ACTIVATE_ON_SHOW, CHAT_MENU_GAMEPAD_SCENE)
    ZO_SocialOptionsDialogGamepad.Initialize(self)

    self:InitializeFragment()
    self:InitializeControls()
    self:InitializePassiveFocus()
    self:RegisterForEvents()
end

function ZO_ChatMenu_Gamepad:InitializeFragment()
    local chatMenuFragment = ZO_FadeSceneFragment:New(self.control)
    self.scene:AddFragment(chatMenuFragment)

    self.headerData =
    {
        titleText = GetString(SI_GAMEPAD_TEXT_CHAT),
    }
    ZO_GamepadGenericHeader_Refresh(self.header, self.headerData)
end

function ZO_ChatMenu_Gamepad:InitializeControls()
    self.messageEntries = {}
    self.nextMessageId = 1
    self.mask = self.control:GetNamedChild("Mask")

    --Log List--
    local list = self:GetMainList()
    list:SetSelectedItemOffsets(0, 0)
    list:SetAnchorOppositeSide(true)
    list:AddDataTemplate("ZO_ChatMenu_Gamepad_LogLine", function(...) self:SetupLogMessage(...) end, ZO_GamepadMenuEntryTemplateParametricListFunction, function(a, b) return a.data.id == b.data.id end)

    local CONSUME_INPUT = true
    local function HandleListDirectionalInput(result)
        if result == MOVEMENT_CONTROLLER_MOVE_NEXT then
            if list:GetSelectedIndex() == list:GetNumEntries() then
                self:FocusTextInput()
            end
        end
    end

    list:SetCustomDirectionInputHandler(HandleListDirectionalInput)
    list:SetDirectionalInputEnabled(false)
    list:SetSoundEnabled(false)
    self.list = list
    self:BuildChatList()
    self.currentLinkIndex = 1

    self.moreBelowTimeline = ANIMATION_MANAGER:CreateTimelineFromVirtual("ZO_ChatMenu_Gamepad_MoreBelowAnimation", self.mask:GetNamedChild("MoreBelow"))

    self:InitializeTextInputSection()
end

function ZO_ChatMenu_Gamepad:InitializeTextInputSection()
    self.textInputControl = self.mask:GetNamedChild("TextInput")
    --For active focus switching between channel and edit box
    self.textInputFocusSwitcher = ZO_GamepadFocus:New(self.textInputControl, nil, MOVEMENT_CONTROLLER_DIRECTION_HORIZONTAL)
    --For passive focus switching between text input area and chat entry list
    self.textInputVerticalMovementController = ZO_MovementController:New(MOVEMENT_CONTROLLER_DIRECTION_VERTICAL)

    self:InitializeChannelDropdown()
    self:InitializeTextEdit()
end

function ZO_ChatMenu_Gamepad:InitializeChannelDropdown()
    local channelControl = self.textInputControl:GetNamedChild("Channel")
    local channelDropdownControl = channelControl:GetNamedChild("Dropdown")
    local channelDropdown = ZO_ComboBox_ObjectFromContainer(channelDropdownControl)
    channelDropdown:SetSelectedColor(ZO_DISABLED_TEXT)
    channelDropdown:SetSortsItems(false)
    channelDropdown:SetDontSetSelectedTextOnSelection(true)
    self.selectedChannelLabel = channelDropdownControl:GetNamedChild("SelectedItemText")
    self.selectedChannelFakeLabel = channelDropdownControl:GetNamedChild("SelectedItemFakeTextForResizing")

    -- Prepare switches for sorting
    -- These switches are the slash commands used to set the channel (e.g.:/zone)
    -- The channelData holds a table of all the channels and their information, 
    -- and the switch lookup provides the mapping of the channel id to the default (e.g.: /zone vs /z) switch needed to go there
    local channelData = CHAT_SYSTEM.channelData
    local switchLookup = CHAT_SYSTEM.switchLookup
    local switches = {}
    for channel in pairs(channelData) do
        local switch = switchLookup[channel]
        --Not every channel in the channel data is going to map to a switch
        if switch then
            switches[#switches + 1] = switch
        end
    end

    table.sort(switches)

    local channelFocusData = {
        keybindText = GetString(SI_GAMEPAD_SELECT_OPTION),
        callback = function()
            channelDropdown:Activate()
        end,
        highlight = channelControl:GetNamedChild("Highlight"),
        control = channelDropdown,
    }
    self.textInputFocusSwitcher:AddEntry(channelFocusData)

    self.channelDropdown = channelDropdown
    self.channelControl = channelControl
    self.sortedChannelSwitches = switches

    local DONT_RESELECT = false
    self:RefreshChannelDropdown(DONT_RESELECT)
end

function ZO_ChatMenu_Gamepad:InitializeTextEdit()
    local textControl = self.textInputControl:GetNamedChild("Text")
    local textEdit = textControl:GetNamedChild("EditBox")

    local function TextEditFocusGained()
        self:FocusTextInput()
        self.textInputAreaFocalArea:Deactivate()
        ZO_GamepadEditBox_FocusGained(textEdit)
    end

    local function TextEditFocusLost()
        ZO_GamepadEditBox_FocusLost(textEdit)
        self:FocusTextInput()
    end

    local function TextEditTextChanged()
        if self.textInputAreaFocalArea:IsFocused() and not self.channelDropdown:IsActive() then
            self.textInputAreaFocalArea:UpdateKeybinds()
        end
    end

    textEdit:SetHandler("OnFocusGained", TextEditFocusGained)
    textEdit:SetHandler("OnFocusLost", TextEditFocusLost)
    textEdit:SetHandler("OnTextChanged", TextEditTextChanged)

    local textEditData = {
        callback = function()
            if not textEdit:HasFocus() then
                textEdit:TakeFocus()
            end
        end,
        highlight = textControl:GetNamedChild("Highlight"),
        control = textEdit,
    }
    self.textInputFocusSwitcher:AddEntry(textEditData)

    self.textEdit = textEdit
end

function ZO_ChatMenu_Gamepad:InitializePassiveFocus()
    --Passive Area Focus--
    local function TextInputAreaActivateCallback()
        self.textInputFocusSwitcher:Activate()
        DIRECTIONAL_INPUT:Activate(self, self.textInputControl)
    end

    local function TextInputAreaDeactivateCallback()
        self.textInputFocusSwitcher:Deactivate()
        DIRECTIONAL_INPUT:Deactivate(self)
    end

    self.textInputAreaFocalArea = ZO_GamepadPassiveFocus:New(self, TextInputAreaActivateCallback, TextInputAreaDeactivateCallback)

    local function EnableChatDirectionalInputLater()
        if self.chatEntryPanelFocalArea:IsFocused() then
            self.list:SetDirectionalInputEnabled(true)
        end
    end

    local function ChatEntryPanelActivateCallback()
        --We want the chat entry list to wait a moment before it starts processing the input
        --Otherwise it will move immediately on the next frame after gaining focus
        zo_callLater(EnableChatDirectionalInputLater, 200)
        self.list:RefreshVisible()
        self.list:SetSoundEnabled(true)
        self.currentLinkIndex = 1
        self:RefreshTooltip()
    end

    local function ChatEntryPanelDeactivateCallback()
        self.list:SetDirectionalInputEnabled(false)
        self.list:RefreshVisible()
        self.list:SetSoundEnabled(false)
        GAMEPAD_TOOLTIPS:ClearTooltip(GAMEPAD_RIGHT_TOOLTIP)
    end
    self.chatEntryPanelFocalArea =  ZO_GamepadPassiveFocus:New(self, ChatEntryPanelActivateCallback, ChatEntryPanelDeactivateCallback)

    local NO_PREVIOUS, NO_NEXT
    self.chatEntryPanelFocalArea:SetupSiblings(NO_PREVIOUS, self.textInputAreaFocalArea)
    self.textInputAreaFocalArea:SetupSiblings(self.chatEntryPanelFocalArea, NO_NEXT)
end

function ZO_ChatMenu_Gamepad:RegisterForEvents()
    local RESELECT = true
    local function RefreshChannelDropdown()
        self:RefreshChannelDropdown(RESELECT)
    end

    local function OnGroupMemberJoined(eventCode, playerName)
        if playerName == GetRawUnitName("player") then
            RefreshChannelDropdown()
        end
    end

    local function OnGroupMemberLeft(eventCode, characterName, reason, isLocalPlayer)
        if isLocalPlayer then
            RefreshChannelDropdown()
        end
    end

    local function OnGuildMemberRankChanged(eventCode, guildId, displayName)
        if displayName == GetDisplayName() then
            RefreshChannelDropdown()
        end
    end

    CALLBACK_MANAGER:RegisterCallback("OnFormattedChatEvent", function(...) self:AddMessage(...) end)
    CALLBACK_MANAGER:RegisterCallback("OnChatSetChannel", function(...) self:OnChatChannelChanged(...) end)
    self.control:RegisterForEvent(EVENT_SCREEN_RESIZED, function() self:ReadjustFixedCenterOffset() end)
    self.control:RegisterForEvent(EVENT_GROUP_MEMBER_JOINED, OnGroupMemberJoined)
    self.control:RegisterForEvent(EVENT_GROUP_MEMBER_LEFT, OnGroupMemberLeft)
    self.control:RegisterForEvent(EVENT_GUILD_SELF_JOINED_GUILD, RefreshChannelDropdown)
    self.control:RegisterForEvent(EVENT_GUILD_SELF_LEFT_GUILD, RefreshChannelDropdown)
    self.control:RegisterForEvent(EVENT_GUILD_MEMBER_RANK_CHANGED, OnGuildMemberRankChanged)
    self.control:RegisterForEvent(EVENT_SCREEN_RESIZED, RefreshChannelDropdown)
end

function ZO_ChatMenu_Gamepad:InitializeFocusKeybinds()
    local function LinkShouldersEnabled()
        local targetData = self.list:GetTargetData()
        if targetData then
            local links = targetData.data.links
            if links then
                return #links > 1
            end
        end
        return false
    end

    self.chatEntryListKeybindDescriptor =
    {
        alignment = KEYBIND_STRIP_ALIGN_LEFT,

        -- Back to text input
        {
            name = GetString(SI_GAMEPAD_BACK_OPTION),

            keybind = "UI_SHORTCUT_NEGATIVE",

            callback = function()
                self:FocusTextInput()
            end,

            sound = SOUNDS.GAMEPAD_MENU_BACK,
        },

        {
            alignment = KEYBIND_STRIP_ALIGN_RIGHT,

            name = GetString(SI_GAMEPAD_CHAT_MENU_CYCLE_TOOLTIP_BINDING),

            keybind = "UI_SHORTCUT_INPUT_RIGHT",

            callback = function()
                self.currentLinkIndex = self.currentLinkIndex + 1
                local targetData = self.list:GetTargetData()
                if self.currentLinkIndex > #targetData.data.links then
                    self.currentLinkIndex = 1
                end
                self:RefreshTooltip(targetData)
            end,

            visible = LinkShouldersEnabled,
        },

        {
            ethereal = true,

            keybind = "UI_SHORTCUT_INPUT_LEFT",

            callback = function()
                self.currentLinkIndex = self.currentLinkIndex - 1
                local targetData = self.list:GetTargetData()
                if self.currentLinkIndex == 0 then
                    self.currentLinkIndex = #targetData.data.links
                end
                self:RefreshTooltip(targetData)
            end,

            enabled = LinkShouldersEnabled,
        }
    }
    ZO_Gamepad_AddListTriggerKeybindDescriptors(self.chatEntryListKeybindDescriptor, self.list)

    local function AreOptionsAvailable()
        local targetData = self.list:GetTargetData()
        if targetData then
            local data = targetData.data
            if data then
                if data.fromDisplayName and data.fromDisplayName ~= "" and self:HasAnyShownOptions() then
                    return true
                end
            end
        end
        return false
    end
    local DEFAULT_CALLBACK, DEFAULT_KEYBIND, DEFAULT_NAME, DEFAULT_SOUND
    self:AddSocialOptionsKeybind(self.chatEntryListKeybindDescriptor, DEFAULT_CALLBACK, DEFAULT_KEYBIND, DEFAULT_NAME, DEFAULT_SOUND, AreOptionsAvailable)
    self.chatEntryPanelFocalArea:SetKeybindDescriptor(self.chatEntryListKeybindDescriptor)

    self.textInputAreaKeybindDescriptor =
    {
        alignment = KEYBIND_STRIP_ALIGN_LEFT,

        {
            name = GetString(SI_GAMEPAD_SELECT_OPTION),

            keybind = "UI_SHORTCUT_PRIMARY",

            callback = function()
                local data = self.textInputFocusSwitcher:GetFocusItem()
                data.callback()
            end,
        },

        {
            name = GetString(SI_GAMEPAD_CHAT_MENU_SEND_KEYBIND),

            keybind = "UI_SHORTCUT_SECONDARY",

            callback = function()
                local CURRENT_CHANNEL, CURRENT_TARGET
                local DONT_SHOW_HUD_WINDOW = true
                AutoSendChatInput(self.textEdit:GetText(), CURRENT_CHANNEL, CURRENT_TARGET, DONT_SHOW_HUD_WINDOW)
                self.textEdit:Clear()
            end,

            enabled = function()
                local text = self.textEdit:GetText()
                return text and text ~= ""
            end,
        }
    }
    ZO_Gamepad_AddBackNavigationKeybindDescriptors(self.textInputAreaKeybindDescriptor, GAME_NAVIGATION_TYPE_BUTTON)
    self.textInputAreaFocalArea:SetKeybindDescriptor(self.textInputAreaKeybindDescriptor)
end

----------
--Events--
----------

function ZO_ChatMenu_Gamepad:OnDeferredInitialize()
    self:ReadjustFixedCenterOffset()
    self:InitializeFocusKeybinds()
end

function ZO_ChatMenu_Gamepad:PerformUpdate()
    -- We have to override this to prevent an assert in the base class
end

function ZO_ChatMenu_Gamepad:OnShow()
    self.list:RefreshVisible()
    self:FocusTextInput()
end

function ZO_ChatMenu_Gamepad:OnHiding()
    if self.currentFocalArea then
        self.currentFocalArea:Deactivate()
    end
end

function ZO_ChatMenu_Gamepad:FocusTextInput()
    if self.scene:IsShowing() then
        if self.currentFocalArea ~= self.textInputAreaFocalArea then
            if self.currentFocalArea then
                self.currentFocalArea:Deactivate()
            end
            self.currentFocalArea = self.textInputAreaFocalArea
        end
        self.currentFocalArea:Activate()
        self.textInputFocusSwitcher:SetFocusToMatchingEntry(self.textEdit)
    end
end

function ZO_ChatMenu_Gamepad:UpdateDirectionalInput()
    --We don't want to change focus to the chat entry area if there are no entries to scroll through
    if self.list:GetNumEntries() > 0 then
        local result = self.textInputVerticalMovementController:CheckMovement()
        if result == MOVEMENT_CONTROLLER_MOVE_PREVIOUS then
            local newFocus = self.textInputAreaFocalArea:MovePrevious()
            if newFocus then
                self.currentFocalArea = newFocus
            end
        end
    end
end

do
    local FIXED_CENTER_OFFSET_PADDING = 37

    function ZO_ChatMenu_Gamepad:ReadjustFixedCenterOffset()
        local scrollHeight = self.list.control:GetHeight()
        local fixedCenterOffset = scrollHeight / 2 - FIXED_CENTER_OFFSET_PADDING
        self.list:SetFixedCenterOffset(fixedCenterOffset)
    end
end

function ZO_ChatMenu_Gamepad:SetupLogMessage(control, data, selected, reselectingDuringRebuild, enabled, active)
    ZO_SharedGamepadEntry_OnSetup(control, data, selected, reselectingDuringRebuild, enabled, active)
    local entryData = data.data
    local r, g, b = GetChatCategoryColor(entryData.category)
    local useSelectedColor = selected and self.chatEntryPanelFocalArea:IsFocused()
    local colorSelectedModifier = useSelectedColor and 1 or ZO_CHAT_MENU_GAMEPAD_COLOR_MODIFIER
    control.label:SetColor(r * colorSelectedModifier, g * colorSelectedModifier, b * colorSelectedModifier, 1)
    control.label:SetDesaturation(useSelectedColor and 0 or ZO_CHAT_MENU_GAMEPAD_DESATURATION_MODIFIER)
end

do
    local LINK_GMATCH_PATTERN = "|H.-|h.-|h"
    local LINK_TYPE_MATCH_PATTERN = "|H%d:(.-):"
    function ZO_ChatMenu_Gamepad:AddMessage(message, category, targetChannel, fromDisplayName, rawMessageText)
        if message ~= nil then
            local targetIndex = self.list:GetTargetIndex()
            local selectingMostRecent = targetIndex == #self.messageEntries

            local links
            --Only chat channel messages will have raw text, because they're the only ones that could have links in them
            if rawMessageText then
                for link in zo_strgmatch(rawMessageText, LINK_GMATCH_PATTERN) do
                    local linkType = zo_strmatch(link, LINK_TYPE_MATCH_PATTERN)
                    if linkType == ACHIEVEMENT_LINK_TYPE or linkType == ITEM_LINK_TYPE or linkType == COLLECTIBLE_LINK_TYPE then
                        if not links then
                            links = {}
                        end
                        table.insert(links, { linkType = linkType, link = link })
                    end
                end
            end

            local messageEntry = ZO_GamepadEntryData:New(message)
            messageEntry:SetFontScaleOnSelection(false)
            messageEntry.data = 
            {
                id = self.nextMessageId,
                fromDisplayName = fromDisplayName,
                category = category,
                targetChannel = targetChannel,
                rawMessageText = rawMessageText,
                links = links
            }

            self.nextMessageId = self.nextMessageId + 1
            table.insert(self.messageEntries, messageEntry)

            if #self.messageEntries > ZO_CHAT_MENU_GAMEPAD_LOG_MAX_SIZE then
                table.remove(self.messageEntries, 1)
                self:BuildChatList()
            else
                self.list:AddEntry("ZO_ChatMenu_Gamepad_LogLine", messageEntry)
                self.list:Commit()
            end

            if selectingMostRecent then
                self.list:SetSelectedIndex(#self.messageEntries)
            end
        end
    end
end

do
    local function IsEntryForCurrentChannel(entry)
        local channelData = CHAT_SYSTEM:GetCurrentChannelData()
        return entry.data == channelData
    end

    function ZO_ChatMenu_Gamepad:OnChatChannelChanged()
        --Set the dropdown selection to the appropriate channel
        self.channelDropdown:SetSelectedItemByEval(IsEntryForCurrentChannel, true)
        
        --Set the selected item text for the dropdown to the appropriate text
        local channelData, channelTarget = CHAT_SYSTEM:GetCurrentChannelData()
        local channelText
        if channelTarget then
            --Console can only have display names.  This won't do anything to character names on PC
            channelTarget = ZO_FormatUserFacingDisplayName(channelTarget)
            channelText = zo_strformat(SI_CHAT_ENTRY_TARGET_FORMAT, GetChannelName(channelData.id), channelTarget)
        else
            channelText = zo_strformat(SI_CHAT_ENTRY_GENERAL_FORMAT, GetChannelName(channelData.id))
        end
        self.selectedChannelLabel:SetText(channelText)
        local r, g, b = CHAT_SYSTEM:GetCategoryColorFromChannel(channelData.id)
        self.selectedChannelLabel:SetColor(r, g, b, 1)
        self.textEdit:SetColor(r, g, b)

        --Set the dropdown width to be wide enough to fit the text
        local stringWidth = self.selectedChannelFakeLabel:GetStringWidth(zo_strupper(channelText)) / GetUIGlobalScale()
        self.channelControl:SetWidth(zo_max(self.channelDropdown.minimumWidth, stringWidth))
    end
end

function ZO_ChatMenu_Gamepad:RefreshMoreBelow(targetSelectedIndex)
    local isMoreBelow = targetSelectedIndex < self.list:GetNumItems()
    if isMoreBelow then
        self.moreBelowTimeline:PlayForward()
    else
        self.moreBelowTimeline:PlayBackward()
    end
end

function ZO_ChatMenu_Gamepad:RefreshChannelDropdown(reselectDuringRebuild)
    local function OnChannelSelected(_, _, entry, _)
        local data = entry.data
        --Target means we don't yet have enough info to properly change channels
        if data and not data.target then
            CHAT_SYSTEM:SetChannel(data.id)
        else
            --TODO: Fill the chat with something to get the player started
        end
    end

    local switchLookup = CHAT_SYSTEM.switchLookup
    local channelDropdown = self.channelDropdown
    channelDropdown.minimumWidth = 0
    channelDropdown:ClearItems()

    --Add sorted switches
    for i, switch in ipairs(self.sortedChannelSwitches) do
        --The switchLookup also includes a backward lookup to use any switch (not just defaults) to find the associated channel data
        local channelData = switchLookup[switch]
        --TODO: Figure out an elegant way to handle /tell using a gamepad and virtual keyboard for display names on a console (see also TODO in OnChannelSelected)
        if channelData and not channelData.target and (not channelData.requires or channelData.requires(channelData.id)) then
            local r, g, b = CHAT_SYSTEM:GetCategoryColorFromChannel(channelData.id)
            local itemColor = ZO_ColorDef:New(r, g, b)
            local coloredSwitchText = itemColor:Colorize(switch)
            local entry = ZO_ComboBox:CreateItemEntry(coloredSwitchText, OnChannelSelected)
            entry.data = channelData
            channelDropdown:AddItem(entry, ZO_COMBOBOX_SUPRESS_UPDATE)
            local stringWidth = self.selectedChannelFakeLabel:GetStringWidth(zo_strupper(switch)) / GetUIGlobalScale()
            channelDropdown.minimumWidth = zo_max(stringWidth, channelDropdown.minimumWidth)
        end
    end

    if reselectDuringRebuild then
        self:OnChatChannelChanged()
    end
end

function ZO_ChatMenu_Gamepad:OnTargetChanged(list, targetData, oldTargetData, reachedTarget, targetSelectedIndex)
    self:RefreshMoreBelow(targetSelectedIndex)
    self:SetupOptions(targetData)
    self.currentLinkIndex = 1
    if self.chatEntryPanelFocalArea:IsFocused() then
        self.chatEntryPanelFocalArea:UpdateKeybinds()
        self:RefreshTooltip(targetData)
    end
end

function ZO_ChatMenu_Gamepad:RefreshTooltip(targetData)
    local targetData = targetData or self.list:GetTargetData()
    if targetData then
        local links = targetData.data.links
        if links then
            local currentLinkData = links[self.currentLinkIndex]
            local linkType = currentLinkData.linkType
            local link = currentLinkData.link

            --TODO: Implement quest item links and maybe books (if we even care about books)
            if linkType == COLLECTIBLE_LINK_TYPE then
                GAMEPAD_TOOLTIPS:LayoutCollectibleFromLink(GAMEPAD_RIGHT_TOOLTIP, link)
            elseif linkType == ACHIEVEMENT_LINK_TYPE then
                GAMEPAD_TOOLTIPS:LayoutAchievementFromLink(GAMEPAD_RIGHT_TOOLTIP, link)
            elseif linkType == ITEM_LINK_TYPE then
                GAMEPAD_TOOLTIPS:LayoutItem(GAMEPAD_RIGHT_TOOLTIP, link)
            end

            return
        end
    end
    GAMEPAD_TOOLTIPS:ClearTooltip(GAMEPAD_RIGHT_TOOLTIP)
end

function ZO_ChatMenu_Gamepad:BuildChatList()
    --TODO: Implement filtering systems
    self.list:Clear()

    for i, entry in ipairs(self.messageEntries) do
        self.list:AddEntry("ZO_ChatMenu_Gamepad_LogLine", entry)
    end

    self.list:Commit()
end

function ZO_ChatMenu_Gamepad:SetupOptions(entryData)
    local data = entryData.data

    local socialData = 
    {
        displayName = data.fromDisplayName,
        category = data.category,
        targetChannel = data.targetChannel,
    }

    ZO_SocialOptionsDialogGamepad.SetupOptions(self, socialData)
end

function ZO_ChatMenu_Gamepad:BuildOptionsList()
    local groupId = self:AddOptionTemplateGroup(ZO_SocialOptionsDialogGamepad.GetDefaultHeader)
    
    self:AddOptionTemplate(groupId, ZO_SocialOptionsDialogGamepad.BuildGamerCardOption, IsConsoleUI)
    self:AddOptionTemplate(groupId, ZO_SocialOptionsDialogGamepad.BuildInviteToGroupOption, ZO_SocialOptionsDialogGamepad.ShouldAddInviteToGroupOption)
    self:AddOptionTemplate(groupId, ZO_SocialOptionsDialogGamepad.BuildWhisperOption)
    self:AddOptionTemplate(groupId, ZO_SocialOptionsDialogGamepad.BuildAddFriendOption, ZO_SocialOptionsDialogGamepad.ShouldAddFriendOption)
    self:AddOptionTemplate(groupId, ZO_SocialOptionsDialogGamepad.BuildSendMailOption)
    self:AddOptionTemplate(groupId, ZO_SocialOptionsDialogGamepad.BuildIgnoreOption, ZO_SocialOptionsDialogGamepad.SelectedDataIsNotPlayer)
end

--------------
--Global XML--
--------------

do
    local function GetHeight(self)
        return self.label:GetTextHeight()
    end

    function ZO_ChatMenu_Gamepad_LogLine_OnInitialized(self)
        ZO_SharedGamepadEntry_OnInitialized(self)
        self.GetHeight = GetHeight
        self.label = self:GetNamedChild("Label")
    end
end

function ZO_ChatMenu_Gamepad_OnInitialized(self)
    CHAT_MENU_GAMEPAD = ZO_ChatMenu_Gamepad:New(self)
end