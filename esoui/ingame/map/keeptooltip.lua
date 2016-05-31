local LINE_SPACING = 3
local BORDER = 8
local MAX_WIDTH = 400
local NUM_RESOURCES = 3

local KEEP_TOOLTIP_NAME = ZO_ColorDef:New(GetInterfaceColor(INTERFACE_COLOR_TYPE_KEEP_TOOLTIP, KEEP_TOOLTIP_COLOR_NAME))
local KEEP_TOOLTIP_ATTACK_LINE = ZO_ColorDef:New(GetInterfaceColor(INTERFACE_COLOR_TYPE_KEEP_TOOLTIP, KEEP_TOOLTIP_COLOR_ATTACK_LINE))
local KEEP_TOOLTIP_NORMAL_LINE = ZO_ColorDef:New(GetInterfaceColor(INTERFACE_COLOR_TYPE_KEEP_TOOLTIP, KEEP_TOOLTIP_COLOR_NORMAL_LINE))
local KEEP_TOOLTIP_ACCESSIBLE = ZO_ColorDef:New(GetInterfaceColor(INTERFACE_COLOR_TYPE_KEEP_TOOLTIP, KEEP_TOOLTIP_COLOR_ACCESSIBLE))
local KEEP_TOOLTIP_NOT_ACCESSIBLE = ZO_ColorDef:New(GetInterfaceColor(INTERFACE_COLOR_TYPE_KEEP_TOOLTIP, KEEP_TOOLTIP_COLOR_NOT_ACCESSIBLE))
local KEEP_TOOLTIP_AT_KEEP = ZO_ColorDef:New(GetInterfaceColor(INTERFACE_COLOR_TYPE_KEEP_TOOLTIP, KEEP_TOOLTIP_COLOR_AT_KEEP))
local KEEP_TOOLTIP_OWNER = ZO_ColorDef:New(GetInterfaceColor(INTERFACE_COLOR_TYPE_KEEP_TOOLTIP, KEEP_TOOLTIP_COLOR_OWNER))
local KEEP_TOOLTIP_UNCLAIMED = ZO_ColorDef:New(GetInterfaceColor(INTERFACE_COLOR_TYPE_KEEP_TOOLTIP, KEEP_TOOLTIP_COLOR_UNCLAIMED))
local IMPERIAL_CITY_TOOLTIP_COLLECTIBLE_LOCKED = ZO_ColorDef:New(GetInterfaceColor(INTERFACE_COLOR_TYPE_MARKET_COLORS, MARKET_COLORS_ON_SALE))

local SMALL_KEEP_ICON_STRING = zo_iconFormatInheritColor("EsoUI/Art/AvA/AvA_tooltipIcon_keep.dds", 32, 32)

local function AddVerticalSpace(self, offsetY)
    self.extraSpace = offsetY
end

local function AddLine(self, text, color)
    local line = self.linePool:AcquireObject()
    line:SetHidden(false)
    line:SetDimensionConstraints(0, 0, MAX_WIDTH, 0)
    line:SetText(text)

    local r,g,b,a = color:UnpackRGBA()
    line:SetColor(r,g,b,a)

    local spacing = self.extraSpace or LINE_SPACING
    if(self.lastLine) then
        line:SetAnchor(TOPLEFT, self.lastLine, BOTTOMLEFT, 0, spacing)
    else
        line:SetAnchor(TOPLEFT, GetControl(self, "Name"), BOTTOMLEFT, 0, spacing)
    end

    self.extraSpace = nil
    self.lastLine = line

    local width, height = line:GetTextDimensions()

    if(width > self.width) then
        self.width = width
    end

    self.height = self.height + height + LINE_SPACING
end

local function Reset(self)
    self.linePool:ReleaseAllObjects()
    self.lastLine = nil
    self.width = 0
    self.height = 0
    self.extraSpace = nil
    self.keepId = nil
    self.districtIds = nil
    self.battlegroundContext = nil
    self.isLockedByLinkedCollectible = nil
    self.historyPercent = 1.0
end

local KEYBOARD_TEL_VAR_ICON_TEXT = zo_iconFormat("EsoUI/Art/currency/currency_telvar.dds", 16, 16)
local GAMEPAD_TEL_VAR_ICON_TEXT = zo_iconFormat("EsoUI/Art/currency/currency_telvar_32.dds", 24, 24)
local DISTRICT_BONUS_VALUE_FORMAT = GetString(SI_TOOLTIP_DISTRICT_TEL_VAR_BONUS_FORMAT)
local DISTRICT_BONUS_RESTRICTION_TEXT = GetString(SI_TOOLTIP_DISTRICT_TEL_VAR_BONUS_RESTRICTION_TEXT)

local function GetDistrictTelVarBonusText(keepId, battlegroundContext, keepAlliance)
    local telVarBonus = GetDistrictOwnershipTelVarBonusPercent(keepId, battlegroundContext)
    if telVarBonus > 0 then
        local telVarBonusText = zo_strformat(DISTRICT_BONUS_VALUE_FORMAT, telVarBonus)
        local captured = keepAlliance == GetUnitAlliance("player")
        local color = captured and KEEP_TOOLTIP_ACCESSIBLE or KEEP_TOOLTIP_UNCLAIMED
        return color:Colorize(telVarBonusText)
    end
    return nil
