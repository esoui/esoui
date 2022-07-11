ZO_TributePatronSelection_Shared = ZO_InitializingObject:Subclass()

function ZO_TributePatronSelection_Shared:Initialize(control, templateData)
    self.control = control
    self.templateData = templateData

    ZO_TRIBUTE_PATRON_SELECTION_MANAGER:RegisterCallback("BeginSelection", function() 
        self:OnBeginSelection() 
    end)

    ZO_TRIBUTE_PATRON_SELECTION_MANAGER:RegisterCallback("EndSelection", function() 
        self:Hide() 
    end)

    ZO_TRIBUTE_PATRON_SELECTION_MANAGER:RegisterCallback("PatronDrafted", function()
        local DONT_RESET_TO_TOP = false
        local RESELECT_DATA = true
        self:RefreshGridList(DONT_RESET_TO_TOP, RESELECT_DATA) 
    end)

    ZO_TRIBUTE_PATRON_SELECTION_MANAGER:RegisterCallback("PatronSelected", function()
        local DONT_RESET_TO_TOP = false
        local RESELECT_DATA = true
        self:RefreshGridList(DONT_RESET_TO_TOP, RESELECT_DATA) 
    end)

    ZO_TRIBUTE_PATRON_SELECTION_MANAGER:RegisterCallback("BeginNextDraftingPhase", function()
        KEYBIND_STRIP:UpdateCurrentKeybindButtonGroups()
        self:RefreshSelectionState() 
    end)

    self:InitializeControls()
    self:InitializeGridList()
    self:InitializeKeybindStripDescriptors()

    self.turnTimerWarningThresholdMs = GetTributePatronDraftTurnTimerWarningThreshold()

    local function OnUpdateTimeCallback(_, frameTimeSeconds)
        local formattedTimeLeft = GetString(SI_TRIBUTE_DECK_SELECTION_TURN_TIMER_NO_TIME)
        local timeLeftMs = GetTributeRemainingTimeForTurn()
        if timeLeftMs and not ZO_TRIBUTE_PATRON_SELECTION_MANAGER:IsDraftAnimating() then
            formattedTimeLeft = ZO_FormatTimeAsDecimalWhenBelowThreshold(timeLeftMs / 1000)
            if timeLeftMs < self.turnTimerWarningThresholdMs then
                formattedTimeLeft = ZO_ERROR_COLOR:Colorize(formattedTimeLeft)
            end
        end
        self.timerText:SetText(formattedTimeLeft)
    end
    self.timerContainer:SetHandler("OnUpdate", OnUpdateTimeCallback)
end

function ZO_TributePatronSelection_Shared:InitializeGridList()
    self.gridContainerControl = self.control:GetNamedChild("GridContainer")
    self.gridListControl = self.gridContainerControl:GetNamedChild("GridList")
    self.gridList = self.templateData.gridListClass:New(self.gridListControl)

    local function PatronEntryEqualityFunction(left, right)
        return left:GetId() == right:GetId()
    end

    local patronEntryData = self.templateData.patronEntryData
    local HIDE_CALLBACK = nil
    self.gridList:AddEntryTemplate(patronEntryData.entryTemplate, patronEntryData.width, patronEntryData.height, ZO_DefaultGridTileEntrySetup, HIDE_CALLBACK, ZO_DefaultGridTileEntryReset, patronEntryData.gridPaddingX, patronEntryData.gridPaddingY)
    self.gridList:SetEntryTemplateEqualityFunction(patronEntryData.entryTemplate, PatronEntryEqualityFunction)
end

function ZO_TributePatronSelection_Shared:RefreshGridList(resetToTop, reselectData, animateInstantly)
    if self.gridList then
        local selectedData = self.gridList:GetSelectedData()
        self.gridList:ClearGridList(not resetToTop)
        local patronDataList = ZO_TRIBUTE_PATRON_SELECTION_MANAGER:GetPatronData()
        for _, patronData in ipairs(patronDataList) do
            local entryData = ZO_EntryData:New(patronData)
            entryData.animateInstantly = animateInstantly
            self.gridList:AddEntry(entryData, self.templateData.patronEntryData.entryTemplate)
        end

        if reselectData then
            self.gridList:SetAutoSelectToMatchingDataEntry(selectedData)
        end
        self.gridList:CommitGridList()
        KEYBIND_STRIP:UpdateKeybindButtonGroup(self.keybindStripDescriptor)
    end
