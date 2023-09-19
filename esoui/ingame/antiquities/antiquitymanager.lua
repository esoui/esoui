ZO_ANTIQUITY_UNKNOWN_ICON_TEXTURE = "EsoUI/Art/Icons/U26_Unknown_Antiquity_QuestionMark.dds"
ZO_DIGSITE_UNKNOWN_ICON_TEXTURE = "EsoUI/Art/Antiquities/digsite_unknown.dds"
ZO_DIGSITE_COMPLETE_ICON_TEXTURE = "EsoUI/Art/Antiquities/digsite_complete.dds"

ZO_LEAD_EXPIRATION_WARNING_DAYS = 7

ZO_ANTIQUITY_SECTION_TYPE =
{
    IN_PROGRESS = 1,
    AVAILABLE = 2,
    REQUIRES_LEAD = 3,
    ACTIVE_LEAD = 4,
    REQUIRES_SKILL = 5,
}

ZO_SCRYABLE_ANTIQUITY_CATEGORY_ID = 0
ZO_SCRYABLE_ANTIQUITY_CURRENT_ZONE_SUBCATEGORY_ID = -1
ZO_SCRYABLE_ANTIQUITY_ALL_LEADS_SUBCATEGORY_ID = -2

-- scryables category
local g_scryableAntiquityCategoryData = ZO_AntiquityFilterCategory:New(ZO_SCRYABLE_ANTIQUITY_CATEGORY_ID, GetString(SI_ANTIQUITY_SCRYABLE), 0)
g_scryableAntiquityCategoryData:SetGamepadIcon("EsoUI/Art/TreeIcons/gamepad/GP_antiquities_indexIcon_scryable.dds" )
g_scryableAntiquityCategoryData:SetKeyboardIcons("EsoUI/Art/TreeIcons/antiquities_indexIcon_scryable_UP.dds", "EsoUI/Art/TreeIcons/antiquities_indexIcon_scryable_DOWN.dds", "EsoUI/Art/TreeIcons/antiquities_indexIcon_scryable_OVER.dds")
ZO_SCRYABLE_ANTIQUITY_CATEGORY_DATA = g_scryableAntiquityCategoryData

-- current zone subcategory
local g_scryableAntiquityInCurrentZoneCategoryData = ZO_AntiquityFilterCategory:New(ZO_SCRYABLE_ANTIQUITY_CURRENT_ZONE_SUBCATEGORY_ID, GetString(SI_ANTIQUITY_SCRYABLE_CURRENT_ZONE_SUBCATEGORY), 0)
local function MatchAllScryableAntiquitiesInCurrentZone(antiquityData)
    return antiquityData:IsInCurrentPlayerZone() and (antiquityData:IsInProgress() or antiquityData:HasDiscovered() or antiquityData:IsScryable())
end
g_scryableAntiquityInCurrentZoneCategoryData:SetAntiquityFilterFunction(MatchAllScryableAntiquitiesInCurrentZone)
g_scryableAntiquityCategoryData:AddSubcategoryData(g_scryableAntiquityInCurrentZoneCategoryData)
ZO_SCRYABLE_ANTIQUITY_CURRENT_ZONE_SUBCATEGORY_DATA = g_scryableAntiquityInCurrentZoneCategoryData

-- all leads subcategory
local g_allLeadsAntiquityCategoryData = ZO_AntiquityFilterCategory:New(ZO_SCRYABLE_ANTIQUITY_ALL_LEADS_SUBCATEGORY_ID, GetString(SI_ANTIQUITY_SCRYABLE_ALL_LEADS_SUBCATEGORY), 1)
local function MatchAllAntiquitiesWithLeads(antiquityData)
    return antiquityData:IsInProgress() or antiquityData:MeetsLeadRequirements()
end
g_allLeadsAntiquityCategoryData:SetAntiquityFilterFunction(MatchAllAntiquitiesWithLeads)
g_scryableAntiquityCategoryData:AddSubcategoryData(g_allLeadsAntiquityCategoryData)
ZO_SCRYABLE_ANTIQUITY_ALL_LEADS_SUBCATEGORY_DATA = g_allLeadsAntiquityCategoryData

