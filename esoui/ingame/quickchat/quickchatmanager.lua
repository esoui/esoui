local CUSTOM_QUICK_CHAT_INDEX_START = 1000

ZO_QuickChatManager = ZO_InitializingObject:Subclass()

function ZO_QuickChatManager:Initialize()
    self.formattedNames = {}
end

function ZO_QuickChatManager:GetNumQuickChats()
    return GetNumDefaultQuickChats()
end

function ZO_QuickChatManager:IsDefaultQuickChat(quickChatIndex)
    return quickChatIndex < CUSTOM_QUICK_CHAT_INDEX_START
end

--This number can be treated as both an ID or an index depending on what it's being used for, so GetQuickChatId and GetQuickChatIndex are here to help make it more obvious when we want one vs the other
function ZO_QuickChatManager:GetQuickChatId(index)
    return index
end

function ZO_QuickChatManager:GetQuickChatIndex(id)
    return id
end

function ZO_QuickChatManager:HasQuickChat(id)
    local quickChatIndex = self:GetQuickChatIndex(id)
    if self:IsDefaultQuickChat(quickChatIndex) then
        return quickChatIndex <= GetNumDefaultQuickChats()
    end
end

function ZO_QuickChatManager:GetQuickChatName(quickChatIndex)
    if self:IsDefaultQuickChat(quickChatIndex) then
        return GetDefaultQuickChatName(quickChatIndex)
    end
end

function ZO_QuickChatManager:GetFormattedQuickChatName(id)
    local quickChatIndex = self:GetQuickChatIndex(id)
    if not self.formattedNames[quickChatIndex] then
        self.formattedNames[quickChatIndex] = zo_strformat(SI_PLAYER_EMOTE_NAME, self:GetQuickChatName(quickChatIndex))
    end
    return self.formattedNames[quickChatIndex]
end

function ZO_QuickChatManager:GetQuickChatMessage(id)
    local quickChatIndex = self:GetQuickChatIndex(id)
    if self:IsDefaultQuickChat(quickChatIndex) then
        return GetDefaultQuickChatMessage(quickChatIndex)
    end
end

function ZO_QuickChatManager:PlayQuickChat(id)
    local quickChatIndex = self:GetQuickChatIndex(id)
    if self:IsDefaultQuickChat(quickChatIndex) then
        return PlayDefaultQuickChat(quickChatIndex)
    end
end

function ZO_QuickChatManager:BuildQuickChatList()
    local quickChats = {}
    local numChats = self:GetNumQuickChats()
    for index = 1, numChats do
        table.insert(quickChats, self:GetQuickChatId(index))
    end
    return quickChats
end

QUICK_CHAT_MANAGER = ZO_QuickChatManager:New()