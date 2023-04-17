-------------------------------------
-- Tribute Confinement Viewer Manager
-------------------------------------

ZO_TributeConfinementViewer_Manager = ZO_TributeViewer_Manager_Base:Subclass()

function ZO_TributeConfinementViewer_Manager:Initialize()
    ZO_TributeViewer_Manager_Base.Initialize(self)

    self.confinedCardsData = {}

    ZO_HELP_OVERLAY_SYNC_OBJECT:SetHandler("OnShown", function(isVisible)
        self:RequestClose()
    end, "tributeConfinementViewer")

    self.keybindStripDescriptor = 
    {
        alignment = KEYBIND_STRIP_ALIGN_RIGHT,
        {
            name = GetString(SI_TRIBUTE_CONFINEMENT_VIEWER_BACK_ACTION),
            keybind = "UI_SHORTCUT_NEGATIVE",
            callback = function()
                self:RequestClose()
            end,
        },
    }
end

function ZO_TributeConfinementViewer_Manager:RegisterForEvents(systemName)
    ZO_TributeViewer_Manager_Base.RegisterForEvents(self, systemName)

    EVENT_MANAGER:RegisterForEvent(systemName, EVENT_TRIBUTE_BEGIN_TARGET_SELECTION, function(_, needsTargetViewer)
        --Close the viewer if target selection begins
        if self:IsActive() then
            self:RequestClose()
        end
    end)

    EVENT_MANAGER:RegisterForEvent(systemName, EVENT_TRIBUTE_END_TARGET_SELECTION, function()
        --Close the viewer if target selection ends
        if self:IsActive() then
            self:RequestClose()
        end
    end)

    EVENT_MANAGER:RegisterForEvent(systemName, EVENT_TRIBUTE_BEGIN_MECHANIC_SELECTION, function(_, cardInstanceId)
        --Close the viewer if mechanic selection begins
        if self:IsActive() then
            self:RequestClose()
        end
    end)

    EVENT_MANAGER:RegisterForEvent(systemName, EVENT_TRIBUTE_AGENT_CONFINEMENTS_CHANGED, function(_, agentInstanceId)
        if self:IsActive() and self.viewingAgentInstanceId == agentInstanceId then
            self:RefreshConfinedCards()
            if #self.confinedCardsData > 0 then
                self:FireCallbacks("ConfinementsChanged")
            else
                --If we have no confined cards, we should automatically close
                self:RequestClose()
            end
        end
    end)
end

function ZO_TributeConfinementViewer_Manager:SetViewingAgent(viewingAgentInstanceId, previousViewer)
    if self.viewingAgentInstanceId ~= viewingAgentInstanceId then
        --Order matters. Set the data before firing the activation state change
        self.viewingAgentInstanceId = viewingAgentInstanceId
        --If we are opening from a viewer, store it off so we know where to return later
        self.previousViewer = previousViewer
        self:RefreshConfinedCards()
        if viewingAgentInstanceId then
            --Order matters. Wait until the callback has been fired before adding the keybinds
            self:FireActivationStateChanged()
            KEYBIND_STRIP:AddKeybindButtonGroup(self.keybindStripDescriptor)
        else
            --Order matters. Remove the keybinds before firing the callback
            KEYBIND_STRIP:RemoveKeybindButtonGroup(self.keybindStripDescriptor)
            self:FireActivationStateChanged()
        end
    end
end

function ZO_TributeConfinementViewer_Manager:GetConfinedCardsData()
    return self.confinedCardsData
end

function ZO_TributeConfinementViewer_Manager:GetConfinementText()
    if self.viewingAgentInstanceId then
        local cardDefId = GetTributeCardInstanceDefIds(self.viewingAgentInstanceId)
        local colorizedName = ZO_SELECTED_TEXT:Colorize(GetTributeCardName(cardDefId))
        return zo_strformat(SI_TRIBUTE_CONFINEMENT_VIEWER_HEADER_FORMATTER, colorizedName)
    end
end

function ZO_TributeConfinementViewer_Manager:RefreshConfinedCards()
    ZO_ClearNumericallyIndexedTable(self.confinedCardsData)
    local viewingAgentInstanceId = self.viewingAgentInstanceId
    if viewingAgentInstanceId then
        local numConfined = GetNumConfinedTributeCards(viewingAgentInstanceId)
        for confinedIndex = 1, numConfined do
            local cardInstanceId = GetConfinedTributeCardInstanceId(viewingAgentInstanceId, confinedIndex)
            local cardId, patronId = GetTributeCardInstanceDefIds(cardInstanceId)
            local data =
            {
                cardId = cardId,
                patronId = patronId,
                cardInstanceId = cardInstanceId,
            }
            table.insert(self.confinedCardsData, data)
        end
    end
end

-- Required Overrides

function ZO_TributeConfinementViewer_Manager:GetSystemName()
    return "TributeConfinementViewer_Manager"
end

function ZO_TributeConfinementViewer_Manager:OnGamepadPreferredModeChanged()
    --If the viewer is already up, we need to close and reopen it to make sure it switches to the correct UI
    if self:IsActive() then
        local viewingAgent = self.viewingAgentInstanceId
        local previousViewer = self.previousViewer
        --Specifically don't call RequestClose here, so we don't attempt to reopen the previous viewer
        self:SetViewingAgent(nil)
        self:SetViewingAgent(viewingAgent, previousViewer)
    end
end

--The confinement viewer does not have functionality for viewing the board while it's open
function ZO_TributeConfinementViewer_Manager:IsViewingBoard()
    return false
end

function ZO_TributeConfinementViewer_Manager:IsActive()
    return self.viewingAgentInstanceId ~= nil
end

--The confinement viewer always has a visible keybind strip
function ZO_TributeConfinementViewer_Manager:IsKeybindStripVisible()
    return true
end

function ZO_TributeConfinementViewer_Manager:RequestClose(isInterceptingCloseAction)
    local previousViewer = self.previousViewer
    local NO_AGENT = nil
    self:SetViewingAgent(NO_AGENT)
    --If we were opened from a viewer, attempt to re-open that viewer upon closing
    if previousViewer then
        previousViewer:OpenFromConfinementViewer(isInterceptingCloseAction)
    end
end

ZO_TRIBUTE_CONFINEMENT_VIEWER_MANAGER = ZO_TributeConfinementViewer_Manager:New()