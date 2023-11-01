ZO_CraftAdvisorManager = ZO_CallbackObject:Subclass()

local DEFAULT_SELECTED_QUEST_INDEX = 1
function ZO_CraftAdvisorManager:New(...)
    local manager = ZO_CallbackObject.New(self)
    manager:Initialize(...)
    return manager
end

function ZO_CraftAdvisorManager:Initialize()
    self.craftingInteractionType = CRAFTING_TYPE_INVALID
    self.questMasterList = {}
    self.selectedMasterListIndex = DEFAULT_SELECTED_QUEST_INDEX
    EVENT_MANAGER:RegisterForEvent("ZO_CraftAdvisorManager", EVENT_CRAFTING_STATION_INTERACT, function(eventCode, craftingType, sameStation, craftingMode)
        --If we are at a different type of crafting station, we need to update the list
        --Otherwise, if anything has changed, we will have already attempted to refresh via the quest events
        --We also need to refresh if the player goes to a new smithing station, since they might be changing to a new set station
        --We always need to refresh the list if we are interacting with a consolidated station, as the available sets at the station could have changed
        if craftingMode == CRAFTING_INTERACTION_MODE_CONSOLIDATED_STATION or craftingType ~= self.craftingInteractionType or (not sameStation and IsSmithingCraftingType(craftingType)) then
            self.craftingInteractionType = craftingType
            self:RefreshQuestMasterList()
        end
    end)

    local function UpdateQuestConditions(questIndex, mainStepChanged)
        if mainStepChanged then
            self:RefreshQuestMasterList()
        end
        local currentlySelectedQuest = self.questMasterList[self.selectedMasterListIndex]
        if currentlySelectedQuest and currentlySelectedQuest.questIndex == questIndex then
            self:UpdateQuestConditionInfo()
            --Tell the craft advisor that it needs to refresh the quest display
            self:FireCallbacks("SelectedQuestConditionsUpdated")
        end
    end

    --Register for the various quest change events
    EVENT_MANAGER:RegisterForEvent("ZO_CraftAdvisorManager", EVENT_QUEST_CONDITION_COUNTER_CHANGED, function(_, questIndex) UpdateQuestConditions(questIndex) end)
    EVENT_MANAGER:RegisterForEvent("ZO_CraftAdvisorManager", EVENT_QUEST_ADVANCED, function(_, questIndex, questName, isPushed, isComplete, mainStepChanged) UpdateQuestConditions(questIndex, mainStepChanged) end)
    EVENT_MANAGER:RegisterForEvent("ZO_CraftAdvisorManager", EVENT_ACHIEVEMENT_UPDATED, function()
        --We need to register for this event to detect if a new translation has been discovered
        --Presumably, this can only happen while enchanting, so if the enchanting scene is not showing, we shouldn't care
        if ZO_Enchanting_IsSceneShowing() then
            self:UpdateQuestConditionInfo()
            self:FireCallbacks("SelectedQuestConditionsUpdated")
        end 
    end)

    --We need to rebuild when the inventory changes so we can make sure we display the proper messaging if there are missing materials/runes/reagents/etc
    EVENT_MANAGER:RegisterForEvent("ZO_CraftAdvisorManager", EVENT_INVENTORY_FULL_UPDATE, function() self:FireCallbacks("SelectedQuestConditionsUpdated") end)
    EVENT_MANAGER:RegisterForEvent("ZO_CraftAdvisorManager", EVENT_INVENTORY_SINGLE_SLOT_UPDATE, function() self:FireCallbacks("SelectedQuestConditionsUpdated") end)

    --We need to rebuild when we learn a new recipe so we can make sure we display the proper messaging for missing recipes
    EVENT_MANAGER:RegisterForEvent("ZO_CraftAdvisorManager", EVENT_RECIPE_LEARNED, function() self:FireCallbacks("SelectedQuestConditionsUpdated") end)
    EVENT_MANAGER:RegisterForEvent("ZO_CraftAdvisorManager", EVENT_MULTIPLE_RECIPES_LEARNED, function() self:FireCallbacks("SelectedQuestConditionsUpdated") end)

    --We need to rebuild if the player's solvent proficiency changed or they got the Laboratory Use skill, to ensure the error messaging refreshes
    EVENT_MANAGER:RegisterForEvent("ZO_CraftAdvisorManager", EVENT_NON_COMBAT_BONUS_CHANGED, function(eventCode, nonCombatBonusType)
        if nonCombatBonusType == NON_COMBAT_BONUS_ALCHEMY_THIRD_SLOT or nonCombatBonusType == NON_COMBAT_BONUS_ALCHEMY_LEVEL then
            self:FireCallbacks("SelectedQuestConditionsUpdated")
        end
    end)

    --We need to rebuild when the active set changes since it will result in different patterns being available
    EVENT_MANAGER:RegisterForEvent("ZO_CraftAdvisorManager", EVENT_CONSOLIDATED_STATION_ACTIVE_SET_UPDATED, function()
        self:UpdateQuestConditionInfo()
        self:FireCallbacks("SelectedQuestConditionsUpdated")
    end)

    --We need to rebuild the whole list when the unlocked consolidated sets change, as it could impact what quests are valid at this station
    EVENT_MANAGER:RegisterForEvent("ZO_CraftAdvisorManager", EVENT_CONSOLIDATED_STATION_SETS_UPDATED, function() self:RefreshQuestMasterList() end)

    QUEST_JOURNAL_MANAGER:RegisterCallback("QuestListUpdated", function() self:RefreshQuestMasterList() end)
