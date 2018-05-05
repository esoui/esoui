INVENTORY_MENU_INVENTORY_BUTTON = "inventory"
INVENTORY_MENU_CRAFT_BAG_BUTTON = "craftBag"
INVENTORY_MENU_WALLET_BUTTON = "wallet"
INVENTORY_MENU_QUICKSLOT_BUTTON = "quickslot"

ZO_InventoryMenuBar = ZO_Object:Subclass()

function ZO_InventoryMenuBar:New(...)
    local object = ZO_Object.New(self)
    object:Initialize(...)
    return object
end
do
    local DEFAULT_BAR_DATA =
    {
        buttonPadding = 20,
        normalSize = 51,
        downSize = 64,
        animationDuration = DEFAULT_SCENE_TRANSITION_TIME,
        buttonTemplate = "ZO_MenuBarTooltipButton",
    }

    function ZO_InventoryMenuBar:Initialize(control, menuBarData)
        self.fragment = ZO_FadeSceneFragment:New(control)
        self.menuBarControl = control:GetNamedChild("Bar")
        self.modeBar = ZO_SceneFragmentBar:New(self.menuBarControl)
        self:CreateTabData()

        local barData = menuBarData or DEFAULT_BAR_DATA
        ZO_MenuBar_SetData(self.menuBarControl, barData)

        self.fragment:RegisterCallback("StateChange", function(oldState, newState)
            if newState == SCENE_FRAGMENT_SHOWING then
                self:OnFragmentShowing()
            elseif newState == SCENE_FRAGMENT_SHOWN then
                self:OnFragmentShown()
            elseif newState == SCENE_FRAGMENT_HIDING then
                self:OnFragmentHiding()
            elseif newState == SCENE_FRAGMENT_HIDDEN then
                self:OnFragmentHidden()
            end
        end)
    end
end

function ZO_InventoryMenuBar:ToggleQuickslotsTab()
    if SCENE_MANAGER:IsShowing("inventory") then
        if QUICKSLOT_FRAGMENT:IsShowing() then
            self.modeBar:SelectFragment(self.quickslotToggleFragment)
        else
            self.modeBar:SelectFragment(SI_INVENTORY_MODE_QUICKSLOTS)
        end
    end
end

function ZO_InventoryMenuBar:SetStartingFragmentQuickslots()
    self.modeBar:SetStartingFragment(SI_INVENTORY_MODE_QUICKSLOTS)
end

function ZO_InventoryMenuBar:UpdateInventoryKeybinds()
    self.modeBar:UpdateActiveKeybind()
end

function ZO_InventoryMenuBar:RemoveAllTabs()
    self.modeBar:RemoveAll()
end

function ZO_InventoryMenuBar:OnButtonClicked()
    local lastFragment = self.modeBar:GetLastFragment()
    if lastFragment ~= SI_INVENTORY_MODE_QUICKSLOTS then
        self.quickslotToggleFragment = lastFragment
    end
    
    ZO_MenuBar_UpdateButtons(self.modeBar.menuBar)
end

function ZO_InventoryMenuBar:LayoutCraftBagTooltip(tooltip)
    local title
    local description
    if HasCraftBagAccess() then
        title = zo_strformat(SI_INVENTORY_CRAFT_BAG_STATUS, ZO_DEFAULT_ENABLED_COLOR:Colorize(GetString(SI_ESO_PLUS_STATUS_UNLOCKED)))
        description = GetString(SI_CRAFT_BAG_STATUS_ESO_PLUS_UNLOCKED_DESCRIPTION)
    else
        title = zo_strformat(SI_INVENTORY_CRAFT_BAG_STATUS, ZO_DEFAULT_ENABLED_COLOR:Colorize(GetString(SI_ESO_PLUS_STATUS_LOCKED)))
        description = GetString(SI_CRAFT_BAG_STATUS_LOCKED_DESCRIPTION)
    end
    SetTooltipText(tooltip, title)
    local r, g, b = ZO_TOOLTIP_DEFAULT_COLOR:UnpackRGB()
    tooltip:AddLine(description, "", r, g, b)
