-- Ingame

function ZO_ShowChapterUpgradePlatformScreen(marketOpenSource, chapterUpgradeId)
    chapterUpgradeId = chapterUpgradeId or GetCurrentChapterUpgradeId()
    if IsInGamepadPreferredMode() then
        ZO_CHAPTER_UPGRADE_GAMEPAD:RequestShowChapterUpgrade(chapterUpgradeId)
    else
        RequestShowMarketChapterUpgrade(marketOpenSource, chapterUpgradeId)
    end
end