end

-- Keep Layout --
-----------------
local function LayoutKeepTooltip(self, keepId, battlegroundContext, historyPercent)
    self:Reset()
    self.keepId = keepId
    self.battlegroundContext = battlegroundContext
    self.historyPercent = historyPercent

    local keepName = GetKeepName(keepId)

    if(keepName) then
        local nameControl = GetControl(self, "Name")
        nameControl:SetText(zo_strformat(SI_TOOLTIP_KEEP_NAME, keepName))
        nameControl:SetColor(KEEP_TOOLTIP_NAME:UnpackRGBA())
        local width, height = nameControl:GetTextDimensions()
        self.width = width
        self.height = height                
    
        --Alliance Owner Name
        local alliance = GetHistoricalKeepAlliance(keepId, battlegroundContext, historyPercent)
        local allianceName
        local allianceColor = GetAllianceColor(alliance)
        if(alliance == ALLIANCE_NONE) then
            allianceName = GetString(SI_KEEP_UNCLAIMED)
        else
            allianceName = GetAllianceName(alliance)
        end
        local text = zo_strformat(GetString(SI_TOOLTIP_KEEP_ALLIANCE_OWNER), allianceColor:Colorize(allianceName))
        AddLine(self, text, KEEP_TOOLTIP_NORMAL_LINE)

        local notHistorical = historyPercent >= 1.0
        if notHistorical then
            local keepType = GetKeepType(keepId)

            --Guild Owner Name
            if(IsKeepTypeClaimable(keepType)) then
                local guildName = GetClaimedKeepGuildName(keepId, battlegroundContext)
                local color = KEEP_TOOLTIP_NAME
                if(guildName == "") then
                    guildName = GetString(SI_KEEP_UNCLAIMED_GUILD)
                    color = KEEP_TOOLTIP_UNCLAIMED
                end
                guildName = color:Colorize(guildName)
                text = zo_strformat(GetString(SI_TOOLTIP_KEEP_GUILD_OWNER), guildName)
                AddLine(self, text, KEEP_TOOLTIP_NORMAL_LINE)
            end

            -- siege weapons
            if(keepType ~= KEEPTYPE_ARTIFACT_GATE and keepType ~= KEEPTYPE_IMPERIAL_CITY_DISTRICT) then
                local playerAlliance = GetUnitAlliance("player")
                local playerAllianceName = zo_strformat(SI_MAP_KEEP_INFO_ALLIANCE_TOOLTIP_FORMAT, GetColoredAllianceName(playerAlliance))
                local maxSiegeWeapons = GetMaxKeepSieges(keepId, battlegroundContext)
                -- always show players alliance weapons
                local numPlayerSiegeWeapons = GetNumSieges(keepId, battlegroundContext, playerAlliance)
                text = zo_strformat(GetString(SI_TOOLTIP_KEEP_SIEGE_WEAPON), playerAllianceName, numPlayerSiegeWeapons, maxSiegeWeapons)
                AddLine(self, text, KEEP_TOOLTIP_NORMAL_LINE)
                -- show siege weapons for each alliance if non zero
                for i = 1, NUM_ALLIANCES do
                    if(i ~= playerAlliance) then
                        local numSiegeWeapons = GetNumSieges(keepId, battlegroundContext, i)
                        if(numSiegeWeapons > 0) then
                            local allianceName = zo_strformat(SI_MAP_KEEP_INFO_ALLIANCE_TOOLTIP_FORMAT, GetColoredAllianceName(i))
                            text = zo_strformat(GetString(SI_TOOLTIP_KEEP_SIEGE_WEAPON), allianceName, numSiegeWeapons, maxSiegeWeapons)
                            AddLine(self, text, KEEP_TOOLTIP_NORMAL_LINE)
                        end
                    end
                end
            end

            --Artifact Info
            if(keepType == KEEPTYPE_ARTIFACT_KEEP) then
                local objectiveId = GetKeepArtifactObjectiveId(keepId)
                if(objectiveId ~= 0) then
                    local text
                    local _, artifactType, artifactState, alliance1, alliance2 = GetAvAObjectiveInfo(keepId, objectiveId, battlegroundContext)
                    if(artifactType == OBJECTIVE_ARTIFACT_OFFENSIVE) then
                        text = zo_strformat(SI_TOOLTIP_ARTIFACT_TYPE_OFFENSIVE)
                    else
                        text = zo_strformat(SI_TOOLTIP_ARTIFACT_TYPE_DEFENSIVE)
                    end
                    AddLine(self, text, KEEP_TOOLTIP_NORMAL_LINE)

                    --it's held by the enemy
                    if(artifactState ~= OBJECTIVE_CONTROL_STATE_FLAG_AT_BASE) then
                        AddLine(self, GetString(SI_TOOLTIP_ARTIFACT_TAKEN), KEEP_TOOLTIP_ATTACK_LINE)
                    end
                end
            end
            
            --Tel Var Bonus Info
            if(keepType == KEEPTYPE_IMPERIAL_CITY_DISTRICT) then
                local telVarBonusText = GetDistrictTelVarBonusText(keepId, battlegroundContext, alliance)
                if telVarBonusText then
                    local finalBonusText = zo_strformat(SI_TOOLTIP_DISTRICT_TEL_VAR_BONUS_TEXT, telVarBonusText, KEYBOARD_TEL_VAR_ICON_TEXT)
                    AddLine(self, finalBonusText, KEEP_TOOLTIP_NORMAL_LINE)
                    AddLine(self, DISTRICT_BONUS_RESTRICTION_TEXT, KEEP_TOOLTIP_NORMAL_LINE)
                end
            end

            --Keep Fast Travel Status
            local startingKeep = GetKeepFastTravelInteraction()
            if(startingKeep) then
                AddVerticalSpace(self, 5)
                if(keepId == startingKeep) then
                    AddLine(self, GetString(SI_TOOLTIP_KEEP_STARTING_KEEP), KEEP_TOOLTIP_AT_KEEP)
                else
                    local bgContext =  ZO_WorldMap_GetBattlegroundQueryType()

                    if(GetKeepAccessible(keepId, bgContext)) then
                        AddLine(self, GetString(SI_TOOLTIP_KEEP_ACCESSIBLE), KEEP_TOOLTIP_ACCESSIBLE)
                    else
                        local playerAlliance = GetUnitAlliance("player")
                        if(keepType ~= KEEPTYPE_KEEP and keepType ~= KEEPTYPE_BORDER_KEEP and keepType ~= KEEPTYPE_OUTPOST) then
                            AddLine(self, GetString(SI_TOOLTIP_KEEP_NOT_ACCESSIBLE), KEEP_TOOLTIP_NOT_ACCESSIBLE)
                        elseif(playerAlliance ~= alliance) then
                            AddLine(self, GetString(SI_TOOLTIP_KEEP_NOT_ACCESSIBLE_WRONG_OWNER), KEEP_TOOLTIP_NOT_ACCESSIBLE)
                        elseif(showUnderAttackLine) then
                            AddLine(self, GetString(SI_TOOLTIP_KEEP_NOT_ACCESSIBLE_UNDER_ATTACK), KEEP_TOOLTIP_NOT_ACCESSIBLE)
                            showUnderAttackLine = false
                        elseif GetKeepUnderAttack(startingKeep, battlegroundContext) then
                            AddLine(self, GetString(SI_TOOLTIP_KEEP_STARTING_KEEP_UNDER_ATTACK), KEEP_TOOLTIP_NOT_ACCESSIBLE)
                        elseif(not GetKeepHasResourcesForTravel(keepId, bgContext)) then
                            AddLine(self, GetString(SI_TOOLTIP_KEEP_NOT_ACCESSIBLE_RESOURCES), KEEP_TOOLTIP_NOT_ACCESSIBLE)
                        elseif(not GetKeepHasResourcesForTravel(startingKeep, bgContext)) then
                            AddLine(self, GetString(SI_TOOLTIP_KEEP_STARTING_KEEP_RESOURCES), KEEP_TOOLTIP_NOT_ACCESSIBLE)
                        else
                            AddLine(self, GetString(SI_TOOLTIP_KEEP_NOT_ACCESSIBLE_NETWORK), KEEP_TOOLTIP_NOT_ACCESSIBLE)
                        end
                    end
                end
            end
        end

        --Keep Under Attack
        local showUnderAttackLine = GetHistoricalKeepUnderAttack(keepId, battlegroundContext, historyPercent)
        if(showUnderAttackLine) then
            AddLine(self, GetString(SI_TOOLTIP_KEEP_IN_COMBAT), KEEP_TOOLTIP_ATTACK_LINE)
        end

        if(ZO_WorldMap_GetMode() == MAP_MODE_AVA_RESPAWN and IsLocalBattlegroundContext(battlegroundContext)) then
            if(CanRespawnAtKeep(keepId)) then
                AddLine(self, GetString(SI_TOOLTIP_KEEP_RESPAWNABLE), KEEP_TOOLTIP_ACCESSIBLE)
            else
                AddLine(self, GetString(SI_TOOLTIP_KEEP_NOT_RESPAWNABLE), KEEP_TOOLTIP_NOT_ACCESSIBLE)
            end
        end
    end

    self.width = self.width + BORDER * 2
    self.height = self.height + BORDER * 2
    self:SetDimensions(self.width, self.height)
