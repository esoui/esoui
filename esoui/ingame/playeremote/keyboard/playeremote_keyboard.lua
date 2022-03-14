local TOTALS_EMOTES_IN_ONE_COLUMN = 22
local NUM_OF_COLUMNS = 4
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
    control.owner = self
    local wheelData =
    {
        --TODO: Currently not used
        restrictToActionTypes =
        {
            [ACTION_TYPE_EMOTE] = true,
            [ACTION_TYPE_QUICK_CHAT] = true,
        },
        numSlots = ACTION_BAR_EMOTE_QUICK_SLOT_SIZE,
        startSlotIndex = ACTION_BAR_FIRST_EMOTE_QUICK_SLOT_INDEX,
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
                                                                        --TODO: Re-enable this
                                                                        --KEYBIND_STRIP:AddKeybindButtonGroup(self.keybindStripDescriptor)
                                                                    elseif newState == SCENE_FRAGMENT_HIDDEN then
                                                                        --TODO: Re-enable this
                                                                        --KEYBIND_STRIP:RemoveKeybindButtonGroup(self.keybindStripDescriptor)
                                                                    end
                                                                end)
                                                                
    --TODO: Include this fragment in the scene
    HELP_KEYBOARD_PLAYER_EMOTE_WHEEL_FRAGMENT = ZO_FadeSceneFragment:New(self.wheelControl)
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
    self:InitializeEmoteControlPool()
    self:InitializeKeybindStripDescriptors()
end

function ZO_PlayerEmote_Keyboard:InitializeKeybindStripDescriptors()
    self.keybindStripDescriptor =
    {
        alignment = KEYBIND_STRIP_ALIGN_CENTER,
        {
            name = GetString(SI_HELP_EMOTES_TOGGLE_EMOTE_WHEEL),
            keybind = "UI_SHORTCUT_SECONDARY",
            callback = function()
                if HELP_KEYBOARD_PLAYER_EMOTE_WHEEL_FRAGMENT:IsShowing() then
                    HELP_EMOTES_SCENE:RemoveFragment(HELP_KEYBOARD_PLAYER_EMOTE_WHEEL_FRAGMENT)
                    ClearCursor()
                else
                    HELP_EMOTES_SCENE:AddFragment(HELP_KEYBOARD_PLAYER_EMOTE_WHEEL_FRAGMENT)
                end
            end,
        },
    }
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
            self:UpdateEmotes(data.emoteCategory)
        end
        CategorySetup(nil, control, data, selected)
    end

    self.categoryTree:AddTemplate("ZO_IconChildlessHeader", CategorySetup, CategorySelected, nil)
    self.categoryTree:SetExclusive(true)
end

function ZO_PlayerEmote_Keyboard:InitializeEmoteControlPool()
    local function EmoteTextControlFactory(pool)
        local control = ZO_ObjectPool_CreateNamedControl("EmoteText", "ZO_PlayerEmote_Keyboard_EmoteText", pool, self.control)

        if not self.firstEmoteInColumn then
            self.firstEmoteInColumn = control
            self.totalEmotesInCurrentColumn = 1
            control:SetAnchor(TOPLEFT, self.control:GetNamedChild("EmoteContainer"), TOPLEFT)
        else
            if self.totalEmotesInCurrentColumn > TOTALS_EMOTES_IN_ONE_COLUMN then
                self.totalEmotesInCurrentColumn = 1
                control:SetAnchor(TOPLEFT, self.firstEmoteInColumn, TOPRIGHT)
                self.firstEmoteInColumn = control
            else
                self.totalEmotesInCurrentColumn = self.totalEmotesInCurrentColumn + 1
                control:SetAnchor(TOPLEFT, self.lastEmote, BOTTOMLEFT, 0, 0)
            end
        end

        self.lastEmote = control

        return control
    end

    local function EmoteTextControlReset(control)
        control:SetText("")
        control.data = nil
        ZO_ObjectPool_DefaultResetControl(control)
    end

    --Uses an object pool because we don't want the default control pool behavior of clearing anchors when a control is released back into the pool
    self.emoteControlPool = ZO_ObjectPool:New(EmoteTextControlFactory, EmoteTextControlReset)
    self.emoteControlPool:SetCustomAcquireBehavior(function(control)
        control:SetHidden(false)
    end)