end

function ZO_CraftAdvisorManager:HasActiveWrits()
    return self.questMasterList and #self.questMasterList > 0
end

function ZO_CraftAdvisorManager:RefreshQuestMasterList()
    --Grab the current quest information from the journal
    local quests = QUEST_JOURNAL_MANAGER:GetQuestList()

    --Clear out the current quest pin data
    self:FireCallbacks("QuestInformationUpdated", {patternIndices = {}, materialIndex = nil, traitId = nil, styleId = nil, recipeItemIds = {}, runeIds = {}, alchemyInfo = {}, improvementInfo = {}})
    self.selectedMasterListIndex = DEFAULT_SELECTED_QUEST_INDEX 
    ZO_ClearTable(self.questMasterList)

    --Filter out any non-crafting quests from the list
    for i, questInfo in ipairs(quests) do
        if questInfo.questType == QUEST_TYPE_CRAFTING then
            local conditionCount = select(5, GetJournalQuestStepInfo(questInfo.questIndex, QUEST_MAIN_STEP_INDEX))
            local conditionInfo = {}
            for conditionIndex = 1, conditionCount do
                local conditionType = select(8, GetJournalQuestConditionInfo(questInfo.questIndex, QUEST_MAIN_STEP_INDEX, conditionIndex))

                if conditionType == QUEST_CONDITION_TYPE_GATHER_ITEM then
                    local itemId, materialItemId, craftingType, itemFunctionalQuality = GetQuestConditionItemInfo(questInfo.questIndex, QUEST_MAIN_STEP_INDEX, conditionIndex)
                    --If any of the condition crafting types match the current interaction type, we want to include this quest
                    local shouldShowQuest = (craftingType == self.craftingInteractionType)

                    --Provisioning is special in that in can be done at any crafting station type, so we need to do a slightly different check for it
                    if craftingType == CRAFTING_TYPE_PROVISIONING then
                        local craftingStationType = GetRecipeInfoFromItemId(itemId)
                        shouldShowQuest = (craftingStationType == self.craftingInteractionType)
                    end

                    if shouldShowQuest then
                        local data = 
                        {
                            conditionIndex = conditionIndex,
                            itemId = itemId,
                            materialItemId = materialItemId,
                            craftingType = craftingType,
                            itemFunctionalQuality = itemFunctionalQuality,
                            isMasterWrit = false,
                        }
                        table.insert(conditionInfo, data)
                    end
                elseif conditionType == QUEST_CONDITION_TYPE_CRAFT_RANDOM_WRIT_ITEM then
                    local itemId, materialItemId, craftingType, itemFunctionalQuality, itemTemplateId, itemSetId, itemTraitType, itemStyleId, encodedAlchemyTraits = GetQuestConditionMasterWritInfo(questInfo.questIndex, QUEST_MAIN_STEP_INDEX, conditionIndex)
                    --If any of the condition crafting types match the current interaction type, we want to include this quest
                    local shouldShowQuest = (craftingType == self.craftingInteractionType)

                    --Provisioning is special in that in can be done at any crafting station type, so we need to do a slightly different check for it
                    if craftingType == CRAFTING_TYPE_PROVISIONING then
                        local craftingStationType = GetRecipeInfoFromItemId(itemId)
                        shouldShowQuest = (craftingStationType == self.craftingInteractionType)
                    end

                    if shouldShowQuest then
                        local data = 
                        {
                            conditionIndex = conditionIndex,
                            itemId = itemId,
                            materialItemId = materialItemId,
                            craftingType = craftingType,
                            itemFunctionalQuality = itemFunctionalQuality,
                            itemTemplateId = itemTemplateId,
                            itemSetId = itemSetId,
                            itemTraitType = itemTraitType,
                            itemStyleId = itemStyleId,
                            encodedAlchemyTraits = encodedAlchemyTraits,
                            isMasterWrit = true,
                        }

                        --Smithing master writs should only show up at their specific set station
                        if IsSmithingCraftingType(craftingType) then
                            if CanSpecificSmithingItemSetPatternBeCraftedHere(itemSetId) then
                                table.insert(conditionInfo, data)
                            end
                        else
                            table.insert(conditionInfo, data)
                        end
                    end
                end
            end

            if #conditionInfo > 0 then
                questInfo.conditionData = conditionInfo
                table.insert(self.questMasterList, questInfo)
            end
        end
    end
    self:FireCallbacks("QuestMasterListUpdated", self.questMasterList)
