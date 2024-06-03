----------------------------
-- ZO_ScribingDataManager --
----------------------------

ZO_SCRIBING_LEVEL_GATE = 30

ZO_ScribingDataManager = ZO_InitializingCallbackObject:Subclass()

function ZO_ScribingDataManager:Initialize()
    SCRIBING_DATA_MANAGER = self

    self.craftedAbilityObjects = {}
    self.unlockedCraftedAbilityObjects = {}
    self.craftedAbilityScriptObjects = {}
    self.sortedCraftedAbilityTable = {}
    self.sortedUnlockedCraftedAbilityTable = {}

    self:RebuildData()

    local function OnCraftedAbilityLockStateChanged(eventId, ...)
        self:OnCraftedAbilityLockStateChanged(...)
    end
    EVENT_MANAGER:RegisterForEvent("ZO_ScribingDataManager", EVENT_CRAFTED_ABILITY_LOCK_STATE_CHANGED, OnCraftedAbilityLockStateChanged)

    local function OnCraftedAbilityScriptLockStateChanged(eventId, ...)
        self:OnCraftedAbilityScriptLockStateChanged(...)
    end
    EVENT_MANAGER:RegisterForEvent("ZO_ScribingDataManager", EVENT_CRAFTED_ABILITY_SCRIPT_LOCK_STATE_CHANGED, OnCraftedAbilityScriptLockStateChanged)
end

function ZO_ScribingDataManager:MarkDataDirty()
    self.isDataDirty = true
end

function ZO_ScribingDataManager:CleanData()
    if self.isDataDirty then
        self:RebuildData()
    end
end

do
    local function SortBySkillType(left, right)
        local leftSkillType = left:GetSkillType()
        local rightSkillType = right:GetSkillType()
        if leftSkillType == rightSkillType then
            local leftUnlocked = left:IsUnlocked()
            local rightUnlocked = right:IsUnlocked()
            if leftUnlocked ~= rightUnlocked then
                return leftUnlocked
            else
                return left:GetDisplayName() < right:GetDisplayName()
            end
        else
            return leftSkillType < rightSkillType
        end
    end

    function ZO_ScribingDataManager:RebuildData()
        ZO_ClearTable(self.craftedAbilityObjects)
        ZO_ClearTable(self.unlockedCraftedAbilityObjects)
        ZO_ClearTable(self.craftedAbilityScriptObjects)
        ZO_ClearNumericallyIndexedTable(self.sortedCraftedAbilityTable)

        -- make sure to clear the dirty state before we try to fetch data
        -- or else we will end up in an infinite loop trying to clean data
        self.isDataDirty = false

        local numCraftedAbilities = GetNumCraftedAbilities()
        for i = 1, numCraftedAbilities do
            local craftedAbilityId = GetCraftedAbilityIdAtIndex(i)
            self:InternalGetOrCreateCraftedAbilityData(craftedAbilityId)
        end

        for i, craftedAbilityData in pairs(self.craftedAbilityObjects) do
            table.insert(self.sortedCraftedAbilityTable, craftedAbilityData)
        end

        table.sort(self.sortedCraftedAbilityTable, SortBySkillType)
        self:RefreshSortedUnlockedCraftedAbilityTable()
    end

    function ZO_ScribingDataManager:RefreshSortedUnlockedCraftedAbilityTable()
        ZO_ClearNumericallyIndexedTable(self.sortedUnlockedCraftedAbilityTable)
        for i, craftedAbilityData in pairs(self.unlockedCraftedAbilityObjects) do
            table.insert(self.sortedUnlockedCraftedAbilityTable, craftedAbilityData)
        end
        table.sort(self.sortedUnlockedCraftedAbilityTable, SortBySkillType)
    end
end

function ZO_ScribingDataManager:GetSortedBySkillTypeCraftedAbilityData()
    self:CleanData()
    return self.sortedCraftedAbilityTable
end

function ZO_ScribingDataManager:GetSortedBySkillTypeUnlockedCraftedAbilityData()
    self:CleanData()
    return self.sortedUnlockedCraftedAbilityTable
end

function ZO_ScribingDataManager:GetScribedCraftedAbilitySkillsData()
    local scribedCraftedAbilitySkillsData = {}
    for i, craftedAbilityData in ipairs(self.sortedUnlockedCraftedAbilityTable) do
        local skillData = craftedAbilityData:GetSkillData()
        if skillData and skillData.isPurchased then
            table.insert(scribedCraftedAbilitySkillsData, skillData)
        end
    end
    return scribedCraftedAbilitySkillsData
