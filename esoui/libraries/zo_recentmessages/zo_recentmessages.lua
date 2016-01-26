ZO_RecentMessages = ZO_Object:Subclass()

function ZO_RecentMessages:New(...)
    local object = ZO_Object.New(self)
    object:Initialize(...)
    return object
end

function ZO_RecentMessages:Initialize(expiryDelayMilliseconds)
    self.recentMessages = {}
    self.expiryDelayMilliseconds = expiryDelayMilliseconds or 3000
end

function ZO_RecentMessages:AddRecent(message)
    self.recentMessages[message] = GetFrameTimeMilliseconds()
end

function ZO_RecentMessages:IsRecent(message)
    return self.recentMessages[message] ~= nil
end

function ZO_RecentMessages:Update(timeNowMilliseconds)
    local recentMessages = self.recentMessages
    local expiry = self.expiryDelayMilliseconds
    for message, timeStamp in pairs(recentMessages) do
        if(timeNowMilliseconds >= (timeStamp + expiry)) then
            recentMessages[message] = nil
        end
    end
end

-- Returns true if the message wasn't recent and should be displayed
-- Adds the given message to the recent queue if the message would be displayed
-- Future calls to this function will update the queue automatically
function ZO_RecentMessages:ShouldDisplayMessage(message)
    self:Update(GetFrameTimeMilliseconds())

    if(message == SOUNDS.ABILITY_NOT_ENOUGH_STAMINA or message == SOUNDS.ABILITY_NOT_ENOUGH_MAGICKA or 
        message == SOUNDS.ABILITY_NOT_ENOUGH_ULTIMATE or message == SOUNDS.ITEM_ON_COOLDOWN or
        message == SOUNDS.ABILITY_WEAPON_SWAP_FAIL or message == SOUNDS.ABILITY_NOT_READY or
        message == SOUNDS.ABILITY_TARGET_OUT_OF_LOS or message == SOUNDS.ABILITY_TARGET_OUT_OF_RANGE or
        message == SOUNDS.ABILITY_TARGET_IMMUNE or message == SOUNDS.ABILITY_CASTER_SILENCED or
        message == SOUNDS.ABILITY_CASTER_STUNNED or message == SOUNDS.ABILITY_CASTER_BUSY or
        message == SOUNDS.ABILITY_TARGET_BAD_TARGET or message == SOUNDS.ABILITY_TARGET_DEAD or
        message == SOUNDS.ABILITY_CASTER_DEAD or message == SOUNDS.ABILITY_NOT_ENOUGH_HEALTH or
        message == SOUNDS.ABILITY_FAILED or message == SOUNDS.ABILITY_FAILED_IN_COMBAT or
        message == SOUNDS.ABILITY_FAILED_REQUIREMENTS or message == SOUNDS.ABILITY_CASTER_FEARED or
        message == SOUNDS.ABILITY_CASTER_DISORIENTED or message == SOUNDS.ABILITY_TARGET_TOO_CLOSE or
        message == SOUNDS.ABILITY_WRONG_WEAPON or message == SOUNDS.ABILITY_TARGET_NOT_PVP_FLAGGED or
        message == SOUNDS.ABILITY_CASTER_PACIFIED or message == SOUNDS.ABILITY_CASTER_LEVITATED) then
        return true
    end

    if(self:IsRecent(message)) then 
        return false 
    end

    self:AddRecent(message)
    return true
end