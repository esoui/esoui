local TIME_LEFT_STYLE = "ZO_ChapterUpgrade_TextCallout_TimeLeftStyle"
local ON_SALE_STYLE = "ZO_ChapterUpgrade_TextCallout_OnSaleStyle"
local NEW_STYLE = "ZO_ChapterUpgrade_TextCallout_NewStyle"

ZO_ChapterUpgradePane_Shared = ZO_Object:Subclass()

function ZO_ChapterUpgradePane_Shared:New(...)
    local object = ZO_Object.New(self)
    object:Initialize(...)
    return object
end

function ZO_ChapterUpgradePane_Shared:Initialize(control)
    self.control = control
    self.backgroundTexture = control:GetNamedChild("Background")
    self.titleLabel = control:GetNamedChild("Title")
    self.purchaseStateLabel = control:GetNamedChild("PurchaseState")
    self.textCalloutLabel = control:GetNamedChild("TextCallout")
    self.control:SetHandler("OnUpdate", function() self:UpdateTextCalloutLabel() end)
    self.releaseDateContainer = control:GetNamedChild("Release")
    self.releaseDateLabel = self.releaseDateContainer:GetNamedChild("Date")
end

function ZO_ChapterUpgradePane_Shared:SetChapterUpgradeData(data)
    self.chapterUpgradeData = data
    local isOwned = data:IsOwned()

    self.backgroundTexture:SetTexture(data:GetMarketBackgroundImage())
    self.backgroundTexture:SetDesaturation(isOwned and 1 or 0)

    local textColor = isOwned and ZO_MARKET_PRODUCT_PURCHASED_COLOR or ZO_MARKET_SELECTED_COLOR
    local r, g, b, a = textColor:UnpackRGBA()

    self.titleLabel:SetText(data:GetFormattedName())
    self.titleLabel:SetColor(r, g, b, a)

    self.purchaseStateLabel:SetText(GetString("SI_CHAPTERPURCHASESTATE", data:GetPurchasedState()))
    self.purchaseStateLabel:SetColor(r, g, b, a)

    if data:IsPreRelease() then
        self.releaseDateContainer:SetHidden(false)
        self.releaseDateLabel:SetText(data:GetReleaseDateText())
    else
        self.releaseDateContainer:SetHidden(true)
    end

    self:UpdateTextCalloutLabel()
end

do
    local NEW_STRING = GetString(SI_MARKET_TILE_CALLOUT_NEW)

    function ZO_ChapterUpgradePane_Shared:UpdateTextCalloutLabel()
        local textCalloutLabel = self.textCalloutLabel
        local hideTextCallout = true
        local chapterUpgradeData = self.chapterUpgradeData
        if chapterUpgradeData and not chapterUpgradeData:IsOwned() and chapterUpgradeData:HasMarketProductData() then
            local style = nil
            local modifyTextType = MODIFY_TEXT_TYPE_UPPERCASE
            local text = ""
            if chapterUpgradeData:IsLimitedTime() then
                style = TIME_LEFT_STYLE
                local remainingTime = chapterUpgradeData:GetLTOTimeLeftInSeconds()
                if remainingTime >= ZO_ONE_DAY_IN_SECONDS then
                    text = zo_strformat(SI_TIME_DURATION_LEFT, ZO_FormatTime(remainingTime, TIME_FORMAT_STYLE_SHOW_LARGEST_UNIT_DESCRIPTIVE, TIME_FORMAT_PRECISION_SECONDS))
                else
                    modifyTextType = MODIFY_TEXT_TYPE_NONE
                    text = zo_strformat(SI_TIME_DURATION_LEFT, ZO_FormatTimeLargestTwo(remainingTime, TIME_FORMAT_STYLE_DESCRIPTIVE_MINIMAL))
                end
            else
                local discountPercent = chapterUpgradeData:GetDiscountPercent()
                if discountPercent > 0 then
                    style = ON_SALE_STYLE
                    text = zo_strformat(SI_MARKET_DISCOUNT_PRICE_PERCENT_FORMAT, discountPercent)
                elseif chapterUpgradeData:IsNew() then
                    style = NEW_STYLE
                    text = NEW_STRING
                end
            end

            if style then
                hideTextCallout = false
                textCalloutLabel:SetModifyTextType(modifyTextType)
                textCalloutLabel:SetText(text)

                if textCalloutLabel.currentStyle ~= style then
                    ApplyTemplateToControl(textCalloutLabel, style)
                    textCalloutLabel.currentStyle = style
                end
            end
        end

        textCalloutLabel:SetHidden(hideTextCallout)
    end
end

function ZO_ChapterUpgradePane_Shared:PreviewSelection()
    local marketProductId = self:GetSelectedProductId()
    self:GetItemPreviewListHelper():PreviewMarketProduct(marketProductId)
end

function ZO_ChapterUpgradePane_Shared:CanPreviewSelection()
    local marketProductId = self:GetSelectedProductId()
    return self:GetItemPreviewListHelper():CanPreviewMarketProduct(marketProductId)
end

function ZO_ChapterUpgradePane_Shared:GetChapterUpgradeData()
    return self.chapterUpgradeData
end

function ZO_ChapterUpgradePane_Shared:GetSelectedProductId()
    assert(false) -- Must be overriden
end

function ZO_ChapterUpgradePane_Shared:GetItemPreviewListHelper()
    assert(false) -- Must be overriden
end

function ZO_ChapterUpgradeRewardEntry_Shared_OnInitialized(control)
    control.icon = control:GetNamedChild("Icon")
    control.displayName = control:GetNamedChild("DisplayName")
    control.standardCheckMark = control:GetNamedChild("StandardCheckMark")
    control.collectorsCheckMark = control:GetNamedChild("CollectorsCheckMark")
end
