local DurabilityWarner = ZO_Object:Subclass()

local WARN_WAIT_SECONDS = 60 * 10
local WARN_DAMAGE_THRESHOLD = 0.50

function DurabilityWarner:New()
    local object = ZO_Object.New(self)
    object:Initialize()
    return object
end

function DurabilityWarner:Initialize()
    self.checkSlotBrokenCallback = function(slotId)
        if(DoesItemHaveDurability(BAG_WORN, slotId) and GetItemCondition(BAG_WORN, slotId) <= WARN_DAMAGE_THRESHOLD) then
            return true
        end
    end

    local function OnAddOnLoaded(eventCode, addOnName)
        if(addOnName == "ZO_Ingame") then
            self.savedVar = ZO_SavedVars:New("ZO_Ingame_SavedVariables", 1, "DurabilityWarner")
            local secondsRemaining = self.savedVar.secondsRemaining
            if(secondsRemaining ~= nil) then
                if(self:IsAnyPieceOfGearBroken()) then
                    self.warnTimeSeconds = secondsRemaining + GetFrameTimeSeconds()
                else
                    self.savedVar.secondsRemaining = nil
                end
            else
                self:UpdateWarning()
            end
            self.initialized = true

            local function OnInventoryFullUpdate()
                if(self.initialized) then
                    self:UpdateWarning()
                end
            end
            EVENT_MANAGER:RegisterForEvent("DurabilityWarner", EVENT_INVENTORY_FULL_UPDATE, OnInventoryFullUpdate)

            local function OnInventorySingleSlotUpdate(eventCode, bagId, slotId)
                if(self.initialized and bagId == BAG_WORN) then
                    self:UpdateWarning()
                end
            end
            EVENT_MANAGER:RegisterForEvent("DurabilityWarner", EVENT_INVENTORY_SINGLE_SLOT_UPDATE, OnInventorySingleSlotUpdate)

            EVENT_MANAGER:RegisterForEvent("DurabilityWarner", EVENT_PLAYER_COMBAT_STATE, function() self:UpdateWarning() end)
        end
    end

    EVENT_MANAGER:RegisterForEvent("DurabilityWarner", EVENT_ADD_ON_LOADED, OnAddOnLoaded)
    
    local function OnUpdate()
        local nowSeconds = GetFrameTimeSeconds()
        if(self.warnTimeSeconds) then
            if(nowSeconds > self.warnTimeSeconds) then
                local isInCombat = IsUnitInCombat("player")
                if(not isInCombat) then
                    self:ClearWait()
                    self:WarnAndStartWaiting()
                end
            else
                self.savedVar.secondsRemaining = self.warnTimeSeconds - nowSeconds
            end
        end
    end
    EVENT_MANAGER:RegisterForUpdate("DurabilityWarner", 5000, OnUpdate)
end

function DurabilityWarner:IsAnyPieceOfGearBroken()
    return ZO_Inventory_EnumerateEquipSlots(self.checkSlotBrokenCallback) == true
end

function DurabilityWarner:WarnAndStartWaiting()
    if(not self:IsWaiting()) then
        self:Warn()
        local nowSeconds = GetFrameTimeSeconds()
        self.warnTimeSeconds = nowSeconds + WARN_WAIT_SECONDS
        self.savedVar.secondsRemaining = WARN_WAIT_SECONDS
    end
end

function DurabilityWarner:ClearWait()
    self.warnTimeSeconds = nil
    self.savedVar.secondsRemaining = nil
end

function DurabilityWarner:IsWaiting()
    return self.warnTimeSeconds ~= nil
end

function DurabilityWarner:UpdateWarning()
    local shouldWarn = self:IsAnyPieceOfGearBroken()
    local isInCombat = IsUnitInCombat("player")

    if(shouldWarn) then
        if(not self:IsWaiting()) then
            if(not isInCombat) then
                self:WarnAndStartWaiting()
            end
        end
    else
        if(self:IsWaiting()) then
            self:ClearWait()
        end
    end
end

function DurabilityWarner:Warn()
    ZO_Alert(UI_ALERT_CATEGORY_ALERT, SOUNDS.NEGATIVE_CLICK, SI_EQUIPMENT_DAMAGED)
end

--Initialize
DurabilityWarner:New()