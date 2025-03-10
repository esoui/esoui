local SHOW_BACK_TO_TOC_OPTION = true
local HIDE_BACK_TO_TOC_OPTION = false

local COST_OPTION_TO_PROMPT =
{
    [CHATTER_TALK_CHOICE_MONEY]      = GetString(SI_PAY_FOR_CONVERSATION_GIVE),
    [CHATTER_TALK_CHOICE_PAY_BOUNTY] = GetString(SI_PAY_FOR_CONVERSATION_GIVE),
}

local COST_OPTION_TO_PROMPT_TITLE =
{
    [CHATTER_TALK_CHOICE_MONEY]      = GetString(SI_PAY_FOR_CONVERSATION_GIVE_TITLE),
    [CHATTER_TALK_CHOICE_PAY_BOUNTY] = GetString(SI_PAY_FOR_CONVERSATION_GIVE_TITLE),
}

local CHATTER_OPTION_SHOWS_GOLD_COST =
{
    [CHATTER_TALK_CHOICE_MONEY]      = true,
    [CHATTER_TALK_CHOICE_PAY_BOUNTY] = true,
    [CHATTER_TALK_CHOICE_BEGIN_SKILL_RESPEC] = true,
    [CHATTER_TALK_CHOICE_ATTRIBUTE_RESPEC]   = true,
}

local DIALOGUE_TONE_ICONS =
{
    [DIALOGUE_TONE_TYPE_KIND] = "EsoUI/Art/Miscellaneous/dialogueTone_Kind.dds",
    [DIALOGUE_TONE_TYPE_GRIM] = "EsoUI/Art/Miscellaneous/dialogueTone_Grim.dds",
    [DIALOGUE_TONE_TYPE_JOKER] = "EsoUI/Art/Miscellaneous/dialogueTone_Joker.dds",
    [DIALOGUE_TONE_TYPE_FLIRTY] = "EsoUI/Art/Miscellaneous/dialogueTone_Flirty.dds",
    [DIALOGUE_TONE_TYPE_MERCIFUL] = "EsoUI/Art/Miscellaneous/dialogueTone_Merciful.dds",
    [DIALOGUE_TONE_TYPE_RUTHLESS] = "EsoUI/Art/Miscellaneous/dialogueTone_Ruthless.dds",
    [DIALOGUE_TONE_TYPE_NEUTRAL] = "EsoUI/Art/Miscellaneous/dialogueTone_Neutral.dds",
}

CHATTER_OPTION_ERROR =
{
    [CHATTER_TALK_CHOICE_MONEY] = SI_ERROR_CANT_AFFORD_OPTION,
    [CHATTER_TALK_CHOICE_INTIMIDATE_DISABLED] = SI_ERROR_NEED_INTIMIDATE,
    [CHATTER_TALK_CHOICE_PERSUADE_DISABLED] = SI_ERROR_NEED_PERSUADE,
    [CHATTER_GUILDKIOSK_IN_TRANSITION] = SI_INTERACT_TRADER_BIDDING_CLOSED_DURING_BID_TRANSITIONING_PERIOD,
    [CHATTER_TALK_CHOICE_PAY_BOUNTY] = SI_ERROR_CANT_AFFORD_OPTION,
    [CHATTER_TALK_CHOICE_CLEMENCY_DISABLED] = SI_ERROR_NEED_CLEMENCY,
    [CHATTER_TALK_CHOICE_CLEMENCY_COOLDOWN] = SI_ERROR_CLEMENCY_ON_COOLDOWN,
    [CHATTER_TALK_CHOICE_BEGIN_SKILL_RESPEC] = SI_ERROR_CANT_AFFORD_OPTION,
    [CHATTER_TALK_CHOICE_ATTRIBUTE_RESPEC] = SI_ERROR_CANT_AFFORD_OPTION,
}

--Event Handlers
----------------

local function OnQuestCompleteFailedInventoryFull()
    TriggerTutorial(TUTORIAL_TRIGGER_INVENTORY_FULL)
    ZO_Alert(UI_ALERT_CATEGORY_ERROR, SOUNDS.NEGATIVE_CLICK, GetString(SI_INVENTORY_ERROR_INVENTORY_FULL))
end

local function OnConversationFailedInventoryFull()
    TriggerTutorial(TUTORIAL_TRIGGER_INVENTORY_FULL)
    ZO_Alert(UI_ALERT_CATEGORY_ERROR, SOUNDS.NEGATIVE_CLICK, GetString(SI_INVENTORY_ERROR_INVENTORY_FULL))
end

local function OnConversationFailedUniqueItem()
    ZO_Alert(UI_ALERT_CATEGORY_ERROR, SOUNDS.NEGATIVE_CLICK, GetString(SI_INVENTORY_ERROR_UNIQUE_ITEM))
end

local function ShowInteractConfirmationPrompt(eventId, titleText, bodyText, acceptText, cancelText)
    ZO_Dialogs_ShowPlatformDialog("CONFIRM_INTERACTION", nil, { mainTextParams = { bodyText }, titleParams = { titleText }, buttonTextOverrides = { acceptText, cancelText } })
