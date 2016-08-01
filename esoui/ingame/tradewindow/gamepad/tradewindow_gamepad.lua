-- Definitions
local ATTACH_GOLD_ICON = "EsoUI/Art/TradeWindow/Gamepad/gp_tradeAddGold.dds"
local ADD_ATTACHMENT_ICON = "EsoUI/Art/TradeWindow/Gamepad/gp_tradeAddItem.dds"
local EMPTY_ATTACHMENT_ICON = "EsoUI/Art/TradeWindow/Gamepad/gp_tradeEmptyItem.dds"

local TRADE_ITEM_ENTRY_TEMPLATE = "ZO_GamepadItemSubEntryTemplate"

local ATTACH_GOLD_TEXT = GetString(SI_GAMEPAD_TRADE_ATTACH_GOLD)
local ATTACH_ITEMS_TEXT = GetString(SI_GAMEPAD_TRADE_ATTACH_ITEMS)
local EMPTY_SLOT_TEXT = GetString(SI_GAMEPAD_TRADE_EMPTY_SLOT)

--These functions handle updating the UI as we go between confimation states.
--An entry [A][B] holds the function that can move the UI from confirm state A to confirm state B.
local ConfirmChangeFunctions =
{
    [TRADE_ME] = {
        [TRADE_CONFIRM_EDIT] = {
            [TRADE_CONFIRM_ACCEPT] = function()
                GAMEPAD_TRADE:EnterConfirmation(TRADE_ME)
            end
        },
        [TRADE_CONFIRM_ACCEPT] = {
            [TRADE_CONFIRM_EDIT] = function()
                GAMEPAD_TRADE:ExitConfirmation(TRADE_ME)
            end,
        }
    },
    [TRADE_THEM] = {
        [TRADE_CONFIRM_EDIT] = {
            [TRADE_CONFIRM_ACCEPT] = function()
                GAMEPAD_TRADE:EnterConfirmation(TRADE_THEM)
            end
        },
        [TRADE_CONFIRM_ACCEPT] = {
            [TRADE_CONFIRM_EDIT] = function()
                GAMEPAD_TRADE:ExitConfirmation(TRADE_THEM)
            end,
        }
    },
}

-- Window has two views
local VIEW_OFFER = 1
local VIEW_INVENTORY = 2

-----------------
-- Initialization
-----------------
ZO_GamepadTradeWindow = ZO_Object.MultiSubclass(ZO_SharedTradeWindow, ZO_Gamepad_ParametricList_Screen)

function ZO_GamepadTradeWindow:New(control)
    local tradeWindow = ZO_Object.New(self)
    tradeWindow:Initialize(control)
    return tradeWindow
end

function ZO_GamepadTradeWindow:Initialize(control)
    self.tradeScene = ZO_Scene:New("gamepadTrade", SCENE_MANAGER)

    local DONT_ACTIVATE_ON_SHOW = false
    ZO_Gamepad_ParametricList_Screen.Initialize(self, control, ZO_GAMEPAD_HEADER_TABBAR_DONT_CREATE, DONT_ACTIVATE_ON_SHOW, self.tradeScene)
    ZO_SharedTradeWindow.Initialize(self, self.control)
end

function ZO_GamepadTradeWindow:PerformDeferredInitialization()
    if self.isFullyInitialized then
        return
    end
    self.isFullyInitialized = true

    local function HandleInventoryChanged()
        if not self.control:IsHidden() then
            self:RefreshOfferList(TRADE_ME)
        end
    end
    self.control:RegisterForEvent(EVENT_INVENTORY_FULL_UPDATE, HandleInventoryChanged)
    self.control:RegisterForEvent(EVENT_INVENTORY_SINGLE_SLOT_UPDATE, HandleInventoryChanged)

    self.sceneName = "gamepadTrade"
    self.confirmChangeFunctions = ConfirmChangeFunctions

    self.theirControls = self.control:GetNamedChild("TheirControls")

    -- Gold Slider
    self.goldSliderControl = self.control:GetNamedChild("Mask"):GetNamedChild("GoldSliderBox")
    self.goldSlider = ZO_CurrencySelector_Gamepad:New(self.goldSliderControl:GetNamedChild("Selector"))
    self.goldSlider:SetClampValues(true)

    self:InitializeOfferLists()
    self:InitializeInventoryList()
    self:InitializeHeaders()
