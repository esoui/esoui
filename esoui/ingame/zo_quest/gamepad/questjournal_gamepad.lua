ZO_QuestJournal_Gamepad = ZO_InitializingObject:Subclass()

function ZO_QuestJournal_Gamepad:Initialize(control)
    GAMEPAD_QUEST_JOURNAL_ROOT_SCENE = ZO_Scene:New("gamepad_quest_journal", SCENE_MANAGER)
    self.scene = GAMEPAD_QUEST_JOURNAL_ROOT_SCENE

    GAMEPAD_QUEST_JOURNAL_FRAGMENT = ZO_SimpleSceneFragment:New(control)
    GAMEPAD_QUEST_JOURNAL_FRAGMENT:SetHideOnSceneHidden(true)

    self.scene:AddFragment(GAMEPAD_QUEST_JOURNAL_FRAGMENT)

    ZO_QUEST_JOURNAL_QUESTS_GAMEPAD = ZO_QuestJournal_Quests_Gamepad:New(control:GetNamedChild("Quests"), self)
    ZO_QUEST_JOURNAL_RUMORS_GAMEPAD = ZO_QuestJournal_Rumors_Gamepad:New(control:GetNamedChild("Rumors"), self)

    self.scene:RegisterCallback("StateChange", function(oldState, newState)
        if newState == SCENE_FRAGMENT_SHOWING then
            self:OnShowing()
        elseif newState == SCENE_FRAGMENT_HIDDEN then
            self:OnHidden()
        end
    end)

    self.tabBarEntries =
    {
        {
            callback = function()
                self:SetMode(ZO_QUEST_JOURNAL_MODE.QUESTS)
            end,
        },
        {
            callback = function()
                self:SetMode(ZO_QUEST_JOURNAL_MODE.RUMORS)
            end,
        },
    }

    self:SetMode(ZO_QUEST_JOURNAL_MODE.QUESTS)
end

function ZO_QuestJournal_Gamepad:OnShowing()
    SCENE_MANAGER:AddFragmentGroup(self.modeFragments)
end

function ZO_QuestJournal_Gamepad:OnHidden()
    -- TODO Rumors
end

function ZO_QuestJournal_Gamepad:GetTabBarEntries()
    return self.tabBarEntries
end

function ZO_QuestJournal_Gamepad:SetMode(mode)
    if mode ~= self.mode then
        if self.modeFragments then
            SCENE_MANAGER:RemoveFragmentGroup(self.modeFragments)
        end

        self.scene:RemoveTemporaryFragments()

        self.mode = mode

        self.modeFragments = self:GetFragmentsForMode(mode)

        if self.scene:IsShowing() then
            SCENE_MANAGER:AddFragmentGroup(self.modeFragments)
        end
    end
end

function ZO_QuestJournal_Gamepad:GetMode()
    return self.mode
end

function ZO_QuestJournal_Gamepad:GetFragmentsForMode(mode)
    if mode == ZO_QUEST_JOURNAL_MODE.QUESTS then
        return ZO_QUEST_JOURNAL_QUESTS_GAMEPAD:GetFragmentGroup()
    else
        return ZO_QUEST_JOURNAL_RUMORS_GAMEPAD:GetFragmentGroup()
    end
end

-- TODO Rumors: Have callers access the quests object directly
function ZO_QuestJournal_Gamepad:RegisterCallback(...)
    ZO_QUEST_JOURNAL_QUESTS_GAMEPAD:RegisterCallback(...)
end

-- TODO Rumors: Have callers access the quests object directly
function ZO_QuestJournal_Gamepad:GetIconTexture(...)
    return ZO_QUEST_JOURNAL_QUESTS_GAMEPAD:GetIconTexture(...)
end

function ZO_QuestJournal_Gamepad:OpenQuestJournalToQuest(questIndex)
    self:SetMode(ZO_QUEST_JOURNAL_MODE.QUESTS)
    SCENE_MANAGER:Show("gamepad_quest_journal")
    ZO_QUEST_JOURNAL_QUESTS_GAMEPAD:QueuePendingJournalQuestIndex(questIndex)
end

function ZO_QuestJournal_Gamepad_OnInitialized(control)
    QUEST_JOURNAL_GAMEPAD = ZO_QuestJournal_Gamepad:New(control)
    SYSTEMS:RegisterGamepadObject("questJournal", QUEST_JOURNAL_GAMEPAD)
end