end

ZO_SharedInteraction = ZO_Object:Subclass()

function ZO_SharedInteraction:Initialize(control)
    self.control = control
    self:InitializeSharedEvents()
end

local function ContextFilter(object, callback)
    -- This will wrap the callback so that it gets called with the control
    return function(...)
        local obj = SYSTEMS:GetObject(ZO_INTERACTION_SYSTEM_NAME)

        if (obj == object) then
            callback(...)
        end
    end
end

function ZO_SharedInteraction:InitializeSharedEvents()

    local function OnQuestOffered()
        local dialog, response = GetOfferedQuestInfo()
        local _, farewell = GetChatterFarewell()

        if(farewell == "") then farewell = GetString(SI_GOODBYE) end

        self:InitializeInteractWindow(dialog)

        self.importantOptions = {}
        self:PopulateChatterOption(1, AcceptOfferedQuest, response, CHATTER_GENERIC_ACCEPT)
        self:PopulateChatterOption(2, function() self:CloseChatter() end, farewell, CHATTER_GOODBYE)

        self:FinalizeChatterOptions(2)
    end

    local function OnQuestComplete(_, journalQuestIndex)
        local _, endDialog, confirmComplete, declineComplete = GetJournalQuestEnding(journalQuestIndex)

        if(confirmComplete == "") then  confirmComplete = GetString(SI_DEFAULT_QUEST_COMPLETE_CONFIRM_TEXT) end
        if(declineComplete == "") then  declineComplete = GetString(SI_DEFAULT_QUEST_COMPLETE_DECLINE_TEXT) end

        self:InitializeInteractWindow(endDialog)

        local confirmError, currenciesWithMaxWarning, amountsAcquiredWithMaxWarning = self:ShowQuestRewards(journalQuestIndex)
        if confirmError then
            confirmComplete = zo_strformat(SI_QUEST_COMPLETE_FORMAT_STRING, confirmComplete, confirmError)
        end

        local function OnCompleteQuest()
            if confirmError then
                ZO_Dialogs_ShowPlatformDialog("CONFIRM_COMPLETE_QUEST_MAX_WARNINGS", { journalQuestIndex = journalQuestIndex, currenciesWithMaxWarning = currenciesWithMaxWarning, amountsAcquiredWithMaxWarning = amountsAcquiredWithMaxWarning })
            else
                CompleteQuest()
            end
        end

        self.importantOptions = {}
        self:PopulateChatterOption(1, OnCompleteQuest, confirmComplete, CHATTER_COMPLETE_QUEST)
        self:PopulateChatterOption(2, function() self:CloseChatter() end, declineComplete, CHATTER_GOODBYE)

        self:FinalizeChatterOptions(2)
    end

    local function OnChatterBegin(_, chatterOptionCount, debugSource)
        -- Catching a rogue event coming down that causes a UI error when a bad option count is passed down.  Root cause still unknown, this will just suppress the error.
        -- ESO-692130
        if internalassert(chatterOptionCount <= MAX_CHATTER_OPTIONS, string.format("Tried to begin a chatter from source type %d with %d chatter options, which is invalid. Please notify a UI engineer.", debugSource, chatterOptionCount)) then
            self:InitializeInteractWindow(GetChatterGreeting())
            self:UpdateChatterOptions(chatterOptionCount, HIDE_BACK_TO_TOC_OPTION)
        end
    end

    local function OnChatterEnd()
        self:CloseChatter()
    end

    local function OnPlayerDead()
        self:CloseChatter()

        -- hmm, this seems wrong; should it happen as part of closing interact?
        -- why would a dead party member not be able to accept a shared quest?
        ZO_Dialogs_ReleaseDialog("SHARE_QUEST")
        ZO_Dialogs_ReleaseDialog("RITUAL_OF_MARA_PROMPT")
    end

    local function OnPlayerDeactivated()
        self:CloseChatter()
    end

    local function OnConversationUpdated(_, bodyText, choiceCount)
        self:InitializeInteractWindow(bodyText)
        self:UpdateChatterOptions(choiceCount, SHOW_BACK_TO_TOC_OPTION)
    end

    local function OnScreenResized()
        self:OnScreenResized()
    end

    self.eventCallbacks =
    {
        [EVENT_CHATTER_BEGIN] = OnChatterBegin,
        [EVENT_CHATTER_END] = OnChatterEnd,
        [EVENT_CONVERSATION_UPDATED] = OnConversationUpdated,
        [EVENT_QUEST_OFFERED] = OnQuestOffered,
        [EVENT_QUEST_COMPLETE_DIALOG] = OnQuestComplete,
        [EVENT_QUEST_COMPLETE_ATTEMPT_FAILED_INVENTORY_FULL] = OnQuestCompleteFailedInventoryFull,
        [EVENT_CONVERSATION_FAILED_INVENTORY_FULL] = OnConversationFailedInventoryFull,
        [EVENT_CONVERSATION_FAILED_UNIQUE_ITEM] = OnConversationFailedUniqueItem,
        [EVENT_PLAYER_DEAD] = OnPlayerDead,
        [EVENT_PLAYER_DEACTIVATED] = OnPlayerDeactivated,
        [EVENT_CONFIRM_INTERACT] = ShowInteractConfirmationPrompt,

        -- Handle the layout of the interaction window proportional to the available space
        [EVENT_SCREEN_RESIZED] = OnScreenResized,
    }

    for event, callback in pairs(self.eventCallbacks) do
        self.control:RegisterForEvent(event, ContextFilter(self, callback))
    end