end

function ZO_PlayerEmote_Keyboard:UpdateCategories()
    local oldSelectedData = self.categoryTree:GetSelectedData()
    local oldSelectedCategory
    if oldSelectedData then
        oldSelectedCategory = oldSelectedData.emoteCategory
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

function ZO_PlayerEmote_Keyboard:UpdateEmotes(category)
    self.emoteControlPool:ReleaseAllObjects()

    if category == QUICK_CHAT_CATEGORY then
        local quickChatList = QUICK_CHAT_MANAGER:BuildQuickChatList()
        for i, quickChatId in ipairs(quickChatList) do
            if i <= NUM_OF_COLUMNS * TOTALS_EMOTES_IN_ONE_COLUMN then
                local quickChatControl = self.emoteControlPool:AcquireObject(i)
                quickChatControl:SetText(QUICK_CHAT_MANAGER:GetFormattedQuickChatName(quickChatId))
                local quickChatData = 
                {
                    quickChatId = quickChatId,
                    isOverriddenByPersonality = false, 
                }
                quickChatControl.data = quickChatData
                ZO_SelectableLabel_SetNormalColor(quickChatControl, ZO_NORMAL_TEXT)
            else
                break
            end
        end
    else
        local emoteList = PLAYER_EMOTE_MANAGER:GetEmoteListForType(category)

        for i, emote in ipairs(emoteList) do
            if i <= NUM_OF_COLUMNS * TOTALS_EMOTES_IN_ONE_COLUMN then
                local emoteInfo = PLAYER_EMOTE_MANAGER:GetEmoteItemInfo(emote)

                local emoteControl = self.emoteControlPool:AcquireObject(i)
                emoteControl.data = emoteInfo

                if emoteInfo.isOverriddenByPersonality then
                    ZO_SelectableLabel_SetNormalColor(emoteControl, ZO_PERSONALITY_EMOTES_COLOR)
                else
                    ZO_SelectableLabel_SetNormalColor(emoteControl, ZO_NORMAL_TEXT)
                end
                emoteControl:SetText(emoteInfo.emoteSlashName)
            else
                break
            end
        end
    end
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
    if HELP_KEYBOARD_PLAYER_EMOTE_WHEEL_FRAGMENT:IsShowing() and GetCursorContentType() == MOUSE_CONTENT_EMPTY then
        if control.data.emoteId then
            PickupEmoteById(control.data.emoteId)
        elseif control.data.quickChatId then
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

        --Only include the following options if the wheel is toggled on
        if HELP_KEYBOARD_PLAYER_EMOTE_WHEEL_FRAGMENT:IsShowing() and actionId and actionType then
            local slottedEmotes = PLAYER_EMOTE_MANAGER:GetSlottedEmotes()

            --TODO: Do we want to be allowing emotes to be in multiple slots at once?
            local matchingSlots = {}
            for i, slotData in ipairs(slottedEmotes) do
                if slotData.id == actionId then
                    table.insert(matchingSlots, slotData.slotIndex)
                end
            end

            --If the emote/quick chat is slotted in at least one slot, show the Remove option
            if #matchingSlots > 0 then
                AddMenuItem(GetString(SI_ABILITY_ACTION_CLEAR_SLOT), function()
                    for i, slotIndex in ipairs(matchingSlots) do
                        ClearSlot(slotIndex)
                    end
                end)
            else
                --If the emote/quick chat is not slotted, show the Assign option
                local validSlot = GetFirstFreeValidSlotForSimpleAction(actionType, actionId)
                if validSlot then
                    AddMenuItem(GetString(SI_PLAYER_EMOTE_ASSIGN_EMOTE), function()
                        SelectSlotSimpleAction(actionType, actionId, validSlot)
                    end)
                end
            end
        end

        ShowMenu(control)
    end
end