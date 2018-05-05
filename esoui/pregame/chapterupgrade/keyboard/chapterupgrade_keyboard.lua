
local ChapterUpgrade_Keyboard = ZO_ChapterUpgrade_Shared:Subclass()

function ChapterUpgrade_Keyboard:New(...)
    return ZO_ChapterUpgrade_Shared.New(self, ...)
end

function ChapterUpgrade_Keyboard:Initialize(control)
    ZO_ChapterUpgrade_Shared.Initialize(self, control, "chapterUpgradeKeyboard")
    local serviceType = GetPlatformServiceType()
    if serviceType == PLATFORM_SERVICE_TYPE_DMM or serviceType == PLATFORM_SERVICE_TYPE_STEAM then
        -- We don't have access to any sort of code entry on these platforms, so just hide the controls
        local enterCodeButton = control:GetNamedChild("EnterCodeButton")
        enterCodeButton:SetHidden(true)
        local textContainer = control:GetNamedChild("TextContainer")
    end
end

function ChapterUpgrade_Keyboard:UpgradeButtonClicked()
    local IS_STANDARD_EDITION = false
    ZO_ShowChapterUpgradePlatformDialog(IS_STANDARD_EDITION, CHAPTER_UPGRADE_SOURCE_PREGAME)
end

local ACCOUNT_PAGE_TEXT_PARAMS = { mainTextParams = { GetString(SI_ESO_ACCOUNT_PAGE_LINK_TEXT) }}

function ChapterUpgrade_Keyboard:EnterCodeButtonClicked()
    ZO_Dialogs_ShowDialog("SHOW_REDEEM_CODE", nil, ACCOUNT_PAGE_TEXT_PARAMS)
end

function ZO_ChapterUpgrade_Keyboard_OnInitialized(control)
    CHAPTER_UPGRADE_SCREEN_KEYBOARD = ChapterUpgrade_Keyboard:New(control)
end