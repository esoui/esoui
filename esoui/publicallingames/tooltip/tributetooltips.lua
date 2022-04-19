-- optionalDockCardUpgradeContext should be a table from ZO_TributePatronData:GetDockCards
function ZO_Tooltip:LayoutTributeCard(cardData, optionalDockCardUpgradeContext)
    local patronData = TRIBUTE_DATA_MANAGER:GetTributePatronData(cardData:GetPatronDefId())

    -- Header
    local topSection = self:AcquireSection(self:GetStyle("collectionsTopSection"))

    local cardTypeString = GetString("SI_TRIBUTECARDTYPE", cardData:GetCardType())
    if cardData:IsContract() then
        topSection:AddLine(zo_strformat(SI_TRIBUTE_CARD_TYPE_CONTRACT, cardTypeString))
    else
        topSection:AddLine(cardTypeString)
    end

    topSection:AddLine(patronData:GetFormattedNameAndSuitIcon())
    topSection:AddLine(GetString(SI_TRIBUTE_CARD_ITEM_TYPE))
    self:AddSection(topSection)

    -- Title
    local titleSection = self:AcquireSection(self:GetStyle("title"))
    local itemDisplayQuality = cardData:GetRarity()
    local qualityColor = GetItemQualityColor(itemDisplayQuality)
    titleSection:AddLine(cardData:GetFormattedName(), { fontColor = qualityColor })

    local costResourceType, acquireCost = cardData:GetAcquireCost()
    if acquireCost > 0 then
        local acquirePair = titleSection:AcquireStatValuePair(self:GetStyle("statValuePair"))
        acquirePair:SetStat(GetString("SI_TRIBUTERESOURCE_ACQUIRE", costResourceType), self:GetStyle("statValuePairStat"))
        acquirePair:SetValue(acquireCost, self:GetStyle("statValuePairValue"))
        titleSection:AddStatValuePair(acquirePair)
    end

    local defeatResourceType, defeatCost = cardData:GetDefeatCost()
    if defeatCost > 0 then
        local defeatPair = titleSection:AcquireStatValuePair(self:GetStyle("statValuePair"))
        defeatPair:SetStat(GetString("SI_TRIBUTERESOURCE_DEFEAT", defeatResourceType), self:GetStyle("statValuePairStat"))
        defeatPair:SetValue(defeatCost, self:GetStyle("statValuePairValue"))
        titleSection:AddStatValuePair(defeatPair)
    end

    self:AddSection(titleSection)

    -- Tribute Mechanics
    local function AddPlayMechanics()
        local ACTIVATION_TRIGGER = TRIBUTE_MECHANIC_TRIGGER_ACTIVATION
        local numMechanics = cardData:GetNumMechanics(ACTIVATION_TRIGGER)
        if numMechanics > 0 then
            local activationSection = self:AcquireSection(self:GetStyle("bodySection"))
            activationSection:AddLine(GetString(SI_TRIBUTE_CARD_PLAY_EFFECT), self:GetStyle("bodyHeader"))
            if cardData:DoesChooseOneMechanic() then
                activationSection:AddLine(GetString(SI_TRIBUTE_CARD_CHOOSE_ONE_MECHANIC), self:GetStyle("tributeBodyText"), self:GetStyle("tributeChooseOneText"))
            end
            local PREPEND_ICON = true
            for index = 1, numMechanics do
                local mechanicText = cardData:GetMechanicText(ACTIVATION_TRIGGER, index, PREPEND_ICON)
                activationSection:AddLine(mechanicText, self:GetStyle("tributeBodyText"))
            end
            self:AddSection(activationSection)
        end
    end

    local function AddComboMechanics()
        local COMBO_TRIGGER = TRIBUTE_MECHANIC_TRIGGER_COMBO
        local numMechanics = cardData:GetNumMechanics(COMBO_TRIGGER)
        if numMechanics > 0 then
            local comboSection = nil
            local mechanicsProcessed = 0
            for currentComboIndex = 1, numMechanics do
                local currentComboNum = select(3, cardData:GetMechanicInfo(COMBO_TRIGGER, currentComboIndex))
                local isHeaderShown = false
                local PREPEND_ICON = true
                
                for index = 1, numMechanics do
                    local mechanicComboNum = select(3, cardData:GetMechanicInfo(COMBO_TRIGGER, index))
                    if currentComboNum == mechanicComboNum then
                        if not isHeaderShown then
                            local headerText = zo_strformat(SI_TRIBUTE_CARD_COMBO_EFFECT, currentComboNum)
                            if comboSection then
                                self:AddSection(comboSection)
                            end
                            comboSection = self:AcquireSection(self:GetStyle("bodySection"))
                            comboSection:AddLine(headerText, self:GetStyle("bodyHeader"))
                            isHeaderShown = true
                        end
                        local mechanicText = cardData:GetMechanicText(COMBO_TRIGGER, index, PREPEND_ICON)
                        comboSection:AddLine(mechanicText, self:GetStyle("tributeBodyText"))

                        mechanicsProcessed = mechanicsProcessed + 1
                        if mechanicsProcessed == numMechanics then
                            self:AddSection(comboSection)
                            return
                        end
                    end
                end
            end
        end
    end

    AddPlayMechanics()

    AddComboMechanics()

    -- Tribute Actions
    if cardData:DoesTaunt() then
        local section = self:AcquireSection(self:GetStyle("bodySection"))
        section:AddLine(GetString(SI_TRIBUTE_CARD_TAUNT_TITLE), self:GetStyle("bodyHeader"))
        section:AddLine(GetString(SI_TRIBUTE_CARD_TAUNT_DESCRIPTION), self:GetStyle("tributeBodyText"))
        self:AddSection(section)
    end

    -- Flavor Text
    local flavorText = cardData:GetFlavorText()
    if flavorText ~= "" then
        local section = self:AcquireSection(self:GetStyle("bodySection"))
        section:AddLine(zo_strformat(GetString(SI_TRIBUTE_CARD_TEXT_FORMATTER), cardData:GetFlavorText()), self:GetStyle("tributeBodyText"))
        self:AddSection(section)
    end

    -- Upgrade Information
    -- If the context has an upgradesTo, that means it's a base card, it has an upgrade, and we do not currently have the upgrade unlocked
    if optionalDockCardUpgradeContext and optionalDockCardUpgradeContext.upgradesTo then
        local section = self:AcquireSection(self:GetStyle("bodySection"))
        local upgradesToCardData = ZO_TributeCardData:New(cardData:GetPatronDefId(), optionalDockCardUpgradeContext.upgradesTo)
        section:AddLine(GetString(SI_TRIBUTE_PATRON_UPGRADE_TITLE), self:GetStyle("bodyHeader"))
        section:AddLine(zo_strformat(GetString(SI_TRIBUTE_CARD_AVAILABLE_UPGRADE_FORMATTER), cardData:GetColorizedName(), upgradesToCardData:GetColorizedName()), self:GetStyle("tributeBodyText"))
        section:AddLine(GetTributeCardUpgradeHintText(cardData:GetPatronDefId(), optionalDockCardUpgradeContext.cardIndex), self:GetStyle("tributeBodyText"))
        self:AddSection(section)
    end
