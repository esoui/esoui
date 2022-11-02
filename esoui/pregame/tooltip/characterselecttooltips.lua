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

do
    local function GetFormattedLevel(characterData)
        local gamepadIconString = "EsoUI/Art/Champion/Gamepad/gp_champion_icon.dds"
        local formattedIcon = zo_iconFormat(gamepadIconString, "100%", "100%")
        if characterData.championPoints and characterData.championPoints > 0 then
            return zo_strformat(SI_CHARACTER_SELECT_LEVEL_CHAMPION, formattedIcon, characterData.championPoints)
        else
            return zo_strformat(SI_CHARACTER_SELECT_LEVEL_VALUE, characterData.level)
        end
    end

    local function GetFormattedRace(characterData)
        local raceName = characterData.race and GetRaceName(characterData.gender, characterData.race) or GetString(SI_UNKNOWN_RACE)
        return zo_strformat(SI_CHARACTER_SELECT_RACE, raceName)
    end

    local function GetFormattedClass(characterData)
        local className = characterData.class and GetClassName(characterData.gender, characterData.class) or GetString(SI_UNKNOWN_CLASS)
        return zo_strformat(SI_CHARACTER_SELECT_CLASS, className)
    end

    local function GetFormattedAlliance(characterData)
        local allianceName = GetAllianceName(characterData.alliance) or GetString(SI_UNKNOWN_CLASS)
        return zo_strformat(SI_CHARACTER_SELECT_ALLIANCE, allianceName)
    end

    local function GetFormattedLocation(characterData)
        local locationName = characterData.location ~= 0 and GetLocationName(characterData.location) or GetString(SI_UNKNOWN_LOCATION)
        return zo_strformat(SI_CHARACTER_SELECT_LOCATION, locationName)
    end

    function ZO_Tooltip:LayoutCharacterDetailsTooltip(characterData)
        local name = ZO_CharacterSelect_Manager_GetFormattedCharacterName(characterData)
        self:AddLine(name, self:GetStyle("characterDetailsHeader"))

        local detailsSection = self:AcquireSection(self:GetStyle("characterDetailsStatsSection"))

        local characterLevelPair = detailsSection:AcquireStatValuePair(self:GetStyle("statValuePair"), self:GetStyle("fullWidth"))
        characterLevelPair:SetStat(GetString(SI_CHARACTER_SELECT_LEVEL), self:GetStyle("statValuePairStat"))
        characterLevelPair:SetValue(GetFormattedLevel(characterData), self:GetStyle("statValuePairValue"))
        detailsSection:AddStatValuePair(characterLevelPair)

        local characterRacePair = detailsSection:AcquireStatValuePair(self:GetStyle("statValuePair"), self:GetStyle("fullWidth"))
        characterRacePair:SetStat(GetString(SI_CHARACTER_SELECT_RACE_LABEL), self:GetStyle("statValuePairStat"))
        characterRacePair:SetValue(GetFormattedRace(characterData), self:GetStyle("statValuePairValue"))
        detailsSection:AddStatValuePair(characterRacePair)

        local characterClassPair = detailsSection:AcquireStatValuePair(self:GetStyle("statValuePair"), self:GetStyle("fullWidth"))
        characterClassPair:SetStat(GetString(SI_CHARACTER_SELECT_CLASS_LABEL), self:GetStyle("statValuePairStat"))
        characterClassPair:SetValue(GetFormattedClass(characterData), self:GetStyle("statValuePairValue"))
        detailsSection:AddStatValuePair(characterClassPair)

        local characterAlliancePair = detailsSection:AcquireStatValuePair(self:GetStyle("statValuePair"), self:GetStyle("fullWidth"))
        characterAlliancePair:SetStat(GetString(SI_CHARACTER_SELECT_ALLIANCE_LABEL), self:GetStyle("statValuePairStat"))
        characterAlliancePair:SetValue(GetFormattedAlliance(characterData), self:GetStyle("statValuePairValue"))
        detailsSection:AddStatValuePair(characterAlliancePair)

        local characterLocationPair = detailsSection:AcquireStatValuePair(self:GetStyle("statValuePair"), self:GetStyle("fullWidth"))
        characterLocationPair:SetStat(GetString(SI_CHARACTER_SELECT_LOCATION_LABEL), self:GetStyle("statValuePairStat"))
        characterLocationPair:SetValue(GetFormattedLocation(characterData), self:GetStyle("statValuePairValue"))
        detailsSection:AddStatValuePair(characterLocationPair)

        self:AddSection(detailsSection)
    end
end
