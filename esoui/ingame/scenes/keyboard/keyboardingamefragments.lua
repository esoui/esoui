TRADE_FRAGMENT = ZO_FadeSceneFragment:New(ZO_Trade)
GROUP_MENU_FRAGMENT = ZO_FadeSceneFragment:New(ZO_GroupMenu_Keyboard)
ACHIEVEMENTS_FRAGMENT = ZO_FadeSceneFragment:New(ZO_Achievements)
CADWELLS_ALMANAC_FRAGMENT = ZO_FadeSceneFragment:New(ZO_Cadwell)
STABLES_MENU_FRAGMENT = ZO_FadeSceneFragment:New(ZO_StableWindowMenu)
DLC_BOOK_FRAGMENT = ZO_FadeSceneFragment:New(ZO_DLCBook_Keyboard)
HOUSING_BOOK_FRAGMENT = ZO_FadeSceneFragment:New(ZO_HousingBook_Keyboard)
HOUSING_FURNITURE_BROWSER_MENU_FRAGMENT = ZO_FadeSceneFragment:New(ZO_HousingFurnitureBrowserMenu_KeyboardTopLevel)
ANTIQUITY_JOURNAL_FRAGMENT = ZO_FadeSceneFragment:New(ZO_AntiquityJournal_Keyboard_TopLevel)
ANTIQUITY_LORE_FRAGMENT = ZO_FadeSceneFragment:New(ZO_AntiquityLore_Keyboard_TopLevel)
ANTIQUITY_LORE_READER_FRAGMENT = ZO_FadeSceneFragment:New(ZO_AntiquityLoreReader_Keyboard_TopLevel)
HOUSING_PATH_SETTINGS_FRAGMENT = ZO_FadeSceneFragment:New(ZO_HousingPathSettingsMenu_KeyboardTopLevel)

CROWN_STORE_TITLE_FRAGMENT = ZO_SetTitleFragment:New(SI_CROWN_STORE_TITLE)

RIGHT_BG_ITEM_PREVIEW_OPTIONS_FRAGMENT = ZO_ItemPreviewOptionsFragment:New({
    paddingLeft = 0,
    paddingRight = 950,
    dynamicFramingConsumedWidth = 1150,
    dynamicFramingConsumedHeight = 300,
    forcePreparePreview = false,
})

RIGHT_BG_FORCE_PREPARE_ITEM_PREVIEW_OPTIONS_FRAGMENT = ZO_ItemPreviewOptionsFragment:New({
    paddingLeft = 0,
    paddingRight = 950,
    dynamicFramingConsumedWidth = 1150,
    dynamicFramingConsumedHeight = 300,
    forcePreparePreview = true,
})

RIGHT_BG_EMPTY_WORLD_ITEM_PREVIEW_OPTIONS_FRAGMENT = ZO_ItemPreviewOptionsFragment:New({
    paddingLeft = 0,
    paddingRight = 950,
    dynamicFramingConsumedWidth = 1150,
    dynamicFramingConsumedHeight = 300,
    previewInEmptyWorld = true,
})

FURNITURE_BROWSER_ITEM_PREVIEW_OPTIONS_FRAGMENT = ZO_ItemPreviewOptionsFragment:New({
    paddingLeft = 0,
    paddingRight = 950,
    dynamicFramingConsumedWidth = 950,
    dynamicFramingConsumedHeight = 80,
    previewInEmptyWorld = true,
    forcePreparePreview = false,
})

CRAFTING_PREVIEW_OPTIONS_FRAGMENT = ZO_ItemPreviewOptionsFragment:New({
    paddingLeft = 245,
    paddingRight = 605,
    dynamicFramingConsumedWidth = 1050,
    dynamicFramingConsumedHeight = 300,
    previewInEmptyWorld = true,
})

RIGHT_PANEL_BG_EMPTY_WORLD_ITEM_PREVIEW_OPTIONS_FRAGMENT = ZO_ItemPreviewOptionsFragment:New({
    paddingLeft = 0,
    paddingRight = 550,
    dynamicFramingConsumedWidth = 550,
    dynamicFramingConsumedHeight = 300,
    previewInEmptyWorld = true,
    forcePreparePreview = false,
})

RESTYLE_PREVIEW_OPTIONS_FRAGMENT = ZO_ItemPreviewOptionsFragment:New({
    paddingLeft = 350,
    paddingRight = 950,
    dynamicFramingConsumedWidth = 1350,
    dynamicFramingConsumedHeight = 300,
    forcePreparePreview = false,
})

STATS_OUTFIT_PREVIEW_OPTIONS_FRAGMENT = ZO_ItemPreviewOptionsFragment:New({
    paddingLeft = 0,
    paddingRight = 680,
    dynamicFramingConsumedWidth = 1250,
    dynamicFramingConsumedHeight = 300,
    forcePreparePreview = false,
})

COMPANION_MENU_PREVIEW_OPTIONS_FRAGMENT = ZO_ItemPreviewOptionsFragment:New({
    paddingLeft = 200,
    paddingRight = 950,
    dynamicFramingConsumedWidth = 1050,
    dynamicFramingConsumedHeight = 300,
    forcePreparePreview = false,
})

COLLECTIBLE_PREVIEW_OPTIONS_FRAGMENT = ZO_ItemPreviewOptionsFragment:New({
    paddingLeft = 0,
    paddingRight = 950,
    dynamicFramingConsumedWidth = 1050,
    dynamicFramingConsumedHeight = 300,
    forcePreparePreview = false,
})

PROMOTIONAL_EVENTS_PREVIEW_OPTIONS_FRAGMENT = ZO_ItemPreviewOptionsFragment:New({
    paddingLeft = 0,
    paddingRight = 950,
    dynamicFramingConsumedWidth = 1050,
    dynamicFramingConsumedHeight = 300,
    forcePreparePreview = false,
})