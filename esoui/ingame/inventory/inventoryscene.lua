local InventoryMenuBar = ZO_Object:Subclass()

function InventoryMenuBar:New()
    local object = ZO_Object.New(self)
    object:Initialize()
    return object
end

function InventoryMenuBar:Initialize()
    INVENTORY_MENU_FRAGMENT = ZO_FadeSceneFragment:New(ZO_PlayerInventoryMenu)
    
    -- Quickslot toggle button
    local quickslotToggleKeybind = {
        keybind = "UI_SHORTCUT_QUICK_SLOTS",

        callback = function()
            self:ToggleQuickslotsTab()
        end,

        ethereal = true,
    }

    -- Stack all
    local stackAllKeybind = {
        name = GetString(SI_ITEM_ACTION_STACK_ALL),
        keybind = "UI_SHORTCUT_STACK_ALL",
        callback = function()
            StackBag(BAG_BACKPACK)
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
                            if(type(currentFilter) ~= "function" and currentFilter == ITEMFILTERTYPE_JUNK) then
                                return HasAnyJunk(BAG_BACKPACK)
                            end
                        end,

            callback =  function()
                            ZO_Dialogs_ShowDialog("DESTROY_ALL_JUNK")
                        end,
        },
        quickslotToggleKeybind,
        stackAllKeybind,
    }

    local function OnButtonClicked()
        local lastFragment = self.modeBar:GetLastFragment()
        if lastFragment ~= SI_INVENTORY_MODE_QUICKSLOTS then
            self.quickslotToggleFragment = lastFragment
        end
    end

    local function CreateButtonData(normal, pressed, highlight, clickSound, tutorialTrigger)
        return {
            normal = normal,
            pressed = pressed,
            highlight = highlight,
            clickSound = clickSound,
            callback = OnButtonClicked
        }
    end
    
    self.modeBar = ZO_SceneFragmentBar:New(ZO_PlayerInventoryMenuBar)
    
    --Inventory Button
    local inventoryButtonData = CreateButtonData("EsoUI/Art/Inventory/inventory_tabIcon_items_up.dds",
                                            "EsoUI/Art/Inventory/inventory_tabIcon_items_down.dds",
                                            "EsoUI/Art/Inventory/inventory_tabIcon_items_over.dds",
                                            SOUNDS.QUICKSLOT_CLOSE)
    self.modeBar:Add(SI_INVENTORY_MODE_ITEMS, { INVENTORY_FRAGMENT, BACKPACK_MENU_BAR_LAYOUT_FRAGMENT }, inventoryButtonData, keybindButtons)
    --Wallet Button
    local currencyButtonData = CreateButtonData("EsoUI/Art/Bank/bank_tabIcon_gold_up.dds",
                                            "EsoUI/Art/Bank/bank_tabIcon_gold_down.dds",
                                            "EsoUI/Art/Bank/bank_tabIcon_gold_over.dds",
                                            SOUNDS.QUICKSLOT_CLOSE)
    self.modeBar:Add(SI_INVENTORY_MODE_CURRENCY, { WALLET_FRAGMENT }, currencyButtonData)
    --Quickslots Button
    local quickslotsButtonData = CreateButtonData("EsoUI/Art/Inventory/inventory_tabIcon_quickslot_up.dds",
                                            "EsoUI/Art/Inventory/inventory_tabIcon_quickslot_down.dds",
                                            "EsoUI/Art/Inventory/inventory_tabIcon_quickslot_over.dds",
                                            SOUNDS.QUICKSLOT_OPEN)
    self.modeBar:Add(SI_INVENTORY_MODE_QUICKSLOTS, { QUICKSLOT_FRAGMENT, QUICKSLOT_CIRCLE_FRAGMENT }, quickslotsButtonData, quickslotToggleKeybindButtons)

    local function OnInventoryShown()
        TriggerTutorial(TUTORIAL_TRIGGER_INVENTORY_OPENED)
        local numUsedSlots, numMaxSlots = PLAYER_INVENTORY:GetNumSlots(INVENTORY_BACKPACK) 
        if numUsedSlots == numMaxSlots then
            TriggerTutorial(TUTORIAL_TRIGGER_INVENTORY_OPENED_AND_FULL)
        end
        if PLAYER_INVENTORY:HasAnyQuickSlottableItems(INVENTORY_BACKPACK) then
            TriggerTutorial(TUTORIAL_TRIGGER_INVENTORY_OPENED_AND_QUICKSLOTS_AVAILABLE)
        end
        if GetUnitLevel("player") >= GetWeaponSwapUnlockedLevel() then
            TriggerTutorial(TUTORIAL_TRIGGER_INVENTORY_OPENED_AND_WEAPON_SETS_AVAILABLE)
        end  
        if AreAnyItemsStolen(INVENTORY_BACKPACK) then
            TriggerTutorial(TUTORIAL_TRIGGER_INVENTORY_OPENED_AND_STOLEN_ITEMS_PRESENT)
        end
    end

    local inventoryScene = ZO_Scene:New("inventory", SCENE_MANAGER)
    inventoryScene:RegisterCallback("StateChange", function(oldState, newState)
        if(newState == SCENE_SHOWING) then
            self.modeBar:ShowLastFragment()
        elseif(newState == SCENE_SHOWN) then
            OnInventoryShown()            
        elseif(newState == SCENE_HIDDEN) then
            self.modeBar:Clear()
            ZO_InventorySlot_RemoveMouseOverKeybinds()       
        end
    end)
    self.modeBar:SetStartingFragment(SI_INVENTORY_MODE_ITEMS)
    self.quickslotToggleFragment = SI_INVENTORY_MODE_ITEMS
end

function InventoryMenuBar:ToggleQuickslotsTab()
    if(SCENE_MANAGER:IsShowing("inventory")) then
        if(QUICKSLOT_FRAGMENT:IsShowing()) then
            self.modeBar:SelectFragment(self.quickslotToggleFragment)
        else
            self.modeBar:SelectFragment(SI_INVENTORY_MODE_QUICKSLOTS)
        end
    end
end

function InventoryMenuBar:SetStartingFragmentQuickslots()
    self.modeBar:SetStartingFragment(SI_INVENTORY_MODE_QUICKSLOTS)
end

function InventoryMenuBar:UpdateInventoryKeybinds()
    self.modeBar:UpdateActiveKeybind()
end


--Global XML

function ZO_PlayerInventoryScene_OnInitialized()
    INVENTORY_MENU_BAR = InventoryMenuBar:New()
end