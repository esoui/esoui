local SimpleEventToCategoryMappings = {
    [EVENT_SERVER_SHUTDOWN_INFO] = CHAT_CATEGORY_SYSTEM,
    [EVENT_BROADCAST] = CHAT_CATEGORY_SYSTEM,

    [EVENT_FRIEND_PLAYER_STATUS_CHANGED] = CHAT_CATEGORY_SYSTEM,
    [EVENT_IGNORE_ADDED] = CHAT_CATEGORY_SYSTEM,
    [EVENT_IGNORE_REMOVED] = CHAT_CATEGORY_SYSTEM,
    [EVENT_GROUP_MEMBER_JOINED] = CHAT_CATEGORY_SYSTEM,
    [EVENT_GROUP_MEMBER_LEFT] = CHAT_CATEGORY_SYSTEM,
    [EVENT_GROUP_TYPE_CHANGED] = CHAT_CATEGORY_SYSTEM,
    [EVENT_GROUP_INVITE_RESPONSE] = CHAT_CATEGORY_SYSTEM,

	[EVENT_SOCIAL_ERROR] = CHAT_CATEGORY_SYSTEM,

    [EVENT_STUCK_ERROR_ON_COOLDOWN] = CHAT_CATEGORY_SYSTEM,
    [EVENT_STUCK_ERROR_ALREADY_IN_PROGRESS] = CHAT_CATEGORY_SYSTEM,
    [EVENT_STUCK_ERROR_IN_COMBAT] = CHAT_CATEGORY_SYSTEM,
    [EVENT_STUCK_ERROR_INVALID_LOCATION] = CHAT_CATEGORY_SYSTEM,
    [EVENT_TRIAL_FEATURE_RESTRICTED] = CHAT_CATEGORY_SYSTEM,
}

local MultiLevelEventToCategoryMappings = {
    [EVENT_CHAT_MESSAGE_CHANNEL] = {
        [CHAT_CHANNEL_SAY] = GetChannelCategoryFromChannel(CHAT_CHANNEL_SAY),
        [CHAT_CHANNEL_YELL] = GetChannelCategoryFromChannel(CHAT_CHANNEL_YELL),
        [CHAT_CHANNEL_ZONE] = GetChannelCategoryFromChannel(CHAT_CHANNEL_ZONE),
        [CHAT_CHANNEL_ZONE_LANGUAGE_1] = GetChannelCategoryFromChannel(CHAT_CHANNEL_ZONE_LANGUAGE_1),
        [CHAT_CHANNEL_ZONE_LANGUAGE_2] = GetChannelCategoryFromChannel(CHAT_CHANNEL_ZONE_LANGUAGE_2),
        [CHAT_CHANNEL_ZONE_LANGUAGE_3] = GetChannelCategoryFromChannel(CHAT_CHANNEL_ZONE_LANGUAGE_3),
        [CHAT_CHANNEL_ZONE_LANGUAGE_4] = GetChannelCategoryFromChannel(CHAT_CHANNEL_ZONE_LANGUAGE_4),
        [CHAT_CHANNEL_WHISPER] = GetChannelCategoryFromChannel(CHAT_CHANNEL_WHISPER),
        [CHAT_CHANNEL_WHISPER_SENT] = GetChannelCategoryFromChannel(CHAT_CHANNEL_WHISPER_SENT),
        [CHAT_CHANNEL_PARTY] = GetChannelCategoryFromChannel(CHAT_CHANNEL_PARTY),
        [CHAT_CHANNEL_EMOTE] = GetChannelCategoryFromChannel(CHAT_CHANNEL_EMOTE),
        [CHAT_CHANNEL_SYSTEM] = GetChannelCategoryFromChannel(CHAT_CHANNEL_SYSTEM),
        [CHAT_CHANNEL_GUILD_1] = GetChannelCategoryFromChannel(CHAT_CHANNEL_GUILD_1),
        [CHAT_CHANNEL_GUILD_2] = GetChannelCategoryFromChannel(CHAT_CHANNEL_GUILD_2),
        [CHAT_CHANNEL_GUILD_3] = GetChannelCategoryFromChannel(CHAT_CHANNEL_GUILD_3),
        [CHAT_CHANNEL_GUILD_4] = GetChannelCategoryFromChannel(CHAT_CHANNEL_GUILD_4),
        [CHAT_CHANNEL_GUILD_5] = GetChannelCategoryFromChannel(CHAT_CHANNEL_GUILD_5),
        [CHAT_CHANNEL_OFFICER_1] = GetChannelCategoryFromChannel(CHAT_CHANNEL_OFFICER_1),
        [CHAT_CHANNEL_OFFICER_2] = GetChannelCategoryFromChannel(CHAT_CHANNEL_OFFICER_2),
        [CHAT_CHANNEL_OFFICER_3] = GetChannelCategoryFromChannel(CHAT_CHANNEL_OFFICER_3),
        [CHAT_CHANNEL_OFFICER_4] = GetChannelCategoryFromChannel(CHAT_CHANNEL_OFFICER_4),
        [CHAT_CHANNEL_OFFICER_5] = GetChannelCategoryFromChannel(CHAT_CHANNEL_OFFICER_5),

        [CHAT_CHANNEL_MONSTER_SAY] = GetChannelCategoryFromChannel(CHAT_CHANNEL_MONSTER_SAY),
        [CHAT_CHANNEL_MONSTER_YELL] = GetChannelCategoryFromChannel(CHAT_CHANNEL_MONSTER_YELL),
        [CHAT_CHANNEL_MONSTER_WHISPER] = GetChannelCategoryFromChannel(CHAT_CHANNEL_MONSTER_WHISPER),
        [CHAT_CHANNEL_MONSTER_EMOTE] = GetChannelCategoryFromChannel(CHAT_CHANNEL_MONSTER_EMOTE),
    },
}

