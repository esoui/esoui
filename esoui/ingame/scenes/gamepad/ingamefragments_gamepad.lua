--Gamepad fragments
local ALWAYS_ANIMATE = true

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

GAMEPAD_COLLECTIONS_BOOK_FRAGMENT = ZO_SimpleSceneFragment:New(ZO_GamepadCollections)
GAMEPAD_COLLECTIONS_BOOK_FRAGMENT:SetHideOnSceneHidden(true)
GAMEPAD_COLLECTIONS_BOOK_DLC_PANEL_FRAGMENT = ZO_FadeSceneFragment:New(ZO_GamepadCollectionsDLCPanel, true)
GAMEPAD_COLLECTIONS_BOOK_HOUSING_PANEL_FRAGMENT = ZO_FadeSceneFragment:New(ZO_GamepadCollectionsHousingPanel, true)

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

GAMEPAD_STATS_FRAGMENT = ZO_SimpleSceneFragment:New(ZO_GamepadStatsTopLevel)
GAMEPAD_STATS_FRAGMENT:SetHideOnSceneHidden(true)

GAMEPAD_STATS_CHARACTER_INFO_PANEL_FRAGMENT = ZO_FadeSceneFragment:New(ZO_GamepadStatsTopLevelRightPane, ALWAYS_ANIMATE)

GAMEPAD_GUILD_HUB_FRAGMENT = ZO_SimpleSceneFragment:New(ZO_GamepadGuildHubTopLevel)
GAMEPAD_GUILD_HUB_FRAGMENT:SetHideOnSceneHidden(true)

GAMEPAD_GUILD_HOME_FRAGMENT = ZO_SimpleSceneFragment:New(ZO_GamepadGuildHomeTopLevel)
GAMEPAD_GUILD_HOME_FRAGMENT:SetHideOnSceneHidden(true)

GAMEPAD_DYEING_FRAGMENT = ZO_FadeSceneFragment:New(ZO_DyeGamepadTopLevel)
GAMEPAD_DYEING_FRAGMENT:SetHideOnSceneHidden(true)
GAMEPAD_DYEING_ROOT_FRAGMENT = ZO_CreateQuadrantConveyorFragment(ZO_DyeGamepadTopLevelMaskContainer)
GAMEPAD_DYEING_ITEMS_FRAGMENT = ZO_FadeSceneFragment:New(ZO_DyeGamepadTopLevelDyeItems)

GAMEPAD_INVENTORY_FRAGMENT = ZO_SimpleSceneFragment:New(ZO_GamepadInventoryTopLevel)
GAMEPAD_INVENTORY_FRAGMENT:SetHideOnSceneHidden(true)

GAMEPAD_EMOTES_FRAGMENT = ZO_FadeSceneFragment:New(ZO_GamepadPlayerEmoteTopLevel)

GAMEPAD_ENCHANTING_FRAGMENT = ZO_FadeSceneFragment:New(ZO_GamepadEnchantingTopLevel)
GAMEPAD_ENCHANTING_MODE_FRAGMENT = ZO_CreateQuadrantConveyorFragment(ZO_GamepadEnchantingTopLevelContainerMode)
GAMEPAD_ENCHANTING_INVENTORY_FRAGMENT = ZO_CreateQuadrantConveyorFragment(ZO_GamepadEnchantingTopLevelContainerInventory)

GAMEPAD_SKILLS_FRAGMENT = ZO_SimpleSceneFragment:New(ZO_GamepadSkillsTopLevel)
GAMEPAD_SKILLS_FRAGMENT:SetHideOnSceneHidden(true)
GAMEPAD_SKILLS_LINE_PREVIEW_FRAGMENT = ZO_FadeSceneFragment:New(ZO_GamepadSkillsLinePreview)

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
GAMEPAD_AVA_CAMPAIGN_INFO_FRAGMENT = ZO_FadeSceneFragment:New(ZO_CampaignBrowser_GamepadTopLevelCampaignInfo, ALWAYS_ANIMATE)
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