end

function ZO_GamepadTradeWindow:InitializeOfferLists()
    -- Offer Lists
    self.lists = {}
    self.listTradeItemCount = {}
    self.offeredMoney = {}

    self:SetupOfferList(TRADE_ME)
    self:SetupOfferList(TRADE_THEM)

    self.lists[TRADE_ME]:SetDirectionalInputEnabled(false)
    self.lists[TRADE_THEM]:SetDirectionalInputEnabled(false)
    self.listMovementController = ZO_MovementController:New(MOVEMENT_CONTROLLER_DIRECTION_VERTICAL)
    self.activeListType = TRADE_ME
end

do
    local function SetupList(list)
        list:AddDataTemplate(TRADE_ITEM_ENTRY_TEMPLATE, ZO_SharedGamepadEntry_OnSetup, ZO_GamepadMenuEntryTemplateParametricListFunction)
    end

    function ZO_GamepadTradeWindow:SetupOfferList(tradetype)
        local list = nil
        if tradetype == TRADE_ME then
            list = self:AddList("MyOffer", SetupList)
        else
            -- Parametric list screen assumes that its lists operate in the nav 1 panel.
            -- In order to have another list be in a different panel, it can't be grouped with all the lists the 
            -- base class keeps track of
            list = ZO_GamepadVerticalItemParametricScrollList:New(self.theirControls:GetNamedChild("Mask"):GetNamedChild("Container"):GetNamedChild("List"))
            SetupList(list)
            list:SetAlignToScreenCenter(true)
            list:SetOnSelectedDataChangedCallback(function(list, selectedData) self:OnSelectionChanged(list, selectedData) end)
        end

        list:SetNoItemText(GetString(SI_GAMEPAD_TRADE_NO_ITEMS_OFFERED))
        list.tradetype = tradetype
        list:Activate()
        self.lists[tradetype] = list
    end
end

do
    local function ItemFilter(itemData)
        return TRADE_WINDOW:CanTradeItem(itemData) and not ZO_IsItemCurrentlyOfferedForTrade(itemData.bagId, itemData.slotIndex)
    end

    function ZO_GamepadTradeWindow:InitializeInventoryList()
        local SETUP_LOCALLY = true
        self.inventoryList = self:AddList("Inventory", SETUP_LOCALLY, ZO_GamepadInventoryList, BAG_BACKPACK, SLOT_TYPE_ITEM, 
                                            function(_, selectedData) 
                                                self:InventorySelectionChanged(selectedData) 
                                            end, InventorySetupFunction)
        self.inventoryList:SetItemFilterFunction(ItemFilter)
    end
end

function ZO_GamepadTradeWindow:AddOfferListEntry(list, text, icon, callback, modifyTextType)
    local newEntry = ZO_GamepadEntryData:New(text, icon)
    newEntry:SetFontScaleOnSelection(false)
    newEntry.actionFunction = callback
    
    newEntry:SetModifyTextType(modifyTextType or MODIFY_TEXT_TYPE_NONE)
    list:AddEntry(TRADE_ITEM_ENTRY_TEMPLATE, newEntry)
    return newEntry
end

function ZO_GamepadTradeWindow:InitializeHeaders()
    
    local theirHeader = self.theirControls:GetNamedChild("Mask"):GetNamedChild("HeaderContainer"):GetNamedChild("Header")
    theirHeader.dividerSimple = theirHeader:GetNamedChild("DividerSimple")
    theirHeader.dividerAccent = theirHeader:GetNamedChild("DividerAccent")
    ZO_GamepadGenericHeader_Initialize(theirHeader, ZO_GAMEPAD_HEADER_TABBAR_DONT_CREATE)

    local myHeader = self.header
    myHeader.dividerSimple = myHeader:GetNamedChild("DividerSimple")
    myHeader.dividerAccent = myHeader:GetNamedChild("DividerAccent")

    self.headers = 
    {
        [TRADE_THEM] = theirHeader,
        [TRADE_ME] = myHeader,
    }

    self:UpdateHeaders()
