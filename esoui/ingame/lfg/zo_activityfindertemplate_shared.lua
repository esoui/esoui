local MAX_ITEM_REWARDS = 3
ZO_ACTIVITY_FINDER_REWARD_ENTRY_PADDING_X = 20
ZO_ACTIVITY_FINDER_REWARD_ENTRY_PADDING_Y = 10

ZO_TRIBUTE_FINDER_MATCH_WON = 1
ZO_TRIBUTE_FINDER_MATCH_LOSE = 2
ZO_TRIBUTE_FINDER_MATCH_EMPTY = 3

local TRIBUTE_RANK_ICON_FORMATTER = "EsoUI/Art/Tribute/tributeRankIcon_%d.dds"
-- Arbitrary large number that we are not likely to ever overtake
local TRIBUTE_RANKS_COMPLETED_ICON_INDEX = 100

------------------
--Initialization--
------------------

ZO_ActivityFinderTemplate_Shared = ZO_InitializingObject:Subclass()

function ZO_ActivityFinderTemplate_Shared:Initialize(control, dataManager, categoryData, categoryPriority)
    self.control = control
    control.object = self
    self.dataManager = dataManager
    self.categoryData = categoryData
    self.categoryPriority = categoryPriority
    self.categoryData.activityFinderObject = self

    self:InitializeControls()
    self:RegisterEvents()
end

function ZO_ActivityFinderTemplate_Shared:InitializeControls(rewardsTemplate)
    self:InitializeSingularPanelControls(rewardsTemplate)
    self:InitializeFragment()
    self:InitializeFilters()
end

function ZO_ActivityFinderTemplate_Shared:InitializeFilters()
    -- Meant to be overridden
end

function ZO_ActivityFinderTemplate_Shared:InitializeFragment()
    -- Meant to be overridden
end

function ZO_ActivityFinderTemplate_Shared:RegisterEvents()
    local function RefreshFilters()
        self:RefreshFilters()
    end
    ZO_ACTIVITY_FINDER_ROOT_MANAGER:RegisterCallback("OnUpdateLocationData", RefreshFilters)
    ZO_ACTIVITY_FINDER_ROOT_MANAGER:RegisterCallback("OnActivityFinderStatusUpdate", function() self:OnActivityFinderStatusUpdate() end)
    ZO_ACTIVITY_FINDER_ROOT_MANAGER:RegisterCallback("OnHandleLFMPromptResponse", function() self:OnHandleLFMPromptResponse() end)
    ZO_ACTIVITY_FINDER_ROOT_MANAGER:RegisterCallback("OnLevelUpdate", RefreshFilters)
    ZO_ACTIVITY_FINDER_ROOT_MANAGER:RegisterCallback("OnCooldownsUpdate", function() self:OnCooldownsUpdate() end)
    ZO_ACTIVITY_FINDER_ROOT_MANAGER:RegisterCallback("OnCurrentCampaignChanged", RefreshFilters)
    ZO_ACTIVITY_FINDER_ROOT_MANAGER:RegisterCallback("OnHolidaysChanged", RefreshFilters)
    
    ZO_ACTIVITY_FINDER_ROOT_MANAGER:RegisterCallback("OnTributeClubDataInitialized", function() self:OnTributeClubDataInitialized() end)
    ZO_ACTIVITY_FINDER_ROOT_MANAGER:RegisterCallback("OnTributeCampaignDataInitialized", function() self:OnTributeCampaignDataInitialized() end)
    ZO_ACTIVITY_FINDER_ROOT_MANAGER:RegisterCallback("OnTributeClubRankDataChanged", function() self:OnTributeClubRankDataChanged() end)
    ZO_ACTIVITY_FINDER_ROOT_MANAGER:RegisterCallback("OnTributeCampaignDataChanged", function() self:OnTributeCampaignDataChanged() end)
    ZO_ACTIVITY_FINDER_ROOT_MANAGER:RegisterCallback("OnTributeLeaderboardRankChanged", function() self:OnTributeLeaderboardRankChanged() end)

    EVENT_MANAGER:RegisterForEvent(self:GetSystemName(), EVENT_GROUP_FINDER_APPLY_TO_GROUP_LISTING_RESULT, function() self:OnActivityFinderStatusUpdate() end)
    EVENT_MANAGER:RegisterForEvent(self:GetSystemName(), EVENT_GROUP_FINDER_RESOLVE_GROUP_LISTING_APPLICATION_RESULT, function() self:OnActivityFinderStatusUpdate() end)
    EVENT_MANAGER:RegisterForEvent(self:GetSystemName(), EVENT_GROUP_FINDER_REMOVE_GROUP_LISTING_APPLICATION, function() self:OnActivityFinderStatusUpdate() end)
    EVENT_MANAGER:RegisterForEvent(self:GetSystemName(), EVENT_GROUP_FINDER_CREATE_GROUP_LISTING_RESULT, function() self:OnActivityFinderStatusUpdate() end)
    EVENT_MANAGER:RegisterForEvent(self:GetSystemName(), EVENT_GROUP_FINDER_REMOVE_GROUP_LISTING_RESULT, function() self:OnActivityFinderStatusUpdate() end)