end

function ZO_SharedInteraction:CreateInteractScene(name)

    local CONVERSATION_INTERACTION =
    {
        type = "Interact",
        interactTypes = { INTERACTION_CONVERSATION, INTERACTION_QUEST },
        OnInteractSwitch = function() self:SwitchInteraction() end,
    }

    self.sceneName = name

    return ZO_InteractScene:New(name, SCENE_MANAGER, CONVERSATION_INTERACTION)
end

function ZO_SharedInteraction:CloseChatter()
    SCENE_MANAGER:Hide(self.sceneName)
end

function ZO_SharedInteraction:CloseChatterAndDismissAssistant()
    self:CloseChatter()
    local activeAssistantId = GetActiveCollectibleByType(COLLECTIBLE_CATEGORY_TYPE_ASSISTANT, GAMEPLAY_ACTOR_CATEGORY_PLAYER)
    if activeAssistantId ~= 0 then
        local collectibleData = ZO_COLLECTIBLE_DATA_MANAGER:GetCollectibleDataById(activeAssistantId)
        collectibleData:Use(GAMEPLAY_ACTOR_CATEGORY_PLAYER)
    end
end

function ZO_SharedInteraction:InitializeInteractWindow(bodyText)
    self:ResetInteraction(bodyText)

    INTERACT_WINDOW:ShowInteractWindow()
end

function ZO_SharedInteraction:OnHidden()
    RemoveActionLayerByName("SceneChangeInterceptLayer")
    ZO_Dialogs_ReleaseDialog("PAY_FOR_CONVERSATION")

    INTERACT_WINDOW:FireCallbacks("Hidden")
end

do
    local function UpdatePlayerGold(control)
        ZO_CurrencyControl_SetSimpleCurrency(control, CURT_MONEY, GetCurrencyAmount(CURT_MONEY, CURRENCY_LOCATION_CHARACTER), ZO_GAMEPAD_CURRENCY_OPTIONS_LONG_FORMAT)
        return true
    end
    function ZO_SharedInteraction:HandleChatterOptionClicked(label)
        --if it's not enabled, report why it cant be used and return
        if(not label.enabled) then
            local errorStringId = CHATTER_OPTION_ERROR[label.optionType]
            if(errorStringId) then
                ZO_Alert(UI_ALERT_CATEGORY_ERROR, SOUNDS.NEGATIVE_CLICK, errorStringId)
            end
            return
        end

        if(label.optionIndex) then
            local oiType = type(label.optionIndex)
            if(oiType == "number") then
                --popup a dialog if it's an option with a cost and the cost is greater than free
                if(COST_OPTION_TO_PROMPT[label.optionType] and label.gold and label.gold > 0) then
                    ZO_Dialogs_ShowPlatformDialog(
                        "PAY_FOR_CONVERSATION", 
                        {
                            chatterOptionIndex = label.optionIndex,
                            data1 = {
                                        header = GetString(SI_GAMEPAD_PAY_FOR_CONVERSATION_AVAILABLE_FUNDS),
                                        value = UpdatePlayerGold,
                                        valueNarration = ZO_Currency_GetPlayerCarriedGoldNarration,
                                    },
                        },
                        {
                            titleParams = { COST_OPTION_TO_PROMPT_TITLE[label.optionType] },
                            mainTextParams = { COST_OPTION_TO_PROMPT[label.optionType], ZO_Currency_FormatPlatform(CURT_MONEY, label.gold, ZO_CURRENCY_FORMAT_WHITE_AMOUNT_ICON) }
                        }
                    )
                --otherwise just do it
                else
                    SelectChatterOption(label.optionIndex)
                end
            elseif(oiType == "function") then
                label.optionIndex()
            end
        else
            self:CloseChatter()
        end
    end
end

CHATTER_GENERIC_ACCEPT = 42
CHATTER_COMPLETE_QUEST = 43

local function UpdateFleeChatterOption(self)
    self:SetText(zo_strformat(SI_INTERACT_OPTION_FLEE_ARREST, GetSecondsUntilArrestTimeout()))
end

function ZO_SharedInteraction:UpdateClemencyChatterOption(control, data)
    local clemencyTimeRemaningSeconds = GetTimeToClemencyResetInSeconds()

    if clemencyTimeRemaningSeconds == 0 and not data.optionUsable then
        self:UpdateClemencyOnTimeComplete(control, data)
    elseif clemencyTimeRemaningSeconds > 0 then
        local formattedString = zo_strformat(SI_INTERACT_OPTION_USE_CLEMENCY_COOLDOWN, control.optionText, ZO_FormatTimeLargestTwo(clemencyTimeRemaningSeconds, TIME_FORMAT_STYLE_DESCRIPTIVE_MINIMAL))
        control:SetText(formattedString)
    end
