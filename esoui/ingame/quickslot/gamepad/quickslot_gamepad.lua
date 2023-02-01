ZO_Quickslot_Gamepad = ZO_InitializingObject:Subclass()

local QUICKSLOT_ASSIGNMENT_TYPE_ITEM = 1
local QUICKSLOT_ASSIGNMENT_TYPE_COLLECTIBLE = 2
local QUICKSLOT_ASSIGNMENT_TYPE_QUEST_ITEM = 3

function ZO_Quickslot_Gamepad:Initialize(control)
    self.control = control

    local container = control:GetNamedChild("Container")
    self.wheelControl = container:GetNamedChild("Radial")

    local function OnSelectionChangedCallback(selectedEntry)
        self:OnSelectionChanged(selectedEntry)
    end

    local wheelData =
    {
        hotbarCategories = { HOTBAR_CATEGORY_QUICKSLOT_WHEEL },
        numSlots = ACTION_BAR_UTILITY_BAR_SIZE,
        showPendingIcon = true,
        showCategoryLabel = true,
        onSelectionChangedCallback = OnSelectionChangedCallback,
        overrideGamepadTooltip = GAMEPAD_LEFT_TOOLTIP,
        customNarrationObjectName = "QuickslotAssignableUtilityWheel",
        headerNarrationFunction = function()
            local narrations = {}
            local pendingData = self.wheel:GetPendingData()
            if self.assignmentType == QUICKSLOT_ASSIGNMENT_TYPE_COLLECTIBLE then
                --If we are trying to assign a collectible, treat it like one in the narration
                ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(GetString(SI_GAMEPAD_COLLECTIBLE_ASSIGN_INSTRUCTIONS)))
                local collectibleData = ZO_COLLECTIBLE_DATA_MANAGER:GetCollectibleDataById(pendingData.actionId)
                if collectibleData then
                    ZO_AppendNarration(narrations, collectibleData:GetFormattedName())
                end
            elseif self.assignmentType == QUICKSLOT_ASSIGNMENT_TYPE_QUEST_ITEM then
                --If we are trying to assign a quest item, treat it like one in the narration
                ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(GetString(SI_GAMEPAD_INVENTORY_ASSIGN_INSTRUCTIONS_NARRATION)))
                ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(zo_strformat(SI_TOOLTIP_ITEM_NAME, GetQuestItemName(pendingData.actionId))))
            elseif self.assignmentType == QUICKSLOT_ASSIGNMENT_TYPE_ITEM then
                --If we are trying to assign an item, treat it like one in the narration
                ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(GetString(SI_GAMEPAD_INVENTORY_ASSIGN_INSTRUCTIONS_NARRATION)))
                ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(zo_strformat(SI_TOOLTIP_ITEM_NAME, GetItemName(pendingData.bagId, pendingData.itemSlotIndex))))
            else
                internalassert(false, "Attempting to narrate unknown quickslot assignment type")
            end
            return narrations
        end,
    }
    self.wheel = ZO_AssignableUtilityWheel_Gamepad:New(self.wheelControl, wheelData)
    self.wheel:SetCustomSparkleStopCallback(function() SCENE_MANAGER:Hide("gamepad_quickslot") end)

    self.header = container:GetNamedChild("HeaderContainer").header
    ZO_GamepadGenericHeader_Initialize(self.header, ZO_GAMEPAD_HEADER_TABBAR_DONT_CREATE)

    GAMEPAD_QUICKSLOT_SCENE = ZO_Scene:New("gamepad_quickslot", SCENE_MANAGER)
    GAMEPAD_QUICKSLOT_SCENE:RegisterCallback("StateChange", function(oldState, newState)
        if newState == SCENE_SHOWING then
            self:PerformDeferredInitialization()
            self:RefreshHeader()
            local UNSLOT_PENDING_ENTRY = true
            self.wheel:Show(UNSLOT_PENDING_ENTRY)
            KEYBIND_STRIP:AddKeybindButtonGroup(self.navigationKeybindDescriptor)
        elseif newState == SCENE_HIDING then
            self.wheel:Hide()
        elseif newState == SCENE_HIDDEN then
            GAMEPAD_TOOLTIPS:Reset(GAMEPAD_LEFT_TOOLTIP)
            KEYBIND_STRIP:RemoveKeybindButtonGroup(self.navigationKeybindDescriptor)
            KEYBIND_STRIP:RemoveKeybindButtonGroup(self.assignKeybindDescriptor)
        end
    end)
end

function ZO_Quickslot_Gamepad:OnSelectionChanged(selectedEntry)
    if not self.wheel:GetPendingData() then
        KEYBIND_STRIP:RemoveKeybindButtonGroup(self.assignKeybindDescriptor)
    else
        KEYBIND_STRIP:AddKeybindButtonGroup(self.assignKeybindDescriptor)
    end
end

function ZO_Quickslot_Gamepad:PerformDeferredInitialization()
    if self.navigationKeybindDescriptor then
        return 
    end

    self:InitializeHeader()
    self:InitializeKeybindStrip()
end