end

function ZO_ActivityFinderTemplate_Shared:InitializeSingularPanelControls(rewardsTemplate)
    local panel = self.control:GetNamedChild("SingularSection")

    self.backgroundTexture = panel:GetNamedChild("Background")
    self.titleLabel = panel:GetNamedChild("Title")
    self.descriptionLabel = panel:GetNamedChild("Description")
    self.setTypesSectionControl = panel:GetNamedChild("SetTypesSection")
    self.ratingSectionControl = panel:GetNamedChild("RatingSection")
    self.groupSizeRangeLabel = panel:GetNamedChild("GroupSizeLabel")

    local rewardsSection = panel:GetNamedChild("RewardsSection")
    self.rewardsHeader = rewardsSection:GetNamedChild("Header")
    local rewardsEntries = rewardsSection:GetNamedChild("Entries")
    self.rewardEntryPaddingControl = rewardsEntries:GetNamedChild("Padding")
    self.itemRewardControls = {}
    for i = 1, MAX_ITEM_REWARDS do
        local itemRewardControl = CreateControlFromVirtual("$(parent)ItemReward" .. i, rewardsEntries, "ZO_ActivityFinderTemplateRewardTemplate_Shared")
        ApplyTemplateToControl(itemRewardControl, rewardsTemplate)
        table.insert(self.itemRewardControls, itemRewardControl)
    end

    local xpRewardControl = rewardsEntries:GetNamedChild("XPReward")
    self.xpRewardLabel = xpRewardControl:GetNamedChild("Text")
    ApplyTemplateToControl(xpRewardControl, rewardsTemplate)
    self.xpRewardControl = xpRewardControl

    self.tributeSeasonProgressControl = panel:GetNamedChild("TributeSeasonSection")
    self.tributeSeasonProgressHeader = self.tributeSeasonProgressControl:GetNamedChild("Header")
    self.seasonTimeRemainingLabel = self.tributeSeasonProgressControl:GetNamedChild("CountDown")
    self.leaderboardRankLabel = self.tributeSeasonProgressControl:GetNamedChild("LeaderboardRank")
    self.currentRankIcon = self.tributeSeasonProgressControl:GetNamedChild("CurrentRankIcon")
    self.nextRankIcon = self.tributeSeasonProgressControl:GetNamedChild("NextRankIcon")
    self.progressStateLabel = self.tributeSeasonProgressControl:GetNamedChild("ProgressStateLabel")
    self.progressValueLabel = self.tributeSeasonProgressControl:GetNamedChild("ProgressValueLabel")

    local function UpdateBarVisualDisplay(control, segmentIndex)
        local overlayControl = control:GetNamedChild("Overlay")
        local leftControl = overlayControl:GetNamedChild("Left")
        local rightControl = overlayControl:GetNamedChild("Right")
        local middleControl = overlayControl:GetNamedChild("Middle")

        local numRequiredMatches = GetNumRequiredPlacementMatches()
        local drawLevel = numRequiredMatches + 2 - segmentIndex
        leftControl:SetDrawLevel(drawLevel)
        rightControl:SetDrawLevel(drawLevel)
        middleControl:SetDrawLevel(drawLevel)

        local glossControl = control:GetNamedChild("Gloss")
        glossControl:SetDrawLevel(numRequiredMatches + 2 - segmentIndex)
        glossControl:SetHidden(false)

        if segmentIndex <= numRequiredMatches then
            if self.matchResults[segmentIndex] == ZO_TRIBUTE_FINDER_MATCH_WON then
                ZO_StatusBar_SetGradientColor(control, ZO_XP_BAR_GRADIENT_COLORS)
            elseif self.matchResults[segmentIndex] == ZO_TRIBUTE_FINDER_MATCH_LOSE then
                ZO_StatusBar_SetGradientColor(control, ZO_LOSE_BAR_GRADIENT_COLORS)
            elseif self.matchResults[segmentIndex] == ZO_TRIBUTE_FINDER_MATCH_EMPTY then
                control:SetColor(0, 0, 0, 1)
                glossControl:SetHidden(true)
            end
        end
    end

    self.placementMatchProgressControl = self.tributeSeasonProgressControl:GetNamedChild("PlacementMatchProgressBar")

    self.placementMatchProgressBar = ZO_MultiSegmentProgressBar:New(self.placementMatchProgressControl, self.tributeProgressSegmentTemplate, UpdateBarVisualDisplay)
    self.placementMatchProgressBar:SetSegmentationUniformity(true)
    self.placementMatchProgressBar:SetMaxSegments(GetNumRequiredPlacementMatches())
    self.placementMatchProgressBar:SetProgressBarGrowthDirection(ZO_PROGRESS_BAR_GROWTH_DIRECTION_LEFT_TO_RIGHT)
    self.placementMatchProgressBar:SetPreviousSegmentUnderneathOverlap(-32)

    self.seasonRankProgressStatusBarContainer = self.tributeSeasonProgressControl:GetNamedChild("SeasonRankBarContainer")
    self.seasonRankProgressStatusBar = self.seasonRankProgressStatusBarContainer:GetNamedChild("ProgressBar")
    self.seasonRankProgressBarBG = self.seasonRankProgressStatusBarContainer:GetNamedChild("Bg")
    ZO_StatusBar_SetGradientColor(self.seasonRankProgressStatusBar, ZO_XP_BAR_GRADIENT_COLORS)

    local function OnMouseEnter(...)
        InitializeTooltip(InformationTooltip, self.seasonRankProgressStatusBar, TOP)

        local tierRank = GetTributePlayerCampaignRank()

        if tierRank == TRIBUTE_TIER_INVALID then
            return
        end

        if tierRank == TRIBUTE_TIER_UNRANKED then
            local numRequiredPlacementMatches = GetNumRequiredPlacementMatches()

            local numWins = 0
            local numLoses = 0
            for i = 1, numRequiredPlacementMatches do
                local hasRecord, wasAWin = GetCampaignMatchResultFromHistoryByMatchIndex(i)
                if hasRecord then
                    if wasAWin then
                        numWins = numWins + 1
                    else
                        numLoses = numLoses + 1
                    end
                end
            end

            InformationTooltip:AddLine(zo_strformat(SI_TRIBUTE_SEASON_PLACEMENT_DESCRIPTION, numRequiredPlacementMatches), "", ZO_TOOLTIP_DEFAULT_COLOR:UnpackRGBA())
            InformationTooltip:AddLine(zo_strformat(SI_TRIBUTE_SEASON_PLACEMENT_RECORD_FORMATTER, numWins, numLoses, numRequiredPlacementMatches - numWins - numLoses), "", ZO_TOOLTIP_DEFAULT_COLOR:UnpackRGBA())
        else
            local experience, requiredExperience = GetTributePlayerExperienceInCurrentCampaignRank()

            --If the maximum season experience for this rank is 0, then we are maxed out
            if requiredExperience == 0 then
                InformationTooltip:AddLine(GetString(SI_TRIBUTE_SEASON_EXPERIENCE_LIMIT_REACHED), "", ZO_NORMAL_TEXT:UnpackRGBA())
            else
                local percentageXp = zo_floor(experience / requiredExperience * 100)
                local formattedRatioText = zo_strformat(SI_TRIBUTE_EXPERIENCE_CURRENT_MAX_PERCENT, ZO_CommaDelimitNumber(experience), ZO_CommaDelimitNumber(requiredExperience), percentageXp)
                InformationTooltip:AddLine(zo_strformat(SI_TRIBUTE_SEASON_EXPERIENCE_TOOLTIP_FORMATTER, formattedRatioText), "", ZO_TOOLTIP_DEFAULT_COLOR:UnpackRGBA())
            end

            InformationTooltip:AddVerticalPadding(18)

            InformationTooltip:AddLine(GetString(SI_TRIBUTE_SEASON_EXPERIENCE_DESCRIPTION), "", ZO_TOOLTIP_DEFAULT_COLOR:UnpackRGBA())
        end
    end

    local function OnMouseExit(...)
        ClearTooltip(InformationTooltip)
    end

    self.placementMatchProgressBar.control:SetHandler("OnMouseEnter", OnMouseEnter)
    self.placementMatchProgressBar.control:SetHandler("OnMouseExit", OnMouseExit)
    self.seasonRankProgressStatusBar:SetHandler("OnMouseEnter", OnMouseEnter)
    self.seasonRankProgressStatusBar:SetHandler("OnMouseExit", OnMouseExit)

    self.rewardsSection = rewardsSection
    self.singularSection = panel
