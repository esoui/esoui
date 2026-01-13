ZO_SlashCommandAutoComplete = ZO_AutoComplete:Subclass()

function ZO_SlashCommandAutoComplete:Initialize(editControl, ...)
    ZO_AutoComplete.Initialize(self, editControl, ...)

    self.possibleCommandMatches = {}
    self.commandString = nil
    self.commandInfo = nil
    self.possibleOptionMatches = {}

    self:SetUseCallbacks(true)
    self:SetAnchorStyle(AUTO_COMPLETION_ANCHOR_BOTTOM)
    self:SetOwner(nil)
    self:SetKeepFocusOnCommit(true)

    local function OnAutoCompleteEntrySelected(text, selectionMethod)
        if self.commandString and self.commandString ~= "" then
            editControl:SetText(string.format("%s %s", self.commandString, text))
        else
            editControl:SetText(text)
        end
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

    local function OnEmoteSlashCommandsUpdated()
        self:ClearPossibleCommandMatches()
    end
    PLAYER_EMOTE_MANAGER:RegisterCallback("EmoteSlashCommandsUpdated", OnEmoteSlashCommandsUpdated)
end

function ZO_SlashCommandAutoComplete:ClearPossibleCommandMatches()
    self.possibleCommandMatches = {}
end

function ZO_SlashCommandAutoComplete:AddCommandsToPossibleResults(tableOfCommands)
    if tableOfCommands == nil then
        return
    end

    for command, info in pairs(tableOfCommands) do
        if #command > 0 then
            self.possibleCommandMatches[command:lower()] = command
            -- add in the command aliases, if any, as well
            if info.aliases then
                for index, alias in ipairs(info.aliases) do
                    self.possibleCommandMatches[alias:lower()] = alias
                end
            end
        end
    end
end

function ZO_SlashCommandAutoComplete:BuildPossibleCommandMatches()
    self:ClearPossibleCommandMatches()

    for command in pairs(SLASH_COMMANDS) do
        if #command > 0 then
            self.possibleCommandMatches[command:lower()] = command
        end
    end

    if BRACKET_COMMANDS then
        for command in pairs(BRACKET_COMMANDS) do
            if #command > 0 then
                self.possibleCommandMatches[command:lower()] = command
            end
        end
    end

    self:AddCommandsToPossibleResults(ZO_REGIONCOMMANDS)
    self:AddCommandsToPossibleResults(ZO_CLIENTCOMMANDS)

    local switchLookup = ZO_ChatSystem_GetChannelSwitchLookupTable()
    for channelId, switchString in ipairs(switchLookup) do
        self.possibleCommandMatches[switchString:lower()] = switchString
    end
end

function ZO_SlashCommandAutoComplete:GetCommandAutoCompletionResults(text)
    if next(self.possibleCommandMatches) == nil then
        self:BuildPossibleCommandMatches()
    end

    local results = GetTopMatchesByLevenshteinSubStringScore(self.possibleCommandMatches, text, 2, self.maxResults)
    if results then
        return unpack(results)
    end
    return nil
end

function ZO_SlashCommandAutoComplete:ClearPossibleOptionMatches()
    self.possibleOptionMatches = {}
end

function ZO_SlashCommandAutoComplete:BuildPossibleOptionMatches()
    self:ClearPossibleOptionMatches()

    if self.commandInfo and self.commandInfo.options then
        for index, option in ipairs(self.commandInfo.options) do
            self.possibleOptionMatches[option:lower()] = option
        end
    end
end

function ZO_SlashCommandAutoComplete:SetCommandInfo(commandString, commandInfo)
    self.commandString = commandString
    if commandInfo == self.commandInfo then
        return
    end

    self.commandInfo = commandInfo
    self:BuildPossibleOptionMatches()
end

function ZO_SlashCommandAutoComplete:ClearCommandInfo()
    self:SetCommandInfo(nil, nil)
end

function ZO_SlashCommandAutoComplete:GetOptionAutoCompletionResults(command, text)
    local commandLower = command:lower()
    local commandInfo = nil
    if ZO_REGIONCOMMANDS then
        commandInfo = ZO_REGIONCOMMANDS[commandLower]
    end
    if ZO_CLIENTCOMMANDS then
        local clientCommandInfo = ZO_CLIENTCOMMANDS[commandLower]
        commandInfo = clientCommandInfo or commandInfo
    end

    if not commandInfo then
        return nil
    end

    self:SetCommandInfo(commandLower, commandInfo)

    local results = GetTopMatchesByLevenshteinSubStringScore(self.possibleOptionMatches, text, 1, self.maxResults)
    if results then
        return unpack(results)
    end
end

function ZO_SlashCommandAutoComplete:GetAutoCompletionResults(text)
    if #text < 3 then
        return
    end
    -- make sure the text starts with one of the command prefixes
    local startChar = text:sub(1, 1)
    if startChar ~= "/" and startChar ~= "]" then
        return
    end

    -- if there's a space in the string, then it could be a command + option beign typed
    local firstSpaceStart = text:find(" ", 1, true)
    if firstSpaceStart then
        local secondWordStart = firstSpaceStart + 1
        local optionText = zo_strsub(text, secondWordStart)
        if optionText:find(" ", 1, true) then
            -- there's a second space, so no longer typing an option
            return
        end

        local command = zo_strsub(text, 1, firstSpaceStart - 1)
        return self:GetOptionAutoCompletionResults(command, optionText)
    end

    -- no space, check for auto-completing a command
    self:ClearCommandInfo()
    return self:GetCommandAutoCompletionResults(text)
end