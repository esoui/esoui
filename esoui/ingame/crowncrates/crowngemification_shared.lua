ZO_CrownGemification_Shared = ZO_Object:Subclass()

function ZO_CrownGemification_Shared:New(...)
    local object = ZO_Object.New(self)
    object:Initialize(...)
    return object
end

function ZO_CrownGemification_Shared:Initialize(listFragment, gemificationSlot, exitKeybindStripDescriptor)
    self.listFragment = listFragment
    self.gemificationSlot = gemificationSlot
    self.exitKeybindStripDescriptor = exitKeybindStripDescriptor

    CROWN_GEMIFICATION_MANAGER:RegisterCallback("GemifiableListChanged", function() self:OnGemifiableListChanged() end)
    CROWN_GEMIFICATION_MANAGER:RegisterCallback("GemifiableChanged", function(gemifiable) self:OnGemifiableChanged(gemifiable) end)

    self.refreshGroup = ZO_Refresh:New()

    self.refreshGroup:AddRefreshGroup("Gemifiable",
    {
        RefreshAll = function()
            self:RefreshList()
        end,
        RefreshSingle = function(gemifiable)
            self:RefreshGemifiable(gemifiable)
        end,
    })

    self.listFragment:RegisterCallback("StateChange", function(oldState, newState)
        if newState == SCENE_FRAGMENT_SHOWING then
            self:OnShowing()
        elseif newState == SCENE_FRAGMENT_HIDDEN then
            self:OnHidden()
        end
    end)

    self.gemificationSlot:RegisterCallback("GemifiableChanged", function()
        if self.listFragment:IsShowing() then
            KEYBIND_STRIP:UpdateKeybindButtonGroup(self.sharedKeybindStripDescriptor, self.keybindStripId)
        end
    end)

    self:InitializeSharedKeybinds()
end

function ZO_CrownGemification_Shared:OnShowing()
    self:CleanRefreshGroupIfNecessary()
    self.gemificationSlot:SetGemifiable(nil)
    self.keybindStripId = KEYBIND_STRIP:PushKeybindGroupState()
    KEYBIND_STRIP:RemoveDefaultExit(self.keybindStripId)
    KEYBIND_STRIP:AddKeybindButton(self.exitKeybindStripDescriptor, self.keybindStripId)
    KEYBIND_STRIP:AddKeybindButtonGroup(self.sharedKeybindStripDescriptor, self.keybindStripId)
end

function ZO_CrownGemification_Shared:OnHidden()
    self.gemificationSlot:SetGemifiable(nil)
    KEYBIND_STRIP:RemoveKeybindButton(self.exitKeybindStripDescriptor, self.keybindStripId)
    KEYBIND_STRIP:RestoreDefaultExit(self.keybindStripId)
    KEYBIND_STRIP:RemoveKeybindButtonGroup(self.sharedKeybindStripDescriptor, self.keybindStripId)
    KEYBIND_STRIP:PopKeybindGroupState()
    self.keybindStripId = nil
    ZO_CrownCrates_FireStateMachineTrigger(ZO_CROWN_CRATE_TRIGGER_COMMANDS.GEMIFICATION_HIDDEN)
end

function ZO_CrownGemification_Shared:InitializeSharedKeybinds()
    self.sharedKeybindStripDescriptor =
    {
        {
            alignment = KEYBIND_STRIP_ALIGN_CENTER,
            name = GetString(SI_GEMIFICATION_EXTRACT),
            keybind = "UI_SHORTCUT_SECONDARY",
            enabled = function()
                return self.gemificationSlot:CanGemify()
            end,
            callback = function()
                self.gemificationSlot:GemifyOne()
            end,
        },
        {
            alignment = KEYBIND_STRIP_ALIGN_CENTER,
            name = function()
                return zo_strformat(SI_GEMIFICATION_EXTRACT_ALL, self.gemificationSlot:GetGemifyAllCount())
            end,
            keybind = "UI_SHORTCUT_TERTIARY",
            enabled = function()
                return self.gemificationSlot:CanGemify()
            end,
            callback = function()
                local gemifiable = self.gemificationSlot:GetGemifiable()
                local count = self.gemificationSlot:GetGemifyAllCount()
                local name = ZO_WHITE:Colorize(gemifiable.name)
                local gemTotal = gemifiable.gemTotal
                ZO_Dialogs_ShowPlatformDialog("EXTRACT_ALL_PROMPT", { gemificationSlot = self.gemificationSlot }, {mainTextParams = { count, name, gemTotal }})
            end,
        }
    }
end

function ZO_CrownGemification_Shared:OnGemifiableListChanged()
    self.refreshGroup:RefreshAll("Gemifiable")
    self:CleanRefreshGroupIfNecessary()
end

function ZO_CrownGemification_Shared:OnGemifiableChanged(gemifiable)
    self.refreshGroup:RefreshSingle("Gemifiable", gemifiable)
    self:CleanRefreshGroupIfNecessary()
end

function ZO_CrownGemification_Shared:CleanRefreshGroupIfNecessary()
    if self.listFragment:IsShowing() then
        self.refreshGroup:UpdateRefreshGroups()
    end
end

function ZO_CrownGemification_Shared:RefreshList()
    KEYBIND_STRIP:UpdateKeybindButtonGroup(self.sharedKeybindStripDescriptor, self.keybindStripId)
end

function ZO_CrownGemification_Shared:RefreshGemifiable(gemifiable)
    KEYBIND_STRIP:UpdateKeybindButtonGroup(self.sharedKeybindStripDescriptor, self.keybindStripId)
end

function ZO_CrownGemification_Shared:InsertIntoScene()
    --Override
end

function ZO_CrownGemification_Shared:RemoveFromScene()
    --Override
end