end

---------
--Updates
---------
function ZO_GamepadTradeWindow:UpdateDirectionalInput()
    local list = self.lists[self.activeListType]
    local move = self.listMovementController:CheckMovement()

    -- Pass the movement to the correct list
    if move == MOVEMENT_CONTROLLER_MOVE_NEXT then
        list:MoveNext()
    elseif move == MOVEMENT_CONTROLLER_MOVE_PREVIOUS then
        list:MovePrevious()
    end
end

function ZO_GamepadTradeWindow:RefreshCanSwitchFocus()
    local canSwitch = self.view ~= VIEW_INVENTORY and self.listTradeItemCount[TRADE_THEM] and self.listTradeItemCount[TRADE_THEM] > 0
    self.headers[TRADE_ME].dividerSimple:SetHidden(canSwitch)
    self.headers[TRADE_ME].dividerAccent:SetHidden(not canSwitch)
    self.headers[TRADE_THEM].dividerSimple:SetHidden(canSwitch)
    self.headers[TRADE_THEM].dividerAccent:SetHidden(not canSwitch)
    self.canSwitchFocus = canSwitch
    if not canSwitch then
        self:SetOfferFocus(TRADE_ME)
    end
end

function ZO_GamepadTradeWindow:SetOfferFocus(listType)
    if self.activeListType == listType or (not self.canSwitchFocus and listType == TRADE_THEM) then 
        return 
    end

    if listType == TRADE_ME then
        GAMEPAD_NAV_QUADRANT_4_BACKGROUND_FRAGMENT:ClearFocus()
        GAMEPAD_NAV_QUADRANT_1_BACKGROUND_FRAGMENT:TakeFocus()
        PlaySound(SOUNDS.GAMEPAD_PAGE_BACK)
    else
        if self.view == VIEW_INVENTORY then
            return
        end
        GAMEPAD_NAV_QUADRANT_1_BACKGROUND_FRAGMENT:ClearFocus()
        GAMEPAD_NAV_QUADRANT_4_BACKGROUND_FRAGMENT:TakeFocus()
        PlaySound(SOUNDS.GAMEPAD_PAGE_FORWARD)
    end

    self.activeListType = listType
    self:RefreshKeybind()
    self:RefreshTooltips()
end

do
    local function UpdatePlayerGold(control)
        ZO_CurrencyControl_SetSimpleCurrency(control, CURT_MONEY, GetCarriedCurrencyAmount(CURT_MONEY), ZO_GAMEPAD_CURRENCY_OPTIONS_LONG_FORMAT)
        return true
    end

    local function GetInventoryString()
        return zo_strformat(SI_GAMEPAD_TRADE_INVENTORY_SPACES, GetNumBagUsedSlots(BAG_BACKPACK), GetBagSize(BAG_BACKPACK))
    end

    function ZO_GamepadTradeWindow:UpdateGoldOfferValue(control, tradeType)
        ZO_CurrencyControl_SetSimpleCurrency(control, CURT_MONEY, self.offeredMoney[tradeType] or 0, ZO_GAMEPAD_CURRENCY_OPTIONS_LONG_FORMAT)
        return true
    end

    function ZO_GamepadTradeWindow:UpdateHeaders()
        self.myName = ZO_GetPrimaryPlayerName(GetUnitDisplayName("player"), GetUnitName("player"))
        local myTitle
        if self.confirm[TRADE_ME] == TRADE_CONFIRM_EDIT then
            myTitle = zo_strformat(SI_GAMEPAD_TRADE_USERNAME, self.myName)
        else
            myTitle = GetString(SI_GAMEPAD_TRADE_READY)
        end

        --The other trader doesn't say not ready and doesn't say 0 gold offered
        local theirTitle, theirGoldHeader, theirGoldValue
        
        if self.confirm[TRADE_THEM] == TRADE_CONFIRM_EDIT then
            theirTitle = zo_strformat(SI_GAMEPAD_TRADE_USERNAME, TRADE_WINDOW.target)
        else
            theirTitle = GetString(SI_GAMEPAD_TRADE_READY)
        end 

        if self.offeredMoney[TRADE_THEM] and self.offeredMoney[TRADE_THEM] > 0 then
            theirGoldHeader = GetString(SI_GAMEPAD_TRADE_OFFERED_GOLD)
            theirGoldValue = function(control) return self:UpdateGoldOfferValue(control, TRADE_THEM) end
        end

        self.headerData = {
            [TRADE_ME] = {
                titleText = myTitle,

                data1HeaderText = GetString(SI_GAMEPAD_TRADE_INVENTORY),
                data1Text = GetInventoryString,
            
                data2HeaderText = GetString(SI_GAMEPAD_TRADE_PLAYER_GOLD),
                data2Text = UpdatePlayerGold,

                data3HeaderText = GetString(SI_GAMEPAD_TRADE_OFFERED_GOLD),
                data3Text = function(control) return self:UpdateGoldOfferValue(control, TRADE_ME) end,
            },
            [TRADE_THEM] = {
                titleText = theirTitle,

                data1HeaderText = theirGoldHeader,
                data1Text = theirGoldValue,
            },
        }

        ZO_GamepadGenericHeader_Refresh(self.headers[TRADE_ME], self.headerData[TRADE_ME])
        ZO_GamepadGenericHeader_Refresh(self.headers[TRADE_THEM], self.headerData[TRADE_THEM])
    end