local TrialEventMappings = {
    [TRIAL_RESTRICTION_CANNOT_ZONE_YELL] = true,
    [TRIAL_RESTRICTION_CANNOT_WHISPER] = true,
    [TRIAL_RESTRICTION_WHISPER_FRIENDS_ONLY] = true,
}

local function GetGuildChannelErrorFunction(guildIndex)
    return function()
        if(GetNumGuilds() < guildIndex) then
            return zo_strformat(SI_CANT_GUILD_CHAT_NOT_IN_GUILD, guildIndex)
        else
            return zo_strformat(SI_CANT_GUILD_CHAT_NO_PERMISSION, GetGuildName(guildIndex))
        end
    end
end

local function GetOfficerChannelErrorFunction(guildIndex)
    return function()
        if(GetNumGuilds() < guildIndex) then
            return zo_strformat(SI_CANT_GUILD_CHAT_NOT_IN_GUILD, guildIndex)
        else
            return zo_strformat(SI_CANT_OFFICER_CHAT_NO_PERMISSION, GetGuildName(guildIndex))
        end
    end
end

local ChannelInfo =
{
    [CHAT_CHANNEL_SAY] = {
        format = SI_CHAT_MESSAGE_SAY,
        name = GetString(SI_CHAT_CHANNEL_NAME_SAY),
        playerLinkable = true,
        channelLinkable = false,
        switches = GetString(SI_CHANNEL_SWITCH_SAY),
    },

    [CHAT_CHANNEL_YELL] =
    {
        format = SI_CHAT_MESSAGE_YELL,
        name = GetString(SI_CHAT_CHANNEL_NAME_YELL),
        playerLinkable = true,
        channelLinkable = false,
        switches = GetString(SI_CHANNEL_SWITCH_YELL)
    },
    [CHAT_CHANNEL_ZONE] =
    {
        format = SI_CHAT_MESSAGE_ZONE,
        name = GetString(SI_CHAT_CHANNEL_NAME_ZONE),
        playerLinkable = true,
        channelLinkable = false,
        switches = GetString(SI_CHANNEL_SWITCH_ZONE)
    },
    [CHAT_CHANNEL_PARTY] =
    {
        format = SI_CHAT_MESSAGE_PARTY,
        name = GetString(SI_CHAT_CHANNEL_NAME_PARTY),
        playerLinkable = true,
        channelLinkable = true,
        switches = GetString(SI_CHANNEL_SWITCH_PARTY),
        requires = function()
            return IsUnitGrouped("player")
        end,
        deferRequirement = true,
        requirementErrorMessage = GetString(SI_GROUP_NOTIFICATION_YOU_ARE_NOT_IN_A_GROUP)
    },
    [CHAT_CHANNEL_WHISPER] =
    {
        format = SI_CHAT_MESSAGE_WHISPER,
        name = GetString(SI_CHAT_CHANNEL_NAME_WHISPER),
        playerLinkable = true,
        channelLinkable = false,
        switches = GetString(SI_CHANNEL_SWITCH_WHISPER),
        target = true,
        saveTarget = CHAT_CHANNEL_WHISPER,
        targetSwitches = GetString(SI_CHANNEL_SWITCH_WHISPER_REPLY),
    },
    [CHAT_CHANNEL_WHISPER_SENT] =
    {
        format = SI_CHAT_MESSAGE_WHISPER_SENT,
        playerLinkable = true,
        channelLinkable = false,
    },
    [CHAT_CHANNEL_EMOTE] =
    {
        format = SI_CHAT_EMOTE,
        name = GetString(SI_CHAT_CHANNEL_NAME_EMOTE),
        playerLinkable = true,
        channelLinkable = false,
        switches = GetString(SI_CHANNEL_SWITCH_EMOTE),
    },
    [CHAT_CHANNEL_MONSTER_SAY] =
    {
        format = SI_CHAT_MONSTER_MESSAGE_SAY,
        playerLinkable = false,
        channelLinkable = false,
    },
    [CHAT_CHANNEL_MONSTER_YELL] =
    {
        format = SI_CHAT_MONSTER_MESSAGE_YELL,
        playerLinkable = false,
        channelLinkable = false,
    },
    [CHAT_CHANNEL_MONSTER_WHISPER] =
    {
        format = SI_CHAT_MONSTER_MESSAGE_WHISPER,
        playerLinkable = false,
        channelLinkable = false,
    },
    [CHAT_CHANNEL_MONSTER_EMOTE] =
    {
        format = SI_CHAT_MONSTER_EMOTE,
        playerLinkable = false,
        channelLinkable = false,
    },
    [CHAT_CHANNEL_SYSTEM] =
    {
        format = SI_CHAT_MESSAGE_SYSTEM,
        playerLinkable = false,
        channelLinkable = false,
    },
    [CHAT_CHANNEL_GUILD_1] =
    {
        format = SI_CHAT_MESSAGE_GUILD,
        dynamicName = true,
        playerLinkable = true,
        channelLinkable = true,
        switches = GetString(SI_CHANNEL_SWITCH_GUILD_1),
        requires = CanWriteGuildChannel,
        requirementErrorMessage = GetGuildChannelErrorFunction(1),
        deferRequirement = true,
    },
    [CHAT_CHANNEL_GUILD_2] =
    {
        format = SI_CHAT_MESSAGE_GUILD,
        dynamicName = true,
        playerLinkable = true,
        channelLinkable = true,
        switches = GetString(SI_CHANNEL_SWITCH_GUILD_2),
        requires = CanWriteGuildChannel,
        requirementErrorMessage = GetGuildChannelErrorFunction(2),
        deferRequirement = true,
    },
    [CHAT_CHANNEL_GUILD_3] =
    {
        format = SI_CHAT_MESSAGE_GUILD,
        dynamicName = true,
        playerLinkable = true,
        channelLinkable = true,
        switches = GetString(SI_CHANNEL_SWITCH_GUILD_3),
        requires = CanWriteGuildChannel,
        requirementErrorMessage = GetGuildChannelErrorFunction(3),
        deferRequirement = true,
    },
    [CHAT_CHANNEL_GUILD_4] =
    {
        format = SI_CHAT_MESSAGE_GUILD,
        dynamicName = true,
        playerLinkable = true,
        channelLinkable = true,
        switches = GetString(SI_CHANNEL_SWITCH_GUILD_4),
        requires = CanWriteGuildChannel,
        requirementErrorMessage = GetGuildChannelErrorFunction(4),
        deferRequirement = true,
    },
    [CHAT_CHANNEL_GUILD_5] =
    {
        format = SI_CHAT_MESSAGE_GUILD,
        dynamicName = true,
        playerLinkable = true,
        channelLinkable = true,
        switches = GetString(SI_CHANNEL_SWITCH_GUILD_5),
        requires = CanWriteGuildChannel,
        requirementErrorMessage = GetGuildChannelErrorFunction(5),
        deferRequirement = true,
    },
    [CHAT_CHANNEL_OFFICER_1] =
    {
        format = SI_CHAT_MESSAGE_GUILD,
        dynamicName = true,
        playerLinkable = true,
        channelLinkable = true,
        switches = GetString(SI_CHANNEL_SWITCH_OFFICER_1),
        requires = CanWriteGuildChannel,
        requirementErrorMessage = GetOfficerChannelErrorFunction(1),
        deferRequirement = true,
    },
    [CHAT_CHANNEL_OFFICER_2] =
    {
        format = SI_CHAT_MESSAGE_GUILD,
        dynamicName = true,
        playerLinkable = true,
        channelLinkable = true,
        switches = GetString(SI_CHANNEL_SWITCH_OFFICER_2),
        requires = CanWriteGuildChannel,
        requirementErrorMessage = GetOfficerChannelErrorFunction(2),
        deferRequirement = true,
    },
    [CHAT_CHANNEL_OFFICER_3] =
    {
        format = SI_CHAT_MESSAGE_GUILD,
        dynamicName = true,
        playerLinkable = true,
        channelLinkable = true,
        switches = GetString(SI_CHANNEL_SWITCH_OFFICER_3),
        requires = CanWriteGuildChannel,
        requirementErrorMessage = GetOfficerChannelErrorFunction(3),
        deferRequirement = true,
    },
    [CHAT_CHANNEL_OFFICER_4] =
    {
        format = SI_CHAT_MESSAGE_GUILD,
        dynamicName = true,
        playerLinkable = true,
        channelLinkable = true,
        switches = GetString(SI_CHANNEL_SWITCH_OFFICER_4),
        requires = CanWriteGuildChannel,
        requirementErrorMessage = GetOfficerChannelErrorFunction(4),
        deferRequirement = true,
    },
    [CHAT_CHANNEL_OFFICER_5] =
    {
        format = SI_CHAT_MESSAGE_GUILD,
        dynamicName = true,
        playerLinkable = true,
        channelLinkable = true,
        switches = GetString(SI_CHANNEL_SWITCH_OFFICER_5),
        requires = CanWriteGuildChannel,
        requirementErrorMessage = GetOfficerChannelErrorFunction(5),
        deferRequirement = true,
    },
}

