local Restyle_Manager = ZO_CallbackObject:Subclass()

function Restyle_Manager:New(...)
    return ZO_CallbackObject.New(self)
end

ZO_RESTYLE_MANAGER = Restyle_Manager:New()