end

do
    local function CreateButtonData(normal, pressed, highlight, clickSound, callback, tooltipFunction, statusIcon)
        return {
            normal = normal,
            pressed = pressed,
            highlight = highlight,
            clickSound = clickSound,
            callback = callback,
            CustomTooltipFunction = tooltipFunction,
            statusIcon = statusIcon,
        }
    end

    function ZO_InventoryMenuBar:CreateTabData()
        local onButtonClicked = function(...) self:OnButtonClicked(...) end

        -- TOOD: Sound pass to make sure these are correct
        self.inventoryButtonData = CreateButtonData("EsoUI/Art/Inventory/inventory_tabIcon_items_up.dds",
                                                    "EsoUI/Art/Inventory/inventory_tabIcon_items_down.dds",
                                                    "EsoUI/Art/Inventory/inventory_tabIcon_items_over.dds",
                                                    SOUNDS.QUICKSLOT_CLOSE,
                                                    onButtonClicked,
                                                    nil,
                                                    function()
                                                        if SHARED_INVENTORY and SHARED_INVENTORY:AreAnyItemsNew(nil, nil, BAG_BACKPACK) then
                                                            return ZO_KEYBOARD_NEW_ICON
                                                        end
                                                        return nil
                                                    end)
        self.craftBagButtonData = CreateButtonData("EsoUI/Art/Inventory/inventory_tabIcon_Craftbag_up.dds",
                                                    "EsoUI/Art/Inventory/inventory_tabIcon_Craftbag_down.dds",
                                                    "EsoUI/Art/Inventory/inventory_tabIcon_Craftbag_over.dds",
                                                    SOUNDS.QUICKSLOT_CLOSE,
                                                    onButtonClicked,
                                                    function(...) self:LayoutCraftBagTooltip(...) end,
                                                    function()
                                                        if SHARED_INVENTORY and SHARED_INVENTORY:AreAnyItemsNew(nil, nil, BAG_VIRTUAL) then
                                                            return ZO_KEYBOARD_NEW_ICON
                                                        end
                                                        return nil
                                                    end)
        self.currencyButtonData = CreateButtonData("EsoUI/Art/Bank/bank_tabIcon_gold_up.dds",
                                                    "EsoUI/Art/Bank/bank_tabIcon_gold_down.dds",
                                                    "EsoUI/Art/Bank/bank_tabIcon_gold_over.dds",
                                                    SOUNDS.QUICKSLOT_CLOSE,
                                                    onButtonClicked)
        self.quickslotsButtonData = CreateButtonData("EsoUI/Art/Inventory/inventory_tabIcon_quickslot_up.dds",
                                                    "EsoUI/Art/Inventory/inventory_tabIcon_quickslot_down.dds",
                                                    "EsoUI/Art/Inventory/inventory_tabIcon_quickslot_over.dds",
                                                    SOUNDS.QUICKSLOT_OPEN,
                                                    onButtonClicked)
    end
end

function ZO_InventoryMenuBar:AddTab(tabType, keybinds, additionalFragment)
    if tabType == INVENTORY_MENU_INVENTORY_BUTTON then
        self.modeBar:Add(SI_INVENTORY_MODE_ITEMS, { INVENTORY_FRAGMENT, additionalFragment }, self.inventoryButtonData, keybinds)
    elseif tabType == INVENTORY_MENU_CRAFT_BAG_BUTTON then
        self.modeBar:Add(SI_INVENTORY_MODE_CRAFT_BAG, { CRAFT_BAG_FRAGMENT, additionalFragment }, self.craftBagButtonData, keybinds)
    elseif tabType == INVENTORY_MENU_WALLET_BUTTON then
        self.modeBar:Add(SI_INVENTORY_MODE_CURRENCY, { WALLET_FRAGMENT, additionalFragment }, self.currencyButtonData, keybinds)
    elseif tabType == INVENTORY_MENU_QUICKSLOT_BUTTON then
        self.modeBar:Add(SI_INVENTORY_MODE_QUICKSLOTS, { QUICKSLOT_FRAGMENT, QUICKSLOT_CIRCLE_FRAGMENT, additionalFragment }, self.quickslotsButtonData, keybinds)
    end