end

local function InventorySetupFunction(entryData)
    entryData.isTradeItem = ZO_IsItemCurrentlyOfferedForTrade(entryData.bagId, entryData.slotIndex)
end

function ZO_GamepadTradeWindow:InventorySelectionChanged(inventoryData)
    if self.view == VIEW_OFFER then return end
    
    if inventoryData then
        self.bagId = inventoryData.bagId
        self.slotIndex = inventoryData.slotIndex
        GAMEPAD_TOOLTIPS:LayoutBagItem(GAMEPAD_LEFT_TOOLTIP, self.bagId, self.slotIndex)
    else
        self.bagId = nil
        self.slotIndex = nil
        GAMEPAD_TOOLTIPS:ClearTooltip(GAMEPAD_LEFT_TOOLTIP)
    end

    self:RefreshKeybind()
end

function ZO_GamepadTradeWindow:ShowGoldSliderControl(value, maxValue)
    PlaySound(SOUNDS.GAMEPAD_MENU_FORWARD)

    local currentGold = self.lists[TRADE_ME]:GetTargetControl()
    currentGold:SetHidden(true)

    self.goldSlider:SetMaxValue(maxValue)
    self.goldSlider:SetValue(value)

    self:SwitchToKeybind(self.keybindStripDescriptorGoldSlider)
    self.goldSlider:Activate()
    self.goldSliderControl:SetHidden(false)
end

function ZO_GamepadTradeWindow:HideGoldSliderControl()
    local currentGold = self.lists[TRADE_ME]:GetTargetControl()
    currentGold:SetHidden(false)

    self.goldSlider:Deactivate()
    self.goldSliderControl:SetHidden(true)

    self:SwitchToKeybind(self.keybindStripDescriptorOffer)
end

function ZO_GamepadTradeWindow:OnSelectionChanged(list, item)
    local tradetype = list.tradetype

    local tooltip = tradetype == TRADE_ME and GAMEPAD_LEFT_TOOLTIP or GAMEPAD_QUAD3_TOOLTIP
    
    if self.activeListType == tradetype then
        if item and item.tradeIndex then
            GAMEPAD_TOOLTIPS:LayoutTradeItem(tooltip, tradetype, item.tradeIndex)
        else
            GAMEPAD_TOOLTIPS:ClearTooltip(tooltip)
        end
    end
    self:RefreshKeybind()
end