end

function ZO_SharedInteraction:UpdateShadowyConnectionsChatterOption(control, data)
    local timeRemaining = GetTimeToShadowyConnectionsResetInSeconds()

    if timeRemaining == 0 and not data.optionUsable then
        self:UpdateShadowyConnectionsOnTimeComplete(control, data)
    elseif timeRemaining > 0 then
        local formattedString = zo_strformat(SI_INTERACT_OPTION_USE_SHADOWY_CONNECTIONS_COOLDOWN, control.optionText, ZO_FormatTimeLargestTwo(timeRemaining, TIME_FORMAT_STYLE_DESCRIPTIVE_MINIMAL))
        control:SetText(formattedString)
    end
end

function ZO_SharedInteraction:GetChatterOptionData(optionIndex, optionText, optionType, optionalArg, isImportant, chosenBefore, teleportNPCId, waypointIdTable, dialogueTone)
    optionType = optionType or CHATTER_START_TALK
    local chatterData =
    {
        optionIndex = optionIndex,
        optionType = optionType,
        optionText = optionText,
        isImportant = isImportant,
        chosenBefore = chosenBefore,
        teleportNPCId = teleportNPCId,
        waypointIdTable = waypointIdTable,
        gold = nil,
        iconFiles = {},
        isChatterOption = true,
        optionEnabled = false,
        optionUsable = false,
        recolorIfUnusable = false,
        labelUpdateFunction = nil,
    }

    if optionText and optionType then
        chatterData.optionsEnabled = true
        chatterData.optionUsable = true
        chatterData.recolorIfUnusable = true

        if optionType == CHATTER_GOODBYE and IsUnderArrest() then
            chatterData.labelUpdateFunction = UpdateFleeChatterOption
        end

        if dialogueTone and dialogueTone ~= DIALOGUE_TONE_TYPE_NONE then
            local toneIcon = DIALOGUE_TONE_ICONS[dialogueTone]
            toneIcon = zo_iconFormatInheritColor(toneIcon, "125%", "125%")
            toneIcon = GetDialogueToneColor(dialogueTone):Colorize(toneIcon)
            local optionTextWithTone = string.format("%s %s", toneIcon, zo_strformat("<<1>>", chatterData.optionText))
            chatterData.optionText = optionTextWithTone
            TriggerTutorial(TUTORIAL_TRIGGER_DIALOGUE_TONE_SEEN)
        end

        if CHATTER_OPTION_SHOWS_GOLD_COST[optionType] then
            --optional arg is the cost in gold
            chatterData.gold = optionalArg

            if optionalArg > 0 then
                if GetCurrencyAmount(CURT_MONEY, CURRENCY_LOCATION_CHARACTER) < optionalArg then
                    chatterData.optionUsable = false
                end

                --Determine rules for suppressing the cost suffix
                local suppressCostSuffix = (optionType == CHATTER_TALK_CHOICE_PAY_BOUNTY)

                if not suppressCostSuffix then
                    local currencyText
                    if chatterData.optionUsable then
                        currencyText = ZO_Currency_FormatPlatform(CURT_MONEY, chatterData.gold, ZO_CURRENCY_FORMAT_WHITE_AMOUNT_ICON)
                    else
                        currencyText = ZO_Currency_FormatPlatform(CURT_MONEY, chatterData.gold, ZO_CURRENCY_FORMAT_ERROR_AMOUNT_ICON)
                    end
                    chatterData.optionText = zo_strformat(SI_INTERACT_OPTION_COST, optionText, currencyText)
                end
            end
        elseif optionType == CHATTER_TALK_CHOICE_INTIMIDATE_DISABLED
            or optionType == CHATTER_TALK_CHOICE_PERSUADE_DISABLED
            or optionType == CHATTER_TALK_CHOICE_CLEMENCY_DISABLED
            or optionType == CHATTER_GUILDKIOSK_IN_TRANSITION then
            chatterData.optionUsable = false
            chatterData.recolorIfUnusable = false
        elseif optionType == CHATTER_TALK_CHOICE_CLEMENCY_COOLDOWN then
            local clemencyTimeRemaningSeconds = GetTimeToClemencyResetInSeconds()

            if clemencyTimeRemaningSeconds <= 0 then
                chatterData.optionUsable = true
            else
                chatterData.labelUpdateFunction = function(control)
                                                    self:UpdateClemencyChatterOption(control, chatterData)
                                                  end
                chatterData.optionUsable = false
            end
        elseif optionType == CHATTER_TALK_CHOICE_SHADOWY_CONNECTIONS_UNAVAILABLE then
            local timeRemaining = GetTimeToShadowyConnectionsResetInSeconds()

            if timeRemaining <= 0 then
                -- We're not on cooldown, but the option is otherwise unusable (most likely, the player hasn't unlocked this passive)
                chatterData.optionUsable = false
            else
                chatterData.labelUpdateFunction = function(control)
                    self:UpdateShadowyConnectionsChatterOption(control, chatterData)
                end
                chatterData.optionUsable = false
            end
        elseif (optionType == CHATTER_START_TALK or optionType == CHATTER_TALK_CHOICE) and chatterData.teleportNPCId ~= 0 and chatterData.waypointIdTable and #chatterData.waypointIdTable > 0 then
            -- TODO: Handle zone guide quest tracked but not in journal

            -- Consider breadcrumb pathing for group members
            for groupCharId, groupMember in pairs(WORLD_MAP_QUEST_BREADCRUMBS:GetGroupMemberBreadcrumbingData()) do
                if groupMember.teleportNPCId == chatterData.teleportNPCId then
                    for _, waypointId in pairs(chatterData.waypointIdTable) do
                        if groupMember.waypointId == waypointId then
                            if groupMember.isGroupLeader then
                                if #chatterData.iconFiles == 0 then
                                    table.insert(chatterData.iconFiles, "EsoUI/Art/Compass/groupLeader_door.dds")
                                else
                                    chatterData.iconFiles[1] = "EsoUI/Art/Compass/groupLeader_door.dds"
                                end
                                break
                            else
                                if #chatterData.iconFiles == 0 then
                                    table.insert(chatterData.iconFiles, "EsoUI/Art/Compass/groupMember_door.dds")
                                end
                            end
                        end
                    end
                end
            end

            local previousIconCount = #chatterData.iconFiles
            -- Consider breadcrumb pathing in journal quests
            for questIndex = 1, GetNumJournalQuests() do
                local stepsTable = WORLD_MAP_QUEST_BREADCRUMBS:GetSteps(questIndex)
                -- Check against nil since not every quest is pathable
                if stepsTable then
                    for stepIndex, step in pairs(stepsTable) do
                        for conditionIndex, condition in pairs(step) do
                            if condition.teleportNPCId == chatterData.teleportNPCId and ZO_IsElementInNumericallyIndexedTable(chatterData.waypointIdTable, condition.waypointId) then
                                if GetJournalQuestZoneDisplayType(questIndex) == ZONE_DISPLAY_TYPE_ZONE_STORY then
                                    if questIndex == QUEST_JOURNAL_MANAGER:GetFocusedQuestIndex() then
                                        if #chatterData.iconFiles == previousIconCount then
                                            table.insert(chatterData.iconFiles, "EsoUI/Art/Compass/zoneStoryQuest_icon_door_assisted.dds")
                                        else
                                            chatterData.iconFiles[previousIconCount + 1] = "EsoUI/Art/Compass/zoneStoryQuest_icon_door_assisted.dds"
                                        end
                                        break
                                    elseif #chatterData.iconFiles == previousIconCount then
                                        table.insert(chatterData.iconFiles, "EsoUI/Art/Compass/zoneStoryQuest_icon_door.dds")
                                    end
                                else
                                    if questIndex == QUEST_JOURNAL_MANAGER:GetFocusedQuestIndex() then
                                        if #chatterData.iconFiles == previousIconCount then
                                            table.insert(chatterData.iconFiles, "EsoUI/Art/Compass/quest_icon_door_assisted.dds")
                                        else
                                            chatterData.iconFiles[previousIconCount + 1] = "EsoUI/Art/Compass/quest_icon_door_assisted.dds"
                                        end
                                        break
                                    elseif #chatterData.iconFiles == previousIconCount then
                                        table.insert(chatterData.iconFiles, "EsoUI/Art/Compass/quest_icon_door.dds")
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    end

    return chatterData
