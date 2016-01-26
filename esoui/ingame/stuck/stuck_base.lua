ZO_Stuck_Base = ZO_Object:Subclass()

function ZO_Stuck_Base:New(...)
    local object = ZO_Object.New(self)
    object:Initialize(...)
    return object
end

function ZO_Stuck_Base:Initialize()
end

-- Events to be overriden by the subclasses

function ZO_Stuck_Base:OnPlayerActivated()
end

function ZO_Stuck_Base:OnStuckBegin()
end

function ZO_Stuck_Base:OnStuckCanceled()
end

function ZO_Stuck_Base:OnStuckComplete()
end

function ZO_Stuck_Base:OnStuckErrorAlreadyInProgress()
end

function ZO_Stuck_Base:OnStuckErrorInvalidLocation()
end

function ZO_Stuck_Base:OnStuckErrorInCombat()
end

function ZO_Stuck_Base:OnStuckErrorOnCooldown()
end