function ZO_GamepadTradeWindow:RefreshTooltips()
    local tradetype = self.activeListType

    if tradetype == TRADE_ME then
        GAMEPAD_TOOLTIPS:ClearTooltip(GAMEPAD_QUAD3_TOOLTIP)
        if self.view == VIEW_INVENTORY then
            self:InventorySelectionChanged(self.inventoryList:GetTargetData())
        else
            self:OnSelectionChanged(self.lists[TRADE_ME], self.lists[TRADE_ME]:GetTargetData())
        end
    else
        GAMEPAD_TOOLTIPS:ClearTooltip(GAMEPAD_LEFT_TOOLTIP)
        self:OnSelectionChanged(self.lists[TRADE_THEM], self.lists[TRADE_THEM]:GetTargetData())
    end
end

function ZO_GamepadTradeWindow:RefreshOfferList(tradetype, list)
    local list = list or self.lists[tradetype]
    local isMyEdit = tradetype == TRADE_ME and self.confirm[tradetype] == TRADE_CONFIRM_EDIT

    local lastSelectedIndex = list.selectedIndex or 1

    if list.Clear then
        list:Clear()
    else
        for _, entry in ipairs(list.data) do
            entry.control:SetHidden(true)
        end
    end
    
    if isMyEdit then
        local actionFunction = function() 
                                    if(IsUnitDead("player")) then
                                        ZO_AlertEvent(EVENT_UI_ERROR, SI_CANNOT_DO_THAT_WHILE_DEAD)
                                    else
                                        self:ShowGoldSliderControl(self.offeredMoney[TRADE_ME] or 0, GetCarriedCurrencyAmount(CURT_MONEY))
                                    end
                               end
        self:AddOfferListEntry(list, ATTACH_GOLD_TEXT, ATTACH_GOLD_ICON, actionFunction, MODIFY_TEXT_TYPE_UPPERCASE)
    end
    
    local function SwitchToInventory(tradeIndex)
        PlaySound(SOUNDS.GAMEPAD_MENU_FORWARD)
        self:SwitchView(VIEW_INVENTORY)
        self.desiredTradeIndex = tradeIndex
    end

    local first = true
    self.listTradeItemCount[tradetype] = 0
    for i = 1, TRADE_NUM_SLOTS do
        local itemLink = GetTradeItemLink(tradetype, i, LINK_STYLE_DEFAULT)

        if itemLink and itemLink ~= "" then
            local text, icon, stackCount, quality, creator, sellPrice, meetsUsageRequirement, equipType, itemStyle = GetTradeItemInfo(tradetype, i)

            text = zo_strformat(SI_TOOLTIP_ITEM_NAME_WITH_QUANTITY, text, stackCount)

            local itemData = {
                        text = text,
                        icon = icon,
                        quality = quality,
                        stackCount = stackCount,
                        sellPrice = sellPrice,
                        meetsUsageRequirement = meetsUsageRequirement,
                        equipType = equipType,
                        itemStyle = itemStyle,
                        creator = creator,
                        itemLink = itemLink,
                        tradeIndex = i,
                    }

            local entry = self:AddOfferListEntry(list, text, nil, function() TradeRemoveItem(i) end)
            entry:InitializeInventoryVisualData(itemData)

            self.listTradeItemCount[tradetype] = self.listTradeItemCount[tradetype] + 1
        elseif isMyEdit then
            local text = ATTACH_ITEMS_TEXT
            local icon = ADD_ATTACHMENT_ICON
            local action =  function()
                                if(IsUnitDead("player")) then
                                    ZO_AlertEvent(EVENT_UI_ERROR, SI_CANNOT_DO_THAT_WHILE_DEAD)
                                else
                                    SwitchToInventory(i)
                                end
                             end
            self:AddOfferListEntry(list, text, icon, action, MODIFY_TEXT_TYPE_UPPERCASE)
        end
    end

    if list.Commit then list:Commit() end
    self:UpdateHeaders()
    self:RefreshCanSwitchFocus()

    --- Preserve selection
    local ALLOW_EVEN_IF_DISABLED = true
    local FORCE_ANIMATION = false
    list:SetSelectedIndex(lastSelectedIndex, ALLOW_EVEN_IF_DISABLED, FORCE_ANIMATION)
    return list
end

