local KeybindingsManager = ZO_InitializingCallbackObject:Subclass()

function KeybindingsManager:Initialize()
    local function OnAddOnLoaded(event, name)
        if name == "ZO_Ingame" then
            PushActionLayerByName(GetString(SI_KEYBINDINGS_LAYER_GENERAL))
            EVENT_MANAGER:UnregisterForEvent("KeybindingsManager", EVENT_ADD_ON_LOADED)
        end
    end

    EVENT_MANAGER:RegisterForEvent("KeybindingsManager", EVENT_ADD_ON_LOADED, OnAddOnLoaded)

    EVENT_MANAGER:RegisterForEvent("KeybindingsManager", EVENT_KEYBINDINGS_LOADED, function(eventCode, ...) self:OnKeybindingsLoaded(...) end)
    EVENT_MANAGER:RegisterForEvent("KeybindingsManager", EVENT_KEYBINDING_SET, function(eventCode, ...) self:OnKeybindingSet(...) end)
    EVENT_MANAGER:RegisterForEvent("KeybindingsManager", EVENT_KEYBINDING_CLEARED, function(eventCode, ...) self:OnKeybindingCleared(...) end)
    EVENT_MANAGER:RegisterForEvent("KeybindingsManager", EVENT_INPUT_LANGUAGE_CHANGED, function(eventCode, ...) self:OnInputLanguageChanged(...) end)
end

function KeybindingsManager:OnKeybindingsLoaded(...)
    self:InitializeKeybindData()
    self:FireCallbacks("OnKeybindingsLoaded", ...)
end

function KeybindingsManager:OnKeybindingSet(...)
    self:FireCallbacks("OnKeybindingSet", ...)
end

function KeybindingsManager:OnKeybindingCleared(...)
    self:FireCallbacks("OnKeybindingCleared", ...)
end

function KeybindingsManager:OnInputLanguageChanged()
    self:FireCallbacks("OnInputLanguageChanged", GetKeyboardLayout())
end

function KeybindingsManager:InitializeKeybindData()
    self.keybindLayers = {}

    for layerIndex = 1, GetNumActionLayers() do
        local layerName, numCategories = GetActionLayerInfo(layerIndex)
        local categoryList = {}

        for categoryIndex = 1, numCategories do
            local categoryName, numActions = GetActionLayerCategoryInfo(layerIndex, categoryIndex)
            local actionList = {}

            for actionIndex = 1, numActions do
                local actionName, isRebindable, isHidden = GetActionInfo(layerIndex, categoryIndex, actionIndex)
                if not isHidden then
                    local localizedActionName = GetString(_G["SI_BINDING_NAME_"..actionName])
                    if localizedActionName ~= "" then
                        local data =
                        {
                            actionName = actionName,
                            localizedActionName = localizedActionName,
                            isRebindable = isRebindable,

                            layerIndex = layerIndex,
                            categoryIndex = categoryIndex,
                            actionIndex = actionIndex,
                         }
                         local actionData = ZO_EntryData:New(data)
                         table.insert(actionList, actionData)
                    end
                end
            end

            if #actionList > 0 then
                local categoryData = ZO_EntryData:New({ layerIndex = layerIndex, categoryIndex = categoryIndex, categoryName = categoryName, actions = actionList })
                table.insert(categoryList, categoryData)
            end
        end

        if #categoryList > 0 then
            local layerData = ZO_EntryData:New({ layerIndex = layerIndex, layerName = layerName, categories = categoryList })
            table.insert(self.keybindLayers, layerData)
        end
    end
end

function KeybindingsManager:GetKeybindData()
    return self.keybindLayers
end

function KeybindingsManager:IsBindableKey(key)
    if key ~= KEY_LWINDOWS and key ~= KEY_RWINDOWS then
        return true
    end
    return false
end

internalassert(GetMaxBindingsPerAction() == 4, "Max bindings per action changes, update KeybindingsManager:GetBindTypeTextFromIndex")

function KeybindingsManager:GetBindTypeTextFromIndex(bindingIndex)
    if bindingIndex == 1 then
        return GetString(SI_KEYBINDINGS_PRIMARY)
    elseif bindingIndex == 2 then
        return GetString(SI_KEYBINDINGS_SECONDARY)
    elseif bindingIndex == 3 then
        return GetString(SI_KEYBINDINGS_TERTIARY)
    else
        return GetString(SI_KEYBINDINGS_QUATERNARY)
    end
end

KEYBINDINGS_MANAGER = KeybindingsManager:New()