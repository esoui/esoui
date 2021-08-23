-----------------------------
-- Companion Manager
-----------------------------
ZO_Companion_Manager = ZO_InitializingCallbackObject:Subclass()

function ZO_Companion_Manager:Initialize()
    self.companionInteraction =
    {
        type = "Companion",
        interactTypes = { INTERACTION_COMPANION_MENU },
    }

    -- Shared search for companion equipment
    local filterTargetDescriptor =
    {
        [BACKGROUND_LIST_FILTER_TARGET_BAG_SLOT] =
        {
            searchFilterList =
            {
                BACKGROUND_LIST_FILTER_TYPE_NAME,
            },
            primaryKeys =
            {
                BAG_BACKPACK,
                BAG_COMPANION_WORN,
            }
        },
    }
    TEXT_SEARCH_MANAGER:SetupContextTextSearch("companionEquipmentTextSearch", filterTargetDescriptor)
end

function ZO_Companion_Manager:GetInteraction()
    return self.companionInteraction
end

function ZO_Companion_Manager:GetLevelInfo()

    --The companion's current level and the amount of experience the companion has earned at that level
    local level, currentXpInLevel = GetActiveCompanionLevelInfo()

    --The total amount of experience required to go from the current level to the next
    local totalXpInLevel = GetNumExperiencePointsInCompanionLevel(level + 1) or 0

    local isMaxLevel = totalXpInLevel == 0

    return level, currentXpInLevel, totalXpInLevel, isMaxLevel
end

function ZO_Companion_Manager:GetActiveCompanionIcon()
    local companionId = GetActiveCompanionDefId()
    local collectibleId = GetCompanionCollectibleId(companionId)

    return GetCollectibleIcon(collectibleId)
end

function ZO_Companion_Manager:GetActiveCompanionPassivePerkAbilityId()
    local companionId = GetActiveCompanionDefId()
    return GetCompanionPassivePerkAbilityId(companionId)
end

ZO_COMPANION_MANAGER = ZO_Companion_Manager:New()

function ZO_HasActiveOrBlockedCompanion()
    return HasActiveCompanion() or HasBlockedCompanion()
end