--Gamepad fragments
local ALWAYS_ANIMATE = true

-- Quadrant System Gamepad Grid Backgrounds: DO NOT BLOAT! --

GAMEPAD_NAV_QUADRANT_1_BACKGROUND_FRAGMENT = ZO_TranslateFromLeftSceneFragment:New(ZO_SharedGamepadNavQuadrant_1_Background)
ZO_BackgroundFragment:Mixin(GAMEPAD_NAV_QUADRANT_1_BACKGROUND_FRAGMENT)
GAMEPAD_NAV_QUADRANT_1_INSTANT_BACKGROUND_FRAGMENT = ZO_SimpleSceneFragment:New(ZO_SharedGamepadNavQuadrant_1_Background)
GAMEPAD_NAV_QUADRANT_2_BACKGROUND_FRAGMENT = ZO_FadeSceneFragment:New(ZO_SharedGamepadNavQuadrant_2_Background)
ZO_BackgroundFragment:Mixin(GAMEPAD_NAV_QUADRANT_2_BACKGROUND_FRAGMENT)
GAMEPAD_NAV_QUADRANT_1_2_BACKGROUND_FRAGMENT = ZO_TranslateFromLeftSceneFragment:New(ZO_SharedGamepadNavQuadrant_1_2_Background)
ZO_BackgroundFragment:Mixin(GAMEPAD_NAV_QUADRANT_1_2_BACKGROUND_FRAGMENT)
GAMEPAD_NAV_QUADRANT_4_BACKGROUND_FRAGMENT = ZO_FadeSceneFragment:New(ZO_SharedGamepadNavQuadrant_4_Background)
ZO_BackgroundFragment:Mixin(GAMEPAD_NAV_QUADRANT_4_BACKGROUND_FRAGMENT)
GAMEPAD_NAV_QUADRANT_2_3_BACKGROUND_FRAGMENT = ZO_FadeSceneFragment:New(ZO_SharedGamepadNavQuadrant_2_3_Background, ALWAYS_ANIMATE)
ZO_BackgroundFragment:Mixin(GAMEPAD_NAV_QUADRANT_2_3_BACKGROUND_FRAGMENT)
GAMEPAD_NAV_QUADRANT_2_3_4_BACKGROUND_FRAGMENT = ZO_FadeSceneFragment:New(ZO_SharedGamepadNavQuadrant_2_3_4_Background, ALWAYS_ANIMATE)
GAMEPAD_NAV_QUADRANT_1_2_3_BACKGROUND_FRAGMENT = ZO_TranslateFromLeftSceneFragment:New(ZO_SharedGamepadNavQuadrant_1_2_3_Background)

-- END Quadrant System Gamepad Grid Backgrounds: DO NOT BLOAT! --

GAMEPAD_NAV_QUADRANT_2_3_FURNITURE_ITEM_PREVIEW_OPTIONS_FRAGMENT = ZO_ItemPreviewOptionsFragment:New({
    paddingLeft = ZO_GAMEPAD_PANEL_WIDTH + ZO_GAMEPAD_SAFE_ZONE_INSET_X,
    paddingRight = ZO_GAMEPAD_PANEL_WIDTH + ZO_GAMEPAD_SAFE_ZONE_INSET_X,
    dynamicFramingConsumedWidth = ZO_GAMEPAD_PANEL_WIDTH + ZO_GAMEPAD_SAFE_ZONE_INSET_X,
    dynamicFramingConsumedHeight = 400,
    forcePreparePreview = false,
    previewInEmptyWorld = true,
    previewBufferMS = 300
})

GAMEPAD_NAV_QUADRANT_2_3_4_FURNITURE_ITEM_PREVIEW_OPTIONS_FRAGMENT = ZO_ItemPreviewOptionsFragment:New({
    paddingLeft = ZO_GAMEPAD_PANEL_WIDTH + ZO_GAMEPAD_SAFE_ZONE_INSET_X,
    paddingRight = ZO_GAMEPAD_SAFE_ZONE_INSET_X,
    dynamicFramingConsumedWidth = ZO_GAMEPAD_UI_REFERENCE_WIDTH - ZO_GAMEPAD_PANEL_WIDTH - (ZO_GAMEPAD_SAFE_ZONE_INSET_X * 2),
    dynamicFramingConsumedHeight = 400,
    forcePreparePreview = false,
    previewInEmptyWorld = true,
    previewBufferMS = 300
})

