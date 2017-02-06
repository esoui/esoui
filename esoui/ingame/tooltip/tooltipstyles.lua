--Styles

local GENERAL_COLOR_WHITE = GAMEPAD_TOOLTIP_COLOR_GENERAL_COLOR_1
local GENERAL_COLOR_GREY = GAMEPAD_TOOLTIP_COLOR_GENERAL_COLOR_2
local GENERAL_COLOR_OFF_WHITE = GAMEPAD_TOOLTIP_COLOR_GENERAL_COLOR_3
local GENERAL_COLOR_RED = GAMEPAD_TOOLTIP_COLOR_FAILED

ZO_TOOLTIP_STYLES =
{
    --General

    tooltip =
    {
        width = ZO_GAMEPAD_CONTENT_WIDTH,
        paddingLeft = 0,
        paddingRight = 0,
        fontFace = "$(GAMEPAD_MEDIUM_FONT)",
        fontColorType = INTERFACE_COLOR_TYPE_GAMEPAD_TOOLTIP,
        fontColorField = GENERAL_COLOR_GREY,
        fontStyle = "soft-shadow-thick",
    },
    title =
    {
        fontSize = "$(GP_42)",
        customSpacing = 8,
        uppercase = true,
        fontColorField = GENERAL_COLOR_WHITE,
        widthPercent = 100,
    },
    statValuePair =
    {
        height = 40,
    },
    statValuePairStat =
    {
        fontSize = "$(GP_27)",
        uppercase = true,
        fontColorField = GENERAL_COLOR_OFF_WHITE,
    },
    statValuePairValue =
    {
        fontSize = "$(GP_42)",
        fontColorField = GENERAL_COLOR_WHITE,
    },
    statValuePairMagickaValue =
    {
        fontSize = "$(GP_42)",
        fontColorType = INTERFACE_COLOR_TYPE_POWER,
        fontColorField = POWERTYPE_MAGICKA,
    },
    statValuePairStaminaValue =
    {
        fontSize = "$(GP_42)",
        fontColorType = INTERFACE_COLOR_TYPE_POWER,
        fontColorField = POWERTYPE_STAMINA,
    },
    championRequirements =
    {
        fontSize = "$(GP_42)",
        fontColorField = GENERAL_COLOR_WHITE,
    },
    fullWidth =
    {
        widthPercent = 100
    },
    statValueSlider =
    {
        fontColorField = GENERAL_COLOR_WHITE,
        gradientColors = ZO_XP_BAR_GRADIENT_COLORS,
    },
    statValueSliderStat =
    {
        fontSize = "$(GP_27)",
        fontColorType = INTERFACE_COLOR_TYPE_TEXT_COLORS,
        fontColorField = INTERFACE_TEXT_COLOR_NORMAL,
    },
    statValueSliderValue =
    {
        fontSize = "$(GP_27)",
        fontColorField = GENERAL_COLOR_WHITE,
        gradientColors = ZO_XP_BAR_GRADIENT_COLORS,
    },
    succeeded =
    {
        fontColorField = GAMEPAD_TOOLTIP_COLOR_SUCCEEDED,
    },
    failed =
    {
        fontColorField = GAMEPAD_TOOLTIP_COLOR_FAILED,
    },
    bodySection =
    {
        customSpacing = 30,
        childSpacing = 10,
        widthPercent = 100,
        fontColorField = GENERAL_COLOR_OFF_WHITE,
        fontFace = "$(GAMEPAD_LIGHT_FONT)",
    },
    bodyHeader =
    {
        fontFace = "$(GAMEPAD_MEDIUM_FONT)",
        fontSize = "$(GP_27)",
        uppercase = true,
        fontColorField = GENERAL_COLOR_WHITE,
    },
    itemTagsSection =
    {
        customSpacing = 40,
        widthPercent = 100,
        fontFace = "$(GAMEPAD_LIGHT_FONT)",
    },
    itemTradeBoPSection =
    {
        customSpacing = 80,
        widthPercent = 100,
        fontFace = "$(GAMEPAD_LIGHT_FONT)",
    },

    itemTradeBoPHeader =
    {
        fontColor = ZO_TRADE_BOP_COLOR,
    },

    bodyDescription =
    {
        fontSize = "$(GP_42)",
    },
    enchantIrreplaceable =
    {
        fontSize = "$(GP_34)",
    },

    --Character Attribute Tooltip

    attributeBody =
    {   
        customSpacing = 30,
        widthPercent = 100,
        fontColorField = GENERAL_COLOR_OFF_WHITE,
        fontFace = "$(GAMEPAD_LIGHT_FONT)",
        fontSize = "$(GP_42)",
    },
    equipmentBonusValue =
    {
        fontColorField = GENERAL_COLOR_WHITE,
    },
    equipmentBonusLowestPieceHeader =
    {
        uppercase = true,
        fontSize = "$(GP_27)",
    },
    equipmentBonusLowestPieceValue =
    {
        customSpacing = 0,
    },

    --Item Tooltip

    baseStatsSection =
    {
        layoutPrimaryDirection = "right",
        layoutSecondaryDirection = "down",
        statValuePairSpacing = 3,
        childSpacing = 10,
        childSecondarySpacing = 3,
        widthPercent = 100,
    },
    valueStatsSection =
    {
        layoutPrimaryDirection = "right",
        layoutSecondaryDirection = "down",
        paddingTop = 30,
        widthPercent = 100,
    },
    conditionOrChargeBarSection =
    {
        layoutPrimaryDirection = "right",
        layoutSecondaryDirection = "down",
        statValuePairSpacing = 6,
        childSpacing = 10,
        customSpacing = 10,
        childSecondarySpacing = 3,
        widthPercent = 100,
    },
    conditionOrChargeBar =
    {
        statusBarTemplate = "ZO_GamepadArrowStatusBarWithBGMedium",
        statusBarTemplateOverrideName = "ArrowBar",
        widthPercent = 80,
        statusBarGradientColors = ZO_XP_BAR_GRADIENT_COLORS,
    },
    itemImprovementConditionOrChargeBar =
    {
        statusBarTemplate = "ZO_ItemImproveBar_Gamepad",
        statusBarTemplateOverrideName = "ImproveBar",
        widthPercent = 80,
        statusBarGradientColors = ZO_XP_BAR_GRADIENT_COLORS,
    },
    ridingTrainingChargeBar =
    {
        statusBarTemplate = "ZO_StableTrainingBar_Gamepad",
        statusBarTemplateOverrideName = "TrainBar",
        customSpacing = 4,
        widthPercent = 80,
        statusBarGradientColors = ZO_XP_BAR_GRADIENT_COLORS,
    },
    enchantDiff = 
    {
        customSpacing = 30,
        childSpacing = 10,
        widthPercent = 100,
    },
    enchantDiffAdd = 
    {
        fontColorField = GAMEPAD_TOOLTIP_COLOR_ABILITY_UPGRADE,
    },
    enchantDiffRemove = 
    {
        fontColorField = GAMEPAD_TOOLTIP_COLOR_FAILED,
    },
     enchantDiffTextureContainer = 
    {
        layoutPrimaryDirection = "right",
        layoutSecondaryDirection = "down",
        paddingLeft = -35,
        paddingTop = 3,
        paddingRight = 3,
        paddingBottom = -49,
    },
    enchantDiffTexture = 
    {
        width = 32,
        height = 32
    },
    topSection =
    {
        layoutPrimaryDirection = "up",
        layoutSecondaryDirection = "right",
        widthPercent = 100,
        childSpacing = 1,
        fontSize = "$(GP_27)",
        height = 92,
        uppercase = true,
        fontColorField = GENERAL_COLOR_OFF_WHITE,
    },    
    topSubsection = 
    {
        layoutPrimaryDirection = "right",
        layoutSecondaryDirection = "up",
        widthPercent = 100,
        childSpacing = 8,
        fontSize = "$(GP_27)",
        height = 32,
    },
    collectionsTopSection =
    {
        customSpacing = 7,
        layoutPrimaryDirection = "right",
        layoutSecondaryDirection = "up",
        widthPercent = 100,
        childSpacing = 7,
        fontSize = "$(GP_27)",
        height = 67,
        uppercase = true,
        fontColorField = GENERAL_COLOR_OFF_WHITE,
    },
    topSubsectionItemDetails =
    {
        layoutPrimaryDirection = "right",
        layoutSecondaryDirection = "up",
        widthPercent = 100,
        childSpacing = 15,
        customSpacing = -4,
        fontSize = "$(GP_27)",
        height = 32,
        fontColorField = GENERAL_COLOR_WHITE,
    },
    flavorText =
    {
        fontSize = "$(GP_42)",
    },
    inactiveBonus =
    {
        fontColorField = GAMEPAD_TOOLTIP_COLOR_INACTIVE,
    },
    activeBonus =
    {
        fontColorField = GENERAL_COLOR_OFF_WHITE,
    },
    degradedStat =
    {
        fontColorField = GAMEPAD_TOOLTIP_COLOR_FAILED,
    },
    qualityTrash =
    {
        fontColorType = INTERFACE_COLOR_TYPE_ITEM_QUALITY_COLORS,
        fontColorField = ITEM_QUALITY_TRASH,
    },
    qualityNormal =
    {
        fontColorType = INTERFACE_COLOR_TYPE_ITEM_QUALITY_COLORS,
        fontColorField = ITEM_QUALITY_NORMAL,
    },
    qualityMagic =
    {
        fontColorType = INTERFACE_COLOR_TYPE_ITEM_QUALITY_COLORS,
        fontColorField = ITEM_QUALITY_MAGIC,
    },
    qualityArcane =
    {
        fontColorType = INTERFACE_COLOR_TYPE_ITEM_QUALITY_COLORS,
        fontColorField = ITEM_QUALITY_ARCANE,
    },
    qualityArtifact =
    {
        fontColorType = INTERFACE_COLOR_TYPE_ITEM_QUALITY_COLORS,
        fontColorField = ITEM_QUALITY_ARTIFACT,
    },
    qualityLegendary =
    {
        fontColorType = INTERFACE_COLOR_TYPE_ITEM_QUALITY_COLORS,
        fontColorField = ITEM_QUALITY_LEGENDARY,
    },
    bind = 
    {
        fontColorField = GENERAL_COLOR_OFF_WHITE,
    },
    stolen = 
    {
        fontColorField = GENERAL_COLOR_RED,
    },
    bagCountSection =
    {
        layoutPrimaryDirection = "down",
        layoutSecondaryDirection = "right",
        customSpacing = 30,
        widthPercent = 100,
        fontColorField = GENERAL_COLOR_OFF_WHITE,
        fontFace = "$(GAMEPAD_LIGHT_FONT)",
        fontSize = "$(GP_34)",
    },
    itemTagTitle =
    {
        fontColorField = GENERAL_COLOR_OFF_WHITE,
        fontSize = "$(GP_34)",
        uppercase = true,
    },
    itemTagDescription =
    {
        fontColorField = GENERAL_COLOR_WHITE,
        fontSize = "$(GP_42)",
    },

    --Gamepad Stable Tooltip
    stableGamepadTooltip = {
        width = 352,
        customSpacing = 50,
        fontFace = "$(GAMEPAD_MEDIUM_FONT)",
        fontColorType = INTERFACE_COLOR_TYPE_GAMEPAD_TOOLTIP,
        fontColorField = GENERAL_COLOR_GREY,
        fontStyle = "soft-shadow-thick",
    },

    stableGamepadFlavor = {
        customSpacing = 30,
        fontSize = "$(GP_34)",
    },

    stableGamepadTitle =
    {
        fontSize = "$(GP_42)",
        customSpacing = 8,
        fontColorField = GENERAL_COLOR_WHITE,
        uppercase = false,
    },

    stableGamepadStats =
    {
        statValuePairSpacing = 6,
        childSpacing = 3,
        customSpacing = 40,
    },
    suppressedAbility =
    {
        fontColorField = GAMEPAD_TOOLTIP_COLOR_INACTIVE,
    },
    poisonCountSection =
    {
        layoutPrimaryDirection = "left",
        layoutSecondaryDirection = "down",
    },
    poisonCount =
    {
        fontSize = "$(GP_42)",
        fontColorField = GENERAL_COLOR_WHITE,
    },
    equippedPoisonSection =
    {
        customSpacing = 20,
        paddingBottom = -20,
    },

    --Ability Tooltip

    abilityStatsSection =
    {
        statValuePairSpacing = 10,
        childSpacing = 3,
        customSpacing = 20,
    },
    abilityUpgradeSection =
    {
        customSpacing = 7,
        childSpacing = 10,
        widthPercent = 100,
        fontFace = "$(GAMEPAD_MEDIUM_FONT)",
        layoutPrimaryDirection = "right",
        layoutSecondaryDirection = "up",
        height = 64,
    },
    abilityUpgrade =
    {
        fontColorField = GAMEPAD_TOOLTIP_COLOR_ABILITY_UPGRADE,
        uppercase = true,
        fontSize = "$(GP_27)",
        widthPercent = 100,
    },
    newEffectTitle =
    {
        fontColorField = GAMEPAD_TOOLTIP_COLOR_ABILITY_UPGRADE,
        uppercase = true,
        fontSize = "$(GP_27)",
        widthPercent = 100,
    },
    newEffectBody =
    {
        fontColorField = GAMEPAD_TOOLTIP_COLOR_ABILITY_UPGRADE,
        fontSize = "$(GP_42)",
        widthPercent = 100,
    },
    abilityProgressBar =
    {
        statusBarTemplate = "ZO_GamepadArrowStatusBarWithBGMedium",
        statusBarTemplateOverrideName = "ArrowBar",
        customSpacing = 10,
        widthPercent = 80,
        statusBarGradientColors = ZO_XP_BAR_GRADIENT_COLORS,
    },
    hasIngredient =
    {
        fontColorField = GAMEPAD_TOOLTIP_COLOR_ACTIVE,
    },
    doesntHaveIngredient =
    {
        fontColorField = GAMEPAD_TOOLTIP_COLOR_INACTIVE,
    },
    traitKnown =
    {
        fontColorField = GAMEPAD_TOOLTIP_COLOR_ACTIVE,
    },
    traitUnknown =
    {
        fontColorField = GAMEPAD_TOOLTIP_COLOR_INACTIVE,
    },
    -- WorldMap Tooltips
    worldMapTooltip =
    {
        width = 375,
        paddingTop = 32,
        childSpacing = 10,
        fontFace = "$(GAMEPAD_MEDIUM_FONT)",
        fontSize = "$(GP_27)",
        fontColorType = INTERFACE_COLOR_TYPE_GAMEPAD_TOOLTIP,
        fontColorField = GENERAL_COLOR_GREY,
        fontStyle = "soft-shadow-thick",
    },

    mapTitle =
    {
        width = 327,
        fontFace = "$(GAMEPAD_BOLD_FONT)",
        fontSize = "$(GP_34)",
        uppercase = true,
        fontColorField = GENERAL_COLOR_OFF_WHITE,
    },
    
    mapIconTitle =
    {
        width = 310,
    },

    mapQuestTitle =
    {
        fontFace = "$(GAMEPAD_BOLD_FONT)",
        fontSize = "$(GP_34)",
    },

    -- Map Location Styles
    mapLocationTooltipSection =
    {
        -- The first entry of the location block should be closer to the header than
        --  the entries should be relative to each other.
        paddingTop = -10,
        widthPercent = 100,
    },
    mapKeepCategorySpacing =
    {
        paddingTop = 20,
        paddingBottom = 20,
        widthPercent = 100,
    },
    mapLocationTooltipContentHeader =
    {
        fontFace = "$(GAMEPAD_MEDIUM_FONT)",
        fontSize = "$(GP_27)",
        fontColorField = GENERAL_COLOR_OFF_WHITE,
        uppercase = true,
    },
    mapLocationTooltipWayshrineHeader =
    {
        fontFace = "$(GAMEPAD_BOLD_FONT)",
        fontSize = "$(GP_34)",
        fontColorField = GENERAL_COLOR_WHITE,
        uppercase = true,
        widthPercent = 85,
    },
    mapLocationTooltipWayshrineLinkedCollectibleLockedText =
    {
        fontSize = "$(GP_34)",
        fontColorType = INTERFACE_COLOR_TYPE_MARKET_COLORS,
        fontColorField = MARKET_COLORS_ON_SALE,
        widthPercent = 85,
    },
    mapLocationTooltipContentSection =
    {
        layoutPrimaryDirection = "right",
        layoutSecondaryDirection = "down",
        childSpacing = 20,
        widthPercent = 100,
    },
    mapLocationTooltipContentLabel =
    {
        widthPercent = 80,
    },
    mapLocationTooltipDoubleContentSection =
    {
        layoutPrimaryDirection = "right",
        layoutSecondaryDirection = "up",
        childSpacing = 20,
    },
    mapLocationTooltipContentLeftLabel =
    {
        width = 0,
    },
    mapLocationTooltipContentRightLabel =
    {
        horizontalAlignment = TEXT_ALIGN_LEFT,
        widthPercent = 60,
    },
    mapLocationHeaderTextSection =
    {
        layoutPrimaryDirection = "down",
        layoutSecondaryDirection = "right",
        layoutPrimaryDirectionCentered = true,
        dimensionConstraints = {
            minHeight = 40,
        },
    },
    mapLocationTooltipContentTitle =
    {
        fontSize = "$(GP_34)",
        fontColorField = GENERAL_COLOR_WHITE,
    },
    mapLocationTooltipNameSection =
    {
        paddingLeft = 60,
        widthPercent = 100,
    },
    mapLocationTooltipContentName =
    {
        fontSize = "$(GP_34)",
        fontColorField = GENERAL_COLOR_OFF_WHITE,
    },
    mapRecallCost =
    {
        fontSize = "$(GP_27)",
        fontColorField = GENERAL_COLOR_OFF_WHITE,
        uppercase = true,
    },
    mapKeepGroupSection =
    {
        paddingTop = 15,
        childSpacing = 4,
        widthPercent = 100,
    },
    mapKeepSection =
    {
        paddingTop = -30,
        widthPercent = 100,
    },
    mapLocationSection =
    {
        paddingTop = -30,
        childSpacing = 20,
        widthPercent = 100,
    },
    mapGroupsSection =
    {
        childSpacing = 10,
        widthPercent = 100,
    },
    mapLocationGroupSection =
    {
        childSpacing = 10,
        widthPercent = 100,
    },
    mapLocationEntrySection =
    {
        childSpacing = -5,
        widthPercent = 100,
    },
    mapKeepUnderAttack =
    {
        fontFace = "$(GAMEPAD_BOLD_FONT)",
        fontSize = "$(GP_22)",
        fontColorField = GENERAL_COLOR_RED,
        uppercase = true,
    },
    mapQuestFocused =
    {
        color = ZO_ColorDef:New(GetInterfaceColor(INTERFACE_COLOR_TYPE_GAMEPAD_TOOLTIP, GENERAL_COLOR_WHITE)),
        fontColorField = GENERAL_COLOR_WHITE,
    },
    mapQuestNonFocused =
    {
        color = ZO_ColorDef:New(GetInterfaceColor(INTERFACE_COLOR_TYPE_GAMEPAD_TOOLTIP, GENERAL_COLOR_OFF_WHITE)),
        fontColorField = GENERAL_COLOR_OFF_WHITE,
    },
    mapLocationKeepClaimed =
    {
        fontSize = "$(GP_34)",
        fontColorField = GENERAL_COLOR_WHITE,
    },
    mapLocationKeepElderScrollInfo =
    {
        fontSize = "$(GP_34)",
        fontColorField = GENERAL_COLOR_OFF_WHITE,
    },
    mapLocationKeepUnclaimed =
    {
        fontSize = "$(GP_34)",
        fontColorField = GENERAL_COLOR_GREY,
    },
    mapKeepAccessible = 
    {
        fontColorType = INTERFACE_COLOR_TYPE_KEEP_TOOLTIP,
        fontColorField = KEEP_TOOLTIP_COLOR_ACCESSIBLE,
        width = 305,
    },
    mapKeepInaccessible = 
    {
        fontColorType = INTERFACE_COLOR_TYPE_KEEP_TOOLTIP,
        fontColorField = KEEP_TOOLTIP_COLOR_NOT_ACCESSIBLE,
    },
    mapKeepAt = 
    {
        fontColorType = INTERFACE_COLOR_TYPE_KEEP_TOOLTIP,
        fontColorField = KEEP_TOOLTIP_COLOR_AT_KEEP,
    },
    mapLocationTooltipNoIcon =
    {
        width = 40,
        height = 1,
        color = ZO_ColorDef:New(0, 0, 0, 0),
    },
    mapLocationTooltipIcon =
    {
        width = 40,
        height = 40,
    },
    mapLocationTooltipLargeIcon =
    {
        width = 40,
        height = 40,
        textureCoordinateLeft = 0.2,
        textureCoordinateRight = 0.8,
        textureCoordinateTop = 0.2,
        textureCoordinateBottom = 0.8,
    },
    mapArtifactNormal =
    {
        color = ZO_ColorDef:New(1, 1, 1),
    },
    mapArtifactStolen =
    {
        color = ZO_ColorDef:New(1, 0, 0),
        fontColorField = GENERAL_COLOR_RED,
    },
    keepBaseTooltipContent =
    {
        fontSize = "$(GP_34)",
        fontColorField = GENERAL_COLOR_WHITE,
        width = 305,
    },
    keepUpgradeTooltipContent =
    {
        fontSize = "$(GP_42)",
        fontColorField = GENERAL_COLOR_OFF_WHITE,
        widthPercent = 100,
    },
    gamepadElderScrollTooltipContent =
    {
        fontSize = "$(GP_27)",
        fontColorField = GENERAL_COLOR_OFF_WHITE,
        widthPercent = 100,
        uppercase = true,
    },
    mapUnitName =
    {
        fontSize = "$(GP_34)",
        fontColorType = INTERFACE_COLOR_TYPE_NAME_PLATE,
        fontColorField = UNIT_NAMEPLATE_ALLY_PLAYER,
    },
    mapMoreQuestsContentSection =
    {
        layoutPrimaryDirection = "right",
        layoutSecondaryDirection = "down",
        widthPercent = 100,
        paddingTop = 20,
    },

    -- Achievement Tooltip
    achievementSubtitleText =
    {
        fontSize = "$(GP_30)",
        uppercase = true,
        fontColorField = GENERAL_COLOR_WHITE,
    },

    achievementTextSection =
    {
        widthPercent = 100,
        uppercase = true,
        layoutPrimaryDirection = "down",
        layoutSecondaryDirection = "right",
    },
    
    achievementPointsSection =
    {
        fontSize = "$(GP_27)",
        childSpacing = 10,
        fontColorField = GAMEPAD_TOOLTIP_COLOR_GENERAL_COLOR_3,
        layoutPrimaryDirection = "right",
        layoutSecondaryDirection = "up",
    },

    achievementRewardsEntrySection =
    {
        widthPercent = 100,
        fontSize = "$(GP_30)",
        childSpacing = 10,
        layoutPrimaryDirection = "right",
        layoutSecondaryDirection = "down",
    },
    
    achievementRewardsSection =
    {
        widthPercent = 100,
        paddingTop = 30,
        uppercase = true,
        childSpacing = 25,
        layoutPrimaryDirection = "down",
        layoutSecondaryDirection = "right",
    },

    achievementRewardsTitle =
    {
        widthPercent = 100,
        fontColorField = GAMEPAD_TOOLTIP_COLOR_GENERAL_COLOR_3,
    },
    
    achievementRewardsName =
    {
        widthPercent = 100,
        fontSize = "$(GP_34)",
        uppercase = true,
        fontColorField = GENERAL_COLOR_WHITE,
    },

    achievementSummaryCategorySection =
    {
        paddingBottom = 20,
        uppercase = true,
        layoutPrimaryDirection = "down",
        layoutSecondaryDirection = "right",
    },

    achievementCriteriaSection =
    {
        paddingTop = 30,
        paddingBottom = 15,
        childSpacing = 15,
        uppercase = true,
        layoutPrimaryDirection = "down",
        layoutSecondaryDirection = "right",
    },

    achievementCriteriaSectionCheck =
    {
        uppercase = true,
        layoutPrimaryDirection = "right",
        layoutSecondaryDirection = "down",
    },

    achievementCriteriaSectionBar =
    {
        widthPercent = 100,
        paddingBottom = 5,
    },

    achievementCriteriaBarWrapper =
    {
        paddingLeft = 2
    },

    achievementCriteriaBar =
    {
        width = 380,
        statusBarTemplate = "ZO_GamepadArrowStatusBarWithBGMedium",
        customSpacing = 4,
        statusBarGradientColors = ZO_SKILL_XP_BAR_GRADIENT_COLORS,
    },

    achievementCriteriaProgress =
    {
        widthPercent = 100,
        fontSize = "$(GP_30)",
        fontColorField = GENERAL_COLOR_WHITE,
    },

    achievementDescriptionComplete =
    {
        width = 357,
        fontSize = "$(GP_30)",
        fontColorField = GAMEPAD_TOOLTIP_COLOR_GENERAL_COLOR_3,
    },

    achievementDescriptionIncomplete =
    {
        width = 357,
        fontSize = "$(GP_30)",
        fontColorField = GAMEPAD_TOOLTIP_COLOR_INACTIVE,
    },

    achievementCriteriaCheckComplete =
    {
        width = 32,
        height = 32,
    },
    
    achievementCriteriaCheckIncomplete =
    {
        color = ZO_ColorDef:New(0, 0, 0, 0),
        width = 32,
        height = 32,
    },

    achievementItemIcon =
    {
        width = 48,
        height = 48,
    },

    achievementName =
    {
        widthPercent = 85,
        fontSize = "$(GP_34)",
        fontColorField = GENERAL_COLOR_WHITE,
    },

    achievementComplete =
    {
        fontColorField = GENERAL_COLOR_WHITE,
    },

    achievementIncomplete =
    {
        fontColorField = GENERAL_COLOR_WHITE,
    },

    attributeStatsSection =
    {
        paddingTop = 100,
    },
    attributeUpgradePair =
    {
        customSpacing = 3,
    },

    -- Cadwell
    cadwellSection = 
    {
        paddingTop = 13,
        widthPercent = 100
    },

    cadwellObjectiveTitleSection =
    {
        paddingLeft = 46
    },

    cadwellObjectiveTitle =
    {
        fontFace = "$(GAMEPAD_BOLD_FONT)",
        fontSize = "$(GP_22)",
        customSpacing = 3,
        uppercase = true,
        fontColorType = INTERFACE_COLOR_TYPE_TEXT_COLORS,
        fontColorField = INTERFACE_TEXT_COLOR_NORMAL,
        height = 40,
    },

    cadwellTextureContainer = 
    {
        layoutPrimaryDirection = "down",
        layoutSecondaryDirection = "right",
        paddingTop = 9,
        widthPercent = 10,
    },

    cadwellObjectiveSection = 
    {
        fontSize = "$(GP_34)",
        layoutPrimaryDirection = "right",
        layoutSecondaryDirection = "down",
        widthPercent = 90
    },

    cadwellObjectiveContainerSection = 
    {
        layoutPrimaryDirection = "right",
        layoutSecondaryDirection = "down",
        widthPercent = 100,
    },

    cadwellObjectivesSection = 
    {
        widthPercent = 100,
        childSpacing = 7,
    },

    cadwellObjectiveActive = 
    {
        width = 312,
        fontColorField = GAMEPAD_TOOLTIP_COLOR_ACTIVE
    },

    cadwellObjectiveInactive = 
    {
        width = 312,
        fontColorField = GAMEPAD_TOOLTIP_COLOR_INACTIVE
    },

    cadwellObjectiveComplete = 
    {
        width = 312,
        fontColorField = GAMEPAD_TOOLTIP_COLOR_GENERAL_COLOR_3,
    },

    -- Loot tooltip
    lootTooltip =
    {
        width = 295,
        fontFace = "$(GAMEPAD_MEDIUM_FONT)",
        fontColorType = INTERFACE_COLOR_TYPE_GAMEPAD_TOOLTIP,
        fontColorField = GENERAL_COLOR_GREY,
        fontStyle = "soft-shadow-thick",
    },

    -- Gamepad Social Tooltip
    socialTitle =
    {
        customSpacing = 3,
        fontFace = "$(GAMEPAD_LIGHT_FONT)",
        fontSize = "$(GP_42)",
        fontStyle = "soft-shadow-thick",
        fontColorType = INTERFACE_COLOR_TYPE_TEXT_COLORS,
        fontColorField = INTERFACE_TEXT_COLOR_NORMAL,
    },

    socialStatsSection =
    {
        statValuePairSpacing = 10,
        childSpacing = 3,
        customSpacing = 15,
        widthPercent = 100,
    },

    charaterNameSection =
    {
        customSpacing = 5,
        widthPercent = 100,
    },

    socialStatsValue =
    {
        fontSize = "$(GP_34)",
        fontColorField = GENERAL_COLOR_WHITE,
    },

    socialOffline =
    {
        fontSize = "$(GP_42)",
        fontColorField = GENERAL_COLOR_GREY,
    },

    -- Gamepad Collections
    collectionsInfoSection =
    {
        customSpacing = 25,
        childSpacing = 25,
        widthPercent = 100,
        fontColorField = GENERAL_COLOR_OFF_WHITE,
        fontFace = "$(GAMEPAD_LIGHT_FONT)",
    },

    collectionsStatsSection =
    {
        statValuePairSpacing = 10,
        childSpacing = 20,
        customSpacing = 20,
        widthPercent = 100,
    },

    collectionsRestrictionsSection =
    {
        statValuePairSpacing = 10,
        childSpacing = 10,
        customSpacing = 20,
        widthPercent = 100,
    },

    collectionsStatsValue =
    {
        fontSize = "$(GP_42)",
        customSpacing = 8,
        fontColorField = GENERAL_COLOR_WHITE,
    },

    collectionsPersonality =
    {
        fontColor = ZO_PERSONALITY_EMOTES_COLOR,
    },

    -- Gamepad Crown Store Market
    instantUnlockIneligibilitySection =
    {
        customSpacing = 25,
        widthPercent = 100,
        fontColorField = GENERAL_COLOR_RED,
        fontFace = "$(GAMEPAD_LIGHT_FONT)",
    },

    instantUnlockIneligibilityLine =
    {
        fontSize = "$(GP_34)",
    },

    -- Gamepad Keep Information
    keepInfoSection =
    {
        paddingTop = 20,
        widthPercent = 100,
    },

    --Gamepad Voice Chat
    voiceChatBodyHeader =
    {
        fontFace = "$(GAMEPAD_MEDIUM_FONT)",
        fontSize = "$(GP_27)",
        uppercase = true,
        fontColorField = GENERAL_COLOR_WHITE,
        widthPercent = 100,
    },
    voiceChatPair =
    {
        customSpacing = 25,
        height = 40,
    },
    voiceChatPairLabel =
    {
        fontSize = "$(GP_27)",
        uppercase = true,
        fontColorField = GENERAL_COLOR_OFF_WHITE,
    },
    voiceChatPairText =
    {
        fontSize = "$(GP_34)",
        fontColorField = GENERAL_COLOR_WHITE,
    },
    voiceChatGamepadReputation = {
        fontSize = "$(GP_34)",
        fontColorField = GENERAL_COLOR_RED,
        uppercase = false,
    },
    voiceChatGamepadSpeaker =
    {
        height = 43,
        fontSize = "$(GP_34)",
        fontColorField = GENERAL_COLOR_OFF_WHITE,
        layoutPrimaryDirection = "right",
        childSpacing = 10,
        customSpacing = 15,        
        widthPercent = 100,
    },
    voiceChatGamepadSpeakerTitle =
    {
        fontSize = "$(GP_42)",
        customSpacing = 8,
        uppercase = false,
        fontColorField = GENERAL_COLOR_WHITE,
    },
    voiceChatGamepadSpeakerText =
    {
        fontSize = "$(GP_34)",
        widthPercent = 90,
    },
    voiceChatGamepadSpeakerIcon =
    {
        width = 29,
        height = 43,
        textureCoordinateLeft = 0.2734375,
        textureCoordinateRight = 0.7265625,
        textureCoordinateTop = 0.1640625,
        textureCoordinateBottom = 0.8359375,
        desaturation = 0,
    },
    voiceChatGamepadStatValuePair =
    {
        height = 40,
        widthPercent = 100,
    },

    groupTitleSection =
    {
        fontSize = "$(GP_42)",
        widthPercent = 100,
        uppercase = true,
        fontColorField = GENERAL_COLOR_WHITE,
    },
    groupBodySection =
    {
        childSpacing = 30,
    },
    groupDescription =
    {
        fontSize = "$(GP_42)",
        fontFace = "$(GAMEPAD_LIGHT_FONT)",
    },
    groupDescriptionError =
    {
        fontColorField = GENERAL_COLOR_RED,
    },
    groupRolesTitleSection =
    {
        fontSize = "$(GP_42)",
        widthPercent = 100,
        uppercase = true,
        fontColorField = GENERAL_COLOR_WHITE,
        paddingTop = 70,
    },
    groupRolesStatValuePairValue =
    {
        fontSize = "$(GP_42)",
        uppercase = false,
        fontColorField = GENERAL_COLOR_WHITE,
    },
    -- Gamepad Champion Screen
    attributeTitleSection =
    {
        fontSize = "$(GP_48)",
        fontFace = "$(GAMEPAD_BOLD_FONT)",
        uppercase = true,
        childSpacing = 20,
        fontColorField = GENERAL_COLOR_OFF_WHITE,
        layoutPrimaryDirection = "left",
        layoutSecondaryDirection = "down",
        layoutPrimaryDirectionCentered = true,
        widthPercent = 100,
    },
    attributeTitle =
    {
        horizontalAlignment = TEXT_ALIGN_CENTER,
        layoutPrimaryDirectionCentered = true,
    },
    attributeIcon = 
    {
        width = 48,
        height = 48,
        layoutPrimaryDirectionCentered = true,
    },
    championTitleSection =
    {
        customSpacing = 15,
        widthPercent = 100,
    },
    championTitle =
    {
        widthPercent = 100,
        horizontalAlignment = TEXT_ALIGN_CENTER,
    },
    dividerLine =
    {
        textureCoordinateLeft = 0.25,
        textureCoordinateRight = 0.75,
        textureCoordinateTop = 0.25,
        textureCoordinateBottom = 0.75,
        widthPercent = 100,
        height = 8,
    },
    championPointsSection =
    {
        customSpacing = 5,
        widthPercent = 100,
        layoutPrimaryDirection = "right",
        layoutSecondaryDirection = "up",
    },
    pointsHeader =
    {
        fontSize = "$(GP_27)",
        uppercase = true,
        widthPercent = 60,
        horizontalAlignment = TEXT_ALIGN_LEFT,
        fontColorField = GENERAL_COLOR_OFF_WHITE,
    },
    pointsValue =
    {
        fontSize = "$(GP_42)",
        widthPercent = 40,
        horizontalAlignment = TEXT_ALIGN_RIGHT,
        fontColorField = GENERAL_COLOR_WHITE,
    },
    championBodySection =
    {
        customSpacing = 15,
        horizontalAlignment = TEXT_ALIGN_CENTER,
    },
    
    itemComparisonStatSection = 
    {
        customSpacing = 25,
        widthPercent = 100,
    },
    itemComparisonStatValuePair =
    {
        height = 40,
        widthPercent = 98,
    },
    itemComparisonStatValuePairValue = 
    {
        fontSize = "$(GP_34)",
        fontFace = "$(GAMEPAD_LIGHT_FONT)",
        horizontalAlignment = TEXT_ALIGN_RIGHT,
    },
    itemComparisonStatValuePairDefaultColor = 
    {
        fontColorField = GENERAL_COLOR_WHITE,
    },

    -- Dyes
    dyesSection =
    {
        widthPercent = 100,
        paddingTop = 30,
        childSpacing = 10,
        layoutPrimaryDirection = "down",
        layoutSecondaryDirection = "right",
    },
    dyeSwatchStyle =
    {
        customSpacing = 2,
        width = 38,
        height = 38,
        edgeTextureFile = "EsoUI/Art/Miscellaneous/Gamepad/gp_emptyFrame_gold_edge.dds",
        edgeTextureWidth = 128,
        edgeTextureHeight = 16,
        fontSize = "$(GP_34)",
        fontColorField = GENERAL_COLOR_WHITE,
    },
    dyeSwatchEntrySection =
    {
        widthPercent = 100,
        layoutPrimaryDirection = "right",
        layoutSecondaryDirection = "down",
    },
    dyeStampError =
    {
        fontSize = "$(GP_42)",
        fontColorField = GAMEPAD_TOOLTIP_COLOR_FAILED,
    },
    -- Housing Tooltips
    defaultAccessTopSection =
    {
        customSpacing = 10,
        paddingTop = 30,
        fontFace = "$(GAMEPAD_LIGHT_FONT)",
        fontSize = "$(GP_42)",
    },
    defaultAccessTitle =
    {
        fontColorField = GENERAL_COLOR_WHITE,
    },
    defaultAccessBody =
    {   
        widthPercent = 100,
        fontColorField = GENERAL_COLOR_OFF_WHITE,
        fontFace = "$(GAMEPAD_LIGHT_FONT)",
        fontSize = "$(GP_42)",
    },

    --Gamepad Currency Tooltip
    currencySection =
    {
        customSpacing = 47,
        widthPercent = 100,
        childSpacing = 20,
    },
    currencyStatValuePair =
    {
        height = 40,
        widthPercent = 98,
    },
    currencyStatValuePairStat =
    {
        fontSize = "$(GP_27)",
        fontFace = "$(GAMEPAD_LIGHT_FONT)",
        uppercase = true,
        fontColorField = GENERAL_COLOR_OFF_WHITE,
    },
    currencyStatValuePairValue = 
    {
        fontSize = "$(GP_34)",
        fontFace = "$(GAMEPAD_LIGHT_FONT)",
        horizontalAlignment = TEXT_ALIGN_RIGHT,
        fontColorField = GENERAL_COLOR_WHITE,
    },

}

local function Style(name)
    return ZO_TOOLTIP_STYLES[name]
end

local ITEM_QUALITY_TO_STYLE =
{
    [ITEM_QUALITY_TRASH] = Style("qualityTrash"),
    [ITEM_QUALITY_NORMAL] = Style("qualityNormal"),
    [ITEM_QUALITY_MAGIC] = Style("qualityMagic"),
    [ITEM_QUALITY_ARCANE] = Style("qualityArcane"),
    [ITEM_QUALITY_ARTIFACT] = Style("qualityArtifact"),
    [ITEM_QUALITY_LEGENDARY] = Style("qualityLegendary"),
}

function ZO_TooltipStyles_GetItemQualityStyle(itemQuality)
    return ITEM_QUALITY_TO_STYLE[itemQuality]
end
