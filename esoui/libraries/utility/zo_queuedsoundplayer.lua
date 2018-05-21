ZO_QueuedSoundPlayer = ZO_Object:Subclass()
local g_id = 1

--[[ Public API ]]--
function ZO_QueuedSoundPlayer:New(...)
    local queuedSoundPlayer = ZO_Object.New(self)
    queuedSoundPlayer:Initialize(...)
    return queuedSoundPlayer
end

function ZO_QueuedSoundPlayer:Initialize(soundPaddingMs)
    self.queue = {}
    self.soundPaddingMs = soundPaddingMs or 0
    self.id = "ZO_QueuedSoundPlayer" .. g_id
    g_id = g_id + 1

    self.OnUpdateFunction = function() self:OnSoundFinished() end
end

function ZO_QueuedSoundPlayer:SetFinishedAllSoundsCallback(finishedAllSoundsCallback)
    self.finishedAllSoundsCallback = finishedAllSoundsCallback
end

function ZO_QueuedSoundPlayer:PlaySound(soundName, soundLength)
    if self:IsPlaying() then
        self.queue[#self.queue + 1] = { soundName = soundName, soundLength = soundLength }
    else
        self:StartSound(soundName, soundLength)
    end
end

function ZO_QueuedSoundPlayer:ForceStop()
    EVENT_MANAGER:UnregisterForUpdate(self.id)
    self.currentPlayingSoundLength = nil
    ZO_ClearNumericallyIndexedTable(self.queue)
end

function ZO_QueuedSoundPlayer:IsPlaying()
    return self.currentPlayingSoundLength ~= nil
end

--[[ Private API ]]--
function ZO_QueuedSoundPlayer:StartSound(soundName, soundLength)
    self.currentPlayingSoundLength = soundLength + self.soundPaddingMs
    PlaySound(soundName)

    EVENT_MANAGER:RegisterForUpdate(self.id, self.currentPlayingSoundLength, self.OnUpdateFunction)
end

function ZO_QueuedSoundPlayer:OnSoundFinished()
    EVENT_MANAGER:UnregisterForUpdate(self.id)

    if #self.queue > 0 then
        local nextSound = table.remove(self.queue, 1)
        self:StartSound(nextSound.soundName, nextSound.soundLength)
    else
        self.currentPlayingSoundLength = nil
        if self.finishedAllSoundsCallback then
            self.finishedAllSoundsCallback(self)
        end
    end
end