--
-- ZO_AntiquityManager
--

local ZO_AntiquityManager = ZO_CallbackObject:Subclass()

function ZO_AntiquityManager:New(...)
    local object = ZO_CallbackObject.New(self)
    object:Initialize(...)
    return object
end

function ZO_AntiquityManager:Initialize(...)
    local function OnContentLockChanged()
        self:FireCallbacks("OnContentLockChanged")
    end
    SKILLS_DATA_MANAGER:RegisterCallback("FullSystemUpdated", OnContentLockChanged)

    local function OnSkillLineUpdated(skillLineData)
        local skillLineId = skillLineData:GetId()
        local diggingSkillLineId = GetAntiquityDiggingSkillLineId()
        local scryingSkillLineId = GetAntiquityScryingSkillLineId()

        if skillLineId == diggingSkillLineId or skillLineId == scryingSkillLineId then
            OnContentLockChanged()
        end
    end
    SKILLS_DATA_MANAGER:RegisterCallback("SkillLineAdded", OnSkillLineUpdated)
    SKILLS_DATA_MANAGER:RegisterCallback("SkillLineRankUpdated", OnSkillLineUpdated)

    local antiquarianGuildZoneCollectibleId = self:GetAntiquarianGuildZoneCollectibleData():GetId()
    local scryingToolCollectibleId = self:GetScryingToolCollectibleData():GetId()

    local function OnCollectibleUpdated(collectibleId)
        if collectibleId == antiquarianGuildZoneCollectibleId or collectibleId == scryingToolCollectibleId then
            OnContentLockChanged()
        end
    end
    ZO_COLLECTIBLE_DATA_MANAGER:RegisterCallback("OnCollectibleUpdated", OnCollectibleUpdated)

    local function OnCollectionUpdated(updateType, updatedCollectiblesByState)
        for collectibleState, collectibles in pairs(updatedCollectiblesByState) do
            for _, collectible in ipairs(collectibles) do
                if collectible:GetId() == antiquarianGuildZoneCollectibleId or collectible:GetId() == scryingToolCollectibleId then
                    OnContentLockChanged()
                    return
                end
            end
        end
    end
    ZO_COLLECTIBLE_DATA_MANAGER:RegisterCallback("OnCollectionUpdated", OnCollectionUpdated)
end

function ZO_AntiquityManager:GetAntiquarianGuildZoneName()
    local antiquarianGuildZoneIndex = GetZoneIndex(WESTERN_SKYRIM_ZONE_ID)
    return GetZoneNameByIndex(antiquarianGuildZoneIndex)
end

function ZO_AntiquityManager:GetAntiquarianGuildZoneCollectibleData()
    local antiquarianGuildZoneIndex = GetZoneIndex(WESTERN_SKYRIM_ZONE_ID)
    local antiquarianGuildZoneCollectibleId = GetCollectibleIdForZone(antiquarianGuildZoneIndex)
    return ZO_COLLECTIBLE_DATA_MANAGER:GetCollectibleDataById(antiquarianGuildZoneCollectibleId)
end

function ZO_AntiquityManager:GetAntiquarianGuildZoneLockedMessage()
    local antiquarianGuildZoneCollectibleData = self:GetAntiquarianGuildZoneCollectibleData()
    if antiquarianGuildZoneCollectibleData then
        local antiquarianGuildZoneCollectibleName = antiquarianGuildZoneCollectibleData:GetName()
        local antiquarianGuildZoneCollectibleCategory = antiquarianGuildZoneCollectibleData:GetCategoryTypeDisplayName()
        local antiquarianGuildZoneName = ZO_SELECTED_TEXT:Colorize(self:GetAntiquarianGuildZoneName())
        return zo_strformat(SI_ANTIQUITY_GUILD_ZONE_LOCKED, antiquarianGuildZoneName, antiquarianGuildZoneCollectibleName, antiquarianGuildZoneCollectibleCategory)
    end
end