end

function ZO_ActivityFinderTemplate_Shared:RefreshView()
    assert(false) -- Must override
end

function ZO_ActivityFinderTemplate_Shared:RefreshFilters()
    assert(false) -- Must override
end

function ZO_ActivityFinderTemplate_Shared:IsShowingTributeFinder()
    -- Meant to be overridden
    return false
end

function ZO_ActivityFinderTemplate_Shared:RefreshTributeSeasonData(forceHide)
    if self.isTributeCampaignDataInitialized and not forceHide and HasActiveCampaignStarted() then
        local tierRank = GetTributePlayerCampaignRank()

        if tierRank == TRIBUTE_TIER_INVALID then
            self.tributeSeasonProgressControl:SetHidden(true)
        else
            self.tributeSeasonProgressControl:SetHidden(false)

            local formattedTime
            local remainingTimeS = GetActiveTributeCampaignTimeRemainingS()
            if remainingTimeS <= ZO_ONE_MINUTE_IN_SECONDS then
                formattedTime = GetString(SI_TRIBUTE_CAMPAIGN_LESS_THAN_ONE_MINUTE)
            else
                formattedTime = ZO_FormatTimeLargestTwo(remainingTimeS, TIME_FORMAT_STYLE_DESCRIPTIVE_MINIMAL)
            end
            -- Cache these for narration
            self.tributeSeasonTimeRemainingText = zo_strformat(SI_TRIBUTE_FINDER_TIME_REMAINING, ZO_WHITE:Colorize(formattedTime))
            self.tributeSeasonRankText = GetString("SI_TRIBUTETIER", tierRank)
            self.seasonTimeRemainingLabel:SetText(self.tributeSeasonTimeRemainingText)

            self.progressStateLabel:SetText(self.tributeSeasonRankText)

            if tierRank == TRIBUTE_TIER_UNRANKED then
                local numRequiredPlacementMatches = GetNumRequiredPlacementMatches()

                local numWins = 0
                local numLoses = 0
                self.matchResults = {}
                for i = 1, numRequiredPlacementMatches do
                    local hasRecord, wasAWin = GetCampaignMatchResultFromHistoryByMatchIndex(i)
                    if hasRecord then
                        if wasAWin then
                            table.insert(self.matchResults, ZO_TRIBUTE_FINDER_MATCH_WON)
                            numWins = numWins + 1
                        else
                            table.insert(self.matchResults, ZO_TRIBUTE_FINDER_MATCH_LOSE)
                            numLoses = numLoses + 1
                        end
                    else
                        table.insert(self.matchResults, ZO_TRIBUTE_FINDER_MATCH_EMPTY)
                    end
                end
                local formattedText = zo_strformat(SI_TRIBUTE_FINDER_PLACEMENT_STATUS, numWins, numLoses)
                -- Cache this for narration
                self.tributePlacementMatchNarrationText = zo_strformat(SI_TRIBUTE_FINDER_PLACEMENT_STATUS_NARRATION, numWins, numLoses)
                self.progressValueLabel:SetText(formattedText)

                self.placementMatchProgressBar:Clear()
                self.placementMatchProgressBar:SetMaxSegments(numRequiredPlacementMatches)
                for i = 1, numRequiredPlacementMatches do
                   self.placementMatchProgressBar:AddSegment()
                end

                self.currentRankIcon:SetTexture(string.format(TRIBUTE_RANK_ICON_FORMATTER, tierRank))
                self.nextRankIcon:SetTexture(string.format(TRIBUTE_RANK_ICON_FORMATTER, tierRank + 1))

                self.leaderboardRankLabel:SetHidden(true)
                self.seasonRankProgressStatusBarContainer:SetHidden(true)
                self.placementMatchProgressControl:SetHidden(false)
            else
                local experience, requiredExperience = GetTributePlayerExperienceInCurrentCampaignRank()

                self.seasonRankProgressStatusBar:SetMinMax(0, requiredExperience)
                self.seasonRankProgressStatusBar:SetValue(experience)

                local anchorRelativePoint = self.tributeSeasonProgressHeader

                -- Cache this for narration
                self.progressValueLabelText = nil

                -- In leaderboard rank
                if tierRank == TRIBUTE_TIER_PLATINUM then
                    local readyState = LEADERBOARD_DATA_RESPONSE_PENDING
                    readyState = RequestTributeLeaderboardRank()

                    if readyState == LEADERBOARD_DATA_READY then
                        local playerLeaderboardRank, totalLeaderboardPlayers = GetTributeLeaderboardRankInfo()
                        local topPercent = totalLeaderboardPlayers == 0 and 100 or playerLeaderboardRank * 100 / totalLeaderboardPlayers

                        local colorizedFormattedLeaderboardRank
                        if topPercent <= 10 then
                            local formattedLeaderboardRank = zo_strformat(SI_TRIBUTE_FINDER_LEADERBOARD_RANK_CONTENT_PERCENT, playerLeaderboardRank, topPercent)
                            colorizedFormattedLeaderboardRank = ZO_SELECTED_TEXT:Colorize(formattedLeaderboardRank)
                        else
                            local formattedLeaderboardRank = zo_strformat(SI_TRIBUTE_FINDER_LEADERBOARD_RANK_CONTENT, playerLeaderboardRank)
                            colorizedFormattedLeaderboardRank = ZO_SELECTED_TEXT:Colorize(formattedLeaderboardRank)
                        end

                        --Cache this for narration
                        self.leaderboardRankLabelText = zo_strformat(SI_TRIBUTE_FINDER_LEADERBOARD_RANK_LABEL, colorizedFormattedLeaderboardRank)
                        self.leaderboardRankLabel:SetText(self.leaderboardRankLabelText)

                        anchorRelativePoint = self.leaderboardRankLabel

                        self.leaderboardRankLabel:SetHidden(false)
                    else
                        self.leaderboardRankLabel:SetHidden(true)
                    end

                    self.progressValueLabelText = GetString(SI_TRIBUTE_FINDER_LEADERBOARD_STATUS)
                    self.progressValueLabel:SetText(self.progressValueLabelText)

                    self.currentRankIcon:SetTexture(string.format(TRIBUTE_RANK_ICON_FORMATTER, tierRank))
                    self.nextRankIcon:SetTexture(string.format(TRIBUTE_RANK_ICON_FORMATTER, TRIBUTE_RANKS_COMPLETED_ICON_INDEX))
                else
                    local formattedText = zo_strformat(SI_TRIBUTE_FINDER_RANKED_STATUS, experience, requiredExperience)
                    self.progressValueLabelText = formattedText
                    self.progressValueLabel:SetText(formattedText)

                    self.currentRankIcon:SetTexture(string.format(TRIBUTE_RANK_ICON_FORMATTER, tierRank))
                    self.nextRankIcon:SetTexture(string.format(TRIBUTE_RANK_ICON_FORMATTER, tierRank + 1))

                    self.leaderboardRankLabel:SetHidden(true)
                end

                local isValid, point, relativeTo, relativePoint, offsetX, offsetY, anchorConstrains = self.currentRankIcon:GetAnchor(0)
                if isValid then
                    self.currentRankIcon:ClearAnchors()
                    self.currentRankIcon:SetAnchor(point, anchorRelativePoint, relativePoint, offsetX, offsetY, anchorConstrains)
                end

                self.seasonRankProgressStatusBarContainer:SetHidden(false)
                self.placementMatchProgressControl:SetHidden(true)
            end
        end
    else
        self.tributeSeasonProgressControl:SetHidden(true)
    end
