ZO_ANTIQUITY_UNKNOWN_ICON_TEXTURE = "EsoUI/Art/Icons/U26_Unknown_Antiquity_QuestionMark.dds"
ZO_DIGSITE_UNKNOWN_ICON_TEXTURE = "EsoUI/Art/Antiquities/digsite_unknown.dds"
ZO_DIGSITE_COMPLETE_ICON_TEXTURE = "EsoUI/Art/Antiquities/digsite_complete.dds"

ZO_LEAD_EXPIRATION_WARNING_DAYS = 7
ZO_SCRYABLE_ANTIQUITY_CATEGORY_ID = 0
local g_scryableAntiquityCategoryData = ZO_AntiquityCategory:New(ZO_SCRYABLE_ANTIQUITY_CATEGORY_ID)
ZO_SCRYABLE_ANTIQUITY_CATEGORY_DATA = g_scryableAntiquityCategoryData
g_scryableAntiquityCategoryData.GetName = function() return GetString(SI_ANTIQUITY_SCRYABLE) end
g_scryableAntiquityCategoryData.GetGamepadIcon = function() return "EsoUI/Art/TreeIcons/gamepad/GP_antiquities_indexIcon_scryable.dds" end
g_scryableAntiquityCategoryData.GetKeyboardIcons = function() return "EsoUI/Art/TreeIcons/antiquities_indexIcon_scryable_UP.dds", "EsoUI/Art/TreeIcons/antiquities_indexIcon_scryable_DOWN.dds", "EsoUI/Art/TreeIcons/antiquities_indexIcon_scryable_OVER.dds" end

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

    local function OnSkillsUpdated()
        OnContentLockChanged()
    end
    SKILLS_DATA_MANAGER:RegisterCallback("FullSystemUpdated", OnSkillsUpdated)
    SKILLS_DATA_MANAGER:RegisterCallback("SkillLineAdded", OnSkillsUpdated)
    SKILLS_DATA_MANAGER:RegisterCallback("SkillLineUpdated", OnSkillsUpdated)

    EVENT_MANAGER:RegisterForEvent("ZO_AntiquityManager", EVENT_ANTIQUITY_JOURNAL_SHOW_SCRYABLE, ZO_ShowAntiquityScryables)
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
    local antiquarianGuildZoneCollectibleName = antiquarianGuildZoneCollectibleData:GetName()
    local antiquarianGuildZoneCollectibleCategory = antiquarianGuildZoneCollectibleData:GetCategoryTypeDisplayName()
    local antiquarianGuildZoneName = ZO_SELECTED_TEXT:Colorize(self:GetAntiquarianGuildZoneName())
    return zo_strformat(SI_ANTIQUITY_GUILD_ZONE_LOCKED, antiquarianGuildZoneName, antiquarianGuildZoneCollectibleName, antiquarianGuildZoneCollectibleCategory)
end

function ZO_AntiquityManager:GetScryingToolCollectibleData()
    local scryingToolCollectibleId = GetAntiquityScryingToolCollectibleId()
    return ZO_COLLECTIBLE_DATA_MANAGER:GetCollectibleDataById(scryingToolCollectibleId)
end

function ZO_AntiquityManager:GetScryingLockedMessage()
    local antiquarianGuildCityName = ZO_SELECTED_TEXT:Colorize(GetString(SI_ANTIQUITY_GUILD_CITY_NAME))
    local antiquarianGuildZoneName = ZO_SELECTED_TEXT:Colorize(self:GetAntiquarianGuildZoneName())
    local scryingSkillLineData = ZO_GetAntiquityScryingSkillLineData()
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
        ZO_ShowChapterUpgradePlatformScreen(MARKET_OPEN_OPERATION_ZONE_STORIES)
    else
        local searchTerm = zo_strformat(SI_CROWN_STORE_SEARCH_FORMAT_STRING, antiquarianGuildZoneCollectibleData:GetName())
        ShowMarketAndSearch(searchTerm, MARKET_OPEN_OPERATION_ZONE_STORIES)
    end
end

function ZO_ShowAntiquityScryables()
    SCENE_MANAGER:HideCurrentScene()
    if IsInGamepadPreferredMode() then
        SCENE_MANAGER:CreateStackFromScratch("mainMenuGamepad", "gamepad_antiquity_journal")
        ANTIQUITY_JOURNAL_GAMEPAD:ShowScryable()
    else
        MAIN_MENU_KEYBOARD:ShowSceneGroup("journalSceneGroup", "antiquityJournalKeyboard")
        ANTIQUITY_JOURNAL_KEYBOARD:ShowScryable()
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
                ItemTooltip:AddLine(ZO_NORMAL_TEXT:Colorize(zo_strformat(SI_ANTIQUITY_TOOLTIP_ZONE, ZO_SELECTED_TEXT:Colorize(zoneName))), "ZoFontGameMedium", ZO_SELECTED_TEXT:UnpackRGB())
            end

            local nearExpiration, timeRemaining = antiquityOrSetData:GetLeadExpirationStatus()
            if nearExpiration then
                if not addedPadding then
                    ItemTooltip:AddVerticalPadding(18)
                    addedPadding = true
                end
                ItemTooltip:AddLine(ZO_NORMAL_TEXT:Colorize(zo_strformat(SI_ANTIQUITY_TOOLTIP_LEAD_EXPIRATION, ZO_SELECTED_TEXT:Colorize(timeRemaining))), "ZoFontGameMedium", ZO_SELECTED_TEXT:UnpackRGB())
            end
        end
    end
end

ANTIQUITY_MANAGER = ZO_AntiquityManager:New()
