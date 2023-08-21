local ZO_LootInventory_Gamepad = ZO_InitializingObject.MultiSubclass(ZO_Loot_Gamepad_Base, ZO_Gamepad_ParametricList_Screen)

function ZO_LootInventory_Gamepad:Initialize(control)
    local DONT_CREATE_TABBAR = false
    ZO_Loot_Gamepad_Base.Initialize(self, GAMEPAD_LEFT_TOOLTIP)

    LOOT_INVENTORY_SCENE_GAMEPAD = ZO_LootScene:New("lootInventoryGamepad", SCENE_MANAGER)
    local ACTIVATE_ON_SHOW = true
    ZO_Gamepad_ParametricList_Screen.Initialize(self, control, DONT_CREATE_TABBAR, ACTIVATE_ON_SHOW, LOOT_INVENTORY_SCENE_GAMEPAD)

    self.initialLootUpdate = true
    self.keybindDirty = false
    self.isInitialized = false
    self.isResizable = false

    self.headerData = 
    {
        titleText = ""
    }
end

-- Overridden from base
function ZO_LootInventory_Gamepad:OnHiding()
    ZO_Gamepad_ParametricList_Screen.OnHiding()
    EndLooting()
end

function ZO_LootInventory_Gamepad:SetupList(list)
    list:AddDataTemplate("ZO_GamepadItemSubEntryTemplate", ZO_SharedGamepadEntry_OnSetup)
    self.itemList = list
end

function ZO_LootInventory_Gamepad:DeferredInitialize()
    self:SetTitle(self.headerData.titleText)
    self.isInitialized = true
end

function ZO_LootInventory_Gamepad:OnHide()
    KEYBIND_STRIP:RestoreDefaultExit()
end

function ZO_LootInventory_Gamepad:OnShow()
    local OPEN_LOOT_WINDOW = false
    ZO_PlayLootWindowSound(OPEN_LOOT_WINDOW)
end

function ZO_LootInventory_Gamepad:Hide()
    SCENE_MANAGER:Hide("lootInventoryGamepad")
end

function ZO_LootInventory_Gamepad:Show()
    KEYBIND_STRIP:RemoveDefaultExit()
    SCENE_MANAGER:Push("lootInventoryGamepad")
end

function ZO_LootInventory_Gamepad:InitializeKeybindStripDescriptors()
    local NOT_ETHEREAL = false
    self:InitializeKeybindStripDescriptorsMixin(NOT_ETHEREAL)
end

function ZO_LootInventory_Gamepad:SetTitle(title)
    self.headerData.titleText = title
    ZO_GamepadGenericHeader_Refresh(self.header, self.headerData)
end

function ZO_LootInventory_Gamepad:UpdateKeybindDescriptor()
    KEYBIND_STRIP:UpdateKeybindButtonGroup(self.keybindStripDescriptor)
    self.keybindDirty = false
end

function ZO_LootInventory_Gamepad:PerformUpdate()
    self:UpdateList()

    if self.keybindDirty then
        self:UpdateKeybindDescriptor()
    end
end

--[[ Global Handlers ]]--
function ZO_Gamepad_LootInventory_OnInitialize(control)
    LOOT_INVENTORY_WINDOW_GAMEPAD = ZO_LootInventory_Gamepad:New(control)
end