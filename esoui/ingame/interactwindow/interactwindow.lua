ZO_INTERACTION_SYSTEM_NAME = "interact"

--Interaction Manager
---------------------

ZO_InteractionManager = ZO_CallbackObject:Subclass()

function ZO_InteractionManager:New()
    local manager = ZO_CallbackObject.New(self)

    return manager
end

function ZO_InteractionManager:OnBeginInteraction(interaction)
    if(self.currentInteraction and (interaction.type ~= self.currentInteraction.type) and self.currentInteraction.End) then
        self.currentInteraction.End()
    end
    self.currentInteraction = interaction
end

function ZO_InteractionManager:OnEndInteraction(interaction)
    if(self.currentInteraction == interaction) then
        self:TerminateClientInteraction(interaction)
        self.currentInteraction = nil
    end
end

function ZO_InteractionManager:TerminateClientInteraction(interaction)
    local interactTypes = interaction.interactTypes
    if(interactTypes) then
        for i = 1, #interactTypes do
            EndInteraction(interactTypes[i])
        end
    end
end

function ZO_InteractionManager:IsInteracting(interaction)
    if interaction == nil then
        return self.currentInteraction ~= nil
    else
        return self.currentInteraction and (self.currentInteraction.type == interaction.type)
    end
end

function ZO_InteractionManager:ShowInteractWindow(bodyText)
    if IsUnderArrest() then
        PushActionLayerByName("SceneChangeInterceptLayer")
    end

    SYSTEMS:ShowScene(ZO_INTERACTION_SYSTEM_NAME)
    self:FireCallbacks("Shown")
end

function ZO_InteractionManager:IsShowingInteraction()
    local obj = SYSTEMS:GetObject(ZO_INTERACTION_SYSTEM_NAME)
    if obj then
        return SCENE_MANAGER:IsShowing(obj.sceneName)
    end

    --if the object doesn't exist then it won't be showing
    return false
end

-- function wrappers as this manager function is called from
-- multiple files. Now just redirects it to the proper object
-------------------------------------------------------------
function ZO_InteractionManager:SelectChatterOptionByIndex(optionIndex)
	local obj = SYSTEMS:GetObjectBasedOnCurrentScene(ZO_INTERACTION_SYSTEM_NAME)
	obj:SelectChatterOptionByIndex(optionIndex)
end

function ZO_InteractionManager:SelectLastChatterOption(optionIndex)
	local obj = SYSTEMS:GetObjectBasedOnCurrentScene(ZO_INTERACTION_SYSTEM_NAME)
	obj:SelectLastChatterOption()
end

-- Globals
-------------------------------------------------------------
INTERACT_WINDOW = ZO_InteractionManager:New()
