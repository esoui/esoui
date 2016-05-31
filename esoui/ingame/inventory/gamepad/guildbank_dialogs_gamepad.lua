local CHECKED_ICON = "EsoUI/Art/Inventory/Gamepad/gp_inventory_icon_equipped.dds"

local function IsActiveGuild(data)
    return data.isCurrentGuild
end

local function SetupGuildBankItem(control, data, ...)
    ZO_SharedGamepadEntry_OnSetup(control, data, ...)

    if IsActiveGuild(data) then
        control.statusIndicator:AddIcon(CHECKED_ICON)
        control.statusIndicator:Show()
    end
end

local GUILD_ENTRY_TEMPLATE = "ZO_GamepadSubMenuEntryWithStatusTemplate"

local function SetupGuildSelectionDialog(dialog)
    local currentGuildId = GetSelectedGuildBankId()

    dialog.info.parametricList = {}
    for i = 1, GetNumGuilds() do

        local guildId = GetGuildId(i)
        local guildName = GetGuildName(guildId)
        local allianceId = GetGuildAlliance(guildId)
        local icon = GetLargeAllianceSymbolIcon(allianceId)

        local entryData = ZO_GamepadEntryData:New(guildName, icon)
        entryData:SetFontScaleOnSelection(false)
        entryData:SetIconTintOnSelection(true)
        entryData.guildName = guildName
        entryData.guildId = guildId
        entryData.allianceId = allianceId
        entryData.setup = SetupGuildBankItem
        entryData.isCurrentGuild = guildId == currentGuildId

        local listItem = 
        {
            template = GUILD_ENTRY_TEMPLATE,
            entryData = entryData,
        }
        table.insert(dialog.info.parametricList, listItem)
    end

    dialog:setupFunc()
    dialog.entryList:SetSelectedDataByEval(IsActiveGuild)
end

ESO_Dialogs["GUILD_BANK_GAMEPAD_CHANGE_ACTIVE_GUILD"] =
{
    gamepadInfo =
    {
        dialogType = GAMEPAD_DIALOGS.PARAMETRIC,
    },
    setup = SetupGuildSelectionDialog,
    title =
    {
        text = SI_GAMEPAD_GUILD_BANK_GUILD_SELECTION,
    },
    buttons =
    {
        {
            text = SI_GAMEPAD_SELECT_OPTION,
            callback =  function(dialog)
                            local data = dialog.entryList:GetTargetData()
                            if data.guildId then
                                GAMEPAD_GUILD_BANK:ChangeGuildBank(data.guildId)
                            end
                        end,
        },
        {
            text = SI_DIALOG_EXIT,
        },
    },
}