GAMEPAD_NAV_QUADRANT_3_4_ITEM_PREVIEW_OPTIONS_FRAGMENT = ZO_ItemPreviewOptionsFragment:New({
    paddingLeft = (ZO_GAMEPAD_PANEL_WIDTH * 2) + ZO_GAMEPAD_SAFE_ZONE_INSET_X,
    paddingRight = ZO_GAMEPAD_SAFE_ZONE_INSET_X,
    dynamicFramingConsumedWidth = ZO_GAMEPAD_UI_REFERENCE_WIDTH - (ZO_GAMEPAD_PANEL_WIDTH * 2) - (ZO_GAMEPAD_SAFE_ZONE_INSET_X * 2),
    dynamicFramingConsumedHeight = 400,
    forcePreparePreview = false,
    previewBufferMS = 300,
})

GAMEPAD_NAV_QUADRANT_2_3_4_ITEM_PREVIEW_OPTIONS_FRAGMENT = ZO_ItemPreviewOptionsFragment:New({
    paddingLeft = ZO_GAMEPAD_PANEL_WIDTH + ZO_GAMEPAD_SAFE_ZONE_INSET_X,
    paddingRight = 0,
    dynamicFramingConsumedWidth = 1150,
    dynamicFramingConsumedHeight = 400,
    forcePreparePreview = false,
    previewBufferMS = 300
})

GAMEPAD_RIGHT_TOOLTIP_ITEM_PREVIEW_OPTIONS_FRAGMENT = ZO_ItemPreviewOptionsFragment:New({
    paddingLeft = 0,
    paddingRight = ZO_GAMEPAD_PANEL_WIDTH + ZO_GAMEPAD_SAFE_ZONE_INSET_X,
    dynamicFramingConsumedWidth = 700,
    dynamicFramingConsumedHeight = 400,
})

GAMEPAD_COLLECTIONS_ITEM_PREVIEW_OPTIONS_FRAGMENT = ZO_ItemPreviewOptionsFragment:New({
    paddingLeft = ZO_GAMEPAD_PANEL_WIDTH + ZO_GAMEPAD_SAFE_ZONE_INSET_X,
    paddingRight = 0,
    dynamicFramingConsumedWidth = 1150,
    dynamicFramingConsumedHeight = 400,
    forcePreparePreview = false,
    previewBufferMS = 300,
})

local ZO_Gamepad_GuildNameFooterFragment = ZO_FadeSceneFragment:Subclass()

function ZO_Gamepad_GuildNameFooterFragment:New(...)
    return ZO_FadeSceneFragment.New(self, ...)
end

function ZO_Gamepad_GuildNameFooterFragment:Initialize(...)
    ZO_FadeSceneFragment.Initialize(self, ...)

    self.guildName = nil
    self.guildNameControl = self.control:GetNamedChild("GuildName")
end

function ZO_Gamepad_GuildNameFooterFragment:SetGuildName(guildName)
    self.guildName = guildName
    self.guildNameControl:SetText(guildName)
end

function ZO_Gamepad_GuildNameFooterFragment:Show()
    ZO_FadeSceneFragment.Show(self)
end

ZO_GUILD_NAME_FOOTER_FRAGMENT = ZO_Gamepad_GuildNameFooterFragment:New(ZO_Gamepad_GuildNameFooter)

GAMEPAD_SCREEN_ADJUST_ACTION_LAYER_FRAGMENT = ZO_ActionLayerFragment:New("ScreenAdjust")

OPTIONS_MENU_INFO_PANEL_FRAGMENT = ZO_FadeSceneFragment:New(ZO_GamepadOptionsTopLevelInfoPanel)

