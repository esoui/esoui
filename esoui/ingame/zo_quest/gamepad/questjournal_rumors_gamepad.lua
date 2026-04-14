ZO_QuestJournal_Rumors_Gamepad = ZO_Gamepad_ParametricList_Screen:Subclass()

function ZO_QuestJournal_Rumors_Gamepad:Initialize(control, owner)
    self.owner = owner

    local DONT_ACTIVATE_ON_SHOW = false -- we'll manually set our list
    ZO_Gamepad_ParametricList_Screen.Initialize(self, control, ZO_GAMEPAD_HEADER_TABBAR_CREATE, DONT_ACTIVATE_ON_SHOW)

    self:GetHeaderFragment():SetAlwaysAnimate(false)

    local ALWAYS_ANIMATE = true
    self.fragment = ZO_FadeSceneFragment:New(control, ALWAYS_ANIMATE)
    self:SetParentFragment(self.fragment)
    QUEST_JOURNAL_RUMORS_FRAGMENT_GAMEPAD = self.fragment

    self.fragmentGroup =
    {
        self.fragment,
    }

    local tabBarEntries = self.owner:GetTabBarEntries()
    self.headerData =
    {
        tabBarEntries = tabBarEntries,
        titleText = GetString(SI_QUEST_JOURNAL_RUMORS_MODE),
        data1HeaderText = GetString(SI_GAMEPAD_QUEST_JOURNAL_RUMORS_CURRENT_MAX_LABEL),
        data1Text = function() return zo_strformat(SI_GAMEPAD_QUEST_JOURNAL_RUMORS_CURRENT_MAX, GetNumPendingRumors(), GetMaxPendingRumors()) end,
    }
end

function ZO_QuestJournal_Rumors_Gamepad:InitializeKeybindStripDescriptors()
    self.keybindStripDescriptor =
    {
        alignment = KEYBIND_STRIP_ALIGN_LEFT,
    }

    ZO_Gamepad_AddBackNavigationKeybindDescriptors(self.keybindStripDescriptor, GAME_NAVIGATION_TYPE_BUTTON)
end

function ZO_QuestJournal_Rumors_Gamepad:GetFragmentGroup()
    return self.fragmentGroup
end

function ZO_QuestJournal_Rumors_Gamepad:UpdateHeader()
    local tabBarEntries = self.owner:GetTabBarEntries()
    self.headerData.tabBarEntries = tabBarEntries
    local BLOCK_CALLBACKS = true
    ZO_GamepadGenericHeader_Refresh(self.header, self.headerData, BLOCK_CALLBACKS)
end

-- Start ZO_Gamepad_ParametricList_Screen overrides

function ZO_QuestJournal_Rumors_Gamepad:PerformUpdate()
    self.dirty = false
end

function ZO_QuestJournal_Rumors_Gamepad:OnShowing()
    ZO_Gamepad_ParametricList_Screen.OnShowing(self)

    self:UpdateHeader()

    local DEFAULT_ALLOW_IF_DISABLED = nil
    local BLOCK_CALLBACKS = true
    ZO_GamepadGenericHeader_SetActiveTabIndex(self.header, self.owner:GetMode(), DEFAULT_ALLOW_IF_DISABLED, BLOCK_CALLBACKS)
    ZO_GamepadGenericHeader_Activate(self.header)
end

function ZO_QuestJournal_Rumors_Gamepad:OnHiding()
    self:Deactivate()

    ZO_GamepadGenericHeader_Deactivate(self.header)
end

-- End ZO_Gamepad_ParametricList_Screen overrides
