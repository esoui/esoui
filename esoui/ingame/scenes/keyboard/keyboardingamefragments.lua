TRADE_FRAGMENT = ZO_FadeSceneFragment:New(ZO_Trade)
GROUP_MENU_FRAGMENT = ZO_FadeSceneFragment:New(ZO_GroupMenu_Keyboard)
DYEING_FRAGMENT = ZO_FadeSceneFragment:New(ZO_DyeingTopLevel)
ACHIEVEMENTS_FRAGMENT = ZO_FadeSceneFragment:New(ZO_Achievements)
CADWELLS_ALMANAC_FRAGMENT = ZO_FadeSceneFragment:New(ZO_Cadwell)
STABLES_MENU_FRAGMENT = ZO_FadeSceneFragment:New(ZO_StableWindowMenu)
DLC_BOOK_FRAGMENT = ZO_FadeSceneFragment:New(ZO_DLCBook_Keyboard)
HOUSING_BOOK_FRAGMENT = ZO_FadeSceneFragment:New(ZO_HousingBook_Keyboard)
HOUSING_FURNITURE_BROWSER_MENU_FRAGMENT = ZO_FadeSceneFragment:New(ZO_HousingFurnitureBrowserMenu_KeyboardTopLevel)

RIGHT_BG_ITEM_PREVIEW_OPTIONS_FRAGMENT = ZO_ItemPreviewOptionsFragment:New({
    paddingLeft = 0,
    paddingRight = 950,
    dynamicFramingConsumedWidth = 1150,
    dynamicFramingConsumedHeight = 300,
    forcePreparePreview = false,
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