GAMEPAD_COLLECTIONS_BOOK_FRAGMENT = ZO_SimpleSceneFragment:New(ZO_GamepadCollections)
GAMEPAD_COLLECTIONS_BOOK_FRAGMENT:SetHideOnSceneHidden(true)
GAMEPAD_COLLECTIONS_BOOK_DLC_PANEL_FRAGMENT = ZO_FadeSceneFragment:New(ZO_GamepadCollectionsDLCPanel, true)
GAMEPAD_COLLECTIONS_BOOK_HOUSING_PANEL_FRAGMENT = ZO_FadeSceneFragment:New(ZO_GamepadCollectionsHousingPanel, true)
GAMEPAD_COLLECTIONS_BOOK_GRID_LIST_PANEL_FRAGMENT = ZO_FadeSceneFragment:New(ZO_GamepadCollectionsGridListPanel, true)

GAMEPAD_ACTIVITY_FINDER_FRAGMENT = ZO_SimpleSceneFragment:New(ZO_ActivityFinderRoot_Gamepad)
GAMEPAD_ACTIVITY_FINDER_FRAGMENT:SetHideOnSceneHidden(true)

GAMEPAD_HOUSING_FURNITURE_BROWSER_FRAGMENT = ZO_CreateQuadrantConveyorFragment(ZO_HousingFurnitureBrowser_GamepadTopLevel)

GAMEPAD_ALCHEMY_FRAGMENT = ZO_SimpleSceneFragment:New(ZO_GamepadAlchemyTopLevel)
GAMEPAD_ALCHEMY_FRAGMENT:SetHideOnSceneHidden(true)
GAMEPAD_ALCHEMY_MODE_FRAGMENT = ZO_CreateQuadrantConveyorFragment(ZO_GamepadAlchemyTopLevelContainerMode)
GAMEPAD_ALCHEMY_INVENTORY_FRAGMENT = ZO_CreateQuadrantConveyorFragment(ZO_GamepadAlchemyTopLevelContainerInventory)
GAMEPAD_ALCHEMY_SLOTS_FRAGMENT = ZO_FadeSceneFragment:New(ZO_GamepadAlchemyTopLevelSlotContainer)

GAMEPAD_QUICKSLOT_FRAGMENT = ZO_SimpleSceneFragment:New(ZO_GamepadQuickslotToplevel)
GAMEPAD_QUICKSLOT_FRAGMENT:SetHideOnSceneHidden(true)
GAMEPAD_QUICKSLOT_SELECTED_TOOLTIP_FRAGMENT = ZO_FadeSceneFragment:New(ZO_GamepadQuickslotToplevelSelectedTooltipContainer)

GAMEPAD_GUILD_HUB_FRAGMENT = ZO_SimpleSceneFragment:New(ZO_GamepadGuildHubTopLevel)
GAMEPAD_GUILD_HUB_FRAGMENT:SetHideOnSceneHidden(true)

GAMEPAD_GUILD_HOME_FRAGMENT = ZO_SimpleSceneFragment:New(ZO_GamepadGuildHomeTopLevel)
GAMEPAD_GUILD_HOME_FRAGMENT:SetHideOnSceneHidden(true)

GAMEPAD_RESTYLE_FRAGMENT = ZO_FadeSceneFragment:New(ZO_RestyleTopLevel_Gamepad)
GAMEPAD_RESTYLE_ROOT_FRAGMENT = ZO_CreateQuadrantConveyorFragment(ZO_RestyleTopLevel_GamepadMaskContainer)
GAMEPAD_RESTYLE_DYEING_PANEL_FRAGMENT = ZO_FadeSceneFragment:New(ZO_RestyleTopLevel_GamepadDyePanel)

GAMEPAD_INVENTORY_FRAGMENT = ZO_SimpleSceneFragment:New(ZO_GamepadInventoryTopLevel)
GAMEPAD_INVENTORY_FRAGMENT:SetHideOnSceneHidden(true)

GAMEPAD_EMOTES_FRAGMENT = ZO_FadeSceneFragment:New(ZO_GamepadPlayerEmoteTopLevel)

