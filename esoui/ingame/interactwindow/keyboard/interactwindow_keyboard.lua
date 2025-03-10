local CHATTER_OPTION_INDENT = 30

local REWARD_STRIDE = 3
local REWARD_PADDING_X = 10
local REWARD_PADDING_Y = 10
local REWARD_ROOT_OFFSET_X = 0
local REWARD_ROOT_OFFSET_Y = 10
ZO_REWARD_SIZE_X = 275
ZO_REWARD_SIZE_Y = 56

local ENABLED_PLAYER_OPTION_COLOR = ZO_ColorDef:New(GetInterfaceColor(INTERFACE_COLOR_TYPE_TEXT_COLORS, INTERFACE_TEXT_COLOR_CHATTER_PLAYER_OPTION))
local SEEN_PLAYER_OPTION_COLOR = ZO_ColorDef:New(GetInterfaceColor(INTERFACE_COLOR_TYPE_GENERAL, INTERFACE_GENERAL_COLOR_DISABLED))
local DISABLED_PLAYER_OPTION_COLOR = ZO_ERROR_COLOR
local DISABLED_UNUSABLE_PLAYER_OPTION_COLOR = ZO_DISABLED_TEXT

--Keyboard Interaction
---------------------

ZO_Interaction = ZO_SharedInteraction:Subclass()

function ZO_Interaction:New(...)
    local interaction = ZO_SharedInteraction.New(self)
    interaction:Initialize(...)
    return interaction
end

function ZO_Interaction:Initialize(control)
    self.control = control
    self.sceneName = "interaction"

    ZO_SharedInteraction.Initialize(self, control)

    self:InitInteraction()

    local function OnStateChange(oldState, newState)
        if(newState == SCENE_HIDDEN) then
            ZO_SharedInteraction.OnHidden(self)
        end
    end

    local interactScene = self:CreateInteractScene("interact")
    interactScene:RegisterCallback("StateChange", OnStateChange)

    SYSTEMS:RegisterKeyboardObject(ZO_INTERACTION_SYSTEM_NAME, self)

    self:OnScreenResized()
end

function ZO_Interaction:InitInteraction()

    self.titleControl = self.control:GetNamedChild("TargetAreaTitle")
    self.chatterOptionName = "ZO_ChatterOption"
    self.questRewardName = "ZO_QuestReward"
    self.currencyTemplateName = "ZO_CurrencyTemplate"

    --create options
    CreateControlRangeFromVirtual(self.chatterOptionName, self.control:GetNamedChild("PlayerAreaOptions"), self.chatterOptionName, 1, MAX_CHATTER_OPTIONS)

    self.optionControls = {}

    local currentAnchor = ZO_Anchor:New(TOPLEFT, ZO_InteractWindowPlayerAreaOptions, TOPLEFT, CHATTER_OPTION_INDENT, 0)
    for i = 1, MAX_CHATTER_OPTIONS do
        local currentOption = GetControl(self.chatterOptionName, i)
        self.optionControls[i] = currentOption

        currentOption:SetHidden(true)

        currentAnchor:Set(currentOption)
        currentAnchor:SetTarget(currentOption)
        currentAnchor:SetOffsets(0, 8)
        currentAnchor:SetRelativePoint(BOTTOMLEFT)
    end

    --create rewards
    self.givenRewardPool = ZO_ControlPool:New(self.questRewardName, self.control:GetNamedChild("CollapseContainerRewardArea"), "Given")
    self.currencyRewardPool = ZO_ControlPool:New(self.currencyTemplateName, self.control:GetNamedChild("CollapseContainerRewardArea"), "Currency")
end