function ZO_AntiquityManager:GetScryingToolCollectibleData()
    local scryingToolCollectibleId = GetAntiquityScryingToolCollectibleId()
    return ZO_COLLECTIBLE_DATA_MANAGER:GetCollectibleDataById(scryingToolCollectibleId)
end

function ZO_AntiquityManager:GetScryingLockedMessage()
    local scryingSkillLineData = ZO_GetAntiquityScryingSkillLineData()
    if scryingSkillLineData then
        local antiquarianGuildCityName = ZO_SELECTED_TEXT:Colorize(GetString(SI_ANTIQUITY_GUILD_CITY_NAME))
        local antiquarianGuildZoneName = ZO_SELECTED_TEXT:Colorize(self:GetAntiquarianGuildZoneName())
        local scryingSkillLineName = ZO_SELECTED_TEXT:Colorize(scryingSkillLineData:GetFormattedName())

        if not ZO_IsScryingToolUnlocked() then
            local scryingToolCollectibleData = self:GetScryingToolCollectibleData()
            local scryingToolCollectibleName = scryingToolCollectibleData:GetName()
            local scryingToolCollectibleCategory = scryingToolCollectibleData:GetCategoryTypeDisplayName()
            return zo_strformat(SI_ANTIQUITY_SCRYING_TOOL_LOCKED, scryingToolCollectibleName, scryingToolCollectibleCategory, scryingSkillLineName, antiquarianGuildCityName, antiquarianGuildZoneName)
        end

        if not AreAntiquitySkillLinesDiscovered() then
            return zo_strformat(SI_ANTIQUITY_SCRYING_SKILL_LINE_MISSING, scryingSkillLineName, antiquarianGuildCityName, antiquarianGuildZoneName)
        end
    end
end

do
    local function ActiveLeadSectionSortComparison(leftAntiquityData, rightAntiquityData)
        local leftZoneName = GetZoneNameById(leftAntiquityData:GetZoneId())
        local rightZoneName = GetZoneNameById(rightAntiquityData:GetZoneId())
        if leftZoneName ~= rightZoneName then
            return leftZoneName < rightZoneName
        end

        local leftQuality = leftAntiquityData:GetQuality()
        local rightQuality = rightAntiquityData:GetQuality()
        if leftQuality ~= rightQuality then
            return leftQuality < rightQuality
        end

        return leftAntiquityData:CompareNameTo(rightAntiquityData)
    end

    function ZO_AntiquityManager:GetOrCreateAntiquitySectionList()
        if self.antiquitySectionData then
            for _, sectionData in ipairs(self.antiquitySectionData) do
                ZO_ClearNumericallyIndexedTable(sectionData.list)
            end
        else
            -- Note that the order of these sections matters: lower-indexed sections are prioritized above subsequent sections.
            self.antiquitySectionData =
            {
                {
                    sectionHeading = GetString(SI_ANTIQUITY_SUBHEADING_IN_PROGRESS),
                    filterFunctions = { ZO_Antiquity.IsInProgress },
                    sortFunction = ZO_DefaultAntiquitySortComparison,
                    sectionType = ZO_ANTIQUITY_SECTION_TYPE.IN_PROGRESS,
                    list = {}
                },
                {
                    sectionHeading = GetString(SI_ANTIQUITY_SUBHEADING_AVAILABLE),
                    filterFunctions = { ZO_Antiquity.MeetsAllScryingRequirements },
                    sortFunction = ZO_DefaultAntiquitySortComparison,
                    sectionType = ZO_ANTIQUITY_SECTION_TYPE.AVAILABLE,
                    list = {}
                },
                {
                    sectionHeading = GetString(SI_ANTIQUITY_SUBHEADING_REQUIRES_LEAD),
                    filterFunctions =
                    {
                        function(antiquityData)
                            return antiquityData:IsInCurrentPlayerZone() and antiquityData:HasDiscovered() and not antiquityData:MeetsLeadRequirements() and (antiquityData:IsRepeatable() or not antiquityData:HasRecovered())
                        end,
                    },
                    sortFunction = ZO_DefaultAntiquitySortComparison,
                    sectionType = ZO_ANTIQUITY_SECTION_TYPE.REQUIRES_LEAD,
                    list = {}
                },
                -- Note: This Active Leads section will catch most remaining antiquties, including those that would fall into the difficulty sections below
                {
                    sectionHeading = GetString(SI_ANTIQUITY_SUBHEADING_ACTIVE_LEADS),
                    filterFunctions =
                    {
                        function(antiquityData)
                            return antiquityData:HasDiscovered() or (antiquityData:MeetsLeadRequirements() and not antiquityData:HasAchievedAllGoals())
                        end,
                    },
                    sortFunction = ActiveLeadSectionSortComparison,
                    sectionType = ZO_ANTIQUITY_SECTION_TYPE.ACTIVE_LEAD,
                    list = {}
                },
            }

            for antiquityDifficulty = 1, ANTIQUITY_DIFFICULTY_MAX_VALUE do
                local skillName, requiredRank, maximumRank = ZO_GetAntiquityScryingPassiveSkillInfo(antiquityDifficulty)
                local antiquitySection =
                {
                    sectionHeading = zo_strformat(SI_ANTIQUITY_SUBHEADING_REQUIRES_SKILL, skillName, requiredRank, maximumRank),
                    filterFunctions =
                    {
                        function(antiquityData)
                            local isMatch = antiquityData:IsInCurrentPlayerZone() and antiquityData:HasDiscovered() and not antiquityData:MeetsScryingSkillRequirements()
                            return isMatch and antiquityData:GetDifficulty() == antiquityDifficulty
                        end,
                    },
                    sortFunction = ZO_DefaultAntiquitySortComparison,
                    sectionType = ZO_ANTIQUITY_SECTION_TYPE.REQUIRES_SKILL,
                    list = {}
                }
                table.insert(self.antiquitySectionData, antiquitySection)
            end
        end

        return self.antiquitySectionData
    end