end

local function LayoutKeepOwnerSection_Gamepad(self, baseSection, header, icon, name, ...)
    local ownerSection = baseSection:AcquireSection(self.tooltip:GetStyle("mapKeepGroupSection"))
    self:LayoutIconStringLine(ownerSection, nil, header, self.tooltip:GetStyle("mapLocationTooltipContentHeader"))
    self:LayoutIconStringLine(ownerSection, icon, name, ...)
    baseSection:AddSection(ownerSection)
end

local function LayoutKeepActionLine_Gamepad(self, section, formatString, usable)
    if usable then
        local keyText = ZO_Keybindings_GetKeyText(KEY_GAMEPAD_BUTTON_1)
        self:LayoutIconStringLine(section, nil, zo_strformat(formatString, keyText), self.tooltip:GetStyle("mapKeepAccessible"), self.tooltip:GetStyle("keepBaseTooltipContent"))
    else
        self:LayoutIconStringLine(section, nil, GetString(SI_TOOLTIP_KEEP_NOT_RESPAWNABLE), self.tooltip:GetStyle("mapKeepInaccessible"), self.tooltip:GetStyle("keepBaseTooltipContent"))
    end
end

local function LayoutKeepTooltip_Gamepad(self, keepId, battlegroundContext, historyPercent)
    local keepName = GetKeepName(keepId)

    local keepSection = self.tooltip:AcquireSection(self.tooltip:GetStyle("mapKeepSection"))

    if keepName then
        self:LayoutIconStringLine(keepSection, nil, zo_strformat(SI_TOOLTIP_KEEP_NAME, keepName), self.tooltip:GetStyle("mapTitle"))

        local showUnderAttackLine = GetHistoricalKeepUnderAttack(keepId, battlegroundContext, historyPercent)
        local keepType = GetKeepType(keepId)
        local keepAlliance = GetHistoricalKeepAlliance(keepId, battlegroundContext, historyPercent)

        --Keep Fast Travel Status
        local startingKeep = GetKeepFastTravelInteraction()
        if startingKeep then
            if keepId == startingKeep then
                self:LayoutIconStringLine(keepSection, nil, GetString(SI_TOOLTIP_KEEP_STARTING_KEEP), self.tooltip:GetStyle("mapKeepAt"), self.tooltip:GetStyle("keepBaseTooltipContent"))
            else
                local bgContext =  ZO_WorldMap_GetBattlegroundQueryType()

                if GetKeepAccessible(keepId, bgContext) then
                    local USABLE = true
                    LayoutKeepActionLine_Gamepad(self, keepSection, SI_GAMEPAD_WORLD_MAP_TOOLTIP_KEEP_ACCESSIBLE, USABLE)
                else
                    local playerAlliance = GetUnitAlliance("player")
                    if (keepType ~= KEEPTYPE_KEEP) and (keepType ~= KEEPTYPE_BORDER_KEEP) and (keepType ~= KEEPTYPE_OUTPOST) then
                        self:LayoutIconStringLine(keepSection, nil, GetString(SI_TOOLTIP_KEEP_NOT_ACCESSIBLE), self.tooltip:GetStyle("mapKeepInaccessible"), self.tooltip:GetStyle("keepBaseTooltipContent"))
                    elseif playerAlliance ~= keepAlliance then
                        self:LayoutIconStringLine(keepSection, nil, GetString(SI_TOOLTIP_KEEP_NOT_ACCESSIBLE_WRONG_OWNER), self.tooltip:GetStyle("mapKeepInaccessible"), self.tooltip:GetStyle("keepBaseTooltipContent"))
                    elseif showUnderAttackLine then
                        self:LayoutIconStringLine(keepSection, nil, GetString(SI_TOOLTIP_KEEP_NOT_ACCESSIBLE_UNDER_ATTACK), self.tooltip:GetStyle("mapKeepInaccessible"), self.tooltip:GetStyle("keepBaseTooltipContent"))
                        showUnderAttackLine = false
                    elseif GetKeepUnderAttack(startingKeep, battlegroundContext) then
                        self:LayoutIconStringLine(keepSection, nil, GetString(SI_TOOLTIP_KEEP_STARTING_KEEP_UNDER_ATTACK), self.tooltip:GetStyle("mapKeepInaccessible"), self.tooltip:GetStyle("keepBaseTooltipContent"))
                    elseif(not GetKeepHasResourcesForTravel(keepId, bgContext)) then
                        self:LayoutIconStringLine(keepSection, nil, GetString(SI_TOOLTIP_KEEP_NOT_ACCESSIBLE_RESOURCES), self.tooltip:GetStyle("mapKeepInaccessible"), self.tooltip:GetStyle("keepBaseTooltipContent"))
                    elseif(not GetKeepHasResourcesForTravel(startingKeep, bgContext)) then
                        self:LayoutIconStringLine(keepSection, nil, GetString(SI_TOOLTIP_KEEP_STARTING_KEEP_RESOURCES), self.tooltip:GetStyle("mapKeepInaccessible"), self.tooltip:GetStyle("keepBaseTooltipContent"))
                    else
                        self:LayoutIconStringLine(keepSection, nil, GetString(SI_TOOLTIP_KEEP_NOT_ACCESSIBLE_NETWORK), self.tooltip:GetStyle("mapKeepInaccessible"), self.tooltip:GetStyle("keepBaseTooltipContent"))
                    end
                end
            end
        end

        --Keep Under Attack
        if(showUnderAttackLine) then
            self:LayoutIconStringLine(keepSection, nil, GetString(SI_TOOLTIP_KEEP_IN_COMBAT), self.tooltip:GetStyle("mapKeepUnderAttack"))
        end

        -- Respawn
        if (ZO_WorldMap_GetMode() == MAP_MODE_AVA_RESPAWN) and IsLocalBattlegroundContext(battlegroundContext) then
            LayoutKeepActionLine_Gamepad(self, keepSection, SI_GAMEPAD_WORLD_MAP_TOOLTIP_KEEP_RESPAWNABLE, CanRespawnAtKeep(keepId))
        end

        --Alliance Owner Name
        if(keepAlliance == ALLIANCE_NONE) then
            LayoutKeepOwnerSection_Gamepad(self, keepSection, GetString(SI_GAMEPAD_WORLD_MAP_TOOLTIP_ALLIANCE_OWNER), nil, GetString(SI_KEEP_UNCLAIMED), self.tooltip:GetStyle("mapLocationKeepUnclaimed"))
        else
            local allianceIcon = GetLargeAllianceSymbolIcon(keepAlliance)
            local allianceName = zo_strformat(SI_MAP_KEEP_INFO_ALLIANCE_TOOLTIP_FORMAT, GetColoredAllianceName(keepAlliance))
            LayoutKeepOwnerSection_Gamepad(self, keepSection, GetString(SI_GAMEPAD_WORLD_MAP_TOOLTIP_ALLIANCE_OWNER), allianceIcon, allianceName, self.tooltip:GetStyle("mapLocationKeepClaimed"))
        end
        
        local notHistorical = historyPercent >= 1.0
        if notHistorical then
            --Guild Owner Name
            if IsKeepTypeClaimable(keepType) then
                local guildName = GetClaimedKeepGuildName(keepId, battlegroundContext)
                if guildName == "" then
                    LayoutKeepOwnerSection_Gamepad(self, keepSection, GetString(SI_GAMEPAD_WORLD_MAP_TOOLTIP_GUILD_OWNER), nil, GetString(SI_KEEP_UNCLAIMED_GUILD), self.tooltip:GetStyle("mapLocationKeepUnclaimed"))
                else
                    LayoutKeepOwnerSection_Gamepad(self, keepSection, GetString(SI_GAMEPAD_WORLD_MAP_TOOLTIP_GUILD_OWNER), nil, guildName, self.tooltip:GetStyle("mapLocationKeepClaimed"))
                end
            end

            -- Siege Weapons
            if(keepType ~= KEEPTYPE_ARTIFACT_GATE and keepType ~= KEEPTYPE_IMPERIAL_CITY_DISTRICT) then
                local maxSiegeWeapons = GetMaxKeepSieges(keepId, battlegroundContext)

                -- Always show players alliance weapons.
                local playerAlliance = GetUnitAlliance("player")
                local playerAllianceIcon = GetLargeAllianceSymbolIcon(playerAlliance)
                local playerAllianceName = zo_strformat(SI_MAP_KEEP_INFO_ALLIANCE_TOOLTIP_FORMAT, GetColoredAllianceName(playerAlliance))

                local weaponsSection = keepSection:AcquireSection(self.tooltip:GetStyle("mapKeepGroupSection"))
                self:LayoutIconStringLine(weaponsSection, nil, GetString(SI_GAMEPAD_WORLD_MAP_TOOLTIP_SIEGE_WEAPONS), self.tooltip:GetStyle("mapLocationTooltipContentHeader"))

                local numPlayerSiegeWeapons = GetNumSieges(keepId, battlegroundContext, playerAlliance)
                local playerSiegeWeaponsText = zo_strformat(SI_GAMEPAD_WORLD_MAP_TOOLTIP_SIEGE, numPlayerSiegeWeapons, maxSiegeWeapons)
                playerSiegeWeaponsText = GetAllianceColor(playerAlliance):Colorize(playerSiegeWeaponsText)
                self:LayoutIconStringRightStringLine(weaponsSection, playerAllianceIcon, playerSiegeWeaponsText, playerAllianceName, self.tooltip:GetStyle("mapLocationKeepClaimed"))

                -- Show siege weapons for other alliances, if non-zero.
                for i = 1, NUM_ALLIANCES do
                    if(i ~= playerAlliance) then
                        local numSiegeWeapons = GetNumSieges(keepId, battlegroundContext, i)
                        if numSiegeWeapons > 0 then
                            local allianceIcon = GetLargeAllianceSymbolIcon(i)
                            local allianceName = zo_strformat(SI_MAP_KEEP_INFO_ALLIANCE_TOOLTIP_FORMAT, GetColoredAllianceName(i))

                            local siegeWeaponsText = zo_strformat(SI_GAMEPAD_WORLD_MAP_TOOLTIP_SIEGE, numSiegeWeapons, maxSiegeWeapons)
                            self:LayoutIconStringRightStringLine(weaponsSection, allianceIcon, allianceName, siegeWeaponsText, self.tooltip:GetStyle("mapLocationKeepClaimed"))
                        end
                    end
                end

                keepSection:AddSection(weaponsSection)
            end

            --Artifact Info
            if(keepType == KEEPTYPE_ARTIFACT_KEEP) then
                local objectiveId = GetKeepArtifactObjectiveId(keepId)
                if(objectiveId ~= 0) then
                    local text
                    local artifactName, artifactType, artifactState, alliance1, alliance2 = GetAvAObjectiveInfo(keepId, objectiveId, battlegroundContext)
                    if(artifactType == OBJECTIVE_ARTIFACT_OFFENSIVE) then
                        text = GetString(SI_GAMEPAD_WORLD_MAP_TOOLTIP_SCROLL_OFFENSIVE)
                    else
                        text = GetString(SI_GAMEPAD_WORLD_MAP_TOOLTIP_SCROLL_DEFENSIVE)
                    end
                    local isStolen = (artifactState ~= OBJECTIVE_CONTROL_STATE_FLAG_AT_BASE)

                    local colorStyle = isStolen and self.tooltip:GetStyle("mapArtifactStolen") or self.tooltip:GetStyle("mapArtifactNormal")

                    local artifactSection = keepSection:AcquireSection(self.tooltip:GetStyle("mapKeepGroupSection"))
                    if isStolen then
                        self:LayoutIconStringLine(artifactSection, nil, GetString(SI_TOOLTIP_ARTIFACT_TAKEN), colorStyle, self.tooltip:GetStyle("mapLocationTooltipContentHeader"))
                    else
                        self:LayoutIconStringLine(artifactSection, nil, zo_strformat(SI_AVA_OBJECTIVE_ARTIFACT_TOOLTIP, artifactName), colorStyle, self.tooltip:GetStyle("mapLocationTooltipContentHeader"))
                    end
                    self:LayoutIconStringLine(artifactSection, nil, text, colorStyle, self.tooltip:GetStyle("mapLocationKeepElderScrollInfo"))
                    keepSection:AddSection(artifactSection)
                end
            end

            --Tel Var Bonus Info
            if(keepType == KEEPTYPE_IMPERIAL_CITY_DISTRICT) then
                local telVarBonusText = GetDistrictTelVarBonusText(keepId, battlegroundContext, keepAlliance)
                if telVarBonusText then
                    local finalBonusText = zo_strformat(SI_GAMEPAD_WORLD_MAP_TOOLTIP_DISTRICT_TEL_VAR_BONUS_TEXT_FORMAT, telVarBonusText, GAMEPAD_TEL_VAR_ICON_TEXT)
                    local cityBonusSection = keepSection:AcquireSection(self.tooltip:GetStyle("mapKeepGroupSection"))
                    self:LayoutIconStringLine(cityBonusSection, nil, GetString(SI_GAMEPAD_WORLD_MAP_TOOLTIP_DISTRICT_TEL_VAR_BONUS_HEADER), self.tooltip:GetStyle("mapLocationTooltipContentHeader"))
                    self:LayoutIconStringLine(cityBonusSection, nil, finalBonusText, self.tooltip:GetStyle("mapLocationKeepClaimed"), self.tooltip:GetStyle("keepBaseTooltipContent"))
                    self:LayoutIconStringLine(cityBonusSection, nil, DISTRICT_BONUS_RESTRICTION_TEXT, self.tooltip:GetStyle("mapLocationKeepClaimed"), self.tooltip:GetStyle("keepBaseTooltipContent"))
                    keepSection:AddSection(cityBonusSection)
                end
            end
        end
    end

    self.tooltip:AddSection(keepSection)
