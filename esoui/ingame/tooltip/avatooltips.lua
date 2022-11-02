function ZO_Tooltip:LayoutAvABonus(data)
    local headerSection = self:AcquireSection(self:GetStyle("bodyHeader"))
    headerSection:AddLine(data.name, self:GetStyle("title"))

    local infoData = data.dataSource.infoData
    if infoData then
        if infoData.stringId and infoData.value then
            local bonusStatValuePair = headerSection:AcquireStatValuePair(self:GetStyle("statValuePair"))
            bonusStatValuePair:SetStat(GetString(infoData.stringId), self:GetStyle("statValuePairStat"))
            bonusStatValuePair:SetValue(infoData.value, self:GetStyle("statValuePairValue"))
            headerSection:AddStatValuePair(bonusStatValuePair)
        elseif infoData.stringId then
            headerSection:AddLine(GetString(infoData.stringId), self:GetStyle("statValuePairStat"))
        end
    end

    local detailsText = data.dataSource.detailsText
    if detailsText ~= "" then
        headerSection:AddLine(detailsText, self:GetStyle("statValuePairStat"))
    end

    self:AddSection(headerSection)

    local bodySection = self:AcquireSection(self:GetStyle("bodySection"))
    local bonusIcon
    if IsInGamepadPreferredMode() then
        bonusIcon = zo_iconFormat(data.typeIconGamepad, 32, 32)
    else
        bonusIcon = zo_iconFormat(data.typeIcon, 40, 40)
    end

    -- emperor does't have a count, just an icon
    if data.countText then
        bodySection:AddLine(zo_strformat(SI_GAMEPAD_CAMPAIGN_BONUSES_DESCRIPTION_HEADER_WITH_AMOUNT, bonusIcon, data.countText), self:GetStyle("bodyHeader"))
    else
        bodySection:AddLine(zo_strformat(SI_GAMEPAD_CAMPAIGN_BONUSES_DESCRIPTION_HEADER_WITHOUT_AMOUNT, bonusIcon), self:GetStyle("bodyHeader"))
    end

    bodySection:AddLine(data.description, self:GetStyle("bodyDescription"))
    self:AddSection(bodySection)
end