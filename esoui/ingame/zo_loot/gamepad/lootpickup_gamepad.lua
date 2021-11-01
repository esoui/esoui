local ZO_LootPickup_Gamepad = ZO_Loot_Gamepad_Base:Subclass()

function ZO_LootPickup_Gamepad:New(...)
    return ZO_Loot_Gamepad_Base.New(self, ...)
end

function ZO_LootPickup_Gamepad:Initialize(control)
    ZO_Loot_Gamepad_Base.Initialize(self, GAMEPAD_RIGHT_TOOLTIP)

    control.owner = self
    self.control = control

    self.isInitialized = false
    self.intialLootUpdate = true

    local function OnStateChanged(oldState, newState)
        if newState == SCENE_SHOWING then
            self:OnShowing()
        elseif(newState == SCENE_HIDING) then
            EndLooting()
            SCENE_MANAGER:RestoreHUDUIScene()
        elseif newState == SCENE_HIDDEN then
            self:OnHide()
        end
    end

    LOOT_SCENE_GAMEPAD = ZO_LootScene:New("lootGamepad", SCENE_MANAGER)
    LOOT_SCENE_GAMEPAD:RegisterCallback("StateChange", OnStateChanged)
    SYSTEMS:RegisterGamepadRootScene("loot", LOOT_SCENE_GAMEPAD)
end

function ZO_LootPickup_Gamepad:DeferredInitialize()
    self:InitializeKeybindStripDescriptors()

    local contentContainer = self.control:GetNamedChild("Content")
    local listContainer = contentContainer:GetNamedChild("List"):GetNamedChild("Container")
    self.itemList = ZO_GamepadVerticalItemParametricScrollList:New(listContainer:GetNamedChild("List"))

    self.itemList:SetAlignToScreenCenter(true)
    self.itemList:AddDataTemplate("ZO_GamepadItemSubEntryTemplate", ZO_SharedGamepadEntry_OnSetup, ZO_GamepadMenuEntryTemplateParametricListFunction)

    local function OnSelectionChanged(...)
        self:OnSelectionChanged(...)
    end
    self.itemList:SetOnSelectedDataChangedCallback(OnSelectionChanged)

    self.takeControl = contentContainer:GetNamedChild("KeybindContainer"):GetNamedChild("TakeContainer")
    self.takeAllControl = contentContainer:GetNamedChild("KeybindContainer"):GetNamedChild("TakeAllContainer")

    self.takeControl:SetKeybind("UI_SHORTCUT_PRIMARY")
    self.takeAllControl:SetKeybind("UI_SHORTCUT_SECONDARY")

    KEYBIND_STRIP:SetupButtonStyle(self.takeControl, KEYBIND_STRIP_GAMEPAD_STYLE)
    KEYBIND_STRIP:SetupButtonStyle(self.takeAllControl, KEYBIND_STRIP_GAMEPAD_STYLE)

    self.takeControl:SetText(GetString(SI_LOOT_TAKE))
    self.takeAllControl:SetText(GetString(SI_LOOT_TAKE_ALL))
    local MAX_TAKEALL_SINGLE_ROW_WIDTH = 135
    local takeAllNameWidth = self.takeAllControl:GetNamedChild("NameLabel"):GetTextWidth() 
    if takeAllNameWidth > MAX_TAKEALL_SINGLE_ROW_WIDTH then
        self.takeAllControl:ClearAnchors()
        self.takeAllControl:SetAnchor(TOPLEFT, self.takeControl, BOTTOMLEFT)
    end

    self:InitializeHeader(GetString(SI_WINDOW_TITLE_LOOT))

    local function OnPlayerDead()
        if LOOT_SCENE_GAMEPAD:IsShowing() then
            self:Hide()
            EndLooting()
        end
    end

    self.control:RegisterForEvent(EVENT_PLAYER_DEAD, OnPlayerDead)

    self.isInitialized = true
end

function ZO_LootPickup_Gamepad:OnShowing()
    local dontAutomaticallyExitScene = false
    SCENE_MANAGER:SetHUDUIScene("lootGamepad", dontAutomaticallyExitScene)

    KEYBIND_STRIP:RemoveDefaultExit()
    KEYBIND_STRIP:AddKeybindButtonGroup(self.keybindStripDescriptor)
    self.itemList:Activate()

    self:OnSelectionChanged(self.itemList,  self.itemList:GetTargetData())
end

function ZO_LootPickup_Gamepad:OnHide()
    KEYBIND_STRIP:RemoveKeybindButtonGroup(self.keybindStripDescriptor)
    self.itemList:Deactivate()
    KEYBIND_STRIP:RestoreDefaultExit()
    self.returnScene = nil
end

function ZO_LootPickup_Gamepad:SetTitle(title)
    self.headerData.titleText = title
    ZO_GamepadGenericHeader_Refresh(self.header, self.headerData)
end

function ZO_LootPickup_Gamepad:UpdateButtonTextOnSelection(selectedData)
    if selectedData then
        local actionStringId = selectedData.isStolen and SI_LOOT_STEAL or SI_LOOT_TAKE
        self.takeControl:SetText(GetString(actionStringId))
    end
end

function ZO_LootPickup_Gamepad:UpdateAllControlText()
    if self.itemCount > 0 then
        -- update the take all / steal all text depending on the situation
        self.takeAllControl:SetText(GetString(self.nonStolenItemsPresent and SI_LOOT_TAKE_ALL or SI_LOOT_STEAL_ALL))
    end
end

function ZO_LootPickup_Gamepad:Update(isOwned)
    self:UpdateList()
end

function ZO_LootPickup_Gamepad:Hide()
    if self.returnScene then
        SCENE_MANAGER:Show(self.returnScene)
    else
        SCENE_MANAGER:RestoreHUDUIScene()
    end
end

function ZO_LootPickup_Gamepad:Show()
    if SCENE_MANAGER:IsShowingBaseScene() then
        self.returnScene = nil
    else
        self.returnScene = SCENE_MANAGER:GetCurrentScene():GetName()
    end

    SCENE_MANAGER:Show("lootGamepad")
    
    local OPEN_LOOT_WINDOW = false
    ZO_PlayMonsterLootSound(OPEN_LOOT_WINDOW)
end

function ZO_LootPickup_Gamepad:InitializeKeybindStripDescriptors()
    local ARE_ETHEREAL = true
    self:InitializeKeybindStripDescriptorsMixin(ARE_ETHEREAL)
end

function ZO_LootPickup_Gamepad:InitializeHeader(title)
    self.header = self.control:GetNamedChild("Content"):GetNamedChild("HeaderContainer"):GetNamedChild("Header")
    ZO_GamepadGenericHeader_Initialize(self.header, ZO_GAMEPAD_HEADER_TABBAR_DONT_CREATE)

    local function UpdateCapacityString()
        local capacityString = zo_strformat(SI_GAMEPAD_INVENTORY_CAPACITY_FORMAT, self.numUsedBagSlots, self.numTotalBagSlots)
        if self.bagFull then
            capacityString = ZO_ERROR_COLOR:Colorize(capacityString)
        end
        return capacityString
    end

    self.headerData = {
        titleText = title,
        data1HeaderText = GetString(SI_GAMEPAD_LOOT_INVENTORY_CAPACITY),
        data1Text = UpdateCapacityString,
    }
end

--[[ Global Handlers ]]--
function ZO_LootPickup_Gamepad_Initialize(control)
    LOOT_WINDOW_GAMEPAD = ZO_LootPickup_Gamepad:New(control)
end