end

function ZO_ScribingDataManager:HasScribedCraftedAbilitySkillsData()
    local scribedCraftedAbilities = self:GetScribedCraftedAbilitySkillsData()
    return #scribedCraftedAbilities > 0
end

do
    local function SortByUnlocked(left, right)
        local leftUnlocked = left:IsUnlocked()
        local rightUnlocked = right:IsUnlocked()
        if leftUnlocked ~= rightUnlocked then
            return leftUnlocked
        else
            return left:GetDisplayName() < right:GetDisplayName()
        end
    end

    function ZO_ScribingDataManager:GetUnlockedSortedScriptsForCraftedAbilityAndSlot(craftedAbilityId, scribingSlot)
        local unlockedScripts = {}
        local craftedAbilityData = self:GetCraftedAbilityData(craftedAbilityId)
        if craftedAbilityData then
            local scriptIds = craftedAbilityData:GetScriptIdsForScribingSlot(scribingSlot)
            for i, scriptId in ipairs(scriptIds) do
                local scriptData = self:GetCraftedAbilityScriptData(scriptId)
                if scriptData:IsUnlocked() and not scriptData:IsDisabled() then
                    table.insert(unlockedScripts, scriptData)
                end
            end
        end

        table.sort(unlockedScripts, SortByUnlocked)

        local unlockedScriptIds = {}
        for i, scriptData in ipairs(unlockedScripts) do
            table.insert(unlockedScriptIds, scriptData:GetId())
        end

        return unlockedScriptIds
    end

    function ZO_ScribingDataManager:GetAllSortedScriptsForCraftedAbilityAndSlot(craftedAbilityId, scribingSlot)
        local allScripts = {}
        local craftedAbilityData = self:GetCraftedAbilityData(craftedAbilityId)
        if craftedAbilityData then
            local scriptIds = craftedAbilityData:GetScriptIdsForScribingSlot(scribingSlot)
            for i, scriptId in ipairs(scriptIds) do
                local scriptData = self:GetCraftedAbilityScriptData(scriptId)
                table.insert(allScripts, scriptData)
            end
        end

        table.sort(allScripts, SortByUnlocked)

        local allScriptIds = {}
        for i, scriptData in ipairs(allScripts) do
            table.insert(allScriptIds, scriptData:GetId())
        end

        return allScriptIds
    end
end

function ZO_ScribingDataManager:GetAllCraftedAbilityScriptIds()
    self:CleanData()
    local scriptIds = {}
    for scriptId, scriptData in pairs(self.craftedAbilityScriptObjects) do
        table.insert(scriptIds, scriptId)
    end
    return scriptIds
end

function ZO_ScribingDataManager:GetCraftedAbilityData(craftedAbilityId)
    self:CleanData()
    return self.craftedAbilityObjects[craftedAbilityId]
end

function ZO_ScribingDataManager:GetCraftedAbilityScriptData(scriptId)
    self:CleanData()
    return self.craftedAbilityScriptObjects[scriptId]
end

function ZO_ScribingDataManager:IsScribingUnlocked()
    local scribingCollectibleId = GetScribingCollectibleId()
    local collectibleData = ZO_COLLECTIBLE_DATA_MANAGER:GetCollectibleDataById(scribingCollectibleId)
    if collectibleData then
        return collectibleData:IsUnlocked()
    end
    return false
end

function ZO_ScribingDataManager:GetScribingUnlockCollectibleData()
    local scribingCollectibleId = GetScribingCollectibleId()
    return ZO_COLLECTIBLE_DATA_MANAGER:GetCollectibleDataById(scribingCollectibleId)
end

function ZO_ScribingDataManager:GetScribingPurchasableCollectibleData()
    local scribingCollectibleId = GetScribingCollectibleId()
    local purchasableCollectibleId = GetPurchasableCollectibleIdForCollectible(scribingCollectibleId)
    local relevantCollectibleId = purchasableCollectibleId == 0 and scribingCollectibleId or purchasableCollectibleId
    return ZO_COLLECTIBLE_DATA_MANAGER:GetCollectibleDataById(relevantCollectibleId)
end

