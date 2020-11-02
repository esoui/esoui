function ZO_Tooltip:LayoutServiceTokenTooltip(tokenType)
    local tokenTypeString = GetString("SI_SERVICETOKENTYPE", tokenType)

    local headerSection = self:AcquireSection(self:GetStyle("bodyHeader"))
    local title = zo_strformat(SI_SERVICE_TOOLTIP_HEADER_FORMATTER, tokenTypeString)
    headerSection:AddLine(title, self:GetStyle("title"))
    self:AddSection(headerSection)

    local descriptionSection = self:AcquireSection(self:GetStyle("bodySection"))
    local tokenDescription = GetServiceTokenDescription(tokenType)
    descriptionSection:AddLine(tokenDescription, self:GetStyle("bodyDescription"))
    self:AddSection(descriptionSection)

    if tokenType == SERVICE_TOKEN_ALLIANCE_CHANGE then
        local anyRaceCollectibleId = GetAnyRaceAnyAllianceCollectibleId()
        local collectibleName = GetCollectibleName(anyRaceCollectibleId)
        local categoryName = GetCollectibleCategoryNameByCollectibleId(anyRaceCollectibleId)
        local tokensAvailableText = zo_strformat(SI_SERVICE_TOOLTIP_REQUIRES_COLLECTIBLE_TO_USE, collectibleName, categoryName)

        local meetsRequirementTextStyle
        local numTokens = GetNumServiceTokens(tokenType)
        if CanPlayAnyRaceAsAnyAlliance() then
            meetsRequirementTextStyle = self:GetStyle("succeeded")
        else
            meetsRequirementTextStyle = self:GetStyle("failed")
        end

        local requiredCollectibleSection = self:AcquireSection(self:GetStyle("bodySection"))
        requiredCollectibleSection:AddLine(tokensAvailableText, self:GetStyle("bodyDescription"), meetsRequirementTextStyle)
        self:AddSection(requiredCollectibleSection)
    end

    local tokensAvailableText
    local tokensAvailableTextStyle
    local numTokens = GetNumServiceTokens(tokenType)
    if numTokens ~= 0 then
        tokensAvailableText = zo_strformat(SI_SERVICE_TOOLTIP_SERVICE_TOKENS_AVAILABLE, numTokens, tokenTypeString)
        tokensAvailableTextStyle = self:GetStyle("succeeded")
    else
        tokensAvailableText = zo_strformat(SI_SERVICE_TOOLTIP_NO_SERVICE_TOKENS_AVAILABLE, tokenTypeString)
        tokensAvailableTextStyle = self:GetStyle("failed")
    end

    local tokenSection = self:AcquireSection(self:GetStyle("bodySection"))
    tokenSection:AddLine(tokensAvailableText, self:GetStyle("bodyDescription"), tokensAvailableTextStyle)
    self:AddSection(tokenSection)
end