end

local function RefreshKeepInfo(self)
    if(self.keepId and self.battlegroundContext and self.historyPercent) then
        LayoutKeepTooltip(self, self.keepId, self.battlegroundContext, self.historyPercent)
    end
end

-- Imperial City Layout --
--------------------------
local function GetImperialCityStrings(campaignId, isLockedByLinkedCollectible)
    --Name--
    local name = zo_strformat(SI_TOOLTIP_KEEP_NAME, GetMapNameByIndex(GetImperialCityMapIndex()))

    --Access rule--
    local rulesetId = GetCampaignRulesetId(campaignId)
    local accessType = GetCampaignRulesetImperialAccessRule(rulesetId)
    local ruleText = GetString("SI_IMPERIALCITYACCESSRULESTYPE", accessType)
    if accessType ~= IMPERIAL_CITY_ACCESS_RULE_TYPE_MAJORITY_KEEPS then
        local totalNativeKeeps = select(4, GetAvAKeepScore(campaignId, GetUnitAlliance("player")))
        ruleText = zo_strformat(ruleText, totalNativeKeeps)
    end

    --Locked--
    local lockedText
    if isLockedByLinkedCollectible then
        local collectibleId = GetImperialCityCollectibleId()
        local categoryName, collectibleName = ZO_GetCollectibleCategoryAndName(collectibleId)
        lockedText = zo_strformat(SI_TOOLTIP_POI_LINKED_COLLECTIBLE_LOCKED, collectibleName, categoryName)
    end

    return name, ruleText, lockedText
