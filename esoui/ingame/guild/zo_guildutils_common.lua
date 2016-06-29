
local function GetGuildDialogFunction(playerGuildId, data, isGamepad)
    local showDialogFunc = ZO_Dialogs_ShowDialog
    local allianceIconSize = 17
    if(isGamepad) then
        showDialogFunc = ZO_Dialogs_ShowGamepadDialog
    end

	local guildName = GetGuildName(playerGuildId)
	local numGuildMembers = GetNumGuildMembers(playerGuildId)
	local playerIndex = GetPlayerGuildMemberIndex(playerGuildId)
	local _,_,rankIndex,_,_ = GetGuildMemberInfo(playerGuildId, playerIndex)
	local playerIsGuildmaster = IsGuildRankGuildMaster(playerGuildId, rankIndex)
    local guildAlliance = GetGuildAlliance(playerGuildId)
	local allianceIcon = zo_iconFormat(GetAllianceBannerIcon(guildAlliance), allianceIconSize, allianceIconSize)
	local isLastMemberOfGuild = (numGuildMembers == 1)

    if(data == nil) then
        data = {}
    end

    if(isGamepad) then
        allianceIcon = ""
        guildName = ZO_PrefixIconNameFormatter(ZO_GetAllianceIconUserAreaDataName(guildAlliance), guildName)
    end

    data.guildId = playerGuildId

	if(isLastMemberOfGuild) then
        return function() showDialogFunc("GUILD_DISBAND", data, { mainTextParams = { allianceIcon, guildName }}) end
    elseif(playerIsGuildmaster) then
        return function() showDialogFunc("GUILD_LEAVE_LEADER", data, { mainTextParams = { allianceIcon, guildName }}) end
    else
        return function() showDialogFunc("GUILD_LEAVE", data, { mainTextParams = { allianceIcon, guildName }}) end
    end
end

function ZO_AddLeaveGuildMenuItem(playerGuildId)
	AddMenuItem(GetString(SI_GUILD_LEAVE), GetGuildDialogFunction(playerGuildId))
end

function ZO_ShowLeaveGuildDialog(playerGuildId, data, isGamepad)
	GetGuildDialogFunction(playerGuildId, data, isGamepad)()
end

function ZO_CanPlayerCreateGuild()
    local playerIsGuildMaster = false
    local numGuilds = GetNumGuilds()

    for i = 1, numGuilds do
        local guildId = GetGuildId(i)
        if(not playerIsGuildMaster) then
            local guildPlayerIndex = GetPlayerGuildMemberIndex(guildId)
            local _, _, rankIndex = GetGuildMemberInfo(guildId, guildPlayerIndex)
            if(IsGuildRankGuildMaster(guildId, rankIndex)) then
                playerIsGuildMaster = true
                break
            end
        end
    end

    local tooLowLevel = GetUnitLevel("player") < MIN_REQUIRED_LEVEL_TO_CREATE_GUILD

    return not (numGuilds >= MAX_GUILDS or playerIsGuildMaster or tooLowLevel), numGuilds >= MAX_GUILDS, playerIsGuildMaster, tooLowLevel
end

function ZO_UpdateGuildStatusDropdownSelection(dropdown)
    local status = GetPlayerStatus()
    local statusTexture = GetPlayerStatusIcon(status)
    local text = zo_strformat(SI_GAMEPAD_GUILD_STATUS_SELECTOR_FORMAT, statusTexture, GetString("SI_PLAYERSTATUS", status))
    dropdown:SetSelectedItemText(text)
end

function ZO_UpdateGuildStatusDropdown(dropdown)
    dropdown:ClearItems()

    ZO_UpdateGuildStatusDropdownSelection(dropdown)
        
    for i = 1, GetNumPlayerStatuses() do
        local function GuildStatusSelect()
            SelectPlayerStatus(i)
        end

        local statusTexture = GetPlayerStatusIcon(i)
        local text = zo_strformat(SI_GAMEPAD_GUILD_STATUS_SELECTOR_FORMAT, statusTexture, GetString("SI_PLAYERSTATUS", i))
        local entry = ZO_ComboBox:CreateItemEntry(text, GuildStatusSelect)
        dropdown:AddItem(entry, ZO_COMBOBOX_SUPRESS_UPDATE)
    end

    dropdown:UpdateItems()
end

function ZO_GetGuildCreateError()
    local canCreateGuild, tooManyGuilds, isAlreadyGuildmaster, tooLowLevel = ZO_CanPlayerCreateGuild()

    if(not canCreateGuild) then
        if(tooManyGuilds) then
            return zo_strformat(SI_GUILD_CREATE_ERROR_TOO_MANY, MAX_GUILDS)
        elseif(isAlreadyGuildmaster) then
            return GetString(SI_GUILD_CREATE_ERROR_ALREADY_LEADER)
        else
            return zo_strformat(SI_GUILD_CREATE_ERROR_LOW_LEVEL, MIN_REQUIRED_LEVEL_TO_CREATE_GUILD)
        end
    end

    return nil
end

function ZO_SetGuildCreateError(label)
    local error = ZO_GetGuildCreateError()
    label:SetHidden(not error)
    label:SetText(error)
    return error == nil
end


function ZO_ValidatePlayerGuildId(guildIdToValidate)
    local numGuilds = GetNumGuilds()
    for i = 1, numGuilds do
        local guildId = GetGuildId(i)

        if(guildIdToValidate == guildId) then
            return true
        end
    end
    return false
end

function ZO_TryGuildInvite(guildId, displayName)
    if not DoesPlayerHaveGuildPermission(guildId, GUILD_PERMISSION_INVITE) then
        ZO_AlertEvent(EVENT_SOCIAL_ERROR, SOCIAL_RESULT_NO_INVITE_PERMISSION)
        return
    end

    if GetNumGuildMembers(guildId) == MAX_GUILD_MEMBERS then
        ZO_AlertEvent(EVENT_SOCIAL_ERROR, SOCIAL_RESULT_NO_ROOM)
        return
    end

    local guildName = GetGuildName(guildId)
    if IsConsoleUI() then
        local function GuildInviteCallback(success)
            if success then
                GuildInvite(guildId, displayName)
                ZO_Alert(UI_ALERT_CATEGORY_ALERT, nil, zo_strformat(SI_GUILD_ROSTER_INVITED_MESSAGE, UndecorateDisplayName(displayName), guildName))
            end
        end

        ZO_ConsoleAttemptInteractOrError(GuildInviteCallback, displayName, ZO_PLAYER_CONSOLE_INFO_REQUEST_DONT_BLOCK, ZO_CONSOLE_CAN_COMMUNICATE_ERROR_ALERT, ZO_ID_REQUEST_TYPE_DISPLAY_NAME, displayName)
    else
        if IsIgnored(displayName) then
            ZO_Alert(UI_ALERT_CATEGORY_ALERT, nil, SI_GROUP_ALERT_INVITE_PLAYER_BLOCKED)
            return
        end

        GuildInvite(guildId, displayName)
        ZO_Alert(UI_ALERT_CATEGORY_ALERT, nil, zo_strformat(SI_GUILD_ROSTER_INVITED_MESSAGE, displayName, guildName))
    end    
end