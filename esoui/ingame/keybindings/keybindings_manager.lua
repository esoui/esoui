local KeybindingsManager = ZO_Object:Subclass()

function KeybindingsManager:New()
    local obj = ZO_Object.New(self)
    obj:Initialize()
    return obj
end

function KeybindingsManager:Initialize()
    local function OnAddOnLoaded(event, name)
        if name == "ZO_Ingame" then
            PushActionLayerByName(GetString(SI_KEYBINDINGS_LAYER_GENERAL))
            EVENT_MANAGER:UnregisterForEvent("KeybindingsManager", EVENT_ADD_ON_LOADED)
        end
    end

    EVENT_MANAGER:RegisterForEvent("KeybindingsManager", EVENT_ADD_ON_LOADED, OnAddOnLoaded)
end

KEYBINDINGS_MANAGER = KeybindingsManager:New()