end

function ZO_ActivityFinderTemplate_Shared:OnActivityFinderStatusUpdate(status)
    assert(false) -- Must override
end

function ZO_ActivityFinderTemplate_Shared:OnHandleLFMPromptResponse()
    --Can be overridden
end

function ZO_ActivityFinderTemplate_Shared:OnCooldownsUpdate()
    assert(false) -- Must override
end

function ZO_ActivityFinderTemplate_Shared:OnTributeClubDataInitialized()
    self.isTributeClubDataInitialized = true
end

function ZO_ActivityFinderTemplate_Shared:OnTributeCampaignDataInitialized()
    self.isTributeCampaignDataInitialized = true
end

function ZO_ActivityFinderTemplate_Shared:OnTributeClubRankDataChanged()
    self.isTributeClubDataInitialized = true
end

function ZO_ActivityFinderTemplate_Shared:OnTributeCampaignDataChanged()
    --Can be overridden
end

function ZO_ActivityFinderTemplate_Shared:OnTributeLeaderboardRankChanged()
    self:RefreshView()
end

do
    local DAILY_HEADER = GetString(SI_ACTIVITY_FINDER_DAILY_REWARD_HEADER)
    local STANDARD_HEADER = GetString(SI_ACTIVITY_FINDER_STANDARD_REWARD_HEADER)
    local FIRST_DAILY_HEADER = GetString(SI_ACTIVITY_FINDER_FIRST_DAILY_REWARD_HEADER)

    local g_previousControl = nil
    local g_nextControlOnSameLine = false

    local function AnchorRewardControl(rewardControl)
        rewardControl:ClearAnchors()
        if g_previousControl then
            if g_nextControlOnSameLine then
                rewardControl:SetAnchor(LEFT, g_previousControl, RIGHT, ZO_ACTIVITY_FINDER_REWARD_ENTRY_PADDING_X, 0)
            else
                rewardControl:SetAnchor(TOPLEFT, g_previousControl, BOTTOMLEFT, 0, ZO_ACTIVITY_FINDER_REWARD_ENTRY_PADDING_Y)
            end
        else
            rewardControl:SetAnchor(TOPLEFT)
        end

        g_nextControlOnSameLine = not g_nextControlOnSameLine
        if g_nextControlOnSameLine then
            g_previousControl = rewardControl
        end
    end

    local g_rewardControlsToAnchor = {}

    function ZO_ActivityFinderTemplate_Shared:RefreshRewards(location)
        local currentSelectionHasRewardsData = location:HasRewardData()
        local hideRewards = true
        local description = ""
        if currentSelectionHasRewardsData then
            local rewardUIDataId, xpReward = location:GetRewardData()
            ZO_ClearNumericallyIndexedTable(g_rewardControlsToAnchor)

            local numShownItemRewardNodes = 0
            if rewardUIDataId ~= 0 then
                numShownItemRewardNodes = GetNumLFGActivityRewardUINodes(rewardUIDataId)

                assert(numShownItemRewardNodes <= MAX_ITEM_REWARDS) --If we've allowed for more nodes in the def, we haven't accounted for it in the UI

                for nodeIndex = 1, numShownItemRewardNodes do
                    local displayName, icon, textColorRed, textColorBlue, textColorGreen = GetLFGActivityRewardUINodeInfo(rewardUIDataId, nodeIndex)

                    local itemRewardControl = self.itemRewardControls[nodeIndex]
                    itemRewardControl.icon:SetTexture(icon)
                    itemRewardControl.text:SetText(zo_strformat(SI_ACTIVITY_FINDER_REWARD_NAME_FORMAT, displayName))
                    itemRewardControl.text:SetColor(textColorRed, textColorBlue, textColorGreen)
                    itemRewardControl:SetHidden(false)
                    table.insert(g_rewardControlsToAnchor, itemRewardControl)
                    hideRewards = false
                end

                description = GetLFGActivityRewardDescriptionOverride(rewardUIDataId)
            end

            for nodeIndex = numShownItemRewardNodes + 1, MAX_ITEM_REWARDS do
                self.itemRewardControls[nodeIndex]:SetHidden(true)
            end

            if xpReward > 0 then
                self.xpRewardLabel:SetText(zo_strformat(SI_ACTIVITY_FINDER_REWARD_XP_FORMAT, ZO_CommaDelimitNumber(xpReward)))
                self.xpRewardControl:SetHidden(false)
                local xpIndex = #g_rewardControlsToAnchor > 0 and 2 or 1 -- Design always wants XP to be the second thing in the left-to right/top to bottom grid (unless it's the only thing)
                table.insert(g_rewardControlsToAnchor, xpIndex, self.xpRewardControl)
                hideRewards = false
            else
                self.xpRewardControl:SetHidden(true)
            end

            g_previousControl = nil
            g_nextControlOnSameLine = false
            for _, control in ipairs(g_rewardControlsToAnchor) do
                AnchorRewardControl(control)
            end
        end

        if description == "" then
            description = location:GetDescription()
        end

        self.descriptionLabel:SetText(description)

        if hideRewards then
            self.rewardsSection:SetHidden(true)
        else
            local headerText = STANDARD_HEADER
            if location:IsEligibleForDailyReward() then
                if location:GetActivityType() == LFG_ACTIVITY_TRIBUTE_COMPETITIVE then
                    headerText = FIRST_DAILY_HEADER
                else
                    headerText = DAILY_HEADER
                end
            end

            self.rewardsHeader:SetText(headerText)
            self.rewardsSection:SetHidden(false)

            local overrideOffsetY = (location:GetActivityType() == LFG_ACTIVITY_TRIBUTE_COMPETITIVE or location:GetActivityType() == LFG_ACTIVITY_TRIBUTE_CASUAL) and self.rewardsOffsetYTribute or self.rewardsOffsetYDefault
            local isValid, point, relativeTo, relativePoint, offsetX, offsetY = self.rewardsSection:GetAnchor()
            if isValid then
                self.rewardsSection:ClearAnchors()
                self.rewardsSection:SetAnchor(point, relativeTo, relativePoint, offsetX, overrideOffsetY)
            end
        end
    end