end

function ZO_AntiquityManager:ShouldScryableSubcategoryShowSection(categoryData, antiquitySection)
    local categoryId = categoryData:GetId()
    return not (categoryId == ZO_SCRYABLE_ANTIQUITY_CURRENT_ZONE_SUBCATEGORY_ID and antiquitySection.sectionType == ZO_ANTIQUITY_SECTION_TYPE.ACTIVE_LEAD)
end

-- Global Helper Functions

function ZO_IsAntiquarianGuildUnlocked()
    local collectibleData = ANTIQUITY_MANAGER:GetAntiquarianGuildZoneCollectibleData()
    if collectibleData then
        return collectibleData:IsUnlocked()
    end
end

function ZO_IsScryingToolUnlocked()
    local collectibleData = ANTIQUITY_MANAGER:GetScryingToolCollectibleData()
    if collectibleData then
        return collectibleData:IsUnlocked()
    end
end

function ZO_IsScryingUnlocked()
    return AreAntiquitySkillLinesDiscovered() and ZO_IsScryingToolUnlocked() and ZO_IsAntiquarianGuildUnlocked()
end

function ZO_ShowAntiquityContentUpgrade()
    local antiquarianGuildZoneCollectibleData = ANTIQUITY_MANAGER:GetAntiquarianGuildZoneCollectibleData()
    local antiquarianGuildZoneCollectibleCategoryType = antiquarianGuildZoneCollectibleData:GetCategoryType()

    if antiquarianGuildZoneCollectibleCategoryType == COLLECTIBLE_CATEGORY_TYPE_CHAPTER then
        ZO_ShowChapterUpgradePlatformScreen(MARKET_OPEN_OPERATION_ANTIQUITY_JOURNAL)
    else
        local searchTerm = zo_strformat(SI_CROWN_STORE_SEARCH_FORMAT_STRING, antiquarianGuildZoneCollectibleData:GetName())
        ShowMarketAndSearch(searchTerm, MARKET_OPEN_OPERATION_ANTIQUITY_JOURNAL)
    end
end

function ZO_GetAntiquityDiggingSkillLineData()
    local diggingSkillLineId = GetAntiquityDiggingSkillLineId()
    return SKILLS_DATA_MANAGER:GetSkillLineDataById(diggingSkillLineId)