end

function ZO_CraftAdvisorManager:GetMissingMessage(conditionInfo, currentCount, maxCount)
    --If we have already met the condition requirements, we no longer care about what components we have
    if currentCount < maxCount then
        if conditionInfo.craftingType == CRAFTING_TYPE_ENCHANTING then
            local potencyRune, essenceRune, aspectRune = GetRunesForItemIdIfKnown(conditionInfo.itemId, conditionInfo.materialItemId, conditionInfo.itemFunctionalQuality)
            --GetRunesForItemIdIfKnown will return nil for all values if any of the runes are unknown
            --Therefore, checking any of them for nil would be sufficient, it doesn't have to be potency
            if potencyRune == nil then
                return GetString(SI_ENCHANTING_UNKNOWN_RUNES), GetString(SI_CRAFT_ADVISOR_UNKNOWN_RUNES_TOOLTIP)
            elseif not DoesPlayerHaveRunesForEnchanting(aspectRune, essenceRune, potencyRune) then
                return GetString(SI_CRAFTING_MISSING_ITEMS), GetString(SI_CRAFT_ADVISOR_ENCHANTING_MISSING_ITEMS_TOOLTIP)
            end
        elseif conditionInfo.craftingType == CRAFTING_TYPE_PROVISIONING then
            local recipeLists = PROVISIONER_MANAGER:GetRecipeListData(self.craftingInteractionType)
            --Look for a matching recipe
            for listIndex, recipeList in pairs(recipeLists) do
                for _, recipe in ipairs(recipeList.recipes) do
                    --If we have a match, then we're done, return early
                    if recipe.resultItemId == conditionInfo.itemId then
                        return
                    end
                end
            end

            --If we get here, that means we are missing the recipe
            return GetString(SI_PROVISIONER_MISSING_RECIPE), GetString(SI_CRAFT_ADVISOR_PROVISIONING_MISSING_RECIPE_TOOLTIP)
        elseif conditionInfo.craftingType == CRAFTING_TYPE_ALCHEMY then
            local validCombinationFound = false
            local needsThirdSlot = conditionInfo.isMasterWrit and GetNonCombatBonus(NON_COMBAT_BONUS_ALCHEMY_THIRD_SLOT) == 0

            --Check and see if the alchemy logic has found any valid combinations
            if IsInGamepadPreferredMode() then   
                validCombinationFound = GAMEPAD_ALCHEMY:HasValidCombinationForQuest()
            else
                validCombinationFound = ALCHEMY:HasValidCombinationForQuest()
            end

            if needsThirdSlot then
                return GetString(SI_ALCHEMY_REQUIRES_THIRD_SLOT), GetString(SI_CRAFT_ADVISOR_ALCHEMY_REQUIRES_THIRD_SLOT_TOOLTIP)
            elseif not validCombinationFound then
                return GetString(SI_ALCHEMY_MISSING_OR_UNKNOWN), GetString(SI_CRAFT_ADVISOR_ALCHEMY_MISSING_OR_UNKNOWN_TOOLTIP)
            end
        end
    end
