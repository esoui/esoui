--TODO: Refactor the quickslot wheels to use this class
ZO_AssignableUtilityWheel_Shared = ZO_InitializingObject:Subclass()

--TODO: Utilize the restrictToActionTypes table in the data parameter
function ZO_AssignableUtilityWheel_Shared:Initialize(control, data)
    self.control = control
    self.data = data
    self.slots = {}
    self:InitializeSlots()
    self:UpdateAllSlots()
    self:InitializeKeybindStripDescriptors()
    self:RegisterForEvents()
end

function ZO_AssignableUtilityWheel_Shared:RegisterForEvents()
    local function OnSlotUpdated(eventCode, physicalSlot)
        local PLAY_ANIMATION = true
        self:DoSlotUpdate(physicalSlot, PLAY_ANIMATION)
    end

    self.control:RegisterForEvent(EVENT_ACTION_SLOT_UPDATED, OnSlotUpdated)
    --TODO: Filter this based on whether or not the wheel supports emotes
    self.control:RegisterForEvent(EVENT_PERSONALITY_CHANGED, function() self:UpdateAllSlots() end)
end

function ZO_AssignableUtilityWheel_Shared:UpdateAllSlots()
    for physicalSlot in pairs(self.slots) do
        self:DoSlotUpdate(physicalSlot)
    end
end

function ZO_AssignableUtilityWheel_Shared:CreateSlots()
    --To be overridden
end

function ZO_AssignableUtilityWheel_Shared:DoSlotUpdate(physicalSlot, playAnimation)
    --To be overridden
end

function ZO_AssignableUtilityWheel_Shared:InitializeKeybindStripDescriptors()
    --To be overridden
end