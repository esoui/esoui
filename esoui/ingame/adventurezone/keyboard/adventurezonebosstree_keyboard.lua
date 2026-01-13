ZO_AdventureZoneBossTree_Keyboard = ZO_AdventureZoneBossTree_Shared:Subclass()

function ZO_AdventureZoneBossTree_Keyboard:Initialize(...)
    ZO_AdventureZoneBossTree_Shared.Initialize(self, ...)

    local scene = self:GetScene()
    ADVENTURE_ZONE_BOSS_TREE_SCENE_KEYBOARD = scene
    SYSTEMS:RegisterKeyboardRootScene("adventureZoneBossTree", scene)
end

function ZO_AdventureZoneBossTree_Keyboard:GetSceneName()
    return "adventureZoneBossTreeKeyboard"
end

function ZO_AdventureZoneBossTree_Keyboard:UpdateKeybinds()
    KEYBIND_STRIP:UpdateKeybindButtonGroup(self.keybindStripDescriptor)
end

function ZO_AdventureZoneBossTree_Keyboard:SetSelectedBoss(boss)
    self.selectedBoss = boss
end

function ZO_AdventureZoneBossTree_Keyboard:ShowTooltipForBoss(boss, control)
    InitializeTooltip(InformationTooltip, control, RIGHT, -5, 0, LEFT)
    InformationTooltip:SetAdventureZoneBoss(boss)
end

function ZO_AdventureZoneBossTree_Keyboard.OnBossControlMouseEnter(control)
    ADVENTURE_ZONE_BOSS_TREE_KEYBOARD:SetSelectedBoss(control.boss)
    ADVENTURE_ZONE_BOSS_TREE_KEYBOARD:UpdateKeybinds()
    ADVENTURE_ZONE_BOSS_TREE_KEYBOARD:ShowTooltipForBoss(control.boss, control)
end

function ZO_AdventureZoneBossTree_Keyboard.OnBossControlMouseExit(control)
    ADVENTURE_ZONE_BOSS_TREE_KEYBOARD:SetSelectedBoss(nil)
    ADVENTURE_ZONE_BOSS_TREE_KEYBOARD:UpdateKeybinds()

    ClearTooltip(InformationTooltip)
end

function ZO_AdventureZoneBossTree_Keyboard.OnControlInitialized(control)
    ADVENTURE_ZONE_BOSS_TREE_KEYBOARD = ZO_AdventureZoneBossTree_Keyboard:New(control)
end