end

function ZO_Tooltip:LayoutTributePatronFavorStateInfo(patronData, favorState)
    local requirementsText = patronData:GetRequirementsText(favorState)
    local mechanicsText = patronData:GetMechanicsText(favorState)

    if requirementsText ~= "" and mechanicsText ~= "" then
        local favorSection = self:AcquireSection(self:GetStyle("bodySection"))

        --Layout the title of the favor state
        local favorText = GetString("SI_TRIBUTEPATRONPERSPECTIVEFAVORSTATE", favorState)

        if favorState == TRIBUTE_PATRON_PERSPECTIVE_FAVOR_STATE_FAVORS_PLAYER then
            favorSection:AddLine(favorText, self:GetStyle("succeeded"), self:GetStyle("bodyHeader"))
        elseif favorState == TRIBUTE_PATRON_PERSPECTIVE_FAVOR_STATE_NEUTRAL then
            favorSection:AddLine(favorText, self:GetStyle("bodyHeader"))
        elseif favorState == TRIBUTE_PATRON_PERSPECTIVE_FAVOR_STATE_FAVORS_OPPONENT then
            favorSection:AddLine(favorText, self:GetStyle("failed"), self:GetStyle("bodyHeader"))
        else
            internalassert(false, "Unsupported Favor State")
        end

        local resultText = ""

        --Do not include the result string for neutral patrons
        if not patronData:IsNeutral() then
            local displayFavorState = favorState
            if patronData:DoesSkipNeutralFavorState() and favorState == TRIBUTE_PATRON_PERSPECTIVE_FAVOR_STATE_FAVORS_OPPONENT then
                displayFavorState = TRIBUTE_PATRON_PERSPECTIVE_FAVOR_STATE_NEUTRAL
            end
            resultText = GetString("SI_TRIBUTEPATRONPERSPECTIVEFAVORSTATE_RESULT", displayFavorState)
        end

        favorSection:AddLine(zo_strformat(GetString(SI_TRIBUTE_PATRON_TOOLTIP_FAVOR_DESCRIPTION_FORMATTER), requirementsText, mechanicsText, resultText), self:GetStyle("whiteFontColor"), self:GetStyle("bodyDescription"))
        self:AddSection(favorSection)
    end