end

function ZO_ActivityFinderTemplate_Shared:GetLFMPromptInfo()
    local shouldShowLFMPrompt = false
    local lfmPromptActivityName
    if CanSendLFMRequest() then
        local activityId = GetCurrentLFGActivityId()
        local activityType = GetActivityType(activityId)
        local modes = self.dataManager:GetFilterModeData()
        if ZO_IsElementInNumericallyIndexedTable(modes:GetActivityTypes(), activityType) then
            shouldShowLFMPrompt = true
            lfmPromptActivityName = GetActivityName(activityId)
        end
    end
    return shouldShowLFMPrompt, lfmPromptActivityName
end

function ZO_ActivityFinderTemplate_Shared:GetLevelLockInfoByActivity(activityType)
    local isLevelLocked = false
    local lowestLevelLimit, highestLevelLimit, lowestChampionPointLimit, highestChampionPointLimit

    local maxLevel = GetMaxLevel()

    local locationData = ZO_ACTIVITY_FINDER_ROOT_MANAGER:GetLocationsData(activityType)
    for _, location in ipairs(locationData) do
        local locationLevelMin = location:GetLevelMin()
        if locationLevelMin == maxLevel then --This is a veteran activity
            local locationChampionPointsMin = location:GetChampionPointsMin()
            local locationChampionPointsMax = location:GetChampionPointsMax()

            if not lowestChampionPointLimit or locationChampionPointsMin < lowestChampionPointLimit then
                lowestChampionPointLimit = locationChampionPointsMin
            end

            if not highestChampionPointLimit or locationChampionPointsMax > highestChampionPointLimit then
                highestChampionPointLimit = locationChampionPointsMax
            end
        else
            local locationLevelMax = location:GetLevelMax()

            if not lowestLevelLimit or locationLevelMin < lowestLevelLimit then
                lowestLevelLimit = locationLevelMin
            end

            if not highestLevelLimit or locationLevelMax > highestLevelLimit then
                highestLevelLimit = locationLevelMax
            end
        end
    end
    
    if lowestLevelLimit then
        local playerLevel = GetUnitLevel("player")
        if playerLevel < lowestLevelLimit or playerLevel > highestLevelLimit then
            isLevelLocked = true
        end
    elseif lowestChampionPointLimit then
        if not CanUnitGainChampionPoints("player") then
            isLevelLocked = true
        else
            local playerChampionPoints = GetPlayerChampionPointsEarned()
            if playerChampionPoints < lowestChampionPointLimit or playerChampionPoints > highestChampionPointLimit then
                isLevelLocked = true
            end
        end
    else
        -- No location data found for this activity type, so lock it down
        isLevelLocked = true
    end

    return isLevelLocked, lowestLevelLimit, lowestChampionPointLimit, highestLevelLimit, highestChampionPointLimit