end

function ZO_InventoryMenuBar:GetFragment()
    return self.fragment
end

-- Fragment callback functions
-- may be overridden
function ZO_InventoryMenuBar:OnFragmentShowing()
    self.modeBar:ShowLastFragment()
end

function ZO_InventoryMenuBar:OnFragmentShown()
    -- optional override by subclass
end

function ZO_InventoryMenuBar:OnFragmentHiding()
    -- optional override by subclass
end

function ZO_InventoryMenuBar:OnFragmentHidden()
    self.modeBar:Clear()
    ZO_InventorySlot_RemoveMouseOverKeybinds()
end

-----
-- PLAYER INVENTORY MENU BAR
-----

local PlayerInventoryMenuBar = ZO_InventoryMenuBar:Subclass()

function PlayerInventoryMenuBar:New(...)
    return ZO_InventoryMenuBar.New(self, ...)
end

function PlayerInventoryMenuBar:Initialize(control)
    ZO_InventoryMenuBar.Initialize(self, control)

    SHARED_INVENTORY:RegisterCallback("FullInventoryUpdate", function() self:UpdateInventoryKeybinds() end)

    -- Quickslot toggle button
    local quickslotToggleKeybind = {
        --Ethereal binds show no text, the name field is used to help identify the keybind when debugging. This text does not have to be localized.
        name = "Toggle Quickslots",
        keybind = "UI_SHORTCUT_QUICK_SLOTS",
        callback =  function()
                        self:ToggleQuickslotsTab()
                    end,
        ethereal = true,
    }

    -- Stack all
    local stackAllKeybind = {
        name = GetString(SI_ITEM_ACTION_STACK_ALL),
        keybind = "UI_SHORTCUT_STACK_ALL",
        visible =   function()
                        return PLAYER_INVENTORY:IsShowingBackpack()
                    end,
        callback = function()
            StackBag(BAG_BACKPACK)
        end,
    }

    -- Stow all materials to craft bag
    local stowMaterialsKeybind = {
        name = GetString(SI_ITEM_ACTION_STOW_MATERIALS),
        keybind = "UI_SHORTCUT_QUATERNARY",
        visible =   function()
                        return PLAYER_INVENTORY:IsShowingBackpack() and IsESOPlusSubscriber() and CanAnyItemsBeStoredInCraftBag(BAG_BACKPACK)
                    end,
        callback = function()
            ZO_Inventory_TryStowAllMaterials()
        end,
    }

    local quickslotToggleKeybindButtons =
    {
        alignment = KEYBIND_STRIP_ALIGN_CENTER,
        quickslotToggleKeybind,
        stackAllKeybind,
    }

    local keybindButtons = {
        alignment = KEYBIND_STRIP_ALIGN_CENTER,

        -- Destroy All Junk
        {
            name = GetString(SI_DESTROY_ALL_JUNK_KEYBIND_TEXT),
            keybind = "UI_SHORTCUT_NEGATIVE",

            visible =   function()
                            local inventory = PLAYER_INVENTORY.inventories[INVENTORY_BACKPACK]
                            local currentFilter = inventory.currentFilter
                            if type(currentFilter) ~= "function" and currentFilter == ITEMFILTERTYPE_JUNK then
                                return HasAnyJunk(BAG_BACKPACK)
                            end
                        end,

            callback =  function()
                            ZO_Dialogs_ShowDialog("DESTROY_ALL_JUNK")
                        end,
        },
        quickslotToggleKeybind,
        stackAllKeybind,
        stowMaterialsKeybind,
    }

    self:AddTab(INVENTORY_MENU_INVENTORY_BUTTON, keybindButtons, BACKPACK_MENU_BAR_LAYOUT_FRAGMENT)
    self:AddTab(INVENTORY_MENU_CRAFT_BAG_BUTTON, nil, BACKPACK_MENU_BAR_LAYOUT_FRAGMENT)
    self:AddTab(INVENTORY_MENU_WALLET_BUTTON)
    self:AddTab(INVENTORY_MENU_QUICKSLOT_BUTTON, quickslotToggleKeybindButtons)

    self.modeBar:SetStartingFragment(SI_INVENTORY_MODE_ITEMS)
    self.quickslotToggleFragment = SI_INVENTORY_MODE_ITEMS
