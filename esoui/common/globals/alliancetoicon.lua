local allianceToIcon =
{
    [ALLIANCE_DAGGERFALL_COVENANT] = "EsoUI/Art/CharacterWindow/allianceBadge_daggerfall.dds",
    [ALLIANCE_ALDMERI_DOMINION] = "EsoUI/Art/CharacterWindow/allianceBadge_aldmeri.dds",
    [ALLIANCE_EBONHEART_PACT] = "EsoUI/Art/CharacterWindow/allianceBadge_ebonheart.dds",
}

function ZO_GetAllianceIcon(alliance)
    return allianceToIcon[alliance] or allianceToIcon[ALLIANCE_DAGGERFALL_COVENANT]
end
