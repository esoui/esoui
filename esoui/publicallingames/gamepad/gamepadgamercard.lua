function GetGamerCardStringId()
    return ZO_IsPlaystationPlatform() and SI_PLAYER_TO_PLAYER_VIEW_PSN_PROFILE
           or SI_PLAYER_TO_PLAYER_VIEW_GAMER_CARD
end