function ZO_GamepadTradeWindow:EnterConfirmation(tradetype)
    local tradeComplete = self.confirm[TRADE_ME] == TRADE_CONFIRM_ACCEPT and self.confirm[TRADE_THEM] == TRADE_CONFIRM_ACCEPT
    ZO_Trade_GamepadWaiting:SetHidden(tradeComplete)
    local name
    if tradetype == TRADE_ME then
        self:RefreshKeybind()
        GAMEPAD_NAV_QUADRANT_1_BACKGROUND_FRAGMENT:SetHighlightHidden(false)
        name = zo_strformat(SI_GAMEPAD_TRADE_USERNAME, TRADE_WINDOW.target)
    else
        GAMEPAD_NAV_QUADRANT_4_BACKGROUND_FRAGMENT:SetHighlightHidden(false)
        name = self.myName
    end

    if not tradeComplete then
        ZO_Trade_GamepadWaiting.name:SetText(name)
    end

    self:RefreshOfferList(tradetype)

    PlaySound(SOUNDS.TRADE_PARTICIPANT_READY)
end

function ZO_GamepadTradeWindow:ExitConfirmation(tradetype)
    ZO_Trade_GamepadWaiting:SetHidden(true)
    if tradetype == TRADE_ME then
        self.lists[TRADE_ME]:RefreshVisible()
        self:RefreshKeybind()
        GAMEPAD_NAV_QUADRANT_1_BACKGROUND_FRAGMENT:ClearHighlight()
    else
        GAMEPAD_NAV_QUADRANT_4_BACKGROUND_FRAGMENT:ClearHighlight()
    end
    
    self:RefreshOfferList(tradetype)

    self:SetConfirmationDelay(TRADE_DELAY_TIME)
    PlaySound(SOUNDS.TRADE_PARTICIPANT_RECONSIDER)
end

function ZO_GamepadTradeWindow:PrepareWindowForNewTrade()
    self:PerformDeferredInitialization()
end

function ZO_GamepadTradeWindow:BeginTrade()
    self.inventoryList:RefreshList()

    self:RefreshOfferList(TRADE_ME)
    self:RefreshOfferList(TRADE_THEM)

    self:SwitchView(VIEW_OFFER)
end

function ZO_GamepadTradeWindow:SwitchView(view)
    self.view = view

    if view == VIEW_INVENTORY then
        self:SwitchToKeybind(self.keybindStripDescriptorInventory)  -- inventoryControl adds conflicting keybinds so this must be done first
        self:SetCurrentList(self.inventoryList)
    else --- VIEW_OFFER
        self:SetCurrentList(self.lists[TRADE_ME])
        self.lists[TRADE_ME]:RefreshVisible()

        self:SwitchToKeybind(self.keybindStripDescriptorOffer)  -- inventoryControl removes conflicting keybinds so this must be done last
    end
    self:RefreshTooltips()
    self:RefreshCanSwitchFocus()
end

----------
--Keybinds
----------
function ZO_GamepadTradeWindow:SwitchToKeybind(keybindStripDescriptor)
    if self.keybindStripDescriptor then
        KEYBIND_STRIP:RemoveKeybindButtonGroup(self.keybindStripDescriptor)
    end
    self.keybindStripDescriptor = keybindStripDescriptor
    if keybindStripDescriptor then
        KEYBIND_STRIP:RemoveDefaultExit()
        KEYBIND_STRIP:AddKeybindButtonGroup(keybindStripDescriptor)
    end
end

function ZO_GamepadTradeWindow:RefreshKeybind()
    if self.keybindStripDescriptor then
        KEYBIND_STRIP:UpdateKeybindButtonGroup(self.keybindStripDescriptor)
    end
end

function ZO_GamepadTradeWindow:GetActiveItemSlot()
    local targetData = self.inventoryList.list:GetTargetData()

    if targetData then
        ZO_InventorySlot_SetType(targetData, SLOT_TYPE_GAMEPAD_INVENTORY_ITEM)
    end

    return targetData
end