end

function ZO_SharedInteraction:PopulateChatterOptions(optionCount, backToTOCOption)
    local importantOptions = {}

    for i = 1, optionCount do
        local optionString, optionType, optionalArg, isImportant, chosenBefore, teleportNPCId, dialogueTone = GetChatterOption(i)
        local waypointIdTable = { GetChatterOptionWaypoints(i) }
        local controlID = i
        self:PopulateChatterOption(controlID, i, optionString, optionType, optionalArg, isImportant, chosenBefore, importantOptions, teleportNPCId, waypointIdTable, dialogueTone)
    end

    local backToTOC, farewell, isImportant = GetChatterFarewell()
    if(backToTOCOption == SHOW_BACK_TO_TOC_OPTION and backToTOC ~= "") then
        optionCount = optionCount + 1
        self:PopulateChatterOption(optionCount, ResetChatter, backToTOC, CHATTER_TALK_CHOICE)
    end

    if(farewell == "") then farewell = GetString(SI_GOODBYE) end
    optionCount = optionCount + 1
    self:PopulateChatterOption(optionCount, function() self:CloseChatter() end, farewell, CHATTER_GOODBYE, nil, isImportant, nil, importantOptions, nil, nil, DIALOGUE_TONE_TYPE_NONE)

    if IsInteractingWithMyAssistant() then
        local collectibleData = ZO_COLLECTIBLE_DATA_MANAGER:GetCollectibleDataById(GetActiveCollectibleByType(COLLECTIBLE_CATEGORY_TYPE_ASSISTANT, GAMEPLAY_ACTOR_CATEGORY_PLAYER))
        farewell = zo_strformat(SI_INTERACT_OPTION_DISMISS_ASSISTANT, collectibleData:GetName())
        optionCount = optionCount + 1
        self:PopulateChatterOption(optionCount, function() self:CloseChatterAndDismissAssistant() end, farewell, CHATTER_GOODBYE, nil, isImportant, nil, importantOptions)
    end

    self:FinalizeChatterOptions(optionCount)

    return optionCount, importantOptions
