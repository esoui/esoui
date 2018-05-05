--[[
    ZO_AutoComplete is a utility object that connects to an edit control to provide autocomplete functionality.
]]

local COMMIT_BEHAVIOR_KEEP_FOCUS = 1
local COMMIT_BEHAVIOR_LOSE_FOCUS = 2

AUTO_COMPLETION_AUTOMATIC_MODE = true
AUTO_COMPLETION_MANUAL_MODE = false

AUTO_COMPLETION_USE_ARROWS = true
AUTO_COMPLETION_DONT_USE_ARROWS = false

AUTO_COMPLETION_DONT_CALL_HOOKED_HANDLERS = true
AUTO_COMPLETION_CALL_HOOKED_HANDLERS = false

AUTO_COMPLETION_ONLINE_ONLY = true
AUTO_COMPLETION_ONLINE_OR_OFFLINE = false

AUTO_COMPLETION_ANCHOR_TOP = 0
AUTO_COMPLETION_ANCHOR_BOTTOM = 1

AUTO_COMPLETION_SELECTED_BY_SPACE = 0
AUTO_COMPLETION_SELECTED_BY_ENTER = 1
AUTO_COMPLETION_SELECTED_BY_CLICK = 2
AUTO_COMPLETION_SELECTED_BY_TAB = 3

ZO_AutoComplete = ZO_CallbackObject:Subclass()
ZO_AutoComplete.ON_ENTRY_SELECTED = "ZO_AutoComplete_On_Entry_Selected"

AUTO_COMPLETE_FLAG_ALL = -1
AUTO_COMPLETE_FLAG_NONE = 0

ZO_AutoComplete.FlagHandlers = { }

function ZO_AutoComplete.AddFlag(handler)
    table.insert(ZO_AutoComplete.FlagHandlers, handler)
    return #ZO_AutoComplete.FlagHandlers
end


function ZO_AutoComplete:New(...)
    local autoComplete = ZO_CallbackObject.New(self)
    autoComplete:Initialize(...)
    return autoComplete
end

function ZO_AutoComplete:Initialize(editControl, includeFlags, excludeFlags, onlineOnly, maxResults, mode, allowArrows, dontCallHookedHandlers)
    self:SetEnabled(true)
    self:SetIncludeFlags(includeFlags)
    self:SetExcludeFlags(excludeFlags)
    self:SetOnlineOnly(onlineOnly)
    self:SetMaxResults(maxResults)
    
    self.automaticMode = mode == nil or mode == AUTO_COMPLETION_AUTOMATIC_MODE
    self.anchorStyle = AUTO_COMPLETION_ANCHOR_TOP
    self.useArrows = allowArrows == nil or AUTO_COMPLETION_USE_ARROWS == allowArrows
    self.dontCallHookedHandlers = dontCallHookedHandlers
    if(self.dontCallHookedHandlers == nil) then
        self.dontCallHookedHandlers = true
    end
     
    self.keepFocusOnCommit = true
    
    self:SetEditControl(editControl)
    self:SetOwner(editControl)
end

function ZO_AutoComplete:SetEnabled(enabled)
    self.enabled = enabled
    if not enabled then
        self:Hide()
    end
end

function ZO_AutoComplete:SetIncludeFlags(includeFlags)
    self.includeFlags = includeFlags
end

function ZO_AutoComplete:SetExcludeFlags(excludeFlags)
    self.excludeFlags = excludeFlags
end

function ZO_AutoComplete:SetOnlineOnly(onlineOnly)
    self.onlineOnly = onlineOnly
end

function ZO_AutoComplete:SetMaxResults(maxResults)
    self.maxResults = maxResults
end