function ZO_GamepadTradeWindow:InitializeKeybindDescriptor()
    self.keybindStripDescriptorOffer =
    {
        alignment = KEYBIND_STRIP_ALIGN_LEFT,
        -- Review My Offer
        {
            keybind = "UI_SHORTCUT_LEFT_TRIGGER",

            callback = function()
                self:SetOfferFocus(TRADE_ME)
            end,

            ethereal = true,
        },
        -- Edit Trade
        {
            keybind = "UI_SHORTCUT_PRIMARY",

            name = function()
                local selectedData = self.lists[TRADE_ME]:GetTargetData()
                if selectedData and selectedData.tradeIndex then
                    return GetString(SI_GAMEPAD_TRADE_REMOVE)
                else
                    return GetString(SI_GAMEPAD_TRADE_ADD)
                end
            end,

            callback = function()
                local selectedData = self.lists[TRADE_ME]:GetTargetData()
                if selectedData and selectedData.actionFunction then
                    selectedData:actionFunction()
                end
            end,

            visible = function()
                return self.activeListType == TRADE_ME and self.confirm[TRADE_ME] == TRADE_CONFIRM_EDIT
            end,
        },
        -- Cancel Trade
        {
            keybind = "UI_SHORTCUT_NEGATIVE",

            name = function()
                if self.confirm[TRADE_ME] == TRADE_CONFIRM_ACCEPT then
                    return GetString(SI_GAMEPAD_TRADE_CANCEL_OFFER)
                else
                    return GetString(SI_GAMEPAD_TRADE_CANCEL_TRADE)
                end
            end,

            callback = function()
                if self.confirm[TRADE_ME] == TRADE_CONFIRM_ACCEPT then
                    TradeEdit()
                elseif self.listTradeItemCount[TRADE_ME] ~= 0 or (self.offeredMoney[TRADE_ME] and self.offeredMoney[TRADE_ME] ~= 0) then
                    ZO_Dialogs_ShowGamepadDialog("TRADE_CANCEL_TRADE")
                else
                    SCENE_MANAGER:HideCurrentScene()
                end
            end,

            sound = SOUNDS.DIALOG_DECLINE,
        },
        -- Confirm Trade
        {
            keybind = "UI_SHORTCUT_SECONDARY",
            
            name = GetString(SI_GAMEPAD_TRADE_SUBMIT),

            visible = function()
                return self.confirm[TRADE_ME] == TRADE_CONFIRM_EDIT and self:IsModifyConfirmationLevelEnabled() and not IsUnitDead("player")
            end,

            callback = TradeAccept,
            sound = SOUNDS.DIALOG_ACCEPT,
        },
        -- Review Their Offer
        {
            keybind = "UI_SHORTCUT_RIGHT_TRIGGER",

            callback = function()
                self:SetOfferFocus(TRADE_THEM)
            end,

            ethereal = true,
        }
    }

    local function LeaveInventory()
        PlaySound(SOUNDS.GAMEPAD_MENU_BACK)
        self:SwitchView(VIEW_OFFER)
        self.desiredTradeIndex = nil
    end

    self.keybindStripDescriptorInventory =
    {
        alignment = KEYBIND_STRIP_ALIGN_LEFT,
        -- Edit Trade
        {
            keybind = "UI_SHORTCUT_PRIMARY",
            
            name = GetString(SI_GAMEPAD_TRADE_ADD),

            callback = function()
                TradeAddItem(self.bagId, self.slotIndex, self.desiredTradeIndex)
                LeaveInventory()
            end,

            enabled = function()
                return self.inventoryList.list:GetNumItems() > 0
            end,
        },
        -- Switch back to Offer view
        {
            keybind = "UI_SHORTCUT_NEGATIVE",
            
            name = GetString(SI_GAMEPAD_BACK_OPTION),

            callback = function()
                LeaveInventory()
            end,
        },
        -- Split Stack
        {
            name = GetString(SI_ITEM_ACTION_SPLIT_STACK),
            keybind = "UI_SHORTCUT_TERTIARY",
            callback = function()
                local itemSlot = self:GetActiveItemSlot()
                if itemSlot then
                    ZO_InventorySlot_TrySplitStack(itemSlot)

                    self.inventoryList:RefreshList()
                    self:RefreshKeybind()
                end
            end,
            visible = function()
                local itemSlot = self:GetActiveItemSlot()
                return itemSlot and ZO_InventorySlot_CanSplitItemStack(itemSlot)
            end,
        },
    }

    -- Gold Slider Edit
    self.keybindStripDescriptorGoldSlider =
    {
        alignment = KEYBIND_STRIP_ALIGN_LEFT,

        -- Accept
        {
            name = GetString(SI_GAMEPAD_TRADE_ACCEPT_MONEY),
            keybind = "UI_SHORTCUT_PRIMARY",
            callback = function()
                            TradeSetMoney(self.goldSlider:GetValue())

                            PlaySound(SOUNDS.GAMEPAD_MENU_BACK)
                            self:HideGoldSliderControl()
                       end,
        },
        -- Cancel
        {
            keybind = "UI_SHORTCUT_NEGATIVE",
            
            name = GetString(SI_GAMEPAD_BACK_OPTION),

            callback = function()
                PlaySound(SOUNDS.GAMEPAD_MENU_BACK)
                self:HideGoldSliderControl()
            end,
        },
    }

    self.keybindStripDescriptor = self.keybindStripDescriptorOffer