end

local function LayoutImperialCityTooltip(self, battlegroundContext, isLockedByLinkedCollectible, historyPercent)
    self:Reset()
    self.battlegroundContext = battlegroundContext
    self.isLockedByLinkedCollectible = isLockedByLinkedCollectible
    self.historyPercent = historyPercent

    local campaignId = GetPreferredCampaign()
    local name, ruleText, lockedText = GetImperialCityStrings(campaignId, isLockedByLinkedCollectible)

    --Name--
    local nameControl = GetControl(self, "Name")
    nameControl:SetText(name)
    nameControl:SetColor(KEEP_TOOLTIP_NAME:UnpackRGBA())
    local width, height = nameControl:GetTextDimensions()
    self.width = width
    self.height = height

    --Access rule--
    AddLine(self, ruleText, KEEP_TOOLTIP_NORMAL_LINE)

    --Alliance access to city rows--
    for i = 1, NUM_ALLIANCES do
        local allianceColor = GetAllianceColor(i)
        local allianceIcon = zo_iconFormatInheritColor(GetAllianceSymbolIcon(i), 28, 28)
        allianceIcon = allianceColor:Colorize(allianceIcon)
        local allianceName = GetAllianceName(i)
        local hasAccess = DoesAllianceHaveImperialCityAccess(campaignId, i)
        local accessColor = hasAccess and KEEP_TOOLTIP_ACCESSIBLE or KEEP_TOOLTIP_NOT_ACCESSIBLE

        if accessType == IMPERIAL_CITY_ACCESS_RULE_TYPE_MAJORITY_KEEPS then
            local keepsHeld = accessColor:Colorize(GetAvAKeepsHeld(campaignId, i))
            local keepIcon = allianceColor:Colorize(SMALL_KEEP_ICON_STRING)
            AddLine(self, zo_strformat(SI_TOOLTIP_IMPERIAL_CITY_ACCESS_ROW_MAJORITY, allianceName, keepsHeld, keepIcon), KEEP_TOOLTIP_OWNER)
        else
            local accessText = GetString(hasAccess and SI_TOOLTIP_IMPERIAL_CITY_UNLOCKED or SI_TOOLTIP_IMPERIAL_CITY_LOCKED)
            accessText = accessColor:Colorize(accessText)
            AddLine(self, zo_strformat(SI_TOOLTIP_IMPERIAL_CITY_ACCESS_ROW_NATIVE, allianceIcon, allianceName, accessText), KEEP_TOOLTIP_OWNER)
        end
    end

    if lockedText then
        AddLine(self, lockedText, IMPERIAL_CITY_TOOLTIP_COLLECTIBLE_LOCKED)
    end

    self.width = self.width + BORDER * 2
    self.height = self.height + BORDER * 2
    self:SetDimensions(self.width, self.height)