end

function ZO_Tooltip:LayoutTributePatron(patronData)
    -- Header
    local topSection = self:AcquireSection(self:GetStyle("collectionsTopSection"))

    topSection:AddLine(GetString(SI_TRIBUTE_PATRON_TYPE))
    local collectionId = patronData:GetPatronCollectibleId()
    if patronData:IsNeutral() then
        topSection:AddLine(GetString("SI_TRIBUTEPATRONPERSPECTIVEFAVORSTATE", TRIBUTE_PATRON_PERSPECTIVE_FAVOR_STATE_NEUTRAL))
    else
        --Neutral patrons should never be collectible
        if collectionId ~= 0 then
            topSection:AddLine(GetString("SI_COLLECTIBLEUNLOCKSTATE", GetCollectibleUnlockStateById(collectionId)))
        end
    end
    self:AddSection(topSection)

    -- Title
    local titleSection = self:AcquireSection(self:GetStyle("title"))
    local itemDisplayQuality = patronData:GetRarity()
    local qualityColor = GetItemQualityColor(itemDisplayQuality)
    titleSection:AddLine(patronData:GetFormattedName(), { fontColor = qualityColor })
    self:AddSection(titleSection)

    self:LayoutTributePatronFavorStateInfo(patronData, TRIBUTE_PATRON_PERSPECTIVE_FAVOR_STATE_FAVORS_PLAYER)
    self:LayoutTributePatronFavorStateInfo(patronData, TRIBUTE_PATRON_PERSPECTIVE_FAVOR_STATE_NEUTRAL)
    self:LayoutTributePatronFavorStateInfo(patronData, TRIBUTE_PATRON_PERSPECTIVE_FAVOR_STATE_FAVORS_OPPONENT)

    -- Body
    local bodySection = self:AcquireSection(self:GetStyle("bodySection"))
    bodySection:AddLine(patronData:GetLoreDescription(), self:GetStyle("bodyDescription"))
    self:AddSection(bodySection)

    local infoSection = self:AcquireSection(self:GetStyle("bodySection"))
    if collectionId == 0 then
        infoSection:AddLine(GetString(SI_TRIBUTE_PATRON_TOOLTIP_NO_COLLECTIBLE), self:GetStyle("bodyDescription"), self:GetStyle("failed"))
    end
    self:AddSection(infoSection)
end

function ZO_Tooltip:LayoutTributeBoardLocationPatrons(boardLocationData)
    if boardLocationData:GetNumCards() == 0 then
        return
    end

    do
        local titleSection = self:AcquireSection(self:GetStyle("title"))
        local displayName = boardLocationData:GetName()
        titleSection:AddLine(displayName)
        self:AddSection(titleSection)
    end

    do
        local patronsSection = self:AcquireSection(self:GetStyle("bodySection"))
        local patronCardCountList = boardLocationData:GetPatronCardCountList()
        for _, patronCardCountData in ipairs(patronCardCountList) do
            local numCards = patronCardCountData.numCards
            local patronSuitIcon = patronCardCountData.patronData:GetPatronSuitIcon()
            local patronName = patronCardCountData.patronData:GetFormattedName()
            patronsSection:AddLine(zo_strformat(GetString(SI_TRIBUTE_PATRON_NAME_WITH_COUNT_AND_SUIT_ICON_FORMATTER), numCards, patronSuitIcon, patronName), self:GetStyle("whiteFontColor"), self:GetStyle("bodyDescription"))
        end
        self:AddSection(patronsSection)
    end
end