function ZO_AutoComplete:SetEditControl(editControl)
    if editControl then
        if self.automaticMode then
            ZO_PreHookHandler(editControl, "OnTextChanged", function() self:OnTextChanged() end)
        end

        ZO_PreHookHandler(editControl, "OnEnter", function()
            if self:IsOpen() then
                if not self.keepFocusOnCommit and self.automaticMode then
                    return self:OnCommit(COMMIT_BEHAVIOR_LOSE_FOCUS, AUTO_COMPLETION_SELECTED_BY_ENTER)
                else
                    return self:OnCommit(COMMIT_BEHAVIOR_KEEP_FOCUS, AUTO_COMPLETION_SELECTED_BY_ENTER)
                end
            end
        end)

        ZO_PreHookHandler(editControl, "OnTab", function()
            if self:IsOpen() then
                if not ZO_Menu_GetSelectedIndex() then
                    self:ChangeAutoCompleteIndex(1)
                end
                return self:OnCommit(COMMIT_BEHAVIOR_KEEP_FOCUS, AUTO_COMPLETION_SELECTED_BY_TAB)
            end
        end)

        if self.useArrows then
            ZO_PreHookHandler(editControl, "OnDownArrow", function() self:ChangeAutoCompleteIndex(1) end)
            ZO_PreHookHandler(editControl, "OnUpArrow", function() self:ChangeAutoCompleteIndex(-1) end)
        end
    
        ZO_PreHookHandler(editControl, "OnFocusLost", function() self:Hide() end)
        ZO_PreHookHandler(editControl, "OnHide", function() self:Hide() end)
    end
    
    self.editControl = editControl
end

function ZO_AutoComplete:SetOwner(owner)
    self.owner = owner
end

function ZO_AutoComplete:SetKeepFocusOnCommit(keepFocus)
    self.keepFocusOnCommit = keepFocus
end

function ZO_AutoComplete:Show(text)
    if not self:ApplyAutoCompletionResults(self:GetAutoCompletionResults(text)) then
        self:Hide()
    end
end

function ZO_AutoComplete:Hide()
    if self:IsOpen() then
        ClearMenu()
    end
end

function ZO_AutoComplete:IsOpen()
    return IsMenuVisisble() and GetMenuOwner() == self.owner
end

function ZO_AutoComplete:SetUseCallbacks(useCallbacks)
    self.useCallbacks = useCallbacks
end

function ZO_AutoComplete:SetAnchorStyle(style)
    self.anchorStyle = style
end