GAMEPAD_ENCHANTING_FRAGMENT = ZO_FadeSceneFragment:New(ZO_GamepadEnchantingTopLevel)
GAMEPAD_ENCHANTING_MODE_FRAGMENT = ZO_CreateQuadrantConveyorFragment(ZO_GamepadEnchantingTopLevelContainerMode)
GAMEPAD_ENCHANTING_INVENTORY_FRAGMENT = ZO_CreateQuadrantConveyorFragment(ZO_GamepadEnchantingTopLevelContainerInventory)

GAMEPAD_SKILLS_FRAGMENT = ZO_SimpleSceneFragment:New(ZO_GamepadSkillsTopLevel)
GAMEPAD_SKILLS_FRAGMENT:SetHideOnSceneHidden(true)

GAMEPAD_QUEST_JOURNAL_FRAGMENT = ZO_SimpleSceneFragment:New(ZO_QuestJournal_GamepadTopLevel)
GAMEPAD_QUEST_JOURNAL_FRAGMENT:SetHideOnSceneHidden(true)

GAMEPAD_LEADERBOARDS_FRAGMENT = ZO_SimpleSceneFragment:New(ZO_Leaderboards_Gamepad)
GAMEPAD_LEADERBOARDS_FRAGMENT:SetHideOnSceneHidden(true)
GAMEPAD_LEADERBOARDS_LIST_FRAGMENT = ZO_FadeSceneFragment:New(ZO_LeaderboardList_Gamepad)

GAMEPAD_SMITHING_FRAGMENT = ZO_SimpleSceneFragment:New(ZO_GamepadSmithingTopLevel)
GAMEPAD_SMITHING_FRAGMENT:SetHideOnSceneHidden(true)
GAMEPAD_SMITHING_MODE_FRAGMENT = ZO_CreateQuadrantConveyorFragment(ZO_GamepadSmithingTopLevelMaskContainer)

GAMEPAD_SMITHING_REFINE_INVENTORY_FRAGMENT = ZO_CreateQuadrantConveyorFragment(ZO_GamepadSmithingTopLevelMaskRefinementInventory)
GAMEPAD_SMITHING_REFINE_FLOATING_FRAGMENT = ZO_FadeSceneFragment:New(ZO_GamepadSmithingTopLevelRefinement)

GAMEPAD_SMITHING_DECONSTRUCT_INVENTORY_FRAGMENT = ZO_CreateQuadrantConveyorFragment(ZO_GamepadSmithingTopLevelMaskDeconstructionInventory)
GAMEPAD_SMITHING_DECONSTRUCT_FLOATING_FRAGMENT = ZO_FadeSceneFragment:New(ZO_GamepadSmithingTopLevelDeconstruction)

GAMEPAD_SMITHING_CREATION_CREATE_FRAGMENT = ZO_CreateQuadrantConveyorFragment(ZO_GamepadSmithingTopLevelMaskCreationCreate)
GAMEPAD_SMITHING_CREATION_OPTIONS_FRAGMENT = ZO_CreateQuadrantConveyorFragment(ZO_GamepadSmithingTopLevelMaskCreationOptions)
GAMEPAD_SMITHING_CREATION_FLOATING_FRAGMENT = ZO_FadeSceneFragment:New(ZO_GamepadSmithingTopLevelCreation)

GAMEPAD_SMITHING_IMPROVEMENT_INVENTORY_FRAGMENT = ZO_CreateQuadrantConveyorFragment(ZO_GamepadSmithingTopLevelMaskImprovementInventory)
GAMEPAD_SMITHING_IMPROVEMENT_FLOATING_FRAGMENT = ZO_FadeSceneFragment:New(ZO_GamepadSmithingTopLevelImprovement)

GAMEPAD_SMITHING_RESEARCH_RESEARCH_FRAGMENT = ZO_CreateQuadrantConveyorFragment(ZO_GamepadSmithingTopLevelMaskResearchResearch)
GAMEPAD_SMITHING_RESEARCH_CONFIRM_FRAGMENT = ZO_CreateQuadrantConveyorFragment(ZO_GamepadSmithingTopLevelMaskResearchConfirm)

