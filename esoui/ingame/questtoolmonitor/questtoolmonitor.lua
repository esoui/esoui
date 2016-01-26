ACTIVE_QUEST_TOOL_MONITOR_SYSTEM = nil
ZO_ActiveQuestToolMonitor = ZO_Object:Subclass()

function ZO_ActiveQuestToolMonitor:New(...)
    local qtm = ZO_Object.New(self)
    qtm:Initialize(...)
    return qtm
end

function ZO_ActiveQuestToolMonitor:Initialize(control)
    self.prompt = control:GetNamedChild("Prompt")

    EVENT_MANAGER:RegisterForEvent(control:GetName() .. "_OnActiveQuestToolChanged", EVENT_ACTIVE_QUEST_TOOL_CHANGED, function(...) self:OnActiveQuestToolChanged(...) end)
    EVENT_MANAGER:RegisterForEvent(control:GetName() .. "_OnActiveQuestToolRemoved", EVENT_ACTIVE_QUEST_TOOL_CLEARED, function(...) self:OnActiveQuestToolRemoved(...) end)
end

function ZO_ActiveQuestToolMonitor:OnActiveQuestToolChanged(eventCode, journalIndex, toolIndex)
    local _, _, _, questToolName = GetQuestToolInfo(journalIndex, toolIndex)

    self.prompt:SetText(zo_strformat(GetString(SI_QUEST_USE_QUEST_ITEM_PROMPT), questToolName))
end

function ZO_ActiveQuestToolMonitor:OnActiveQuestToolRemoved(eventCode)
    self.prompt:SetText("")
end

function ZO_ActiveQuestToolMonitor_Initialize(control) 
    ACTIVE_QUEST_TOOL_MONITOR_SYSTEM = ZO_ActiveQuestToolMonitor:New(control)
end