end

--Reward Creator

local USE_LOWERCASE_NUMBER_SUFFIXES = false
local function SetupBasicReward(control, name, stackSize, icon, meetsUsageRequirement, r, g, b)
    local nameControl = GetControl(control, "Name")
    local iconControl = GetControl(control, "Icon")
    local stackControl = GetControl(control, "StackSize")

    control:SetHidden(false)

    nameControl:SetText(zo_strformat(SI_TOOLTIP_ITEM_NAME, name))
    iconControl:SetTexture(icon)
    iconControl:SetHidden(false)

    if meetsUsageRequirement then
        nameControl:SetColor(r or 1, g or 1, b or 1, 1)
        iconControl:SetColor(1, 1, 1, 1)
    else
        nameControl:SetColor(ZO_ERROR_COLOR:UnpackRGBA())
        iconControl:SetColor(ZO_ERROR_COLOR:UnpackRGBA())
    end

    if stackSize > 1 then
        local stackSizeString = ZO_AbbreviateAndLocalizeNumber(stackSize, NUMBER_ABBREVIATION_PRECISION_TENTHS, USE_LOWERCASE_NUMBER_SUFFIXES)
        stackControl:SetText(stackSizeString)
        stackControl:SetHidden(false)
    else
        stackControl:SetHidden(true)
    end

    control.allowTooltip = true
end

local function SetupCurrencyReward(control, currencyType, amount, currencyOptions)
    ZO_CurrencyControl_SetSimpleCurrency(control, currencyType, amount, currencyOptions)
    control:SetHidden(false)
end

function ZO_QuestReward_GetSkillPointText(numPartialSkillPoints)
    if numPartialSkillPoints >= NUM_PARTIAL_SKILL_POINTS_FOR_FULL then
        local fullSkillPoints = zo_floor(numPartialSkillPoints / NUM_PARTIAL_SKILL_POINTS_FOR_FULL)
        local remainingPartialSkillPoints = numPartialSkillPoints % NUM_PARTIAL_SKILL_POINTS_FOR_FULL
        if remainingPartialSkillPoints == 0 then
            return zo_strformat(SI_QUEST_REWARD_SKILL_POINTS, fullSkillPoints)
        end
        return zo_strformat(SI_QUEST_REWARD_SKILL_POINTS_MIXED, fullSkillPoints, remainingPartialSkillPoints)
    end

    return zo_strformat(SI_QUEST_REWARD_PARTIAL_SKILL_POINTS, numPartialSkillPoints)
end

local function SetupPartialSkillPointReward(control, amount)
    local nameControl = control:GetNamedChild("Name")
    control:GetNamedChild("Icon"):SetHidden(true)
    control:GetNamedChild("StackSize"):SetHidden(true)

    nameControl:SetText(ZO_QuestReward_GetSkillPointText(amount))
    nameControl:SetColor(GetInterfaceColor(INTERFACE_COLOR_TYPE_TEXT_COLORS, INTERFACE_TEXT_COLOR_SELECTED))
    control.allowTooltip = false
    control:SetHidden(false)
end

local function SetupSkillLineReward(control, name, icon)
    local nameControl = control:GetNamedChild("Name")
    local iconTexture = control:GetNamedChild("Icon")
    iconTexture:SetHidden(false)
    iconTexture:SetTexture(icon)
    control:GetNamedChild("StackSize"):SetHidden(true)

    nameControl:SetText(ZO_QuestReward_GetSkillLineEarnedText(name))
    nameControl:SetColor(GetInterfaceColor(INTERFACE_COLOR_TYPE_TEXT_COLORS, INTERFACE_TEXT_COLOR_SELECTED))
    control.allowTooltip = false
    control:SetHidden(false)
end

function ZO_QuestReward_GetSkillLineEarnedText(skillLineName)
    return zo_strformat(SI_QUEST_REWARD_SKILL_LINE, skillLineName)
end

local function SetupTribureClubReward(control, name, icon)
    local nameControl = control:GetNamedChild("Name")
    local iconTexture = control:GetNamedChild("Icon")
    iconTexture:SetHidden(false)
    iconTexture:SetTexture(icon)
    control:GetNamedChild("StackSize"):SetHidden(true)

    nameControl:SetText(name)
    nameControl:SetColor(GetInterfaceColor(INTERFACE_COLOR_TYPE_TEXT_COLORS, INTERFACE_TEXT_COLOR_SELECTED))
    control.allowTooltip = false
    control:SetHidden(false)
