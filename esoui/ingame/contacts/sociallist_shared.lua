
function ZO_SocialList_GetRowColors(data, selected)
    local textColor = data.online and ZO_SECOND_CONTRAST_TEXT or ZO_DISABLED_TEXT
    local iconColor = data.online and ZO_DEFAULT_ENABLED_COLOR or ZO_DISABLED_TEXT
    if selected then
        textColor = ZO_SELECTED_TEXT
        iconColor = ZO_SELECTED_TEXT
    end

    return textColor, iconColor
end

function ZO_SocialList_ColorRow(control, data, displayNameTextColor, iconColor, otherTextColor)
    local displayNameControl = control:GetNamedChild("DisplayName")
    displayNameControl:SetColor(displayNameTextColor:UnpackRGBA())

    if data.hasCharacter then
        local characterNameLabel = control:GetNamedChild("CharacterName")
        if characterNameLabel then
            characterNameLabel:SetColor(otherTextColor:UnpackRGBA())
        end

        local zoneLabel = control:GetNamedChild("Zone")
        zoneLabel:SetColor(otherTextColor:UnpackRGBA())

        local championIconControl = control:GetNamedChild("Champion")
        championIconControl:SetColor(iconColor:UnpackRGBA())

        local levelLabel = control:GetNamedChild("Level")
        levelLabel:SetColor(otherTextColor:UnpackRGBA())

        local allianceIconControl = control:GetNamedChild("AllianceIcon")
        allianceIconControl:SetColor(iconColor:UnpackRGBA())

        local classIconControl = control:GetNamedChild("ClassIcon")
        classIconControl:SetColor(iconColor:UnpackRGBA())
    end
end

function ZO_SocialList_SetUpOnlineData(data, online, secsSinceLogoff)
    data.online = online
    data.secsSinceLogoff = online and -1 or secsSinceLogoff
    data.normalizedLogoffSort = online and -1 or ZO_NormalizeSecondsPositive(secsSinceLogoff)
    data.timeStamp = online and 0 or GetFrameTimeSeconds()
end

local KEYBOARD_FUNCTIONS =
{
    playerStatusIcon = GetPlayerStatusIcon,
    championPointsIcon = GetChampionPointsIconSmall,
    allianceIcon = GetAllianceSymbolIcon,
    classIcon = GetClassIcon,
}

local GAMEPAD_FUNCTIONS =
{
    playerStatusIcon = GetGamepadPlayerStatusIcon,
    championPointsIcon = GetGamepadChampionPointsIcon,
    allianceIcon = GetLargeAllianceSymbolIcon,
    classIcon = GetGamepadClassIcon,
}

function ZO_SocialList_GetPlatformTextureFunctions()
    return IsInGamepadPreferredMode() and GAMEPAD_FUNCTIONS or KEYBOARD_FUNCTIONS
end

function ZO_SocialList_SharedSocialSetup(control, data, selected)
    local textureFunctions = ZO_SocialList_GetPlatformTextureFunctions()

    local displayNameLabel = control:GetNamedChild("DisplayName")
    if displayNameLabel then
        displayNameLabel:SetText(ZO_FormatUserFacingDisplayName(data.displayName))
    end

    local heronUserInfoTextureControl = control:GetNamedChild("HeronUserInfoIcon")
    if heronUserInfoTextureControl then
        heronUserInfoTextureControl:SetHidden(not data.isHeronUser)
    end

    local statusIconControl = control:GetNamedChild("StatusIcon")
    if statusIconControl then
        statusIconControl:SetTexture(textureFunctions.playerStatusIcon(data.status))
    end

    local hideCharacterFields = not data.hasCharacter or (zo_strlen(data.characterName) <= 0)

    local characterNameLabel = control:GetNamedChild("CharacterName")
    if characterNameLabel then
        if not hideCharacterFields then
            characterNameLabel:SetText(ZO_FormatUserFacingCharacterName(data.characterName))
        else
            characterNameLabel:SetText("")
        end
    end

    local zoneLabel = control:GetNamedChild("Zone")
    zoneLabel:SetHidden(hideCharacterFields)

    local classIconControl = control:GetNamedChild("ClassIcon")
    classIconControl:SetHidden(hideCharacterFields)

    local allianceIconControl = control:GetNamedChild("AllianceIcon")
    if allianceIconControl then
        allianceIconControl:SetHidden(hideCharacterFields)
    end

    local levelLabel = control:GetNamedChild("Level")
    levelLabel:SetHidden(hideCharacterFields)

    local championIconControl = control:GetNamedChild("Champion")
    championIconControl:SetHidden(hideCharacterFields)

    if data.hasCharacter then
        zoneLabel:SetText(data.formattedZone)

        levelLabel:SetText(GetLevelOrChampionPointsStringNoIcon(data.level, data.championPoints))

        if data.championPoints and data.championPoints > 0 then
            championIconControl:SetTexture(textureFunctions.championPointsIcon())
        else
            championIconControl:SetHidden(true)
        end

        if allianceIconControl then
            local allianceTexture = textureFunctions.allianceIcon(data.alliance)
            if allianceTexture then
                allianceIconControl:SetTexture(allianceTexture)
            else
                allianceIconControl:SetHidden(true)
            end
        end

        local classTexture = textureFunctions.classIcon(data.class)
        if classTexture  then
            classIconControl:SetTexture(classTexture)
        else
            classIconControl:SetHidden(true)
        end
    end
end

-- Social lists tend to respond to events caused by other players, which can happen even when you aren't viewing the list directly.
-- To make sure this doesn't impact the rest of the game these events should just dirty the list when it isn't visible, instead of refreshing and potentially causing slow sorts/string formats
-- This class should be used as part of an inheritance chain that includes SortFilterList
ZO_SocialListDirtyLogic_Shared = ZO_Object:Subclass()

function ZO_SocialListDirtyLogic_Shared:New(...)
    local object = ZO_Object.New(self)
    object:Initialize(...)
    return object
end

function ZO_SocialListDirtyLogic_Shared:InitializeDirtyLogic(listFragment)
    self.refreshGroup = ZO_OrderedRefreshGroup:New(ZO_ORDERED_REFRESH_GROUP_AUTO_CLEAN_IMMEDIATELY)
    self.refreshGroup:AddDirtyState("Data", function()
        self:RefreshData()
    end)
    self.refreshGroup:AddDirtyState("Filters", function()
        self:RefreshFilters()
    end)
    self.refreshGroup:AddDirtyState("Sort", function()
        self:RefreshSort()
    end)
    self.refreshGroup:SetActive(function()
        return listFragment:IsShowing()
    end)
    listFragment:RegisterCallback("StateChange", function(oldState, newState)
        if newState == SCENE_FRAGMENT_SHOWING then
            self.refreshGroup:TryClean()
        end
    end)
end

function ZO_SocialListDirtyLogic_Shared:DirtyData()
    self.refreshGroup:MarkDirty("Data")
end

function ZO_SocialListDirtyLogic_Shared:DirtyFilters()
    self.refreshGroup:MarkDirty("Filters")
end

function ZO_SocialListDirtyLogic_Shared:DirtySort()
    self.refreshGroup:MarkDirty("Sort")
end
