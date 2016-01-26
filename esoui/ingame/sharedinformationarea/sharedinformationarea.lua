local SharedInformationArea = ZO_Object:Subclass()

function SharedInformationArea:New(...)
    local sharedInformationArea = ZO_Object.New(self)
    sharedInformationArea:Initialize(...)
    return sharedInformationArea
end

function SharedInformationArea:Initialize()
    self.prioritizedVisibility = ZO_PrioritizedVisibility:New()
end

local LOOT_PRIORITY = 1
local INSTANCE_KICK_PRIORITY = 2
local TUTORIAL_PRIORITY = 3
local SYNERGY_PRIORITY = 4
local RAM_PRIORITY = 5
local FLAG_CAPTURE_PRIORITY = 6
local PLAYER_TO_PLAYER_PRIORITY = 7
local ACTS_PRIORITY = 8

function SharedInformationArea:AddLoot(lootWindow)
    self.prioritizedVisibility:Add(lootWindow, LOOT_PRIORITY)
end

function SharedInformationArea:AddTutorial(tutorial)
    self.prioritizedVisibility:Add(tutorial, TUTORIAL_PRIORITY)
end

function SharedInformationArea:AddSynergy(synergy)
    self.prioritizedVisibility:Add(synergy, SYNERGY_PRIORITY)
end

function SharedInformationArea:AddRam(ram)
    self.prioritizedVisibility:Add(ram, RAM_PRIORITY)
end

function SharedInformationArea:AddFlagCapture(flagCapture)
    self.prioritizedVisibility:Add(flagCapture, FLAG_CAPTURE_PRIORITY)
end

function SharedInformationArea:AddPlayerToPlayer(playerToPlayer)
    self.prioritizedVisibility:Add(playerToPlayer, PLAYER_TO_PLAYER_PRIORITY)
end

function SharedInformationArea:AddActiveCombatTips(acts)
    self.prioritizedVisibility:Add(acts, ACTS_PRIORITY)
end

function SharedInformationArea:AddInstanceKick(instanceKick)
    self.prioritizedVisibility:Add(instanceKick, INSTANCE_KICK_PRIORITY)
end

function SharedInformationArea:SetHidden(object, hidden)
    self.prioritizedVisibility:SetHidden(object, hidden)
end

function SharedInformationArea:IsHidden(object)
    return self.prioritizedVisibility:IsHidden(object)
end

function SharedInformationArea:SetSupressed(supressed)
    self.prioritizedVisibility:SetSupressed(supressed)
end

function SharedInformationArea:IsSuppressed()
    return self.prioritizedVisibility:IsSuppressed()
end

SHARED_INFORMATION_AREA = SharedInformationArea:New()