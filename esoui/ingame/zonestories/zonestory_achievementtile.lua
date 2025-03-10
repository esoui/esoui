-- Primary logic class must be subclassed after the platform class so that platform specific functions will have priority over the logic class functionality
ZO_ZoneStory_AchievementTile = ZO_Tile:Subclass()

function ZO_ZoneStory_AchievementTile:New(...)
    return ZO_Tile.New(self, ...)
end

function ZO_ZoneStory_AchievementTile:Initialize(...)
    ZO_Tile.Initialize(self, ...)

    local control = self.control
    local contentControl = control:GetNamedChild("TextContainer")
    self.iconControl = control:GetNamedChild("Icon")
    self.characterFrame = self.iconControl:GetNamedChild("CharacterFrame")
    self.titleControl = contentControl:GetNamedChild("Title")
    self.statusControl = contentControl:GetNamedChild("Status")
end

function ZO_ZoneStory_AchievementTile:Layout(data)
    ZO_Tile.Layout(self, data)

    self.achievementId = data.achievementId

    local name, _, _, icon, completed, date = GetAchievementInfo(data.achievementId)

    local persistenceLevel = GetAchievementPersistenceLevel(self.achievementId)
    local isCharacterPersistent = persistenceLevel == ACHIEVEMENT_PERSISTENCE_CHARACTER
    if isCharacterPersistent then
        local frameColor = completed and ZO_SECOND_SELECTED_TEXT or ZO_SECOND_NORMAL_TEXT
        self.characterFrame:SetColor(frameColor:UnpackRGBA())
        self.characterFrame:SetHidden(false)

    else
        self.characterFrame:SetHidden(true)
    end

    self.iconControl:SetTexture(icon)
    self:SetTitle(zo_strformat(name), completed, isCharacterPersistent)
    self:SetStatus(date)
end

function ZO_ZoneStory_AchievementTile:SetTitle(title, completed, isCharacterPersistent)
    local control = self.titleControl
    local titleColor

    if isCharacterPersistent then
        titleColor = completed and ZO_SECOND_SELECTED_TEXT or ZO_SECOND_NORMAL_TEXT
    else
        titleColor = completed and ZO_SELECTED_TEXT or ZO_DEFAULT_TEXT
    end

    control:SetText(title)
    control:SetColor(titleColor:UnpackRGB())
end

function ZO_ZoneStory_AchievementTile:SetStatus(date)
    local control = self.statusControl
    local achievementStatus = ZO_GetAchievementStatus(self.achievementId)
    if achievementStatus == ZO_ACHIEVEMENTS_COMPLETION_STATUS.COMPLETE then
        control:SetText(date)
        control:SetColor(ZO_NORMAL_TEXT:UnpackRGB())
    elseif achievementStatus == ZO_ACHIEVEMENTS_COMPLETION_STATUS.IN_PROGRESS then
        control:SetText(GetString(SI_ACHIEVEMENTS_PROGRESS))
        control:SetColor(ZO_DEFAULT_TEXT:UnpackRGB())
    elseif achievementStatus == ZO_ACHIEVEMENTS_COMPLETION_STATUS.INCOMPLETE then
        control:SetText(GetString(SI_ACHIEVEMENTS_INCOMPLETE))
        control:SetColor(ZO_DEFAULT_TEXT:UnpackRGB())
    end
end