end

local function LayoutImperialCityTooltip_Gamepad(self, battlegroundContext, isLockedByLinkedCollectible, historyPercent)
    local citySection = self.tooltip:AcquireSection(self.tooltip:GetStyle("mapKeepSection"))
    local campaignId = GetPreferredCampaign()
    local name, ruleText, lockedText = GetImperialCityStrings(campaignId, isLockedByLinkedCollectible)

    --Name--
    self:LayoutIconStringLine(citySection, nil, name, self.tooltip:GetStyle("mapTitle"))

    --Access rule--
    local accessRuleSection = citySection:AcquireSection(self.tooltip:GetStyle("mapKeepGroupSection"))
    self:LayoutIconStringLine(accessRuleSection, nil, ruleText, self.tooltip:GetStyle("keepBaseTooltipContent"))
    citySection:AddSection(accessRuleSection)

    --Alliance access to city rows--
    local unlockedSection
    local lockedSection
    for i = 1, NUM_ALLIANCES do
        local allianceIcon = GetLargeAllianceSymbolIcon(i)
        local allianceName = zo_strformat(SI_MAP_KEEP_INFO_ALLIANCE_TOOLTIP_FORMAT, GetColoredAllianceName(i))
        local hasAccess = DoesAllianceHaveImperialCityAccess(campaignId, i)

        if hasAccess then
            if not unlockedSection then
                unlockedSection = citySection:AcquireSection(self.tooltip:GetStyle("mapKeepGroupSection"))
                self:LayoutIconStringLine(unlockedSection, nil, GetString(SI_TOOLTIP_IMPERIAL_CITY_UNLOCKED), self.tooltip:GetStyle("mapLocationTooltipContentHeader"))
            end
            self:LayoutIconStringLine(unlockedSection, allianceIcon, allianceName, self.tooltip:GetStyle("mapLocationKeepClaimed"))
        else
            if not lockedSection then
                lockedSection = citySection:AcquireSection(self.tooltip:GetStyle("mapKeepGroupSection"))
                self:LayoutIconStringLine(lockedSection, nil, GetString(SI_TOOLTIP_IMPERIAL_CITY_LOCKED), self.tooltip:GetStyle("mapLocationTooltipContentHeader"))
            end
            self:LayoutIconStringLine(lockedSection, allianceIcon, allianceName, self.tooltip:GetStyle("mapLocationKeepClaimed"))
        end
    end

    if unlockedSection then
        citySection:AddSection(unlockedSection)
    end

    if lockedSection then
        citySection:AddSection(lockedSection)
    end

    if lockedText then
        local collectibleLockedSection = citySection:AcquireSection(self.tooltip:GetStyle("mapKeepGroupSection"))
        self:LayoutIconStringLine(collectibleLockedSection, ZO_GAMEPAD_CURRENCY_ICON_CROWNS_TEXTURE, lockedText, self.tooltip:GetStyle("mapLocationTooltipWayshrineLinkedCollectibleLockedText"))
        citySection:AddSection(collectibleLockedSection)
    end
    self.tooltip:AddSection(citySection)