end

function ZO_GamepadTradeWindow:OnStateChanged(oldState, newState)
    if(newState == SCENE_SHOWING) then
        self:PerformDeferredInitialization()
        KEYBIND_STRIP:RemoveDefaultExit()
        KEYBIND_STRIP:AddKeybindButtonGroup(self.keybindStripDescriptor)
        DIRECTIONAL_INPUT:Activate(self, self.control)
        self.activeListType = TRADE_ME
        self:SetCurrentList(self.lists[TRADE_ME])
        GAMEPAD_NAV_QUADRANT_4_BACKGROUND_FRAGMENT:ClearFocus()
        self:BeginTrade()
    elseif(newState == SCENE_HIDDEN) then
        self.goldSlider:Deactivate()
        self.goldSliderControl:SetHidden(true)
        self:DisableCurrentList()
        KEYBIND_STRIP:RemoveKeybindButtonGroup(self.keybindStripDescriptor)
        KEYBIND_STRIP:RestoreDefaultExit()
        TradeCancel()
        TradeSetMoney(0)
        self.offeredMoney = {}
        DIRECTIONAL_INPUT:Deactivate(self)
        GAMEPAD_NAV_QUADRANT_1_BACKGROUND_FRAGMENT:ClearHighlight()
        GAMEPAD_NAV_QUADRANT_4_BACKGROUND_FRAGMENT:ClearHighlight()
        ZO_Trade_GamepadWaiting:SetHidden(true)
    end
end

----------------------------
-- Slot management functions
----------------------------

--Either player added an item to the trade
function ZO_GamepadTradeWindow:OnTradeWindowItemAdded(eventCode, who, tradeSlot, itemSoundCategory)
    self:RefreshOfferList(who)

    if (who == TRADE_ME) then
        self.inventoryList:RefreshList()
        self:RefreshKeybind()
    end

    PlayItemSound(itemSoundCategory, ITEM_SOUND_ACTION_SLOT)
end

--Either player removed an item from the trade
function ZO_GamepadTradeWindow:OnTradeWindowItemRemoved(eventCode, who, tradeSlot, itemSoundCategory)
    self:RefreshOfferList(who)

    if (who == TRADE_ME) then
        self.inventoryList:RefreshList()
        self:RefreshKeybind()
    end

    PlayItemSound(itemSoundCategory, ITEM_SOUND_ACTION_PICKUP)
end

--region promotion of money change event
function ZO_GamepadTradeWindow:OnTradeWindowMoneyChanged(eventCode, who, money)
    self.offeredMoney[who] = money

    self:RefreshOfferList(who)

    PlaySound(SOUNDS.ITEM_MONEY_CHANGED)
end

--
--XML handlers
--

function ZO_Trade_Gamepad_OnInitialize(control)
    GAMEPAD_TRADE = ZO_GamepadTradeWindow:New(control)

    SYSTEMS:RegisterGamepadObject("trade", GAMEPAD_TRADE)
end