end

internalassert(REWARD_TYPE_MAX_VALUE == 15, "Check if new RewardType needs REWARD_CREATORS")
local REWARD_CREATORS =
{
    [REWARD_TYPE_AUTO_ITEM] =
        function(control, name, amount, icon, meetsUsageRequirement, itemQuality, itemType)
            --Collectibles should display as the default text color, white.
            if itemType == REWARD_ITEM_TYPE_COLLECTIBLE then
                SetupBasicReward(control, name, amount, icon, meetsUsageRequirement)
            else
                local r, g, b = GetInterfaceColor(INTERFACE_COLOR_TYPE_ITEM_QUALITY_COLORS, itemQuality)
                SetupBasicReward(control, name, amount, icon, meetsUsageRequirement, r, g, b)
            end
        end,
    [REWARD_TYPE_INSPIRATION] =
        function(control, name, amount, icon)
            local MEETS_USAGE_REQUIREMENTS = true
            SetupBasicReward(control, name, amount, icon, MEETS_USAGE_REQUIREMENTS)
        end,
    [REWARD_TYPE_ALLIANCE_POINTS] =
        function(control, name, amount, currencyOptions)
            SetupCurrencyReward(control, CURT_ALLIANCE_POINTS, amount, currencyOptions)
        end,
    [REWARD_TYPE_TELVAR_STONES] =
        function(control, name, amount, currencyOptions)
            SetupCurrencyReward(control, CURT_TELVAR_STONES, amount, currencyOptions)
        end,
    [REWARD_TYPE_EVENT_TICKETS] =
        function(control, name, amount, currencyOptions)
            SetupCurrencyReward(control, CURT_EVENT_TICKETS, amount, currencyOptions)
        end,
    [REWARD_TYPE_MONEY] =
        function(control, name, amount, currencyOptions)
            SetupCurrencyReward(control, CURT_MONEY, amount, currencyOptions)
        end,
    [REWARD_TYPE_PARTIAL_SKILL_POINTS] =
        function(control, name, amount)
            SetupPartialSkillPointReward(control, amount)
        end,
    [REWARD_TYPE_WRIT_VOUCHERS] =
        function(control, name, amount, currencyOptions)
            SetupCurrencyReward(control, CURT_WRIT_VOUCHERS, amount, currencyOptions)
        end,
    [REWARD_TYPE_SKILL_LINE] =
        function(control, name, amount, icon)
            SetupSkillLineReward(control, name, icon)
        end,
    [REWARD_TYPE_CHAOTIC_CREATIA] =
        function(control, name, amount, currencyOptions)
            SetupCurrencyReward(control, CURT_CHAOTIC_CREATIA, amount, currencyOptions)
        end,
    [REWARD_TYPE_STYLE_STONES] =
        function(control, name, amount, currencyOptions)
            SetupCurrencyReward(control, CURT_STYLE_STONES, amount, currencyOptions)
        end,
    [REWARD_TYPE_UNDAUNTED_KEYS] =
        function(control, name, amount, currencyOptions)
            SetupCurrencyReward(control, CURT_UNDAUNTED_KEYS, amount, currencyOptions)
        end,
    [REWARD_TYPE_IMPERIAL_FRAGMENTS] =
        function(control, name, amount, currencyOptions)
            SetupCurrencyReward(control, CURT_IMPERIAL_FRAGMENTS, amount, currencyOptions)
        end,
    [REWARD_TYPE_TRIBUTE_CLUB_EXPERIENCE] =
        function(control, name, amount, icon)
            SetupTribureClubReward(control, name, icon)
        end,
}

internalassert(REWARD_TYPE_MAX_VALUE == 15, "Check if new RewardType is a currencyRewards")
local currencyRewards =
{
    [REWARD_TYPE_MONEY] = true,
    [REWARD_TYPE_ALLIANCE_POINTS] = true,
    [REWARD_TYPE_TELVAR_STONES] = true,
    [REWARD_TYPE_WRIT_VOUCHERS] = true,
    [REWARD_TYPE_CHAOTIC_CREATIA] = true,
    [REWARD_TYPE_STYLE_STONES] = true,
    [REWARD_TYPE_EVENT_TICKETS] = true,
    [REWARD_TYPE_UNDAUNTED_KEYS] = true,
    [REWARD_TYPE_IMPERIAL_FRAGMENTS] = true,
}

function ZO_SharedInteraction:IsCurrencyReward(rewardType)
    return currencyRewards[rewardType]
end

