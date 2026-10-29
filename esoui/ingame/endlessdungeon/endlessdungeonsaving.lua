ZO_ENDLESS_DUNGEON_MAX_SAVE_COUNT = 1

----------------------------------------
-- ZO_EndlessDungeonSaveData
----------------------------------------

ZO_EndlessDungeonSaveData = ZO_InitializingObject:Subclass()

function ZO_EndlessDungeonSaveData:Initialize(saveId)
    self.saveId = saveId
end

function ZO_EndlessDungeonSaveData:GetProgression()
    local stage = self:GetCounterValue(ENDLESS_DUNGEON_COUNTER_TYPE_STAGE)
    local cycle = self:GetCounterValue(ENDLESS_DUNGEON_COUNTER_TYPE_CYCLE)
    local arc = self:GetCounterValue(ENDLESS_DUNGEON_COUNTER_TYPE_ARC)
    return stage, cycle, arc
end

function ZO_EndlessDungeonSaveData:GetCounterValue(counterType)
    return GetEndlessDungeonCounterValueBySaveId(self.saveId, counterType)
end

local USE_THICK_OUTLINE = true

function ZO_EndlessDungeonSaveData:GetProgressionText()
    local stage, cycle, arc = self:GetProgression()
    return ZO_EndlessDungeonManager.GetProgressionText(stage, cycle, arc, USE_THICK_OUTLINE)
end

function ZO_EndlessDungeonSaveData:GetAttemptsRemainingText()
    local lives = self:GetCounterValue(ENDLESS_DUNGEON_COUNTER_TYPE_WIPES_REMAINING)
    return zo_strformat(SI_ENDLESS_DUNGEON_LOAD_SAVE_LIVES_FORMATTER, lives)
end

local MAXIMUM_ADDITIONAL_MEMBERS = 1

function ZO_EndlessDungeonSaveData:GetAdditionalMemberCountText()
    -- Infinite archive only supports one additional player
    local additionalMemberCount = 0
    local groupType = GetEndlessDungeonGroupTypeBySaveId(self.saveId)
    if groupType == ENDLESS_DUNGEON_GROUP_TYPE_DUO then
        additionalMemberCount = 1
    end
    local ratioText = zo_strformat(SI_ENDLESS_DUNGEON_LOAD_SAVE_ADDITIONAL_MEMBER_RATIO_FORMATTER, additionalMemberCount, MAXIMUM_ADDITIONAL_MEMBERS)
    return zo_strformat(SI_ENDLESS_DUNGEON_LOAD_SAVE_ADDITIONAL_MEMBER_FORMATTER, ZO_SELECTED_TEXT:Colorize(ratioText))
end

function ZO_EndlessDungeonSaveData:GetMemberDisplayText()
    local crossplayDisplayName, characterDisplayName, platformDisplayName = GetEndlessDungeonGroupMemberBySaveId(self.saveId)
    if crossplayDisplayName == "" then
        return GetString(SI_ENDLESS_DUNGEON_LOAD_SAVE_ADDITIONAL_MEMBER_NO_MEMBER_NAME)
    else
        return ZO_GetPrimaryPlayerNameWithSecondary(crossplayDisplayName, characterDisplayName, platformDisplayName)
    end
end

----------------------------------------
-- ZO_EndlessDungeonSaveDetails_Shared
----------------------------------------

ZO_EndlessDungeonSaveDetails_Shared = ZO_InitializingObject:Subclass()

function ZO_EndlessDungeonSaveDetails_Shared:Initialize(control)
    self.control = control
    control.object = self

    self.progressionTextLabel = control:GetNamedChild("ProgressionText")
    self.attemptsRemainingTextLabel = control:GetNamedChild("LivesText")
    self.additionalMemberTextLabel = control:GetNamedChild("AdditionalMember")
    self.memberDisplayNameTextLabel = control:GetNamedChild("MemberDisplayName")
end

function ZO_EndlessDungeonSaveDetails_Shared:Layout(saveId)
    self.saveData = ZO_EndlessDungeonSaveData:New(saveId)

    self.progressionTextLabel:SetText(self.saveData:GetProgressionText())
    self.attemptsRemainingTextLabel:SetText(self.saveData:GetAttemptsRemainingText())
    self.additionalMemberTextLabel:SetText(self.saveData:GetAdditionalMemberCountText())
    self.memberDisplayNameTextLabel:SetText(self.saveData:GetMemberDisplayText())
end
