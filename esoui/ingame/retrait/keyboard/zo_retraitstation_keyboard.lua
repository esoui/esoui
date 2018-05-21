local KEYBOARD_RETRAIT_ROOT_SCENE_NAME = "retrait_keyboard_root"

ZO_RetraitStation_Keyboard = ZO_RetraitStation_Base:Subclass()

function ZO_RetraitStation_Keyboard:New(...)
    return ZO_RetraitStation_Base.New(self, ...)
end

function ZO_RetraitStation_Keyboard:Initialize(control)
    ZO_RetraitStation_Base.Initialize(self, control, KEYBOARD_RETRAIT_ROOT_SCENE_NAME)
    self.retraitPanel = ZO_RetraitStation_Retrait_Keyboard:New(self.control:GetNamedChild("RetraitPanel"), self)

    self:InitializeKeybindStripDescriptors()
    self:InitializeModeBar()

    KEYBOARD_RETRAIT_ROOT_SCENE = self.interactScene

    local fragment = ZO_FadeSceneFragment:New(control)
    self.interactScene:AddFragment(fragment)

    SYSTEMS:RegisterKeyboardRootScene("retrait", self.interactScene)
    SYSTEMS:RegisterKeyboardObject("retrait", self)
end

function ZO_RetraitStation_Keyboard:OnInteractSceneShowing()
    KEYBIND_STRIP:AddKeybindButtonGroup(self.keybindStripDescriptor)
end

function ZO_RetraitStation_Keyboard:OnInteractSceneHiding()
    ZO_InventorySlot_RemoveMouseOverKeybinds()
    KEYBIND_STRIP:RemoveKeybindButtonGroup(self.keybindStripDescriptor)

    CRAFTING_RESULTS:SetCraftingTooltip(nil)
end

function ZO_RetraitStation_Keyboard:OnInteractSceneHidden()
    -- this needs to be called on hidden or else the inventory will
    -- attempt a full refresh instead of flagging itself as dirty
    self:HandleDirtyEvent()

    self.retraitPanel:RemoveItemFromRetrait()
end

function ZO_RetraitStation_Keyboard:InitializeKeybindStripDescriptors()
    self.keybindStripDescriptor =
    {
        alignment = KEYBIND_STRIP_ALIGN_CENTER,

        -- Clear selections
        {
            name = GetString(SI_CRAFTING_CLEAR_SELECTIONS),

            keybind = "UI_SHORTCUT_NEGATIVE",

            callback = function()
                if self.mode == ZO_RETRAIT_MODE_RETRAIT then
                    self.retraitPanel:SetRetraitSlotItem()
                end
            end,

            visible = function()
                if not ZO_CraftingUtils_IsPerformingCraftProcess() then
                    if self.mode == ZO_RETRAIT_MODE_RETRAIT then
                        return self.retraitPanel:HasItemSlotted()
                    end
                end
                return false
            end,
        },

        -- Perform craft
        {
            name = function()
                if self.mode == ZO_RETRAIT_MODE_RETRAIT then
                    return GetString(SI_RETRAIT_STATION_PERFORM_RETRAIT)
                end
            end,

            keybind = "UI_SHORTCUT_SECONDARY",

            callback = function()
                if self.mode == ZO_RETRAIT_MODE_RETRAIT then
                    self.retraitPanel:PerformRetrait()
                end
            end,

            enabled = function()
                if not ZO_CraftingUtils_IsPerformingCraftProcess() then
                    if self.mode == ZO_RETRAIT_MODE_RETRAIT then
                        return self.retraitPanel:HasValidSelections()
                    end
                end
                return false
            end,

            visible = function()
                if not ZO_CraftingUtils_IsPerformingCraftProcess() then
                    if self.mode == ZO_RETRAIT_MODE_RETRAIT then
                        return self.retraitPanel:HasItemSlotted()
                    end
                end
                return false
            end,
        },
    }

    ZO_CraftingUtils_ConnectKeybindButtonGroupToCraftingProcess(self.keybindStripDescriptor)
end