function ZO_ScribingDataManager:IsScribingContentAccessible()
    local scribingCollectibleData = self:GetScribingUnlockCollectibleData()
    local scribingQuestId = scribingCollectibleData:GetCollectibleAssociatedQuestState()
    return questState == COLLECTIBLE_ASSOCIATED_QUEST_STATE_COMPLETED
end

function ZO_ScribingDataManager:GetScribingInaccessibleText()
    local collectibleData = self:GetScribingUnlockCollectibleData()
    if collectibleData then
        return zo_strformat(SI_SCRIBING_CONTENT_INACCESSIBLE, ZO_SCRIBING_LEVEL_GATE, collectibleData:GetFormattedName(), collectibleData:GetCategoryTypeDisplayName())
    end
    return ""
end

function ZO_ScribingDataManager:InternalGetOrCreateCraftedAbilityScriptData(scriptId)
    if scriptId > 0 then
        local scriptData = self:GetCraftedAbilityScriptData(scriptId)
        if not scriptData then
            scriptData = ZO_CraftedAbilityScriptData:New(scriptId)
            self.craftedAbilityScriptObjects[scriptId] = scriptData
        end
        return scriptData
    end
    return nil
end

function ZO_ScribingDataManager:InternalGetOrCreateCraftedAbilityData(craftedAbilityId)
    if craftedAbilityId > 0 then
        local craftedAbilityData = self:GetCraftedAbilityData(craftedAbilityId)
        if not craftedAbilityData then
            craftedAbilityData = ZO_CraftedAbilityData:New(craftedAbilityId)

            if craftedAbilityData:GetSkillType() ~= SKILL_TYPE_NONE then
                for scribingSlot = SCRIBING_SLOT_ITERATION_BEGIN, SCRIBING_SLOT_ITERATION_END do
                    local numScriptsInCurrentSlot = GetNumScriptsInSlotForCraftedAbility(craftedAbilityId, scribingSlot)
                    for i = 1, numScriptsInCurrentSlot do
                        local scriptId = GetScriptIdAtSlotIndexForCraftedAbility(craftedAbilityId, scribingSlot, i)
                        local scriptData = self:InternalGetOrCreateCraftedAbilityScriptData(scriptId)
                        if scribingSlot ~= scriptData:GetScribingSlot() then
                            local scriptSlotName = GetString("SI_SCRIBINGSLOT_SHORT", scriptData:GetScribingSlot())
                            local errorText = string.format("Crafted Ability Script %d in %s slot %d of Crafted Ability %d is not a %s script", scriptId, scriptSlotName, craftedAbilityId, scriptSlotName)
                            assert(false, errorText)
                        end
                        craftedAbilityData:AddScript(scribingSlot, scriptId)
                    end
                end

                self.craftedAbilityObjects[craftedAbilityId] = craftedAbilityData
                if craftedAbilityData:IsUnlocked() then
                    self.unlockedCraftedAbilityObjects[craftedAbilityId] = craftedAbilityData
                end
            end
        end
    end
end

function ZO_ScribingDataManager:OnCraftedAbilityLockStateChanged(craftedAbilityId, isUnlocked)
    local craftedAbilityData = self:GetCraftedAbilityData(craftedAbilityId)
    if craftedAbilityData then
        if isUnlocked then
            self.unlockedCraftedAbilityObjects[craftedAbilityId] = craftedAbilityData
        elseif self.unlockedCraftedAbilityObjects[craftedAbilityId] then
            self.unlockedCraftedAbilityObjects[craftedAbilityId] = nil
        end
        self:RefreshSortedUnlockedCraftedAbilityTable()
        self:FireCallbacks("CraftedAbilityLockStateChanged", craftedAbilityData, isUnlocked)
    end
end

function ZO_ScribingDataManager:OnCraftedAbilityScriptLockStateChanged(craftedAbilityScriptId, isUnlocked)
    local craftedAbilityScriptData = self:GetCraftedAbilityScriptData(craftedAbilityScriptId)
    if craftedAbilityScriptData then
        self:FireCallbacks("CraftedAbilityScriptLockStateChanged", craftedAbilityScriptData, isUnlocked)
    end
end

-- Global singleton

-- The global singleton moniker is assigned by the Data Manager's constructor in order to
-- allow data objects to reference the singleton during their construction.
ZO_ScribingDataManager:New()