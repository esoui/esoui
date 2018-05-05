-- InternalIngame

function ZO_ShowChapterUpgradePlatformScreen(marketOpenSource, chapterUpgradeId)
    chapterUpgradeId = chapterUpgradeId or GetCurrentChapterUpgradeId()
    if IsInGamepadPreferredMode() then
        RequestShowGamepadChapterUpgrade(chapterUpgradeId)
    else
        SYSTEMS:GetObject(ZO_MARKET_NAME):RequestShowMarket(marketOpenSource, OPEN_MARKET_BEHAVIOR_SHOW_CHAPTER_UPGRADE, chapterUpgradeId)
    end
end