end

local function RefreshCityInfo(self)
    if(self.battlegroundContext and self.historyPercent) then
        LayoutImperialCityTooltip(self, self.battlegroundContext, self.isLockedByLinkedCollectible, self.historyPercent)
    end
end

local function LayoutForwardCamp(self, graveyardIndex, battlegroundContext, usable)
    self:Reset()

    local nameControl = GetControl(self, "Name")
    nameControl:SetText(GetString(SI_TOOLTIP_FORWARD_CAMP))
    nameControl:SetColor(KEEP_TOOLTIP_NAME:UnpackRGBA())
    local width, height = nameControl:GetTextDimensions()
    self.width = width
    self.height = height

    local allianceName = GetAllianceName(GetUnitAlliance("player"))
    local text = zo_strformat(GetString(SI_TOOLTIP_KEEP_ALLIANCE_OWNER), allianceName)
    AddLine(self, text, KEEP_TOOLTIP_NORMAL_LINE)

    if(IsForwardCampGuildOwned(battlegroundContext, graveyardIndex)) then
        local guildNameText = GetForwardCampOwnerName(battlegroundContext, graveyardIndex)
        if(guildNameText ~= nil) then
            local fullText = zo_strformat(GetString(SI_TOOLTIP_KEEP_GUILD_OWNER), guildNameText)
            AddLine(self, fullText, KEEP_TOOLTIP_NORMAL_LINE)
        end
    end

    if(ZO_WorldMap_GetMode() == MAP_MODE_AVA_RESPAWN) then
        local tooltipText = SI_TOOLTIP_FORWARD_CAMP_RESPAWN
        local tooltipColor = KEEP_TOOLTIP_ACCESSIBLE
        if (not usable) then
            tooltipText = SI_TOOLTIP_KEEP_NOT_RESPAWNABLE
            tooltipColor = KEEP_TOOLTIP_NOT_ACCESSIBLE
        end
        AddLine(self, GetString(tooltipText), tooltipColor)
    end

    self.width = self.width + BORDER * 2
    self.height = self.height + BORDER * 2
    self:SetDimensions(self.width, self.height)
