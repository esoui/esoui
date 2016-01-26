----------------------------------
--Group List Base
----------------------------------

ZO_GroupList_Base = ZO_Object:Subclass()

function ZO_GroupList_Base:New(control)
    local manager = ZO_Object.New(self)
    manager:Initialize(control)
    return manager
end

function ZO_GroupList_Base:Initialize(control)
    self.control = control
end


--Virtual
function ZO_GroupList_Base:SetupGroupEntry(control, data)
    
end