internalassert(REWARD_TYPE_MAX_VALUE == 15, "Check if new RewardType maps to a currencyRewardToCurrencyType")
local currencyRewardToCurrencyType =
{
    [REWARD_TYPE_MONEY] = CURT_MONEY,
    [REWARD_TYPE_ALLIANCE_POINTS] = CURT_ALLIANCE_POINTS,
    [REWARD_TYPE_TELVAR_STONES] = CURT_TELVAR_STONES,
    [REWARD_TYPE_WRIT_VOUCHERS] = CURT_WRIT_VOUCHERS,
    [REWARD_TYPE_CHAOTIC_CREATIA] = CURT_CHAOTIC_CREATIA,
    [REWARD_TYPE_STYLE_STONES] = CURT_STYLE_STONES,
    [REWARD_TYPE_EVENT_TICKETS] = CURT_EVENT_TICKETS,
    [REWARD_TYPE_UNDAUNTED_KEYS] = CURT_UNDAUNTED_KEYS,
    [REWARD_TYPE_IMPERIAL_FRAGMENTS] = CURT_IMPERIAL_FRAGMENTS,
}

function ZO_SharedInteraction:GetCurrencyTypeFromReward(rewardType)
    return currencyRewardToCurrencyType[rewardType]
end

function ZO_SharedInteraction:WouldCurrencyExceedMax(rewardType, rewardAmount)
    local currencyType = currencyRewardToCurrencyType[rewardType]
    if not currencyType then
        return nil
    end

    local playerStoredLocation = GetCurrencyPlayerStoredLocation(currencyType)
    return GetCurrencyAmount(currencyType, playerStoredLocation) + rewardAmount > GetMaxPossibleCurrency(currencyType, playerStoredLocation)
end

function ZO_SharedInteraction:TryGetMaxCurrencyWarningText(rewardType, rewardAmount)
    if self:WouldCurrencyExceedMax(rewardType, rewardAmount) then
        return zo_strformat(SI_QUEST_REWARD_MAX_CURRENCY_ERROR, GetCurrencyName(currencyType))
    end
end

function ZO_SharedInteraction:GetRewardCreateFunc(rewardType)
    return REWARD_CREATORS[rewardType]
end

function ZO_SharedInteraction:GetRewardData(journalQuestIndex, isGamepad)
    local data = {}
    local numRewards = GetJournalQuestNumRewards(journalQuestIndex)
    for i = 1, numRewards do
        local rewardType, name, amount, icon, meetsUsageRequirement, itemDisplayQuality, itemType = GetJournalQuestRewardInfo(journalQuestIndex, i)
        --We don't want to show a collectible if we already own it
        local isCollectible = rewardType == REWARD_TYPE_AUTO_ITEM and itemType == REWARD_ITEM_TYPE_COLLECTIBLE
        local hideOwnedCollectible = isCollectible and not meetsUsageRequirement
        if not hideOwnedCollectible then
            local rewardData = 
            {
                rewardType = rewardType,
                name = name,
                amount = amount,
                icon = icon,
                meetsUsageRequirement = meetsUsageRequirement,
                displayQuality = itemDisplayQuality,
                --This value is deprecated. Keeping it here to maintain backwards compatibility for add-ons
                quality = itemDisplayQuality,
                index = i,
                itemType = itemType
            }

            if rewardType == REWARD_TYPE_SKILL_LINE then
                local skillType = GetJournalQuestRewardSkillLine(journalQuestIndex, i)
                local skillTypeData = SKILLS_DATA_MANAGER:GetSkillTypeData(skillType)
                local announce = skillTypeData:GetAnnounceIcon()
                rewardData.icon = announce
            elseif rewardType == REWARD_TYPE_INSPIRATION then
                if isGamepad then
                    rewardData.icon = "EsoUI/Art/currency/gamepad/gp_inspiration.dds"
                else
                    rewardData.icon = "EsoUI/Art/currency/currency_inspiration.dds"
                end
            elseif rewardType == REWARD_TYPE_TRIBUTE_CLUB_EXPERIENCE then
                rewardData.icon = "EsoUI/Art/Tribute/tributeRankPoints.dds"
            end

            table.insert(data, rewardData)
        end
    end
    return data
end

-- Functions needing to be overridden
-------------------------------------

function ZO_SharedInteraction:OnScreenResized()
    -- Should be overridden
end

function ZO_SharedInteraction:InitInteraction()
    -- Should be overridden
end

function ZO_SharedInteraction:ResetInteraction(bodyText)
    -- Should be overridden
end

function ZO_SharedInteraction:SwitchInteraction()
    -- Should be overridden
end

function ZO_SharedInteraction:SelectChatterOptionByIndex(optionIndex)
    -- Should be overridden
end

function ZO_SharedInteraction:UpdateChatterOptions(optionCount, backToTOCOption)
    -- Should be overridden
end

function ZO_SharedInteraction:PopulateChatterOption(optionCount, backToTOCOption)
    -- Should be overridden
end

function ZO_SharedInteraction:FinalizeChatterOptions(optionCount)
    -- Should be overridden
end

function ZO_SharedInteraction:ShowQuestRewards(journalQuestIndex)
    -- Should be overridden
end

function ZO_SharedInteraction:UpdateClemencyOnTimeComplete(control, data)
    --Should be overridden
end

function ZO_SharedInteraction:UpdateShadowyConnectionsOnTimeComplete(control, data)
    --Should be overridden
end