end

local function LayoutForwardCamp_Gamepad(self, graveyardIndex, battlegroundContext, usable)
    local campSection = self.tooltip:AcquireSection(self.tooltip:GetStyle("mapLocationTooltipSection"))

    -- Respawn
    if ZO_WorldMap_GetMode() == MAP_MODE_AVA_RESPAWN then
        LayoutKeepActionLine_Gamepad(self, campSection, SI_GAMEPAD_WORLD_MAP_TOOLTIP_KEEP_RESPAWNABLE, usable)
    end

    -- Alliance Owner
    local playerAlliance = GetUnitAlliance("player")
    local allianceIcon = GetLargeAllianceSymbolIcon(playerAlliance)
    local allianceName = zo_strformat(SI_MAP_KEEP_INFO_ALLIANCE_TOOLTIP_FORMAT, GetColoredAllianceName(playerAlliance))
    LayoutKeepOwnerSection_Gamepad(self, campSection, GetString(SI_GAMEPAD_WORLD_MAP_TOOLTIP_ALLIANCE_OWNER), allianceIcon, allianceName, self.tooltip:GetStyle("mapLocationKeepClaimed"))

    -- Guild Owner
    if IsForwardCampGuildOwned(battlegroundContext, graveyardIndex) then
        local guildName = GetForwardCampOwnerName(battlegroundContext, graveyardIndex)
        if guildName then
            LayoutKeepOwnerSection_Gamepad(self, campSection, GetString(SI_GAMEPAD_WORLD_MAP_TOOLTIP_GUILD_OWNER), nil, guildName, self.tooltip:GetStyle("mapLocationKeepClaimed"))
        end
    end

    self.tooltip:AddSection(campSection)
end

local function SetOwner(self, owner, point, offsetX, offsetY)
    self:ClearAnchors()
    if(point == TOPLEFT) then
        self:SetAnchor(TOPLEFT, owner, BOTTOMLEFT, offsetX, offsetY)
    elseif(point == TOPRIGHT) then
        self:SetAnchor(TOPRIGHT, owner, BOTTOMRIGHT, offsetX, offsetY)
    elseif(point == BOTTOMLEFT) then
        self:SetAnchor(BOTTOMLEFT, owner, TOPLEFT, offsetX, offsetY)
    else
        self:SetAnchor(BOTTOMRIGHT, owner, TOPRIGHT, offsetX, offsetY)
    end
end

local function GetWidth(self)
    return self.width
end

function ZO_KeepTooltip_OnInitialized(self)
    self.linePool = ZO_ControlPool:New("ZO_KeepTooltipLine", self, "Line")
    self.SetKeep = LayoutKeepTooltip
    self.RefreshKeepInfo = RefreshKeepInfo
    self.SetForwardCamp = LayoutForwardCamp
    self.SetOwner = SetOwner
    self.GetWidth = GetWidth
    self.Reset = Reset
end

function ZO_ImperialCityTooltip_OnInitialized(self)
    self.linePool = ZO_ControlPool:New("ZO_KeepTooltipLine", self, "Line")
    self.SetCity = LayoutImperialCityTooltip
    self.RefreshCityInfo = RefreshCityInfo
    self.SetOwner = SetOwner
    self.GetWidth = GetWidth
    self.Reset = Reset
end

function ZO_KeepTooltip_Gamepad_OnInitialized(self)
    self.SetKeep = LayoutKeepTooltip_Gamepad
    self.RefreshKeepInfo = RefreshKeepInfo
    self.SetForwardCamp = LayoutForwardCamp_Gamepad
    self.SetCity = LayoutImperialCityTooltip_Gamepad
    self.RefreshCityInfo = RefreshCityInfo
end