--TODO: Allow these in console when we implement tabs and filters
if not IsConsoleUI() then
    ChannelInfo[CHAT_CHANNEL_ZONE_LANGUAGE_1] =
    {
        format = SI_CHAT_MESSAGE_ZONE_ENGLISH,
        name = GetString(SI_CHAT_CHANNEL_NAME_ZONE_ENGLISH),
        playerLinkable = true,
        channelLinkable = false,
        switches = GetString(SI_CHANNEL_SWITCH_ZONE_ENGLISH)
    }
    ChannelInfo[CHAT_CHANNEL_ZONE_LANGUAGE_2] =
    {
        format = SI_CHAT_MESSAGE_ZONE_FRENCH,
        name = GetString(SI_CHAT_CHANNEL_NAME_ZONE_FRENCH),
        playerLinkable = true,
        channelLinkable = false,
        switches = GetString(SI_CHANNEL_SWITCH_ZONE_FRENCH)
    }
    ChannelInfo[CHAT_CHANNEL_ZONE_LANGUAGE_3] =
    {
        format = SI_CHAT_MESSAGE_ZONE_GERMAN,
        name = GetString(SI_CHAT_CHANNEL_NAME_ZONE_GERMAN),
        playerLinkable = true,
        channelLinkable = false,
        switches = GetString(SI_CHANNEL_SWITCH_ZONE_GERMAN)
    }
    ChannelInfo[CHAT_CHANNEL_ZONE_LANGUAGE_4] =
    {
        format = SI_CHAT_MESSAGE_ZONE_JAPANESE,
        name = GetString(SI_CHAT_CHANNEL_NAME_ZONE_JAPANESE),
        playerLinkable = true,
        channelLinkable = false,
        switches = GetString(SI_CHANNEL_SWITCH_ZONE_JAPANESE)
    }
end

function ZO_ChatSystem_GetChannelInfo()
    return ChannelInfo
end

function ZO_ChatSystem_GetEventCategoryMappings()
    return MultiLevelEventToCategoryMappings, SimpleEventToCategoryMappings
end

function ZO_ChatSystem_GetTrialEventMappings()
    return TrialEventMappings
end