end

function ZO_ActivityFinderTemplate_Shared:GetLevelLockInfo()
    local isLevelLocked = true
    local lowestLevelLimit, lowestChampionPointLimit

    local modes = self.dataManager:GetFilterModeData()
    for _, activityType in ipairs(modes:GetActivityTypes()) do
        local locked, level, championPoints = self:GetLevelLockInfoByActivity(activityType)
        if level and (not lowestLevelLimit or level < lowestLevelLimit) then
            lowestLevelLimit = level
        end

        if championPoints and (not lowestChampionPointLimit or championPoints < lowestChampionPointLimit) then
            lowestChampionPointLimit = championPoints
        end

        if not locked then
            isLevelLocked = false
        end
    end

    return isLevelLocked, lowestLevelLimit, lowestChampionPointLimit
end

function ZO_ActivityFinderTemplate_Shared:GetNumLocations()
    local numLocations = 0

    local modes = self.dataManager:GetFilterModeData()
    for _, activityType in ipairs(modes:GetActivityTypes()) do
        numLocations = numLocations + ZO_ACTIVITY_FINDER_ROOT_MANAGER:GetNumLocationsByActivity(activityType, modes:GetVisibleEntryTypes())
    end

    return numLocations
end

function ZO_ActivityFinderTemplate_Shared:GetGlobalLockInfo()
    local isGloballyLocked = false
    local globalLockReasons =
    {
        isLockedByManager = self.dataManager:GetManagerLockInfo(),
        isLockedByNotLeader = ZO_ACTIVITY_FINDER_ROOT_MANAGER:IsLockedByNotLeader(),
        isActiveWorldBattleground = IsActiveWorldBattleground(),
        isGroupFinderInUse = ZO_GroupFinder_IsGroupFinderInUse(),
    }

    for _, reason in pairs(globalLockReasons) do
        if reason == true then
            isGloballyLocked = true
            break
        end
    end

    return isGloballyLocked, globalLockReasons
