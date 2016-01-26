local QuickChatManager = ZO_Object:Subclass()

local CUSTOM_QUICK_CHAT_ID_START = 1000

function QuickChatManager:New()
    local obj = ZO_Object.New(self)
    obj:Initialize()
    return obj
end

function QuickChatManager:Initialize()
    self.formattedNames = {}
end

function QuickChatManager:GetNumQuickChats()
    return GetNumDefaultQuickChats()
end

function QuickChatManager:GetQuickChatIcon()
    return "EsoUI/Art/Emotes/Gamepad/gp_emoteIcon_quickchat.dds"
end

function QuickChatManager:IsDefaultQuickChat(id)
    return id < CUSTOM_QUICK_CHAT_ID_START
end

function QuickChatManager:GetQuickChatId(index)
    return index
end

function QuickChatManager:HasQuickChat(id)
    if self:IsDefaultQuickChat(id) then
        return id <= GetNumDefaultQuickChats()
    end
end

function QuickChatManager:GetQuickChatName(id)
    if self:IsDefaultQuickChat(id) then
        return GetDefaultQuickChatName(id)
    end
end

function QuickChatManager:GetFormattedQuickChatName(id)
    if not self.formattedNames[id] then
        self.formattedNames[id] = zo_strformat(SI_GAMEPAD_PLAYER_EMOTE_NAME, self:GetQuickChatName(id))
    end
    return self.formattedNames[id]
end

function QuickChatManager:GetQuickChatMessage(id)
    if self:IsDefaultQuickChat(id) then
        return GetDefaultQuickChatMessage(id)
    end
end

function QuickChatManager:PlayQuickChat(id)
    if self:IsDefaultQuickChat(id) then
        return PlayDefaultQuickChat(id)
    end
end

function QuickChatManager:BuildQuickChatList()
    local quickChats = {}
    local numChats = self:GetNumQuickChats()
    for index = 1, numChats do
        table.insert(quickChats, self:GetQuickChatId(index))
    end
    return quickChats
end

QUICK_CHAT_MANAGER = QuickChatManager:New()