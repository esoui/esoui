ZO_STUCK_NAME = "Stuck"

local Stuck_Manager = ZO_Object:Subclass()

function Stuck_Manager:New(...)
    local stuck = ZO_Object.New(self)
    stuck:Initialize(...)
    return stuck
end

function Stuck_Manager:Initialize()
    -- this is a check for bringing up a dialog after /reloadui and still being stuck
    local function OnPlayerActivated()
        self:SetActiveSystem()
        self.activeSystem:OnPlayerActivated()
    end

    local function OnStuckBegin()
        self:SetActiveSystem()
        self.activeSystem:OnStuckBegin()
    end

    -- keep the same active system for cancel / complete, as we don't want to orphan dialogs from a different platform
    local function OnStuckCanceled()
        self.activeSystem:OnStuckCanceled()
    end

    local function OnStuckComplete()
        self.activeSystem:OnStuckComplete()
    end

    -- use SYSTEMS for the errors, as PC handles them within the chat event handler, and gamepad handles them with dialogs that can be closed
    -- using the active system here causes a bunch of issues if the user runs gamepad unstuck -> PC unstuck, as PC stuck doesn't run through the stuck manager
    local function OnStuckErrorAlreadyInProgress()        
        SYSTEMS:GetObject(ZO_STUCK_NAME):OnStuckErrorAlreadyInProgress()
    end

    local function OnStuckErrorInvalidLocation()
        SYSTEMS:GetObject(ZO_STUCK_NAME):OnStuckErrorInvalidLocation()
    end

    local function OnStuckErrorInCombat()
        SYSTEMS:GetObject(ZO_STUCK_NAME):OnStuckErrorInCombat()
    end

    local function OnStuckErrorOnCooldown()
        SYSTEMS:GetObject(ZO_STUCK_NAME):OnStuckErrorOnCooldown()
    end

    self:SetActiveSystem()

    EVENT_MANAGER:RegisterForEvent(ZO_STUCK_NAME, EVENT_PLAYER_ACTIVATED, function() OnPlayerActivated() end)
    EVENT_MANAGER:RegisterForEvent(ZO_STUCK_NAME, EVENT_STUCK_BEGIN, function() OnStuckBegin() end)
    EVENT_MANAGER:RegisterForEvent(ZO_STUCK_NAME, EVENT_STUCK_CANCELED, function() OnStuckCanceled() end)
    EVENT_MANAGER:RegisterForEvent(ZO_STUCK_NAME, EVENT_STUCK_COMPLETE, function() OnStuckComplete() end)
    EVENT_MANAGER:RegisterForEvent(ZO_STUCK_NAME, EVENT_STUCK_ERROR_ALREADY_IN_PROGRESS, function() OnStuckErrorAlreadyInProgress() end)
    EVENT_MANAGER:RegisterForEvent(ZO_STUCK_NAME, EVENT_STUCK_ERROR_INVALID_LOCATION, function() OnStuckErrorInvalidLocation() end)
    EVENT_MANAGER:RegisterForEvent(ZO_STUCK_NAME, EVENT_STUCK_ERROR_IN_COMBAT, function() OnStuckErrorInCombat() end)
    EVENT_MANAGER:RegisterForEvent(ZO_STUCK_NAME, EVENT_STUCK_ERROR_ON_COOLDOWN, function() OnStuckErrorOnCooldown() end)
end

function Stuck_Manager:SetActiveSystem()
    self.activeSystem = SYSTEMS:GetObject(ZO_STUCK_NAME)
end

ZO_STUCK_MANAGER = Stuck_Manager:New()