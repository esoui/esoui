INVENTORY_SLOT_ACTIONS_USE_CONTEXT_MENU = true
INVENTORY_SLOT_ACTIONS_PREVENT_CONTEXT_MENU = false

ZO_InventorySlotActions = ZO_Object:Subclass()

function ZO_InventorySlotActions:New(useContextMenu)
    local actions = ZO_Object.New(self)
    actions.m_slotActions = {}
    actions.m_keybindActions = {}
    actions.m_numContextMenuActions = 0

    if useContextMenu == nil then
        useContextMenu = INVENTORY_SLOT_ACTIONS_USE_CONTEXT_MENU
    end

    actions:SetContextMenuMode(useContextMenu)

    return actions
end

function ZO_InventorySlotActions:Clear()
    self.m_inventorySlot = nil
    self.m_hasActions = nil
    self.m_numContextMenuActions = 0

    ZO_ClearNumericallyIndexedTable(self.m_slotActions)
    ZO_ClearTable(self.m_keybindActions)

    if(self.m_contextMenuMode) then
        ClearMenu()
    end
end

function ZO_InventorySlotActions:SetContextMenuMode(useContextMenu)
    self.m_contextMenuMode = useContextMenu
end

function ZO_InventorySlotActions:SetInventorySlot(inventorySlot)
    self.m_inventorySlot = inventorySlot
end

function ZO_InventorySlotActions:Show()
    if((self.m_numContextMenuActions > 0) and self.m_contextMenuMode) then
        SetMenuHiddenCallback(function() self:Clear() end)
        ShowMenu(self.m_inventorySlot)
    end
end

local INDEX_ACTION_NAME = 1
local INDEX_ACTION_CALLBACK = 2
local INDEX_ACTION_TYPE = 3
local INDEX_ACTION_VISIBILITY = 4
local INDEX_ACTION_OPTIONS = 5

local PRIMARY_ACTION_KEY = 1

function ZO_InventorySlotActions:GetAction(actionKey, actionType, options)
    if(self.m_hasActions) then
        local actionData
        if actionType == "keybind" then
            actionData = self.m_keybindActions[actionKey]
        else
            actionData = self.m_slotActions[actionKey]
        end

        if(not actionData) then return end

        if(options and options == "ignoreSilent") then
            if(actionData[INDEX_ACTION_OPTIONS] and actionData[INDEX_ACTION_OPTIONS] == "silent") then
                return
            end
        end

        if(not actionType or actionData[INDEX_ACTION_TYPE] == actionType) then
            return actionData
        end
    end
end

function ZO_InventorySlotActions:DoPrimaryAction(options)
    local primaryAction = self:GetAction(PRIMARY_ACTION_KEY, "primary", options)
    local success = false

    if(primaryAction) then
        success = true
        if IsUnitDead("player") then    
            local actionOptions = primaryAction[INDEX_ACTION_OPTIONS]

            if actionOptions and actionOptions.visibleWhenDead == true then
                primaryAction[INDEX_ACTION_CALLBACK]()
            else
                ZO_AlertEvent(EVENT_UI_ERROR, SI_CANNOT_DO_THAT_WHILE_DEAD)
            end
        else
            if self:CheckPrimaryActionVisibility(options) then
                primaryAction[INDEX_ACTION_CALLBACK]()
            end
        end
    end

    return success
end

function ZO_InventorySlotActions:DoKeybindAction(keybindIndex, options)
    local action = self:GetAction(keybindIndex, "keybind", options)
    if(action) then
        action[INDEX_ACTION_CALLBACK]()
    end
end

function ZO_InventorySlotActions:DoAction(action)
    if(action) then
        action[INDEX_ACTION_CALLBACK]()
    end
end

function ZO_InventorySlotActions:GetPrimaryActionName(options)
    local primaryAction = self:GetAction(PRIMARY_ACTION_KEY, "primary", options)
    if(primaryAction) then
        return primaryAction[INDEX_ACTION_NAME]
    end
end

function ZO_InventorySlotActions:GetKeybindActionName(keybindIndex, options)
    local action = self:GetAction(keybindIndex, "keybind", options)
    if(action) then
        return action[INDEX_ACTION_NAME]
    end
end

function ZO_InventorySlotActions:GetRawActionName(action)
    return action[INDEX_ACTION_NAME]
end

function ZO_InventorySlotActions:CheckPrimaryActionVisibility(options)
    local primaryAction = self:GetAction(PRIMARY_ACTION_KEY, "primary", options)
    if primaryAction and primaryAction[INDEX_ACTION_VISIBILITY] then
        return primaryAction[INDEX_ACTION_VISIBILITY]()
    end

    return true
end

function ZO_InventorySlotActions:CheckKeybindActionVisibility(keybindIndex, options)
    local action = self:GetAction(keybindIndex, "keybind", options)
    if action and action[INDEX_ACTION_VISIBILITY] then
        return action[INDEX_ACTION_VISIBILITY]()
    end

    return true
end

local function GetKeybindIndexFromActionType(actionType)
    if actionType == "keybind1" then
        return 1
    elseif actionType == "keybind2" then
        return 2
    elseif actionType == "keybind3" then
        return 3
    end
end

local function IsPlayerAlive()
    return not IsUnitDead("player")
end

function ZO_InventorySlotActions:AddSlotAction(actionStringId, actionCallback, actionType, visibilityFunction, options)
    local actionName = GetString(actionStringId)
    local keybindIndex = GetKeybindIndexFromActionType(actionType)

    if not (options and options.visibleWhenDead) then
        if visibilityFunction then
            local oldVisibilityFunction = visibilityFunction
            visibilityFunction = function() return oldVisibilityFunction() and IsPlayerAlive() end
        else
            visibilityFunction = IsPlayerAlive
        end
    end

    if keybindIndex then
        self.m_keybindActions[keybindIndex] = { actionName, actionCallback, "keybind", visibilityFunction, options }
    end
    table.insert(self.m_slotActions, { actionName, actionCallback, actionType, visibilityFunction, options }) -- NOTE: Update indices if order/data changes
    self.m_hasActions = true

    if(self.m_contextMenuMode and (not options or options ~= "silent") and (not visibilityFunction or visibilityFunction())) then
        AddMenuItem(actionName, actionCallback)
        self.m_numContextMenuActions = self.m_numContextMenuActions + 1
    end
end

function ZO_InventorySlotActions:GetNumSlotActions()
    if(self.m_slotActions) then
        return #self.m_slotActions
    end

    return 0
end

function ZO_InventorySlotActions:GetSlotAction(index)
    if(self.m_slotActions) then
        return self.m_slotActions[index]
    end
end