end

function ZO_ActivityFinderTemplate_Shared:GetGlobalLockText()
    local isGloballyLocked, globalLockReasons = self:GetGlobalLockInfo()
    local lockReasonText
    if isGloballyLocked then
        if globalLockReasons.isActiveWorldBattleground then
            lockReasonText = GetString(SI_LFG_LOCK_REASON_IN_BATTLEGROUND)
        elseif globalLockReasons.isLockedByManager then
            lockReasonText = self.dataManager:GetManagerLockText()
        elseif globalLockReasons.isGroupFinderInUse then
            lockReasonText = GetString(SI_ACTIVITY_FINDER_LOCKED_BY_GROUP_FINDER_TEXT)
        elseif globalLockReasons.isLockedByNotLeader then
            lockReasonText = GetString(SI_ACTIVITY_FINDER_LOCKED_NOT_LEADER_TEXT)
        end
    end
    return lockReasonText
end

function ZO_ActivityFinderTemplate_Shared:GetLevelLockTextByActivity(activityType)
    local isLocked, levelMin, championPointsMin = self:GetLevelLockInfoByActivity(activityType)
    local lockReasonText
    if isLocked then
        if levelMin then
            lockReasonText = zo_strformat(SI_LFG_LOCK_REASON_PLAYER_MIN_LEVEL_REQUIREMENT, levelMin)
        elseif championPointsMin then
            lockReasonText = zo_strformat(SI_LFG_LOCK_REASON_PLAYER_MIN_CHAMPION_REQUIREMENT, championPointsMin)
        end
    end
    return lockReasonText
end

function ZO_ActivityFinderTemplate_Shared:GetLockTextByActivity(activityType)
    local lockText = self:GetGlobalLockText()
    if not lockText then
        lockText = self:GetLevelLockTextByActivity(activityType)
    end
    return lockText
end

function ZO_ActivityFinderTemplate_Shared.AppendSetDataToControl(setTypesSectionControl, setData)
    local hideControls = true
    local setTypesHeader = setTypesSectionControl:GetNamedChild("Header")
    local setTypesList = setTypesSectionControl:GetNamedChild("List")

    if setData:IsSetEntryType() then
        local setTypesHeaderText = setData:GetSetTypesHeaderText()
        local setTypesListText = setData:GetSetTypesListText()
        if setTypesHeaderText ~= "" and setTypesListText ~= "" then
            setTypesHeader:SetText(setTypesHeaderText)
            setTypesList:SetText(setTypesListText)
            hideControls = false
        end
    end

    setTypesHeader:SetHidden(hideControls)
    setTypesList:SetHidden(hideControls)
end