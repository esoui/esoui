ZO_ItemSlotActionsController = ZO_Object:Subclass()

function ZO_ItemSlotActionsController:New(...)
    local command = ZO_Object.New(self)
    command:Initialize(...)
    return command
end

function ZO_ItemSlotActionsController:Initialize(alignmentOverride, additionalMouseOverbinds, useKeybindStrip)
    local slotActions = ZO_InventorySlotActions:New(INVENTORY_SLOT_ACTIONS_PREVENT_CONTEXT_MENU)
    self.slotActions = slotActions
    self.useKeybindStrip = useKeybindStrip == nil and true or useKeybindStrip

    local primaryCommand =
    {
        alignment = alignmentOverride,
        name = function()
            if(self.selectedAction) then
                return slotActions:GetRawActionName(self.selectedAction)
            end

            return self.actionName or ""
        end,
        keybind = "UI_SHORTCUT_PRIMARY",
        order = 500,
        callback = function()
            if self.selectedAction then
                self:DoSelectedAction()
            else
                slotActions:DoPrimaryAction()
            end
        end,
        visible =   function()
                        return slotActions:CheckPrimaryActionVisibility() or self:HasSelectedAction()
                    end,
    }

    local function PrimaryCommandHasBind()
        return (self.actionName ~= nil) or self:HasSelectedAction()
    end

    local function PrimaryCommandActivate(inventorySlot)
        slotActions:Clear()
        slotActions:SetInventorySlot(inventorySlot)
        self.selectedAction = nil -- Do not call the update function, just clear the selected action

        if not inventorySlot then
            self.actionName = nil
        else
            ZO_InventorySlot_DiscoverSlotActionsFromActionList(inventorySlot, slotActions)
            self.actionName = slotActions:GetPrimaryActionName()
        end
    end

    self:AddSubCommand(primaryCommand, PrimaryCommandHasBind, PrimaryCommandActivate)

    if additionalMouseOverbinds then
        local mouseOverCommand, mouseOverCommandIsVisible
        for i=1, #additionalMouseOverbinds do
            mouseOverCommand =
            {
                alignment = alignmentOverride,
                name = function()
                    return slotActions:GetKeybindActionName(i)
                end,
                keybind = additionalMouseOverbinds[i],
                callback = function() slotActions:DoKeybindAction(i) end,
                visible =   function()
                                return slotActions:CheckKeybindActionVisibility(i)
                            end,
            }

            mouseOverCommandIsVisible = function()
                return slotActions:GetKeybindActionName(i) ~= nil
            end

            self:AddSubCommand(mouseOverCommand, mouseOverCommandIsVisible)
        end
    end
end

function ZO_ItemSlotActionsController:SetUseKeybindStrip(useKeybindStrip)
    self.useKeybindStrip = useKeybindStrip
end

function ZO_ItemSlotActionsController:AddSubCommand(command, hasBind, activateCallback)
    self[#self + 1] = { command, hasBind = hasBind, activateCallback = activateCallback }
end

function ZO_ItemSlotActionsController:RefreshKeybindStrip()
    if not self.useKeybindStrip then
        return
    end

    for i, command in ipairs(self) do
        if command.hasBind() then
            if KEYBIND_STRIP:HasKeybindButtonGroup(command) then
                KEYBIND_STRIP:UpdateKeybindButtonGroup(command)
            else
                KEYBIND_STRIP:AddKeybindButtonGroup(command)
            end
        else
            KEYBIND_STRIP:RemoveKeybindButtonGroup(command)
        end
    end
end

function ZO_ItemSlotActionsController:SetInventorySlot(inventorySlot)
    self.inventorySlot = inventorySlot
    self:RebuildActions()
end

function ZO_ItemSlotActionsController:RebuildActions()
    for i, command in ipairs(self) do
        if command.activateCallback then
            command.activateCallback(self.inventorySlot)
        end
    end

    self:RefreshKeybindStrip()
end

function ZO_ItemSlotActionsController:GetSlotActions()
    return self.slotActions
end

function ZO_ItemSlotActionsController:SetSelectedAction(action)
    self.selectedAction = action
end

function ZO_ItemSlotActionsController:HasSelectedAction()
    return self.selectedAction ~= nil
end

function ZO_ItemSlotActionsController:GetSelectedAction()
    return self.selectedAction
end

function ZO_ItemSlotActionsController:DoSelectedAction()
    self.slotActions:DoAction(self.selectedAction)
end

function ZO_ItemSlotActionsController:GetActions()
    return self.slotActions
end