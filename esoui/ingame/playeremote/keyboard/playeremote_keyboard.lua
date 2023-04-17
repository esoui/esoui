--Quick chat is not a real emote category, so make a fake one
local QUICK_CHAT_CATEGORY = -1

local KEYBOARD_INVALID_CATEGORY_EMOTE_ICONS = {
    [EMOTE_CATEGORY_INVALID] = {
        up = "EsoUI/Art/Inventory/inventory_tabIcon_quickslot_up.dds",
        down = "EsoUI/Art/Inventory/inventory_tabIcon_quickslot_down.dds",
        over = "EsoUI/Art/Inventory/inventory_tabIcon_quickslot_over.dds",
    },
    [EMOTE_CATEGORY_DEPRECATED] = {
        up = "EsoUI/Art/Inventory/inventory_tabIcon_quickslot_up.dds",
        down = "EsoUI/Art/Inventory/inventory_tabIcon_quickslot_down.dds",
        over = "EsoUI/Art/Inventory/inventory_tabIcon_quickslot_over.dds",
    },
}

ZO_PlayerEmote_Keyboard = ZO_InitializingObject:Subclass()

function ZO_PlayerEmote_Keyboard:Initialize(control)
    self:MarkDirty()
    self.control = control
    self.wheelControl = self.control:GetNamedChild("EmoteWheel")
    self.emoteGridListControl = self.control:GetNamedChild("EmoteContainer")
    control.owner = self
    local wheelData =
    {
        hotbarCategories = { HOTBAR_CATEGORY_EMOTE_WHEEL, HOTBAR_CATEGORY_QUICKSLOT_WHEEL },
        numSlots = ACTION_BAR_UTILITY_BAR_SIZE,
        showCategoryLabel = true,
        --Display the accessibility keybinds on the wheel if the setting is enabled
        showKeybinds = ZO_AreTogglableWheelsEnabled,
    }
    self.wheel = ZO_AssignableUtilityWheel_Keyboard:New(self.wheelControl, wheelData)

    HELP_EMOTES_SCENE = ZO_Scene:New("helpEmotes", SCENE_MANAGER)
    local keyboardPlayerEmoteFragment = ZO_FadeSceneFragment:New(control)
    keyboardPlayerEmoteFragment:RegisterCallback("StateChange", function(oldState, newState)
        if newState == SCENE_SHOWING then
            TriggerTutorial(TUTORIAL_TRIGGER_EMOTES_MENU_OPENED)
            if self.isDirty then
                self:UpdateCategories()
            end
            self.wheel:Activate()
        elseif newState == SCENE_FRAGMENT_HIDDEN then
            self.wheel:Deactivate()
        end
    end)

    HELP_EMOTES_SCENE:AddFragment(keyboardPlayerEmoteFragment)

    PLAYER_EMOTE_MANAGER:RegisterCallback("EmoteListUpdated",
                                    function()
                                        if keyboardPlayerEmoteFragment:IsShowing() then
                                            self:UpdateCategories()
                                        else
                                            self:MarkDirty()
                                        end
                                    end)

    self:InitializeTree()
    self:InitializeEmoteGridList()
end

function ZO_PlayerEmote_Keyboard:InitializeTree()
    self.categoryTree = ZO_Tree:New(GetControl(self.control, "Categories"), 60, -10, 280)

    local function CategorySetup(node, control, data, down)
        control.text:SetModifyTextType(MODIFY_TEXT_TYPE_UPPERCASE)
        control.text:SetText(data.name)

        control.icon:SetTexture(down and data.down or data.up)
        control.iconHighlight:SetTexture(data.over)

        ZO_IconHeader_Setup(control, down)
    end

    local function CategorySelected(control, data, selected, reselectingDuringRebuild)
        if selected then
            self:BuildEmoteGridList(data.emoteCategory)
        end
        CategorySetup(nil, control, data, selected)
    end

    self.categoryTree:AddTemplate("ZO_IconChildlessHeader", CategorySetup, CategorySelected, nil)
    self.categoryTree:SetExclusive(true)
end