GAMEPAD_LORE_LIBRARY_FRAGMENT = ZO_SimpleSceneFragment:New(ZO_Gamepad_LoreLibrary)
GAMEPAD_LORE_LIBRARY_FRAGMENT:SetHideOnSceneHidden(true)

GAMEPAD_BOOK_SET_FRAGMENT = ZO_SimpleSceneFragment:New(ZO_Gamepad_BookSet)
GAMEPAD_BOOK_SET_FRAGMENT:SetHideOnSceneHidden(true)

GAMEPAD_LOOT_PICKUP_FRAGMENT = ZO_FadeSceneFragment:New(ZO_Gamepad_LootPickup, GAMEPAD_GRID_NAV2)
GAMEPAD_LOOT_INVENTORY_FRAGMENT = ZO_CreateQuadrantConveyorFragment(ZO_Gamepad_LootInventory)

GAMEPAD_ACHIEVEMENTS_FRAGMENT = ZO_SimpleSceneFragment:New(ZO_Gamepad_Achievements)
GAMEPAD_ACHIEVEMENTS_FRAGMENT:SetHideOnSceneHidden(true)

GAMEPAD_ACHIEVEMENTS_FOOTER_FRAGMENT = ZO_FadeSceneFragment:New(ZO_Gamepad_Achievements_FooterBar)

GAMEPAD_CADWELL_FRAGMENT = ZO_SimpleSceneFragment:New(ZO_Gamepad_Cadwell)
GAMEPAD_CADWELL_FRAGMENT:SetHideOnSceneHidden(true)

GAMEPAD_REPAIR_KITS_FRAGMENT = ZO_CreateQuadrantConveyorFragment(ZO_Gamepad_RepairKits)

GAMEPAD_APPLY_ENCHANT_FRAGMENT = ZO_CreateQuadrantConveyorFragment(ZO_Gamepad_ApplyEnchant)

GAMEPAD_SOUL_GEM_ITEM_CHARGER_FRAGMENT = ZO_CreateQuadrantConveyorFragment(ZO_Gamepad_SoulGemItemCharger)

GAMEPAD_MAIL_MANAGER_FRAGMENT = ZO_FadeSceneFragment:New(ZO_MailManager_Gamepad)

GAMEPAD_AVA_FRAGMENT = ZO_SimpleSceneFragment:New(ZO_CampaignBrowser_GamepadTopLevel)
GAMEPAD_AVA_FRAGMENT:SetHideOnSceneHidden(true)
GAMEPAD_AVA_CAMPAIGN_INFO_FRAGMENT = ZO_FadeSceneFragment:New(ZO_CampaignBrowser_GamepadTopLevelCampaignInfo)
GAMPEAD_AVA_RANK_FRAGMENT = ZO_FadeSceneFragment:New(ZO_CampaignBrowser_GamepadTopLevelAvaRankFooter)

GAMEPAD_GROUP_MENU_FRAGMENT = ZO_FadeSceneFragment:New(ZO_GroupMenuGamepad)
GAMEPAD_GROUP_LFG_OPTIONS_FRAGMENT = ZO_FadeSceneFragment:New(ZO_GroupRoleMenu_Gamepad)
GAMEPAD_GROUP_LIST_FRAGMENT = ZO_FadeSceneFragment:New(ZO_GroupMenuGamepadGroupList)
GAMEPAD_GROUP_MEMBERS_FRAGMENT = ZO_FadeSceneFragment:New(ZO_GroupMembers_Gamepad)

GAMEPAD_GROUPING_TOOLS_FRAGMENT = ZO_SimpleSceneFragment:New(ZO_GroupingToolsGamepad)
GAMEPAD_GROUPING_TOOLS_LOCATION_INFO_FRAGMENT = ZO_FadeSceneFragment:New(ZO_GroupingToolsGamepadLocationInfo)

