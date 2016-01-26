---------------------------
--PrefixIconMarkup--
---------------------------
do
    local function GetTexture(data)
        if data == "alliance1" then
            return GetAllianceBannerIcon(1)
        elseif data == "alliance2" then
            return GetAllianceBannerIcon(2)
        elseif data == "alliance3" then
            return GetAllianceBannerIcon(3)
        elseif data == "crowns" then
            return "EsoUI/Art/currency/gamepad/gp_crowns.dds"
        elseif data == "timer" then
            return "EsoUI/Art/Miscellaneous/Gamepad/gp_icon_timer32.dds"
        end
    end

    function ZO_PrefixIconNameFormatter(iconAreaData, name)
        return string.format("|t100%%:100%%:%s|t%s", GetTexture(iconAreaData), name)
    end

    local GUILD_ICON_CONTROLS =
    {
        "alliance1",
        "alliance2",
        "alliance3",
    }

    function ZO_GetAllianceIconUserAreaDataName(allianceId)
        return GUILD_ICON_CONTROLS[allianceId]
    end
end