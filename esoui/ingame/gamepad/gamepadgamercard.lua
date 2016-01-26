function GetGamerCardStringId()
    return GetUIPlatform() == UI_PLATFORM_PS4 and SI_PLAYER_TO_PLAYER_VIEW_PSN_PROFILE
           or SI_PLAYER_TO_PLAYER_VIEW_GAMER_CARD
end