end

function ZO_CraftAdvisorManager:UpdateQuestConditionInfo()
    local questInfo = self.questMasterList[self.selectedMasterListIndex]
    local craftingQuestIndices = 
    {
        patternIndices = {},
        materialIndex = nil,
        traitId = nil,
        styleId = nil,
        recipeItemIds = {},
        runeIds = {},
        alchemyInfo = {},
        improvementInfo = {},
    }

    if questInfo then
        --Determine the pattern and material information for each relevant condition
        for _, conditionInfo in ipairs(questInfo.conditionData) do
            if IsSmithingCraftingType(conditionInfo.craftingType) then
                local _, curCount, maxCount = GetJournalQuestConditionInfo(questInfo.questIndex, QUEST_MAIN_STEP_INDEX, conditionInfo.conditionIndex)

                --If this is a master writ, we need different information from normal ones
                if conditionInfo.isMasterWrit then
                    if curCount < maxCount then
                        local patternIndex, materialIndex, desiredItemId = GetSmithingPatternInfoForItemSet(conditionInfo.itemTemplateId, conditionInfo.itemSetId, conditionInfo.materialItemId, conditionInfo.itemTraitType)
                        if patternIndex and materialIndex then
                            craftingQuestIndices.patternIndices[patternIndex] = true
                            craftingQuestIndices.materialIndex = materialIndex
                            craftingQuestIndices.traitId = conditionInfo.itemTraitType
                            craftingQuestIndices.styleId = conditionInfo.itemStyleId
                            craftingQuestIndices.hasPatterns = true
                        end

                        if desiredItemId and conditionInfo.itemFunctionalQuality and conditionInfo.materialItemId and conditionInfo.itemTraitType and conditionInfo.itemStyleId then
                            craftingQuestIndices.improvementInfo =
                            {
                                desiredItemId = desiredItemId,
                                desiredQuality = conditionInfo.itemFunctionalQuality,
                                desiredMaterial = conditionInfo.materialItemId,
                                desiredTrait = conditionInfo.itemTraitType,
                                desiredStyle = conditionInfo.itemStyleId,
                            }
                            craftingQuestIndices.hasItemToImproveForWrit = HasItemToImproveForWrit(desiredItemId, conditionInfo.materialItemId, conditionInfo.itemTraitType, conditionInfo.itemStyleId, conditionInfo.itemFunctionalQuality)
                        end

                        if IsConsolidatedSmithingItemSetIdUnlocked(conditionInfo.itemSetId) then
                            craftingQuestIndices.consolidatedItemSetId = conditionInfo.itemSetId
                        end
                    end
                else
                    local patternIndex, materialIndex = GetSmithingPatternInfoForItemId(conditionInfo.itemId, conditionInfo.materialItemId, conditionInfo.craftingType)
                    if patternIndex and materialIndex and curCount < maxCount then
                        craftingQuestIndices.patternIndices[patternIndex] = true
                        craftingQuestIndices.materialIndex = materialIndex
                        craftingQuestIndices.hasPatterns = true
                    elseif curCount < maxCount then
                        craftingQuestIndices.smithingItemId = conditionInfo.itemId
                    end
                end
            elseif conditionInfo.craftingType == CRAFTING_TYPE_PROVISIONING then
                local _, curCount, maxCount = GetJournalQuestConditionInfo(questInfo.questIndex, QUEST_MAIN_STEP_INDEX, conditionInfo.conditionIndex)
                if curCount < maxCount then
                    craftingQuestIndices.recipeItemIds[conditionInfo.itemId] = true
                    craftingQuestIndices.hasRecipesForQuest = true
                end
            elseif conditionInfo.craftingType == CRAFTING_TYPE_ENCHANTING then
                local _, curCount, maxCount = GetJournalQuestConditionInfo(questInfo.questIndex, QUEST_MAIN_STEP_INDEX, conditionInfo.conditionIndex)
                local potencyRune, essenceRune, aspectRune = GetRunesForItemIdIfKnown(conditionInfo.itemId, conditionInfo.materialItemId, conditionInfo.itemFunctionalQuality)
                if potencyRune and essenceRune and aspectRune and curCount < maxCount then
                    craftingQuestIndices.runeIds = 
                    {
                        potency = potencyRune,
                        essence = essenceRune,
                        aspect = aspectRune
                    }
                else
                    craftingQuestIndices.runeIds = 
                    {
                        hasRequiredGlyph = curCount >= maxCount
                    }
                end
            elseif conditionInfo.craftingType == CRAFTING_TYPE_ALCHEMY then
                local _, curCount, maxCount = GetJournalQuestConditionInfo(questInfo.questIndex, QUEST_MAIN_STEP_INDEX, conditionInfo.conditionIndex)

                --If this is a master writ, we need different alchemy information than for normal writs
                if conditionInfo.isMasterWrit then
                    if conditionInfo.encodedAlchemyTraits and curCount < maxCount then
                        craftingQuestIndices.alchemyInfo =
                        {
                            basePotionItemId = conditionInfo.itemId,
                            materialItemId = conditionInfo.materialItemId,
                            encodedTraits = conditionInfo.encodedAlchemyTraits,
                            isMasterWrit = true
                        }
                    else
                        craftingQuestIndices.alchemyInfo =
                        {
                            hasDesiredPotion = curCount >= maxCount
                        }
                    end
                else
                    local desiredTraitId = GetTraitIdFromBasePotion(conditionInfo.itemId)
                    if desiredTraitId ~= 0 and curCount < maxCount then
                        craftingQuestIndices.alchemyInfo =
                        {
                            basePotionItemId = conditionInfo.itemId,
                            materialItemId = conditionInfo.materialItemId,
                            desiredTrait = desiredTraitId
                        }
                    else
                        craftingQuestIndices.alchemyInfo =
                        {
                            hasDesiredPotion = curCount >= maxCount
                        }
                    end
                end
            end
        end
    end

    --Send out the updated data necessary for the quest pins
    self:FireCallbacks("QuestInformationUpdated", craftingQuestIndices)
end

function ZO_CraftAdvisorManager:OnSelectionChanged(questIndex)
    for i, questInfo in ipairs(self.questMasterList) do
        --Locate the newly selected quest
        if questInfo.questIndex == questIndex then
            self.selectedMasterListIndex = i
            self:UpdateQuestConditionInfo()
            return
        end
    end
end

function ZO_CraftAdvisorManager:ShouldDeferRefresh()
    return self.craftingInteractionType == CRAFTING_TYPE_ALCHEMY
end

CRAFT_ADVISOR_MANAGER = ZO_CraftAdvisorManager:New()