function ZO_Interaction:ResetInteraction(bodyText)
    self.titleControl:SetText(zo_strformat(GetString(SI_INTERACT_TITLE_FORMAT), GetUnitName("interact")))

    self.control:GetNamedChild("TargetAreaBodyText"):SetText(bodyText)

    for i = 1, MAX_CHATTER_OPTIONS do
        local option = self.optionControls[i]
        option:SetHandler("OnUpdate", nil)
        option.optionIndex = nil
        option:SetHidden(true)
    end

    self.givenRewardPool:ReleaseAllObjects()
    self.currencyRewardPool:ReleaseAllObjects()

    self.control:GetNamedChild("CollapseContainerRewardArea"):SetHidden(true)
    self.control:GetNamedChild("CollapseContainerRewardArea"):SetHeight(0)
end

local INTERACTION_AREA_PERC_WIDTH = 0.4
local INTERACTION_AREA_RIGHT_OFFSET_PERC = 0.0534

function ZO_Interaction:OnScreenResized()
    local uiWidth, uiHeight = GuiRoot:GetDimensions()

    local divider = self.control:GetNamedChild("Divider")
    divider:ClearAnchors()
    divider:SetAnchor(RIGHT, GuiRoot, TOPRIGHT, -uiWidth * INTERACTION_AREA_RIGHT_OFFSET_PERC, uiHeight * .5)

    local interactionElementWidth = uiWidth * INTERACTION_AREA_PERC_WIDTH

    divider:SetWidth(interactionElementWidth)

    for i = 1, MAX_CHATTER_OPTIONS do
        local currentOption = GetControl(self.chatterOptionName, i)
        currentOption:SetWidth(interactionElementWidth - CHATTER_OPTION_INDENT)
    end
end

function ZO_Interaction:DimOtherImportantOptions(chatterControl)
    for i, control in ipairs(self.importantOptions) do
        if control ~= chatterControl then
            control:SetColor(DISABLED_PLAYER_OPTION_COLOR:UnpackRGBA())
        end
    end
end

function ZO_Interaction:RestoreOtherImportantOptions(chatterControl)
    for i, control in ipairs(self.importantOptions) do
        if control ~= chatterControl then
            if control.chosenBefore then
                control:SetColor(SEEN_PLAYER_OPTION_COLOR:UnpackRGBA())
            elseif control.enabled then
                control:SetColor(ENABLED_PLAYER_OPTION_COLOR:UnpackRGBA())
            else
                control:SetColor(DISABLED_PLAYER_OPTION_COLOR:UnpackRGBA())
            end
        end
    end
end

local function DisableChatterOption(option, useDisabledColor, optionUsable)
    if useDisabledColor and not optionUsable then
        option:SetColor(DISABLED_UNUSABLE_PLAYER_OPTION_COLOR:UnpackRGBA())
    elseif useDisabledColor then
        option:SetColor(DISABLED_PLAYER_OPTION_COLOR:UnpackRGBA())
    end

    GetControl(option, "IconImage"):SetDesaturation(1)
    option.enabled = false
end

local function EnableChatterOption(option)
    if(option.chosenBefore) then
        option:SetColor(SEEN_PLAYER_OPTION_COLOR:UnpackRGBA())
    else
        option:SetColor(ENABLED_PLAYER_OPTION_COLOR:UnpackRGBA())
    end
    GetControl(option, "IconImage"):SetDesaturation(0)
    option.enabled = true
end