end

function ZO_TributePatronSelection_Shared:OnBeginSelection()
    if self:CanShow() then
        self:RefreshTimerInfo()
        self:RefreshMatchInfo()
        self:RefreshSelectionState()
        self:Show()
    end
end

function ZO_TributePatronSelection_Shared:RefreshTimerInfo()
    local hasTurnTimer = ZO_TRIBUTE_PATRON_SELECTION_MANAGER:HasTurnTimer()
    self.timerContainer:SetHidden(not hasTurnTimer)
end

function ZO_TributePatronSelection_Shared:RefreshSelectionState()
    local patronToSelect = ZO_TRIBUTE_PATRON_SELECTION_MANAGER:GetNumDraftedPatrons() + 1
    self.activePlayerPerspective = GetActiveTributePlayerPerspective()
    if self.activePlayerPerspective == TRIBUTE_PLAYER_PERSPECTIVE_SELF then
        self.selectionText:SetText(zo_strformat(SI_TRIBUTE_DECK_SELECTION_PLAYER_SELECT, patronToSelect))
        self.divider:SetColor(GetInterfaceColor(INTERFACE_COLOR_TYPE_TEXT_COLORS, INTERFACE_TEXT_COLOR_SUCCEEDED))
    else
        local opponentName, playerType = GetTributePlayerInfo(TRIBUTE_PLAYER_PERSPECTIVE_OPPONENT)
        if playerType == TRIBUTE_PLAYER_TYPE_NPC then
            self.selectionText:SetText(zo_strformat(SI_TRIBUTE_DECK_SELECTION_NPC_SELECT, opponentName))
        else
            opponentName = ZO_FormatUserFacingDisplayName(opponentName)
            self.selectionText:SetText(zo_strformat(SI_TRIBUTE_DECK_SELECTION_OPPONENT_SELECT, opponentName, patronToSelect))
        end
        self.divider:SetColor(GetInterfaceColor(INTERFACE_COLOR_TYPE_TEXT_COLORS, INTERFACE_TEXT_COLOR_FAILED))
    end
end

function ZO_TributePatronSelection_Shared:RefreshMatchInfo()
    local matchType = GetTributeMatchType()
    local opponentName, playerType = GetTributePlayerInfo(TRIBUTE_PLAYER_PERSPECTIVE_OPPONENT)
    opponentName = playerType ~= TRIBUTE_PLAYER_TYPE_NPC and ZO_FormatUserFacingDisplayName(opponentName) or opponentName
    self.matchInfo:SetText(zo_strformat(SI_TRIBUTE_DECK_SELECTION_MATCH_DESCRIPTION, GetString("SI_TRIBUTEMATCHTYPE", matchType), opponentName))
end

function ZO_TributePatronSelection_Shared:ShouldShowConfirm()
    if ZO_TRIBUTE_PATRON_SELECTION_MANAGER:IsDraftAnimating() then
        return false
    else
        return GetActiveTributePlayerPerspective() == TRIBUTE_PLAYER_PERSPECTIVE_SELF
    end
end

ZO_TributePatronSelection_Shared.InitializeControls = ZO_TributePatronSelection_Shared:MUST_IMPLEMENT()

ZO_TributePatronSelection_Shared.InitializeKeybindStripDescriptors = ZO_TributePatronSelection_Shared:MUST_IMPLEMENT()

ZO_TributePatronSelection_Shared.CanShow = ZO_TributePatronSelection_Shared:MUST_IMPLEMENT()

ZO_TributePatronSelection_Shared.Show = ZO_TributePatronSelection_Shared:MUST_IMPLEMENT()

ZO_TributePatronSelection_Shared.Hide = ZO_TributePatronSelection_Shared:MUST_IMPLEMENT()