function ZO_PlayerEmote_Keyboard:InitializeEmoteGridList()
    self.gridList = ZO_SingleTemplateGridScrollList_Keyboard:New(self.emoteGridListControl)
    local function EmoteTextEntrySetup(control, data)
        control.data = data
        if data.quickChatId then
            control:SetText(QUICK_CHAT_MANAGER:GetFormattedQuickChatName(data.quickChatId))
            ZO_SelectableLabel_SetNormalColor(control, ZO_NORMAL_TEXT)
        elseif data.emoteId then
            if data.isOverriddenByPersonality then
                ZO_SelectableLabel_SetNormalColor(control, ZO_PERSONALITY_EMOTES_COLOR)
            else
                ZO_SelectableLabel_SetNormalColor(control, ZO_NORMAL_TEXT)
            end
            control:SetText(data.emoteSlashName)
        end
    end

    local HIDE_CALLBACK = nil
    local DEFAULT_RESET_ENTRY = nil
    local ENTRY_WIDTH = 200
    local ENTRY_HEIGHT = 24
    local ENTRY_PADDING_X = 5
    local ENTRY_PADDING_Y = 0
    self.gridList:SetGridEntryTemplate("ZO_PlayerEmote_Keyboard_EmoteText", ENTRY_WIDTH, ENTRY_HEIGHT, EmoteTextEntrySetup, HIDE_CALLBACK, DEFAULT_RESET_ENTRY, ENTRY_PADDING_X, ENTRY_PADDING_Y)
end

function ZO_PlayerEmote_Keyboard:ShowCategory(category)
    self.queuedCategoryToShow = category
    if not SCENE_MANAGER:IsShowing("helpEmotes") then
        self:MarkDirty()
        MAIN_MENU_KEYBOARD:ShowScene("helpEmotes")
    else
        self:UpdateCategories()
    end
end

function ZO_PlayerEmote_Keyboard:UpdateCategories()
    local oldSelectedCategory

    if self.queuedCategoryToShow then
        oldSelectedCategory = self.queuedCategoryToShow
        self.queuedCategoryToShow = nil
    else
        local oldSelectedData = self.categoryTree:GetSelectedData()
        if oldSelectedData then
            oldSelectedCategory = oldSelectedData.emoteCategory
        end
    end

    local nodeToSelect

    self.categoryTree:Reset()

    local categories = PLAYER_EMOTE_MANAGER:GetEmoteCategories()

    local function GetEmoteIconForCategory(category)
        if KEYBOARD_INVALID_CATEGORY_EMOTE_ICONS[category] then
            local icons = KEYBOARD_INVALID_CATEGORY_EMOTE_ICONS[category]
            return icons.up, icons.down, icons.over
        else
            return GetEmoteCategoryKeyboardIcons(category)
        end
    end

    local quickChatUpIcon, quickChatDownIcon, quickChatOverIcon = GetQuickChatCategoryKeyboardIcons()
    local quickChatData =
    {
        name = GetString(SI_QUICK_CHAT_EMOTE_MENU_ENTRY_NAME),
        up = quickChatUpIcon,
        down = quickChatDownIcon,
        over = quickChatOverIcon,
        emoteCategory = QUICK_CHAT_CATEGORY,
    }
    local quickChatNode = self.categoryTree:AddNode("ZO_IconChildlessHeader", quickChatData)
    if oldSelectedCategory and oldSelectedCategory == QUICK_CHAT_CATEGORY then
        nodeToSelect = quickChatNode
    end

    for _, category in ipairs(categories) do
        if category ~= EMOTE_CATEGORY_INVALID then
            local upIcon, downIcon, overIcon = GetEmoteIconForCategory(category)
            local data = {
                name = GetString("SI_EMOTECATEGORY", category),
                up = upIcon,
                down = downIcon,
                over = overIcon,
                emoteCategory = category,
            }
            local node = self.categoryTree:AddNode("ZO_IconChildlessHeader", data)
            if oldSelectedCategory and category == oldSelectedCategory then
                nodeToSelect = node
            end
        end
    end

    self.categoryTree:Commit(nodeToSelect)

    self.isDirty = false
end

function ZO_PlayerEmote_Keyboard:MarkDirty()
    self.isDirty = true
end

function ZO_PlayerEmote_Keyboard:BuildEmoteGridList(category)
    self.gridList:ClearGridList()

    if category == QUICK_CHAT_CATEGORY then
        local quickChatList = QUICK_CHAT_MANAGER:BuildQuickChatList()
        for i, quickChatId in ipairs(quickChatList) do
            local quickChatData = 
            {
                quickChatId = quickChatId,
                isOverriddenByPersonality = false, 
            }
            self.gridList:AddEntry(quickChatData)
        end
    else
        local emoteList = PLAYER_EMOTE_MANAGER:GetEmoteListForType(category)
        for i, emote in ipairs(emoteList) do
            local emoteInfo = PLAYER_EMOTE_MANAGER:GetEmoteItemInfo(emote)
            self.gridList:AddEntry(emoteInfo)
        end
    end

    self.gridList:CommitGridList()
