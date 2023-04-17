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
                    local localizedActionName = GetString(_G["SI_BINDING_NAME_" .. actionName])
                    if localizedActionName ~= "" then
                        local data =
                        {
                            actionName = actionName,
                            localizedActionName = localizedActionName,
                            localizedActionNameNarration = GetString(_G["SI_SCREEN_NARRATION_BINDING_NAME_" .. actionName]),
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

function KeybindingsManager:GetNumChangedSavedKeybindings(layerIndex, categoryIndex, actionIndex, bindingIndex, pendingKey, pendingMod1, pendingMod2, pendingMod3, pendingMod4)
    local numChangedSavedKeybinds = 0

    -- first check how changing the current keybind to the pending keybind will change what's saved
    local currentKey, currentMod1, currentMod2, currentMod3, currentMod4 = GetActionBindingInfo(layerIndex, categoryIndex, actionIndex, bindingIndex)
    local defaultKey, defaultMod1, defaultMod2, defaultMod3, defaultMod4 = GetActionDefaultBindingInfo(layerIndex, categoryIndex, actionIndex, bindingIndex)

    local isCurrentDefault = currentKey == defaultKey and currentMod1 == defaultMod1 and currentMod2 == defaultMod2 and currentMod3 == defaultMod3 and currentMod4 == defaultMod4
    local isPendingDefault = pendingKey == defaultKey and pendingMod1 == defaultMod1 and pendingMod2 == defaultMod2 and pendingMod3 == defaultMod3 and pendingMod4 == defaultMod4

    if isCurrentDefault and not isPendingDefault then
        -- current key was default, and setting it to pending will cause a save
        numChangedSavedKeybinds = numChangedSavedKeybinds + 1
    elseif not isCurrentDefault and isPendingDefault then
        -- current key is not defualt, but pending key is, so we won't have to save it anymore
        numChangedSavedKeybinds = numChangedSavedKeybinds - 1
    end

    -- then check if the pending key is already bound somewhere else and how unbinding it will affect what's saved
    local existingCategoryIndex, existingActionIndex, existingBindingIndex = GetBindingIndicesFromKeys(layerIndex, pendingKey, pendingMod1, pendingMod2, pendingMod3, pendingMod4)
    if existingCategoryIndex and existingActionIndex and existingBindingIndex and (existingCategoryIndex ~= categoryIndex or existingActionIndex ~= actionIndex or existingBindingIndex ~= bindingIndex) then
        local existingDefaultKey, existingDefaultMod1, existingDefaultMod2, existingDefaultMod3, existingDefaultMod4 = GetActionDefaultBindingInfo(layerIndex, existingCategoryIndex, existingActionIndex, existingBindingIndex)

        local isExistingDefault = pendingKey == existingDefaultKey and pendingMod1 == existingDefaultMod1 and pendingMod2 == existingDefaultMod2 and pendingMod3 == existingDefaultMod3 and pendingMod4 == existingDefaultMod4
        if isExistingDefault then
            -- The pending key is already bound as the default of something else, so unbinding it will increase the number of saved binds
            numChangedSavedKeybinds = numChangedSavedKeybinds + 1
        else
            local isDefaultUnbound = existingDefaultKey == KEY_INVALID
            if isDefaultUnbound then
                -- Unbinding the pending key from the existing will set it to not bound, which is the default, removing a save
                numChangedSavedKeybinds = numChangedSavedKeybinds - 1
            end
        end
    end

    return numChangedSavedKeybinds
end

function KeybindingsManager:GetNumChangedSavedKeybindingsIfUnbound(layerIndex, categoryIndex, actionIndex, bindingIndex)
    return self:GetNumChangedSavedKeybindings(layerIndex, categoryIndex, actionIndex, bindingIndex, KEY_INVALID, KEY_INVALID, KEY_INVALID, KEY_INVALID, KEY_INVALID)
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