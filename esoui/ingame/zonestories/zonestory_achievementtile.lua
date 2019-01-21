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
    self.titleControl = contentControl:GetNamedChild("Title")
    self.statusControl = contentControl:GetNamedChild("Status")
end

function ZO_ZoneStory_AchievementTile:Layout(achievementId)
    ZO_Tile.Layout(self, achievementId)

    self.achievementId = achievementId

    local name, _, _, icon, completed, date = GetAchievementInfo(achievementId)

    self.iconControl:SetTexture(icon)
    self:SetTitle(zo_strformat(name), completed)
    self:SetStatus(date)
end

function ZO_ZoneStory_AchievementTile:SetTitle(title, completed)
    local control = self.titleControl
    control:SetText(title)
    if completed then
        control:SetColor(ZO_SELECTED_TEXT:UnpackRGB())
    else
        control:SetColor(ZO_DEFAULT_TEXT:UnpackRGB())
    end
end

function ZO_ZoneStory_AchievementTile:SetStatus(date)
    local control = self.statusControl
    local achievementStatus = ACHIEVEMENTS_MANAGER:GetAchievementStatus(self.achievementId)
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