end

function ZO_PlayerEmote_Keyboard:GetUtilityWheel()
    return self.wheel
end

-- Global XML --

function ZO_PlayerEmote_Keyboard_Initialize(control)
    KEYBOARD_PLAYER_EMOTE = ZO_PlayerEmote_Keyboard:New(control)
end

function ZO_PlayerEmoteEntry_GetTextColor(entry)
    if entry.mouseover then
        local mouseOverColor = entry.data.isOverriddenByPersonality and ZO_TRADE_BOP_COLOR or ZO_HIGHLIGHT_TEXT
        return mouseOverColor:UnpackRGBA()
    else
        return entry.normalColor:UnpackRGBA()
    end
end

function ZO_PlayerEmoteEntry_OnDragStart(control)
    local utilityWheel = KEYBOARD_PLAYER_EMOTE:GetUtilityWheel()
    local hotbarCategory = utilityWheel:GetHotbarCategory()
    if hotbarCategory ~= ZO_UTILITY_WHEEL_HOTBAR_CATEGORY_HIDDEN and GetCursorContentType() == MOUSE_CONTENT_EMPTY then
        if control.data.emoteId and utilityWheel:IsActionTypeSupported(ACTION_TYPE_EMOTE) then
            PickupEmoteById(control.data.emoteId)
        elseif control.data.quickChatId and utilityWheel:IsActionTypeSupported(ACTION_TYPE_QUICK_CHAT) then
            PickupQuickChatById(control.data.quickChatId)
        end
    end
end

function ZO_PlayerEmoteEntry_OnMouseUp(control, button, upInside)
    if button == MOUSE_BUTTON_INDEX_RIGHT and upInside then
        ClearMenu()
        local data = control.data  
        local actionId
        local actionType

        --Set up the "Use" option differently based on whether this is an emote or quick chat
        if data.emoteId then
            actionId = data.emoteId
            actionType = ACTION_TYPE_EMOTE
            AddMenuItem(GetString(SI_PLAYER_EMOTE_USE_EMOTE), function()
                --Emotes cannot be used while character framing is happening, so close out the menu before playing
                SCENE_MANAGER:ShowBaseScene()
                PlayEmoteByIndex(data.emoteIndex)
            end)
        elseif data.quickChatId then
            actionId = data.quickChatId
            actionType = ACTION_TYPE_QUICK_CHAT
            AddMenuItem(GetString(SI_PLAYER_EMOTE_USE_EMOTE), function()
                --Emotes cannot be used while character framing is happening, so close out the menu before playing
                SCENE_MANAGER:ShowBaseScene()
                QUICK_CHAT_MANAGER:PlayQuickChat(data.quickChatId)
            end)
        end

        local utilityWheel = KEYBOARD_PLAYER_EMOTE:GetUtilityWheel()
        local hotbarCategory = utilityWheel:GetHotbarCategory()
        --Only include the following options if the wheel is toggled on
        if hotbarCategory ~= ZO_UTILITY_WHEEL_HOTBAR_CATEGORY_HIDDEN and actionId and actionType and utilityWheel:IsActionTypeSupported(actionType) then
            local slottedEmotes = ZO_GetUtilityWheelSlottedEntries(hotbarCategory)

            local matchingSlots = {}
            for i, slotData in ipairs(slottedEmotes) do
                if slotData.type == actionType and slotData.id == actionId then
                    table.insert(matchingSlots, slotData.slotIndex)
                end
            end

            --If the emote/quick chat is slotted in at least one slot, show the Remove option
            if #matchingSlots > 0 then
                AddMenuItem(GetString(SI_ABILITY_ACTION_CLEAR_SLOT), function()
                    for i, slotIndex in ipairs(matchingSlots) do
                        ClearSlot(slotIndex, hotbarCategory)
                    end
                end)
            else
                --If the emote/quick chat is not slotted, show the Assign option
                local validSlot = GetFirstFreeValidSlotForSimpleAction(actionType, actionId, hotbarCategory)
                if validSlot then
                    AddMenuItem(GetString(SI_PLAYER_EMOTE_ASSIGN_EMOTE), function()
                        SelectSlotSimpleAction(actionType, actionId, validSlot, hotbarCategory)
                    end)
                end
            end
        end

        ShowMenu(control)
    end
end