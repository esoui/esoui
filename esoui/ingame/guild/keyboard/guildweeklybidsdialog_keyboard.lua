ZO_GUILD_WEEKLY_BIDS_DIALOG_ROW_KEYBOARD_HEIGHT = 32

ZO_GuildWeeklyBidsDialog_Keyboard = ZO_Object.MultiSubclass(ZO_GuildWeeklyBids_Shared, ZO_SortFilterList)

function ZO_GuildWeeklyBidsDialog_Keyboard:New(control)
    return ZO_SortFilterList.New(self, control)
end

function ZO_GuildWeeklyBidsDialog_Keyboard:Initialize(control)
    ZO_SortFilterList.Initialize(self, control)
    ZO_GuildWeeklyBids_Shared.Initialize(self, "ZO_GuildWeeklyBidsDialogRow_Keyboard", ZO_GUILD_WEEKLY_BIDS_DIALOG_ROW_KEYBOARD_HEIGHT)

    ZO_PreHookHandler(self.control, "OnEffectivelyHidden", function() self.guildId = nil end)

    local function OnGuildPermissionChanged(event, guildId)
        if guildId == self.guildId then
            if not DoesPlayerHaveGuildPermission(self.guildId, GUILD_PERMISSION_GUILD_KIOSK_BID) then
                ZO_Dialogs_ReleaseDialog("GUILD_WEEKLY_BIDS_KEYBOARD")
            end
        end
    end

    ZO_Dialogs_RegisterCustomDialog("GUILD_WEEKLY_BIDS_KEYBOARD",
    {
        customControl = control,
        setup = function(dialog, data)
            self:DialogSetup(data)
            EVENT_MANAGER:RegisterForEvent("ZO_GuildWeeklyBidsDialog_Keyboard", EVENT_GUILD_PLAYER_RANK_CHANGED, OnGuildPermissionChanged)
            EVENT_MANAGER:RegisterForEvent("ZO_GuildWeeklyBidsDialog_Keyboard", EVENT_GUILD_SELF_LEFT_GUILD, OnGuildPermissionChanged)
        end,
        title =
        {
            text = SI_GUILD_WEEKLY_BIDS_TITLE,
        },
        finishedCallback = function(dialog)
            EVENT_MANAGER:UnregisterForEvent("ZO_GuildWeeklyBidsDialog_Keyboard", EVENT_GUILD_PLAYER_RANK_CHANGED, OnGuildPermissionChanged)
            EVENT_MANAGER:UnregisterForEvent("ZO_GuildWeeklyBidsDialog_Keyboard", EVENT_GUILD_SELF_LEFT_GUILD, OnGuildPermissionChanged)
        end,
        buttons =
        {       
            {
                control = control:GetNamedChild("Close"),
                text = SI_DIALOG_CLOSE,
                keybind = "DIALOG_NEGATIVE",
            },
        }
    })
end

function ZO_GuildWeeklyBidsDialog_Keyboard:DialogSetup(data)
    self.guildId = data.guildId
    self:TryQueryNewInformation()
end

function ZO_GuildWeeklyBidsDialog_Keyboard:SetWeeklyBidLimitText(text)
    local weeklyBidsLabel = self.control:GetNamedChild("WeeklyBids")
    weeklyBidsLabel:SetText(zo_strformat(SI_GUILD_WEEKLY_BIDS_KEYBOARD_COUNT, text))
end

function ZO_GuildWeeklyBidsDialogTopLevel_Keyboard_OnInitialized(self)
    GUILD_WEEKLY_BIDS_DIALOG =  ZO_GuildWeeklyBidsDialog_Keyboard:New(self)
end