ZO_QuestJournal_Keyboard = ZO_InitializingObject:Subclass()

function ZO_QuestJournal_Keyboard:Initialize(control)
    self.control = control

    self.initializedTabs = false

    self:InitializeModeBar()

    self.mode = ZO_QUEST_JOURNAL_MODE.QUESTS

    self.scene = ZO_Scene:New("questJournal", SCENE_MANAGER)
    self.scene:RegisterCallback("StateChange",
        function(oldState, newState)
            if newState == SCENE_SHOWING then
                self:OnShowing()
            elseif newState == SCENE_HIDING then
                self:OnHiding()
            end
        end)

    local fragment = ZO_FadeSceneFragment:New(control)
    self.scene:AddFragment(fragment)

    QUEST_JOURNAL_SCENE = self.scene

    ZO_QUEST_JOURNAL_QUESTS_KEYBOARD = ZO_QuestJournal_Quests_Keyboard:New(control:GetNamedChild("QuestsPanel"), self)
    ZO_QUEST_JOURNAL_RUMORS_KEYBOARD = ZO_QuestJournal_Rumors_Keyboard:New(control:GetNamedChild("RumorsPanel"), self)
end

function ZO_QuestJournal_Keyboard:InitializeModeBar()
    self.modeBar = self.control:GetNamedChild("ModeBar")

    self.tabs = ZO_SceneFragmentBar:New(self.modeBar)

    self.questsTab =
    {
        categoryName = SI_QUEST_JOURNAL_QUESTS_MODE,
        descriptor = ZO_QUEST_JOURNAL_MODE.QUESTS,
        normal = "EsoUI/Art/Journal/journal_quests_tabIcon_up.dds",
        pressed = "EsoUI/Art/Journal/journal_quests_tabIcon_down.dds",
        highlight = "EsoUI/Art/Journal/journal_quests_tabIcon_over.dds",
        disabled = "EsoUI/Art/Journal/journal_quests_tabIcon_disabled.dds",
        callback = function() self:SetMode(ZO_QUEST_JOURNAL_MODE.QUESTS) end,
    }

    self.rumorsTab =
    {
        categoryName = SI_QUEST_JOURNAL_RUMORS_MODE,
        descriptor = ZO_QUEST_JOURNAL_MODE.RUMORS,
        normal = "EsoUI/Art/Journal/journal_rumors_tabIcon_up.dds",
        pressed = "EsoUI/Art/Journal/journal_rumors_tabIcon_down.dds",
        highlight = "EsoUI/Art/Journal/journal_rumors_tabIcon_over.dds",
        disabled = "EsoUI/Art/Journal/journal_rumors_tabIcon_disabled.dds",
        callback = function() self:SetMode(ZO_QUEST_JOURNAL_MODE.RUMORS) end,
        statusIcon = function()
            if RUMOR_MANAGER:HasAnyNewRumor() then
                return ZO_KEYBOARD_NEW_ICON
            end
            return nil
        end,
    }

    self.tabs:SetStartingFragment(self.questsTab.categoryName)

    self:RegisterForEvents()
end

function ZO_QuestJournal_Keyboard:RegisterForEvents()
    local function RefreshModeBar()
        self.tabs:UpdateButtons()
    end
    RUMOR_MANAGER:RegisterCallback("SingleRumorUpdated", RefreshModeBar)
    RUMOR_MANAGER:RegisterCallback("RumorsUpdated", RefreshModeBar)
end

function ZO_QuestJournal_Keyboard:OnShowing()
    if not self.initializedTabs then
        local questsFragments =
        {
            QUEST_JOURNAL_QUESTS_FRAGMENT_KEYBOARD,
        }
        self.tabs:Add(self.questsTab.categoryName, questsFragments, self.questsTab, ZO_QUEST_JOURNAL_QUESTS_KEYBOARD:GetKeybindStripDescriptor())

        local rumorsFragments =
        {
            QUEST_JOURNAL_RUMORS_FRAGMENT_KEYBOARD,
        }
        self.tabs:Add(self.rumorsTab.categoryName, rumorsFragments, self.rumorsTab, ZO_QUEST_JOURNAL_RUMORS_KEYBOARD:GetKeybindStripDescriptor())

        self.initializedTabs = true
    end

    self.tabs:UpdateButtons()

    if self.mode == ZO_QUEST_JOURNAL_MODE.QUESTS then
        self.tabs:SelectFragment(self.questsTab.categoryName)
    else
        self.tabs:SelectFragment(self.rumorsTab.categoryName)
    end
end

function ZO_QuestJournal_Keyboard:OnHiding()
    self.tabs:Clear()
end

function ZO_QuestJournal_Keyboard:SetMode(mode)
    self.mode = mode
end

-- TODO Rumors: Have callers access the quests object directly
function ZO_QuestJournal_Keyboard:RegisterCallback(...)
    ZO_QUEST_JOURNAL_QUESTS_KEYBOARD:RegisterCallback(...)
end

-- TODO Rumors: Have callers access the quests object directly
function ZO_QuestJournal_Keyboard:GetIconTexture(...)
    return ZO_QUEST_JOURNAL_QUESTS_KEYBOARD:GetIconTexture(...)
end

function ZO_QuestJournal_Keyboard:OpenQuestJournalToQuest(questIndex)
    self:SetMode(ZO_QUEST_JOURNAL_MODE.QUESTS)
    SCENE_MANAGER:Show("questJournal")
    ZO_QUEST_JOURNAL_QUESTS_KEYBOARD:QueuePendingJournalQuestIndex(questIndex)
end

-- XML Functions

function ZO_QuestJournal_Keyboard_OnInitialized(control)
    QUEST_JOURNAL_KEYBOARD = ZO_QuestJournal_Keyboard:New(control)
    SYSTEMS:RegisterKeyboardObject("questJournal", QUEST_JOURNAL_KEYBOARD)
end