end

-- overriden function from ZO_InventoryMenuBar
function PlayerInventoryMenuBar:OnFragmentShown()
    TriggerTutorial(TUTORIAL_TRIGGER_INVENTORY_OPENED)

    if PLAYER_INVENTORY:HasAnyQuickSlottableItems(INVENTORY_BACKPACK) then
        TriggerTutorial(TUTORIAL_TRIGGER_INVENTORY_OPENED_AND_QUICKSLOTS_AVAILABLE)
    end

    if GetUnitLevel("player") >= GetWeaponSwapUnlockedLevel() then
        TriggerTutorial(TUTORIAL_TRIGGER_INVENTORY_OPENED_AND_WEAPON_SETS_AVAILABLE)
    end

    if AreAnyItemsStolen(INVENTORY_BACKPACK) then
        TriggerTutorial(TUTORIAL_TRIGGER_INVENTORY_OPENED_AND_STOLEN_ITEMS_PRESENT)
    end

    if HasPoisonInBag(INVENTORY_BACKPACK) then
        TriggerTutorial(TUTORIAL_TRIGGER_INVENTORY_OPENED_AND_POISONS_PRESENT)
    end
end

--Global XML

function ZO_PlayerInventoryMenu_OnInitialized(control)
    INVENTORY_MENU_BAR = PlayerInventoryMenuBar:New(control)
    INVENTORY_MENU_FRAGMENT = INVENTORY_MENU_BAR:GetFragment()
end

-----
-- VENDOR INVENTORY MENU BAR
-----

local VendorInventoryMenuBar = ZO_InventoryMenuBar:Subclass()

function VendorInventoryMenuBar:New(...)
    return ZO_InventoryMenuBar.New(self, ...)
end

function VendorInventoryMenuBar:Initialize(control)
    local menuBarData =
        {
            buttonPadding = 10,
            normalSize = 48,
            downSize = 51,
            animationDuration = DEFAULT_SCENE_TRANSITION_TIME,
            buttonTemplate = "ZO_MenuBarTooltipButton",
        }
    ZO_InventoryMenuBar.Initialize(self, control, menuBarData)

    -- Stack all
    local stackAllKeybind = {
        name = GetString(SI_ITEM_ACTION_STACK_ALL),
        keybind = "UI_SHORTCUT_STACK_ALL",
        visible =   function()
                        return PLAYER_INVENTORY:IsShowingBackpack()
                    end,
        callback = function()
            StackBag(BAG_BACKPACK)
        end,
    }

    local keybindButtons = {
        alignment = KEYBIND_STRIP_ALIGN_CENTER,
        stackAllKeybind,
    }

    self:AddTab(INVENTORY_MENU_INVENTORY_BUTTON, keybindButtons, BACKPACK_STORE_LAYOUT_FRAGMENT)
    self:AddTab(INVENTORY_MENU_CRAFT_BAG_BUTTON, nil, BACKPACK_STORE_LAYOUT_FRAGMENT)

    self.modeBar:SetStartingFragment(SI_INVENTORY_MODE_ITEMS)
    self.quickslotToggleFragment = SI_INVENTORY_MODE_ITEMS
end

--Global XML

function ZO_VendorInventoryMenu_OnInitialized(control)
    local vendorBar = VendorInventoryMenuBar:New(control)
    VENDOR_INVENTORY_MENU_FRAGMENT = vendorBar:GetFragment()
end