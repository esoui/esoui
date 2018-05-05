SlashCommandAutoComplete = ZO_AutoComplete:Subclass()

function SlashCommandAutoComplete:New(...)
	return ZO_AutoComplete.New(self, ...)
end

function SlashCommandAutoComplete:Initialize(...)
    ZO_AutoComplete.Initialize(self, ...)

    self.possibleMatches = {}

    local editControl = CHAT_SYSTEM:GetEditControl()

    self:SetUseCallbacks(true)
    self:SetAnchorStyle(AUTO_COMPLETION_ANCHOR_BOTTOM)
    self:SetOwner(SLASH_COMMANDS)
    self:SetKeepFocusOnCommit(true)

    local function OnAutoCompleteEntrySelected(name, selectionMethod)
        editControl:SetText(name)
    end

    self:RegisterCallback(ZO_AutoComplete.ON_ENTRY_SELECTED, OnAutoCompleteEntrySelected)

    ZO_PreHook("ZO_ChatTextEntry_PreviousCommand", function(...)
        if not IsShiftKeyDown() and self:IsOpen() then
            local index = self:GetAutoCompleteIndex()
            if not index or index > 1 then
                self:ChangeAutoCompleteIndex(-1)
                return true
            end
        end
    end)

    ZO_PreHook("ZO_ChatTextEntry_NextCommand", function(...)
        if not IsShiftKeyDown() and self:IsOpen() then
            local index = self:GetAutoCompleteIndex()
            if not index or index < self:GetNumAutoCompleteEntries() then
                self:ChangeAutoCompleteIndex(1)
                return true --Handled
            end
        end
    end)
end

function SlashCommandAutoComplete:InvalidateSlashCommandCache()
    self.possibleMatches = {}
end

function SlashCommandAutoComplete:GetAutoCompletionResults(text)
    if #text < 3 then
        return
    end
    local startChar = text:sub(1, 1)
    if startChar ~= "/" and startChar ~= "]" then
        return
    end
    if text:find(" ", 1, true) then
        return
    end

    if next(self.possibleMatches) == nil then
        for command in pairs(SLASH_COMMANDS) do
            if #command > 0 then
                self.possibleMatches[command:lower()] = command
            end
        end

        if BRACKET_COMMANDS then
            for command in pairs(BRACKET_COMMANDS) do
                if #command > 0 then
                    self.possibleMatches[command:lower()] = command
                end
            end
        end

        if SERVER_BRACKET_COMMANDS then
            for command in pairs(SERVER_BRACKET_COMMANDS) do
                if #command > 0 then
                    self.possibleMatches[command:lower()] = command
                end
            end
        end
    end

    local results = GetTopMatchesByLevenshteinSubStringScore(self.possibleMatches, text, 2, self.maxResults)
    if results then
        return unpack(results)
    end
    return nil
end

local editControl = CHAT_SYSTEM:GetEditControl()
SLASH_COMMAND_AUTO_COMPLETE = SlashCommandAutoComplete:New(editControl, nil, nil, nil, 8, AUTO_COMPLETION_AUTOMATIC_MODE, AUTO_COMPLETION_DONT_USE_ARROWS)