do
    local ComputeStringDistance = ComputeStringDistance

    local function ComputeSubStringMatchScore(source, startIndex, trimmedTextToScore)
        local startIndex, endIndex = source:find(trimmedTextToScore, startIndex, true)
        if startIndex then
            return ((endIndex - startIndex) / (#source * .1)) * 10
        end
        return 0
    end

    function ComputeScore(source, scoringText, startIndex, trimmedTextToScore)
        return ComputeStringDistance(source, scoringText) - ComputeSubStringMatchScore(source, startIndex, trimmedTextToScore)
    end

    local POOR_MATCH_RATIO = .75
    local POOR_MATCH_MIN = 1

    local scores = {}
    local function BinaryInsertComparer(leftScore, _, rightIndex)
        return leftScore - scores[rightIndex]
    end

    local zo_binarysearch = zo_binarysearch
    function GetTopMatchesByLevenshteinSubStringScore(stringsToScore, scoringText, startingIndex, maxResults, noMinScore)
        maxResults = maxResults or 10
        if maxResults == 0 then return end

        startingIndex = startingIndex or 1
        scoringText = zo_strlower(scoringText)
        local trimmedTextToScore = scoringText:sub(startingIndex, 20)

        local results = {}
        ZO_ClearNumericallyIndexedTable(scores)

        local minScore = POOR_MATCH_RATIO * (zo_min(#scoringText, 10 + startingIndex) - startingIndex - POOR_MATCH_MIN)
        for lowerSource, source in pairs(stringsToScore) do
            local score = ComputeScore(lowerSource, scoringText, startingIndex, trimmedTextToScore)
            if noMinScore or (score <= minScore) then
                local _, insertPosition = zo_binarysearch(score, results, BinaryInsertComparer)
                table.insert(results, insertPosition, source)
                table.insert(scores, insertPosition, score)

                results[maxResults + 1] = nil
                scores[maxResults + 1] = nil
            end
        end

        return results
    end
end

do
    local function TryCallFlagHandler(flag, possibleMatches, input, onlineOnly, include)
        local handler = ZO_AutoComplete.FlagHandlers[flag]
        if handler then
            handler(possibleMatches, input, onlineOnly, include)
        end
    end

    local INCLUDE = true
    local EXCLUDE = false

    local function GenerateAutoCompletionResults(input, maxResults, onlineOnly, includeFlags, excludeFlags, noMinScore)
        local possibleMatches = {}

        if not includeFlags or includeFlags[1] == AUTO_COMPLETE_FLAG_ALL then
            for flag in ipairs(ZO_AutoComplete.FlagHandlers) do
                TryCallFlagHandler(flag, possibleMatches, input, onlineOnly, INCLUDE)
            end
        else
            for i, flag in ipairs(includeFlags) do
                TryCallFlagHandler(flag, possibleMatches, input, onlineOnly, INCLUDE)
            end
        end

        if excludeFlags then
            if excludeFlags[1] == AUTO_COMPLETE_FLAG_ALL then
                return
            end
            for i, flag in ipairs(excludeFlags) do
                TryCallFlagHandler(flag, possibleMatches, input, onlineOnly, EXCLUDE)
            end
        end 

        local results = GetTopMatchesByLevenshteinSubStringScore(possibleMatches, input, 1, maxResults, noMinScore)
        if results then
            return unpack(results)
        end
    end

    function GetAutoCompletion(input, maxResults, onlineOnly, includeFlags, excludeFlags, noMinScore)
        maxResults = maxResults or 10
        input = input:lower()

        return GenerateAutoCompletionResults(input, maxResults, onlineOnly, includeFlags, excludeFlags, noMinScore)
    end

    function ZO_AutoComplete:GetAutoCompletionResults(text)
        return GetAutoCompletion(text, self.maxResults, self.onlineOnly, self.includeFlags, self.excludeFlags)
    end
end

function ZO_AutoComplete:ApplyAutoCompletionResults(...)
    if ... and ... ~= "" then
        ClearMenu()
        SetMenuMinimumWidth(self.editControl:GetWidth() - GetMenuPadding() * 2)

        local numResults = select("#", ...)
        for i=1, numResults do
            local name = select(i, ...)
            AddMenuItem(name, function()
                if self.useCallbacks then
                    self:FireCallbacks(self.ON_ENTRY_SELECTED, name, AUTO_COMPLETION_SELECTED_BY_CLICK)
                else
                    self.editControl:SetText(name) 
                end
            end)
        end
        
        ShowMenu(self.owner, nil, MENU_TYPE_TEXT_ENTRY_DROP_DOWN)

        if self.anchorStyle == AUTO_COMPLETION_ANCHOR_BOTTOM then
            ZO_Menu:ClearAnchors()
            ZO_Menu:SetAnchor(BOTTOMLEFT, self.editControl, TOPLEFT, -8, -2)
            ZO_Menu:SetAnchor(BOTTOMRIGHT, self.editControl, TOPRIGHT, 8, -2)
        else
            ZO_Menu:ClearAnchors()
            ZO_Menu:SetAnchor(TOPLEFT, self.editControl, BOTTOMLEFT, -8, 2)
            ZO_Menu:SetAnchor(TOPRIGHT, self.editControl, BOTTOMRIGHT, 8, 2)
        end
        
        return true
    end
    
    return false
end

function ZO_AutoComplete:OnTextChanged()
    if self.enabled and self.editControl:HasFocus() and self.editControl:GetText() ~= "" then
        self:Show(self.editControl:GetText())        
    else
        self:Hide()
    end
end

function ZO_AutoComplete:ChangeAutoCompleteIndex(offset)
    if self:IsOpen() then
        local numItems = ZO_Menu_GetNumMenuItems()
        if numItems > 0 then
            local index = (ZO_Menu_GetSelectedIndex() or 0) + offset
        
            ZO_Menu_SetSelectedIndex(index)
        end
    end
end

function ZO_AutoComplete:GetNumAutoCompleteEntries()
    if self:IsOpen() then
        return ZO_Menu_GetNumMenuItems()
    end
end

function ZO_AutoComplete:GetAutoCompleteIndex()
    if self:IsOpen() then
        return ZO_Menu_GetSelectedIndex()
    end
end 

function ZO_AutoComplete:OnCommit(commitBehavior, commitMethod)
    if self:IsOpen() then
        local selectedIndex = ZO_Menu_GetSelectedIndex()
        if selectedIndex then
            local name = ZO_Menu_GetSelectedText()
            if self.useCallbacks then
                self:FireCallbacks(self.ON_ENTRY_SELECTED, name, commitMethod)
            else
                self.editControl:SetText(name) 
            end
        end
        if not commitBehavior or commitBehavior == COMMIT_BEHAVIOR_LOSE_FOCUS then
            self.editControl:LoseFocus()
        end

        self:Hide()

        if selectedIndex then
            return self.dontCallHookedHandlers
        else
            return false
        end
    end
end