function ZO_RetraitStation_Keyboard:InitializeModeBar()
    self.modeBar = self.control:GetNamedChild("ModeMenuBar")
    self.modeBarLabel = self.modeBar:GetNamedChild("Label")

    local function CreateModeData(name, mode, normal, pressed, highlight, disabled)
        return {
            categoryName = name,

            descriptor = mode,
            normal = normal,
            pressed = pressed,
            highlight = highlight,
            disabled = disabled,
            callback = function(tabData)
                self.modeBarLabel:SetText(GetString(name))
                self:SetMode(mode)
            end,
        }
    end

    self.retraitTab = CreateModeData(SI_RETRAIT_STATION_RETRAIT_MODE, ZO_RETRAIT_MODE_RETRAIT, "EsoUI/Art/Crafting/retrait_tabIcon_up.dds", "EsoUI/Art/Crafting/retrait_tabIcon_down.dds", "EsoUI/Art/Crafting/retrait_tabIcon_over.dds", "EsoUI/Art/Crafting/retrait_tabIcon_disabled.dds")

    ZO_MenuBar_AddButton(self.modeBar, self.retraitTab)
    ZO_MenuBar_SelectDescriptor(self.modeBar, ZO_RETRAIT_MODE_RETRAIT)

    ZO_CraftingUtils_ConnectMenuBarToCraftingProcess(self.modeBar)
end

function ZO_RetraitStation_Keyboard:UpdateKeybinds()
    KEYBIND_STRIP:UpdateKeybindButtonGroup(self.keybindStripDescriptor)
end

function ZO_RetraitStation_Keyboard:OnItemReceiveDrag(slotControl, bagId, slotIndex)
    if self.mode == ZO_RETRAIT_MODE_RETRAIT then
        self.retraitPanel:OnItemReceiveDrag(slotControl, bagId, slotIndex)
    end
end

function ZO_RetraitStation_Keyboard:SetMode(mode)
    if self.mode ~= mode then
        self.mode = mode

        CRAFTING_RESULTS:SetCraftingTooltip(nil)

        self:UpdateKeybinds()

        self.retraitPanel:SetHidden(mode ~= ZO_RETRAIT_MODE_RETRAIT)
    end
end

function ZO_RetraitStation_Keyboard:IsItemAlreadySlottedToCraft(bag, slot)
    if self.mode == ZO_RETRAIT_MODE_RETRAIT then
        return self.retraitPanel:IsItemAlreadySlottedToCraft(bag, slot)
    end
    return false
end

function ZO_RetraitStation_Keyboard:CanItemBeAddedToCraft(bag, slot)
    if self.mode == ZO_RETRAIT_MODE_RETRAIT then
        return self.retraitPanel:CanItemBeAddedToCraft(bag, slot)
    end
    return false
end

function ZO_RetraitStation_Keyboard:AddItemToCraft(bag, slot)
    if self.mode == ZO_RETRAIT_MODE_RETRAIT then
        self.retraitPanel:AddItemToCraft(bag, slot)
    end
end

function ZO_RetraitStation_Keyboard:RemoveItemFromCraft(bag, slot)
    if self.mode == ZO_RETRAIT_MODE_RETRAIT then
        self.retraitPanel:RemoveItemFromCraft(bag, slot)
    end
end

function ZO_RetraitStation_Keyboard:OnItemReceiveDrag(inventorySlot, bagId, slotIndex)
     if self.mode == ZO_RETRAIT_MODE_RETRAIT then
        self.retraitPanel:OnItemReceiveDrag(inventorySlot, bagId, slotIndex)
    end
end

function ZO_RetraitStation_Keyboard:OnRetraitResult(result)
    if self.mode == ZO_RETRAIT_MODE_RETRAIT then
        self.retraitPanel:OnRetraitResult(result)
    end
end

function ZO_RetraitStation_Keyboard:HandleDirtyEvent()
    self.retraitPanel:HandleDirtyEvent()
end

function ZO_RetraitStation_Keyboard:GetRetraitObject()
    return self.retraitPanel
end

-- Global XML functions

function ZO_RetraitStation_Keyboard_Initialize(control)
    ZO_RETRAIT_STATION_KEYBOARD = ZO_RetraitStation_Keyboard:New(control)
end