end

function ZO_GetAntiquityScryingSkillLineData()
    local scryingSkillLineId = GetAntiquityScryingSkillLineId()
    return SKILLS_DATA_MANAGER:GetSkillLineDataById(scryingSkillLineId)
end

function ZO_GetAntiquityScryingPassiveSkillInfo(passiveSkillRank)
    local scryingSkillLineId = GetAntiquityScryingSkillLineId()
    local skillLineData = SKILLS_DATA_MANAGER:GetSkillLineDataById(scryingSkillLineId)

    if skillLineData then
        local scryingPassiveSkillIndex = GetScryingPassiveSkillIndex(SCRYING_PASSIVE_SKILL_ANTIQUARIAN_INSIGHT)
        local skillData = skillLineData:GetSkillDataByIndex(scryingPassiveSkillIndex)

        if skillData then
            local skillRankData = skillData:GetRankData(passiveSkillRank)

            if skillRankData then
                return skillRankData:GetName(), passiveSkillRank, skillData:GetNumRanks()
            end
        end
    end

    internalassert(false, "Unable to get passive rank data.")
end

function ZO_LayoutAntiquityRewardTooltip_Keyboard(antiquityOrSetData, control, anchorPoint, anchorPointRelativeTo, anchorOffsetX, anchorOffsetY)
    if antiquityOrSetData:HasDiscovered() then
        ZO_Rewards_Shared_OnMouseEnter(control, anchorPoint, anchorPointRelativeTo, anchorOffsetX, anchorOffsetY)

        if antiquityOrSetData:GetType() == ZO_ANTIQUITY_TYPE_INDIVIDUAL then
            local zoneId = antiquityOrSetData:GetZoneId()
            local zoneName = GetZoneNameById(zoneId)
            local addedPadding = false

            if zoneName ~= "" then
                if not addedPadding then
                    ItemTooltip:AddVerticalPadding(18)
                    addedPadding = true
                end
                ItemTooltip:AddLine(ZO_NORMAL_TEXT:Colorize(zo_strformat(SI_ANTIQUITY_TOOLTIP_ZONE, ZO_SELECTED_TEXT:Colorize(zoneName))), "ZoFontGameMedium", ZO_NORMAL_TEXT:UnpackRGB())
            end

            local leadTimeRemainingS = antiquityOrSetData:GetLeadTimeRemainingS()
            if leadTimeRemainingS > 0 then
                if not addedPadding then
                    ItemTooltip:AddVerticalPadding(18)
                    addedPadding = true
                end
                local leadTimeRemainingText = ZO_FormatAntiquityLeadTime(leadTimeRemainingS)
                ItemTooltip:AddLine(ZO_NORMAL_TEXT:Colorize(zo_strformat(SI_ANTIQUITY_TOOLTIP_LEAD_EXPIRATION, leadTimeRemainingText)), "ZoFontGameMedium", ZO_SELECTED_TEXT:UnpackRGB())
            end
        end
    end
end

function ZO_IsAntiquityScryableCategory(categoryData)
    local categoryId = categoryData:GetId()
    return categoryId == ZO_SCRYABLE_ANTIQUITY_CATEGORY_ID
end

function ZO_IsAntiquityScryableSubcategory(categoryData)
    local parentCategory = categoryData:GetParentCategoryData()
    if parentCategory then
        return ZO_IsAntiquityScryableCategory(parentCategory)
    end

    return false
end

function ZO_FormatAntiquityLeadTime(leadTimeRemainingS)
    local textColor
    if (leadTimeRemainingS / ZO_ONE_DAY_IN_SECONDS) <= ZO_LEAD_EXPIRATION_WARNING_DAYS then
        textColor = ZO_ERROR_COLOR
    else
        textColor = ZO_SELECTED_TEXT
    end

    return textColor:Colorize(ZO_FormatTimeLargestTwo(leadTimeRemainingS, TIME_FORMAT_STYLE_DESCRIPTIVE_MINIMAL_HIDE_ZEROES))
end

ANTIQUITY_MANAGER = ZO_AntiquityManager:New()