GAMEPAD_BUY_BAG_SPACE_FRAGMENT = ZO_SimpleSceneFragment:New(ZO_GamepadBuyBagSpaceTopLevel)
GAMEPAD_BUY_BANK_SPACE_FRAGMENT = ZO_SimpleSceneFragment:New(ZO_GamepadBankingBuyBankSpaceTopLevel)
GAMEPAD_BANKING_WITHDRAW_DEPOSIT_GOLD_FRAGMENT = ZO_SimpleSceneFragment:New(ZO_GamepadBankingWithdrawDepositGoldTopLevel)

GAMEPAD_NOTIFICATIONS_FRAGMENT =  ZO_SimpleSceneFragment:New(ZO_GamepadNotifications)
GAMEPAD_NOTIFICATIONS_FRAGMENT:SetHideOnSceneHidden(true)

GAMEPAD_PROVISIONER_FRAGMENT = ZO_SimpleSceneFragment:New(ZO_GamepadProvisionerTopLevel)
GAMEPAD_PROVISIONER_FRAGMENT:SetHideOnSceneHidden(true)
GAMEPAD_PROVISIONER_RECIPELIST_FRAGMENT = ZO_CreateQuadrantConveyorFragment(ZO_GamepadProvisionerTopLevelContainerRecipe)
GAMEPAD_PROVISIONER_OPTIONS_FRAGMENT = ZO_CreateQuadrantConveyorFragment(ZO_GamepadProvisionerTopLevelContainerOptions)

GAMEPAD_VENDOR_FRAGMENT = ZO_SimpleSceneFragment:New(ZO_StoreWindow_Gamepad)
GAMEPAD_FENCE_FRAGMENT = ZO_SimpleSceneFragment:New(ZO_FenceWindow_Gamepad)

GAMEPAD_BANKING_FRAGMENT = ZO_SimpleSceneFragment:New(ZO_GamepadBankingTopLevel)

GAMEPAD_GUILD_BANK_FRAGMENT = ZO_SimpleSceneFragment:New(ZO_GuildBankTopLevel_Gamepad)
GAMEPAD_GUILD_BANK_FRAGMENT:SetHideOnSceneHidden(true)

GAMEPAD_GUILD_BANK_WITHDRAW_DEPOSIT_GOLD_FRAGMENT = ZO_SimpleSceneFragment:New(ZO_GuildBankWithdrawDepositGoldTopLevel_Gamepad)

GAMEPAD_GUILD_KIOSK_PURCHASE_FRAGMENT = ZO_CreateQuadrantConveyorFragment(ZO_Gamepad_GuildKiosk_Purchase)
GAMEPAD_GUILD_KIOSK_BID_FRAGMENT = ZO_CreateQuadrantConveyorFragment(ZO_Gamepad_GuildKiosk_Bid)

GAMEPAD_TRADING_HOUSE_FRAGMENT = ZO_SimpleSceneFragment:New(ZO_TradingHouse_Gamepad)
GAMEPAD_TRADING_HOUSE_FRAGMENT:SetHideOnSceneHidden(true)
GAMEPAD_TRADING_HOUSE_CREATE_LISTING_ROOT_FRAGMENT = ZO_FadeSceneFragment:New(ZO_TradingHouse_CreateListing_Gamepad)
GAMEPAD_TRADING_HOUSE_CREATE_LISTING_LIST_FRAGMENT = ZO_CreateQuadrantConveyorFragment(ZO_TradingHouse_CreateListing_GamepadMaskContainer)

GAMEPAD_RESTYLE_STATION_LIST_FRAGMENT = ZO_CreateQuadrantConveyorFragment(ZO_RestyleStation_GamepadMaskContainer)
GAMEPAD_OUTFITS_SELECTOR_ROOT_FRAGMENT = ZO_CreateQuadrantConveyorFragment(ZO_Outfits_Selector_GamepadMaskContainer)

GAMEPAD_ZONE_STORIES_FRAGMENT = ZO_SimpleSceneFragment:New(ZO_ZoneStoriesTopLevel_Gamepad)
GAMEPAD_ZONE_STORIES_FRAGMENT:SetHideOnSceneHidden(true)