function ZO_Interaction:PopulateChatterOption(controlID, optionIndex, optionText, optionType, optionalArg, isImportant, chosenBefore, importantOptions, teleportNPCId, teleportWaypointIdTable, dialogueTone)
    local optionControl = self.optionControls[controlID]
    optionControl:SetHidden(false)

    local chatterData = self:GetChatterOptionData(optionIndex, optionText, optionType, optionalArg, isImportant, chosenBefore, teleportNPCId, teleportWaypointIdTable, dialogueTone)

    optionControl.optionIndex = chatterData.optionIndex
    optionControl.optionType = chatterData.optionType
    optionControl.isImportant = chatterData.isImportant
    optionControl.chosenBefore = chatterData.chosenBefore
    optionControl.teleportNPC = chatterData.teleportNPC
    optionControl.teleportWaypointIdTable = chatterData.teleportWaypointIdTable
    optionControl.gold = chatterData.gold
    optionControl.optionText = chatterData.optionText

    if optionControl.isImportant then
        importantOptions[#importantOptions + 1] = optionControl
        TriggerTutorial(TUTORIAL_TRIGGER_IMPORTANT_DIALOGUE)
    end

    if chatterData.optionsEnabled then

        if chatterData.optionUsable then
            EnableChatterOption(optionControl)
        else
            DisableChatterOption(optionControl, chatterData.recolorIfUnusable, chatterData.optionUsable)
        end

        optionControl:SetText(chatterData.optionText)
        optionControl:SetHandler("OnUpdate", chatterData.labelUpdateFunction)

        local icon = optionControl:GetNamedChild("IconImage")

        icon:ClearIcons()
        for iconIndex, iconFile in pairs(chatterData.iconFiles) do
            icon:AddIcon(iconFile)
        end
        icon:Show()

        local _, textHeight = optionControl:GetTextDimensions()
        return textHeight
    end

    return 0
end

function ZO_Interaction:AnchorBottomBG(optionControl)
    -- NOTE: The -10 and 120 come from the XML offset...see how $(parent)TopBG is set up.
    self.control:GetNamedChild("BottomBG"):ClearAnchors()
    self.control:GetNamedChild("BottomBG"):SetAnchor(TOPRIGHT, GuiRoot, RIGHT)
    self.control:GetNamedChild("BottomBG"):SetAnchor(BOTTOMLEFT, optionControl, BOTTOMLEFT, -10 - CHATTER_OPTION_INDENT, 120)
end

function ZO_Interaction:FinalizeChatterOptions(optionCount)
    self:AnchorBottomBG(self.optionControls[optionCount])
end

function ZO_Interaction:UpdateChatterOptions(optionCount, backToTOCOption)

    self.optionCount, self.importantOptions = self:PopulateChatterOptions(optionCount, backToTOCOption)

    if #self.importantOptions > 0 and self.currentMouseLabel then
        self:DimOtherImportantOptions(self.currentMouseLabel)
    end
end

function ZO_Interaction:SelectChatterOptionByIndex(optionIndex)
    local option = self.optionControls[optionIndex]
    if option and option.optionIndex then
        self:HandleChatterOptionClicked(option)
    end
end

function ZO_Interaction:SelectLastChatterOption()
    self:SelectChatterOptionByIndex(self.optionCount)
end

function ZO_Interaction:ShowQuestRewards(journalQuestIndex)
    local anchorIndex = 0
    local ROOT_REWARD_ANCHOR = ZO_Anchor:New(TOPLEFT, self.control:GetNamedChild("CollapseContainerRewardAreaHeader"), BOTTOMLEFT, 0, 0)
    local rewardCurrencyOptions =
    {
        showTooltips = true,
        font = "ZoFontConversationQuestReward",
        iconSize = 24,
        iconSide = LEFT
    }

    local moneyAnchorControl = ZO_InteractWindowCollapseContainerRewardAreaHeader
    local moneyControls = {}

    local IS_KEYBOARD = false
    local rewardData = self:GetRewardData(journalQuestIndex, IS_KEYBOARD)
    local numRewards = #rewardData
    local currenciesWithMaxWarning = {}
    local amountsAcquiredWithMaxWarning = {}
    for i, reward in ipairs(rewardData) do
        local creatorFunc = self:GetRewardCreateFunc(reward.rewardType)
        if creatorFunc then
            if self:IsCurrencyReward(reward.rewardType) then
                local control = self.currencyRewardPool:AcquireObject()
                creatorFunc(control, reward.name, reward.amount, rewardCurrencyOptions)

                if #moneyControls ~= 0 then
                    control:ClearAnchors()
                    control:SetAnchor(TOPLEFT, moneyControls[#moneyControls], BOTTOMLEFT, 0, 4)
                end

                moneyControls[#moneyControls + 1] = control

                --warn the player they aren't going to get their money when they hit complete

                if self:WouldCurrencyExceedMax(reward.rewardType, reward.amount) then
                    local currencyType = self:GetCurrencyTypeFromReward(reward.rewardType)
                    local currencyText = GetCurrencyName(currencyType)
                    table.insert(currenciesWithMaxWarning, currencyText)

                    local playerStoredLocation = GetCurrencyPlayerStoredLocation(currencyType)
                    local currencyAmount = zo_max(0, GetMaxPossibleCurrency(currencyType, playerStoredLocation) - (GetCurrencyAmount(currencyType, playerStoredLocation)))
                    local isSingular = currencyAmount == 1
                    currencyText = GetCurrencyName(currencyType, isSingular)
                    table.insert(amountsAcquiredWithMaxWarning, string.format('%s %s', currencyAmount, currencyText))
                end
            else
                local control = self.givenRewardPool:AcquireObject()
                control.index = reward.index
                control.itemType = reward.itemType
                if control.itemType == REWARD_ITEM_TYPE_COLLECTIBLE then
                    control.itemId = GetJournalQuestRewardCollectibleId(journalQuestIndex, i)
                elseif control.itemType == REWARD_ITEM_TYPE_TRIBUTE_CARD_UPGRADE then
                    local patronDefId, cardIndex = GetJournalQuestRewardTributeCardUpgradeInfo(journalQuestIndex, i)
                    local patronData = TRIBUTE_DATA_MANAGER:GetTributePatronData(patronDefId)
                    local baseCardId, upgradeCardId = patronData:GetDockCardInfoByIndex(cardIndex)
                    control.patronDefId = patronDefId
                    control.upgradeCardId = upgradeCardId
                end

                -- reward.quality is deprecated, included here for addon backwards compatibility
                local displayQuality = reward.displayQuality or reward.quality
                creatorFunc(control, reward.name, reward.amount, reward.icon, reward.meetsUsageRequirement, displayQuality, reward.itemType)

                -- Money rewards do not get box-anchored, they're shown after all the reward icons (or immediately if there were no icons)
                ZO_Anchor_BoxLayout(ROOT_REWARD_ANCHOR, control, anchorIndex, REWARD_STRIDE, REWARD_PADDING_X, REWARD_PADDING_Y, ZO_REWARD_SIZE_X, ZO_REWARD_SIZE_Y, REWARD_ROOT_OFFSET_X, REWARD_ROOT_OFFSET_Y)
                anchorIndex = anchorIndex + 1

                -- Controls in the first column and last row serve as the anchor for the money reward control
                if zo_mod(anchorIndex, REWARD_STRIDE) == 1 then
                    moneyAnchorControl = control
                end
            end
        end
    end

    local confirmError
    if #currenciesWithMaxWarning > 0 then
        local currencyList = ZO_GenerateCommaSeparatedListWithOr(currenciesWithMaxWarning)
        confirmError = ZO_ERROR_COLOR:Colorize(zo_strformat(SI_QUEST_REWARD_MAX_CURRENCY_ERROR, currencyList))
    end

    local rewardWindowHeight = zo_ceil(anchorIndex / REWARD_STRIDE) * (ZO_REWARD_SIZE_Y + REWARD_PADDING_Y) + 50
    local initialMoneyControl = moneyControls[1]

    if initialMoneyControl then
        rewardWindowHeight = rewardWindowHeight + (#moneyControls * 28)

        initialMoneyControl:ClearAnchors()
        initialMoneyControl:SetAnchor(TOPLEFT, moneyAnchorControl, BOTTOMLEFT, 0, 28)
    end

    ZO_InteractWindowCollapseContainerRewardArea:SetHidden(numRewards == 0)
    ZO_InteractWindowCollapseContainerRewardArea:SetHeight(rewardWindowHeight)

    return confirmError, currenciesWithMaxWarning, amountsAcquiredWithMaxWarning
end

function ZO_Interaction:UpdateClemencyOnTimeComplete(control, data)
    control:SetText(control.optionText)
    control.enabled = true
    data.optionUsable = true
    control.optionType = CHATTER_TALK_CHOICE_USE_CLEMENCY
    control:SetColor(ENABLED_PLAYER_OPTION_COLOR:UnpackRGBA())
end

function ZO_Interaction:UpdateShadowyConnectionsOnTimeComplete(control, data)
    control:SetText(control.optionText)
    control.enabled = true
    data.optionUsable = true
    control.optionType = CHATTER_TALK_CHOICE_USE_SHADOWY_CONNECTIONS
    control:SetColor(ENABLED_PLAYER_OPTION_COLOR:UnpackRGBA())
end

--XML Handlers
--------------

function ZO_ChatterOption_MouseUp(label, button, upInside)
    if(button == MOUSE_BUTTON_INDEX_LEFT and upInside) then
        INTERACTION:HandleChatterOptionClicked(label)
    end
end

function ZO_ChatterOption_MouseEnter(label)
    local highlight = ZO_InteractWindowPlayerAreaHighlight
    highlight:ClearAnchors()
    highlight:SetAnchorFill(label)
    highlight:SetHidden(false)

    if label.optionType ~= CHATTER_GOODBYE then
        INTERACTION:DimOtherImportantOptions(label)
    end

    INTERACTION.currentMouseLabel = label
end

function ZO_ChatterOption_MouseExit(label)
    ZO_InteractWindowPlayerAreaHighlight:SetHidden(true)

    if label.optionType ~= CHATTER_GOODBYE then
        INTERACTION:RestoreOtherImportantOptions(label)
    end

    INTERACTION.currentMouseLabel = nil
end

function ZO_QuestReward_MouseEnter(control)
    if control.allowTooltip then
        if control.itemType == REWARD_ITEM_TYPE_ITEM then
            InitializeTooltip(ItemTooltip)
            ItemTooltip:SetQuestReward(control.index)
            ItemTooltip:HideComparativeTooltips()
            ItemTooltip:ShowComparativeTooltips()
            ZO_PlayShowAnimationOnComparisonTooltip(ComparativeTooltip1)
            ZO_PlayShowAnimationOnComparisonTooltip(ComparativeTooltip2)
            ZO_Tooltips_SetupDynamicTooltipAnchors(ItemTooltip, control, ComparativeTooltip1, ComparativeTooltip2)
        elseif control.itemType == REWARD_ITEM_TYPE_COLLECTIBLE then
            InitializeTooltip(ItemTooltip, control, RIGHT, -5, 0, LEFT)
            ItemTooltip:SetCollectible(control.itemId)
        elseif control.itemType == REWARD_ITEM_TYPE_TRIBUTE_CARD_UPGRADE then
            InitializeTooltip(ItemTooltip, control, RIGHT, -5, 0, LEFT)
            ItemTooltip:SetTributeCard(control.patronDefId, control.upgradeCardId)
        end
    end
end

function ZO_QuestReward_MouseExit(control)
    if control.allowTooltip then
        ClearTooltip(ItemTooltip)
        if control.itemType == REWARD_ITEM_TYPE_ITEM then
            ZO_PlayHideAnimationOnComparisonTooltip(ComparativeTooltip1)
            ZO_PlayHideAnimationOnComparisonTooltip(ComparativeTooltip2)
        end
    end
end

function ZO_QuestRewardName_MouseEnter(label)
    local questRewardControl = label:GetParent()
    if questRewardControl.allowTooltip then
        ZO_QuestReward_MouseEnter(questRewardControl)
    else
        ZO_TooltipIfTruncatedLabel_OnMouseEnter(label)
    end
end

function ZO_QuestRewardName_MouseExit(label)
    local questRewardControl = label:GetParent()
    if questRewardControl.allowTooltip then
        ZO_QuestReward_MouseExit(questRewardControl)
    else
        ZO_TooltipIfTruncatedLabel_OnMouseExit(label)
    end
end

function ZO_InteractWindow_Initialize(control)
    INTERACTION = ZO_Interaction:New(control)
end
