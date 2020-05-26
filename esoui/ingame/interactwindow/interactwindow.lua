ZO_INTERACTION_SYSTEM_NAME = "interact"

--Interaction Manager
---------------------

ZO_InteractionManager = ZO_CallbackObject:Subclass()

function ZO_InteractionManager:New(...)
    local manager = ZO_CallbackObject.New(self)
    manager:Initialize(...)
    return manager
end

function ZO_InteractionManager:Initialize()
    ZO_SceneManager_Leader.AddBypassHideSceneConfirmationReason("ARRESTED")

    EVENT_MANAGER:RegisterForEvent("InteractWindow", EVENT_INTERACTION_ENDED, function(_, ...) self:OnInteractionEnded(...) end)
end

function ZO_InteractionManager:OnBeginInteraction(interaction)
    -- If we are interacting already, and the call comes from switching interactions, we need to make sure the previous interact
    -- scene takes care of what it needs to before moving on to another interact scene. This is currently how it works,
    -- but is not the ideal solution since there are implications of how InteractScene works that by happenstance work with this flow
    if(self.currentInteraction and (interaction.type ~= self.currentInteraction.type) and self.currentInteraction.OnInteractSwitch) then
        self.currentInteraction.OnInteractSwitch()
    end
    self.currentInteraction = interaction
end

function ZO_InteractionManager:EndInteraction(interaction)
    if(self.currentInteraction == interaction) then
        self:TerminateClientInteraction(interaction)
        self.currentInteraction = nil
    end
end

function ZO_InteractionManager:OnInteractionEnded(interactType, cancelContext)
    -- The intention here is to account for situations where the interaction got ended in code but Lua hadn't been aware of it
    -- For example, if combat kicked the player out of an interact
    -- For now this will only fire the callback if the interact that was cancelled was the same interact that this manager thought should be running
    -- This is an edge case, the standard flow should have the owning scene starting and ending explicitly wherever possible
    if self.currentInteraction and self.currentInteraction.interactTypes and self.currentInteraction.OnInteractionCanceled then
        if ZO_IsElementInNumericallyIndexedTable(self.currentInteraction.interactTypes, interactType) then
            self.currentInteraction.OnInteractionCanceled(cancelContext)
        end
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
    local sceneName = SYSTEMS:GetRootSceneName(ZO_INTERACTION_SYSTEM_NAME)

    if IsUnderArrest() then
        PushActionLayerByName("SceneChangeInterceptLayer")

        --Bypass any hide confirmations with the arrested reason
        local DONT_PUSH = false
        SCENE_MANAGER:Show(sceneName, DONT_PUSH, nil, nil, ZO_BHSCR_ARRESTED)
        self:FireCallbacks("Shown")
    else
        SCENE_MANAGER:ShowWithFollowup(sceneName, function(allowed)
            if allowed then
                self:FireCallbacks("Shown")
            else
                -- If we're trying to bring up the conversation window but we rejected the request, we want to end that conversation
                -- However, we don't want to end conversations if we were rejected by an already ongoing conversation
                local isNotAlreadyInConversationInteractScene = true
                if self.currentInteraction then
                    for _, interactType in ipairs(self.currentInteraction.interactTypes) do
                        if interactType == INTERACTION_CONVERSATION then
                            isNotAlreadyInConversationInteractScene = false
                            break
                        end
                    end
                end

                if isNotAlreadyInConversationInteractScene then
                    EndInteraction(INTERACTION_CONVERSATION)
                end
            end
        end)
    end
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