function ZO_Quickslot_Gamepad:InitializeKeybindStrip()
    self.navigationKeybindDescriptor = {}

    self.assignKeybindDescriptor =
    {
        {
            alignment = KEYBIND_STRIP_ALIGN_LEFT,
            name = GetString(SI_GAMEPAD_ITEM_ACTION_QUICKSLOT_ASSIGN),
            keybind = "UI_SHORTCUT_PRIMARY",
            order = -500,
            callback = function() 
                local CLEAR_PENDING_DATA = true
                self.wheel:TryAssignPendingToSelectedEntry(CLEAR_PENDING_DATA) 
            end,
        }
    }

    ZO_Gamepad_AddBackNavigationKeybindDescriptors(self.navigationKeybindDescriptor, GAME_NAVIGATION_TYPE_BUTTON)
end

local function UpdateAlliancePoints(control)
    ZO_CurrencyControl_SetSimpleCurrency(control, CURT_ALLIANCE_POINTS, GetCurrencyAmount(CURT_ALLIANCE_POINTS, CURRENCY_LOCATION_CHARACTER), ZO_GAMEPAD_CURRENCY_OPTIONS)
    return true
end

local function UpdateGold(control)
    ZO_CurrencyControl_SetSimpleCurrency(control, CURT_MONEY, GetCurrencyAmount(CURT_MONEY, CURRENCY_LOCATION_CHARACTER), ZO_GAMEPAD_CURRENCY_OPTIONS_LONG_FORMAT)
    return true
end

local function UpdateCapacityString()
    return zo_strformat(SI_GAMEPAD_INVENTORY_CAPACITY_FORMAT, GetNumBagUsedSlots(BAG_BACKPACK), GetBagSize(BAG_BACKPACK))
end

function ZO_Quickslot_Gamepad:InitializeHeader()
    local function RefreshHeader()
        if not self.control:IsHidden() then
            self:RefreshHeader()
        end
    end

    self:RefreshHeader()

    self.control:RegisterForEvent(EVENT_MONEY_UPDATE, RefreshHeader)
    self.control:RegisterForEvent(EVENT_ALLIANCE_POINT_UPDATE, RefreshHeader)
    self.control:RegisterForEvent(EVENT_INVENTORY_FULL_UPDATE, RefreshHeader)
    self.control:RegisterForEvent(EVENT_INVENTORY_SINGLE_SLOT_UPDATE, RefreshHeader)
end

function ZO_Quickslot_Gamepad:RefreshHeader()
    if self.assignmentType == QUICKSLOT_ASSIGNMENT_TYPE_COLLECTIBLE then
        self.headerData = 
        { 
            titleText = GetString(SI_MAIN_MENU_COLLECTIONS)
        }
    elseif self.assignmentType == QUICKSLOT_ASSIGNMENT_TYPE_ITEM then
        self.headerData = 
        {
            data1HeaderText = GetString(SI_GAMEPAD_INVENTORY_AVAILABLE_FUNDS),
            data1Text = UpdateGold,

            data2HeaderText = GetString(SI_GAMEPAD_INVENTORY_ALLIANCE_POINTS),
            data2Text = UpdateAlliancePoints,

            data3HeaderText = GetString(SI_GAMEPAD_INVENTORY_CAPACITY),
            data3Text = UpdateCapacityString,

            titleText = GetString(SI_GAMEPAD_INVENTORY_CONSUMABLES),
        }
    elseif self.assignmentType == QUICKSLOT_ASSIGNMENT_TYPE_QUEST_ITEM then
        self.headerData = 
        { 
            data1HeaderText = GetString(SI_GAMEPAD_INVENTORY_AVAILABLE_FUNDS),
            data1Text = UpdateGold,

            data2HeaderText = GetString(SI_GAMEPAD_INVENTORY_ALLIANCE_POINTS),
            data2Text = UpdateAlliancePoints,

            data3HeaderText = GetString(SI_GAMEPAD_INVENTORY_CAPACITY),
            data3Text = UpdateCapacityString,

            titleText = GetString(SI_GAMEPAD_INVENTORY_QUEST_ITEMS)
        }
    else
        internalassert(false, "Unsupported assignment type")
    end

    ZO_GamepadGenericHeader_Refresh(self.header, self.headerData)
end

function ZO_Quickslot_Gamepad:SetItemToQuickslot(bagId, slotIndex)
    self.assignmentType = QUICKSLOT_ASSIGNMENT_TYPE_ITEM
    self.wheel:SetPendingItem(bagId, slotIndex)
end

function ZO_Quickslot_Gamepad:SetCollectibleToQuickslot(collectibleId)
    self.assignmentType = QUICKSLOT_ASSIGNMENT_TYPE_COLLECTIBLE
    self.wheel:SetPendingSimpleAction(ACTION_TYPE_COLLECTIBLE, collectibleId)
end

function ZO_Quickslot_Gamepad:SetQuestItemToQuickslot(questItemId)
    self.assignmentType = QUICKSLOT_ASSIGNMENT_TYPE_QUEST_ITEM
    self.wheel:SetPendingSimpleAction(ACTION_TYPE_QUEST_ITEM, questItemId)
end

function ZO_Quickslot_Gamepad_Initialize(control)
    GAMEPAD_QUICKSLOT = ZO_Quickslot_Gamepad:New(control)
end