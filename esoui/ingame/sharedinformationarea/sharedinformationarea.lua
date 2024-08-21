-- These are flags for a bitmask.
ZO_SHARED_INFORMATION_AREA_SUPPRESSION_CATEGORIES =
{
    HAS_KEYBINDS = 1,
    HIDDEN_BY_INTERACTIVE_WHEEL = 2,
    -- Next value: 4
}

local LOOT_PRIORITY = 1
local INSTANCE_KICK_PRIORITY = 2
local TUTORIAL_PRIORITY = 3
local SYNERGY_PRIORITY = 4
local RAM_PRIORITY = 5
local FLAG_CAPTURE_PRIORITY = 6
local PLAYER_TO_PLAYER_PRIORITY = 7
local ACTS_PRIORITY = 8

local NO_CATEGORIES = nil

local SharedInformationArea = ZO_InitializingCallbackObject:Subclass()

function SharedInformationArea:Initialize()
    self.prioritizedVisibility = ZO_PrioritizedVisibility:New()
    self.prioritizedVisibility:RegisterCallback("VisibleObjectChanged", self.OnVisibleObjectChanged, self)
end

function SharedInformationArea:AddLoot(lootWindow)
    self.prioritizedVisibility:Add(lootWindow, LOOT_PRIORITY, ZO_SHARED_INFORMATION_AREA_SUPPRESSION_CATEGORIES.HAS_KEYBINDS, "Loot")
end

function SharedInformationArea:AddTutorial(tutorial)
    self.prioritizedVisibility:Add(tutorial, TUTORIAL_PRIORITY, ZO_SHARED_INFORMATION_AREA_SUPPRESSION_CATEGORIES.HIDDEN_BY_INTERACTIVE_WHEEL, "Tutorial")
end

function SharedInformationArea:AddSynergy(synergy)
    self.prioritizedVisibility:Add(synergy, SYNERGY_PRIORITY, ZO_SHARED_INFORMATION_AREA_SUPPRESSION_CATEGORIES.HAS_KEYBINDS, "Synergy")
end

function SharedInformationArea:AddRam(ram)
    self.prioritizedVisibility:Add(ram, RAM_PRIORITY, NO_CATEGORIES, "Ram")
end

function SharedInformationArea:AddFlagCapture(flagCapture)
    self.prioritizedVisibility:Add(flagCapture, FLAG_CAPTURE_PRIORITY, NO_CATEGORIES, "Flag")
end

function SharedInformationArea:AddPlayerToPlayer(playerToPlayer)
    self.prioritizedVisibility:Add(playerToPlayer, PLAYER_TO_PLAYER_PRIORITY, ZO_SHARED_INFORMATION_AREA_SUPPRESSION_CATEGORIES.HAS_KEYBINDS, "PlayerToPlayer")
end

function SharedInformationArea:AddActiveCombatTips(acts)
    self.prioritizedVisibility:Add(acts, ACTS_PRIORITY, NO_CATEGORIES, "ActiveCombatTips")
end

function SharedInformationArea:AddInstanceKick(instanceKick)
    self.prioritizedVisibility:Add(instanceKick, INSTANCE_KICK_PRIORITY, ZO_SHARED_INFORMATION_AREA_SUPPRESSION_CATEGORIES.HAS_KEYBINDS, "InstanceKick")
end

function SharedInformationArea:GetPrioritizedVisibility()
    return self.prioritizedVisibility
end

-- Returns true if the specified object has requested to be hidden.
function SharedInformationArea:IsHidden(object)
    return self.prioritizedVisibility:IsHidden(object)
end

-- Returns true if all objects are globally suppressed.
function SharedInformationArea:IsSuppressed()
    return self.prioritizedVisibility:IsCategorySuppressed(ZO_PRIORITIZED_VISIBILITY_CATEGORIES.ALL)
end

function SharedInformationArea:OnVisibleObjectChanged(newObjectInfo, previousObjectInfo)
    self:FireCallbacks("VisibleObjectChanged", newObjectInfo, previousObjectInfo)
end

-- Requests to show or hide the specified object.
function SharedInformationArea:SetHidden(object, hidden)
    local objectInfo = self.prioritizedVisibility:GetObjectInfo(object)
    local isCurrentlyHidden = objectInfo:IsRequestedHidden()
    if hidden ~= isCurrentlyHidden then
        self.prioritizedVisibility:SetHidden(object, hidden)
        self:FireCallbacks("RequestedHiddenStateChanged", objectInfo, hidden, ZO_GetCallerFunctionName())
    end
end

-- Globally suppresses/unsuppresses the display of all objects.
-- Note that 'descriptor' should be a globally unique identifier of the system issuing the request.
function SharedInformationArea:SetSupressed(suppressed, descriptor)
    local caller = ZO_GetCallerFunctionName()
    descriptor = descriptor or caller
    self.prioritizedVisibility:SetCategoriesSuppressed(suppressed, ZO_PRIORITIZED_VISIBILITY_CATEGORIES.ALL, descriptor)
    self:FireCallbacks("GlobalSuppressionStateChanged", suppressed, descriptor, caller)
end

-- Suppresses or unsuppresses the specified categories.
-- Note that 'descriptor' should be a globally unique identifier of the system issuing the request.
function SharedInformationArea:SetCategoriesSuppressed(suppressed, categoriesMask, descriptor)
    local caller = ZO_GetCallerFunctionName()
    descriptor = descriptor or caller
    self.prioritizedVisibility:SetCategoriesSuppressed(suppressed, categoriesMask, descriptor)
    self:FireCallbacks("CategoriesSuppressionStateChanged", suppressed, categoriesMask, descriptor, caller)
end

-- If 'suppressed' is true, suppresses the specified categories and unsuppresses all other categories;
-- otherwise, unsuppresses the specified categories and suppresses all other categories.
-- Note that 'descriptor' should be a globally unique identifier of the system issuing the request.
function SharedInformationArea:SetSuppressedCategoriesMask(suppressed, categoriesMask, descriptor)
    local caller = ZO_GetCallerFunctionName()
    descriptor = descriptor or caller
    self.prioritizedVisibility:SetSuppressedCategoriesMask(suppressed, categoriesMask, descriptor)
    self:FireCallbacks("CategoriesMaskSuppressionStateChanged", suppressed, categoriesMask, descriptor, caller)
end

SHARED_INFORMATION_AREA = SharedInformationArea:New()