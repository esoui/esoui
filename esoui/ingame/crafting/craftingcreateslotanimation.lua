ZO_CraftingCreateSlotAnimation = ZO_CraftingSlotAnimationBase:Subclass()

function ZO_CraftingCreateSlotAnimation:New(...)
    return ZO_CraftingSlotAnimationBase.New(self, ...)
end

function ZO_CraftingCreateSlotAnimation:Initialize(sceneName, visibilityPredicate)
    ZO_CraftingSlotAnimationBase.Initialize(self, sceneName, visibilityPredicate)
    self.bursts = {}
end

local AcquireSlotBurst, ReleaseSlotBurst
do
    local g_burstPool
    function AcquireSlotBurst()
        if not g_burstPool then
            local function Factory(objectPool)
                local burst = ZO_ObjectPool_CreateControl("ZO_CraftingLockInBurst", objectPool, GuiRoot)
                burst.lockAnimation = ANIMATION_MANAGER:CreateTimelineFromVirtual("CraftingLockInAnimation", burst)
                burst.unlockAnimation = ANIMATION_MANAGER:CreateTimelineFromVirtual("CraftingUnlockAnimation", burst)
                burst.unlockAnimation:SetHandler("OnStop", function() objectPool:ReleaseObject(burst.key) end)

                return burst
            end

            local function Reset()
            end

            g_burstPool = ZO_ObjectPool:New(Factory, Reset)
        end

        local burst, key = g_burstPool:AcquireObject()
        burst.key = key
        return burst
    end

    function ReleaseSlotBurst(burst)
        burst.lockAnimation:Stop()
        burst.unlockAnimation:PlayFromStart()
    end
end

function ZO_CraftingCreateSlotAnimation:GetLockInSound(slot)
    -- Intended to be overriden for custom sounds
    return SOUNDS.CRAFTING_CREATE_SLOT_ANIMATED
end

function ZO_CraftingCreateSlotAnimation:GetAnimationOffset(slot)
    -- Intended to be overriden for custom offsets
    return 200
end

local TOTAL_SLOT_LENGTH_MS = 800
local MIN_LENGTH_PER_SLOT = 200
local MAX_LENGTH_PER_SLOT = 250

local function GetSlotControl(slot)
    if type(slot) == "userdata" then
        return slot
    end
    return slot:GetControl()
end

function ZO_CraftingCreateSlotAnimation:Play(sceneName)
    ClearMenu()

    local offset = 0
    local numSlotsAnimating = 0
    for i, slot in ipairs(self.slots) do
        if slot.HasItem == nil or slot:HasItem() then
            numSlotsAnimating = numSlotsAnimating + 1
        end
    end

    local durationPerSlot = zo_clamp(TOTAL_SLOT_LENGTH_MS / numSlotsAnimating, MIN_LENGTH_PER_SLOT, MAX_LENGTH_PER_SLOT)

    for i, slot in ipairs(self.slots) do
        if slot.HasItem == nil or slot:HasItem() then
            local burst = AcquireSlotBurst()
            local slotControl = GetSlotControl(slot)
            local icon = slotControl:GetNamedChild("Icon")
            ZO_InventorySlot_HandleInventoryUpdate(slotControl)

            burst:SetParent(icon)
            burst:SetAnchor(CENTER, nil, CENTER)

            for animationIndex = 1, burst.lockAnimation:GetNumAnimations() do
                local animation = burst.lockAnimation:GetAnimation(animationIndex)
                animation:SetDuration(durationPerSlot)
                burst.lockAnimation:SetAnimationOffset(animation, offset)
            end

            offset = offset + self:GetAnimationOffset(slot)
        
            burst.lockAnimation:GetLastAnimation():SetAnimatedControl(icon)
            burst.unlockAnimation:GetLastAnimation():SetAnimatedControl(icon)

            burst.lockAnimation.lockInSound = self:GetLockInSound(slot)

            burst.lockAnimation:PlayFromStart()
        
            self.bursts[burst] = true
        end
    end
end

function ZO_CraftingCreateSlotAnimation:Stop(sceneName)
    for burst in pairs(self.bursts) do
        ReleaseSlotBurst(burst)
        self.bursts[burst] = nil
    end
end