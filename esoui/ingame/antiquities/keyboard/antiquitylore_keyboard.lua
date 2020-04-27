ZO_AntiquityLore_Keyboard = ZO_Object:Subclass()

function ZO_AntiquityLore_Keyboard:New(...)
    local object = ZO_Object.New(self)
    object:Initialize(...)
    return object
end

function ZO_AntiquityLore_Keyboard:Initialize(control)
    self:InitializeControls(control)
    self:InitializeEntryTree()
    self:InitializeKeybindDescriptors()
    self:InitializeScene()
end

function ZO_AntiquityLore_Keyboard:InitializeControls(control)
    self.control = control
    self.antiquityIcon = self.control:GetNamedChild("AntiquityIcon")
    self.antiquityName = self.control:GetNamedChild("AntiquityName")
    self.loreEntryCount = self.control:GetNamedChild("LoreEntryCount")
    self.loreScroll = self.control:GetNamedChild("LorePanelLoreScroll")
    self.loreScrollChild = self.loreScroll:GetNamedChild("ContentScrollChild")
    self.loreScrollTitle = self.loreScrollChild:GetNamedChild("Title")
    self.loreScrollBody = self.loreScrollChild:GetNamedChild("Body")
end

function ZO_AntiquityLore_Keyboard:InitializeScene()
    self.scene = ZO_Scene:New("antiquityLoreKeyboard", SCENE_MANAGER)
    SYSTEMS:RegisterKeyboardObject("antiquityLoreKeyboard", self)
    SYSTEMS:RegisterKeyboardRootScene("antiquityLoreKeyboard", self.scene)
    ANTIQUITY_LORE_KEYBOARD_SCENE = self.scene
    self.scene:RegisterCallback("StateChange", function(oldState, newState)
        if newState == SCENE_SHOWING then
            KEYBIND_STRIP:RemoveDefaultExit()
            KEYBIND_STRIP:AddKeybindButtonGroup(self.keybindStripDescriptor)
        elseif newState == SCENE_HIDING then
            KEYBIND_STRIP:RemoveKeybindButtonGroup(self.keybindStripDescriptor)
            KEYBIND_STRIP:RestoreDefaultExit()
        end
    end)
end

function ZO_AntiquityLore_Keyboard:InitializeKeybindDescriptors()
    self.keybindStripDescriptor =
    {
        {
            alignment = KEYBIND_STRIP_ALIGN_RIGHT,
            name = GetString(SI_ANTIQUITY_BACK_TO_JOURNAL),
            keybind = "UI_SHORTCUT_EXIT",
            order = -10000,
            callback = function()
                SCENE_MANAGER:Show("antiquityJournalKeyboard")
            end,
        },
    }
end

function ZO_AntiquityLore_Keyboard:InitializeEntryTree()
    local function TreeEntryEquality(left, right)
        return left.loreEntryIndex == right.loreEntryIndex
    end

    local function SetTreeEntryState(control, unlocked, selected)
        local iconTexture
        if unlocked then
            if selected then
                iconTexture = "EsoUI/Art/Antiquities/bullet_active.dds"
            else
                iconTexture = "EsoUI/Art/Antiquities/bullet.dds"
            end
        else
            iconTexture = "EsoUI/Art/Antiquities/bullet_empty.dds"
        end
        control.icon:SetTexture(iconTexture)
        control.iconHighlight:SetTexture(iconTexture)
    end

    local function TreeEntrySetup(node, control, data, open)
        control.text:SetModifyTextType(MODIFY_TEXT_TYPE_UPPERCASE)
        control.text:SetFont("ZoFontWinH3")
        control.text:SetText(data.title)
        node:SetEnabled(data.unlocked)
        SetTreeEntryState(control, data.unlocked, node == node:IsSelected())

        control.subText = control:GetNamedChild("SubText")
        if data.subTitle then
            control.subText:SetText(data.subTitle)
        end
        control.subText:SetHidden(not data.subTitle)
        control.subText:SetSelected(open)

        ZO_IconHeader_Setup(control, open)
    end

    local function TreeEntryOnSelected(control, data, selected, reselectingDuringRebuild)
        control:SetSelected(selected)
        if selected then
            self:SetLoreScrollEnabled(true)
            self:ShowAntiquityLoreEntry(data.loreEntryIndex)
        end
        SetTreeEntryState(control, data.unlocked, selected)
    end

    self.selectedLoreEntryIndex = 0
    self.loreEntryTree = ZO_Tree:New(GetControl(self.control, "LoreEntryContainerScrollChild"), 0, 10, 400)
    self.loreEntryTree:AddTemplate("ZO_AntiquityLore_IconChildlessHeader", TreeEntrySetup, TreeEntryOnSelected, TreeEntryEquality)
    self.loreEntryTree:SetExclusive(true)
    self.loreEntryTree:SetOpenAnimation("ZO_TreeOpenAnimation")
end

function ZO_AntiquityLore_Keyboard:GetData()
    if self.antiquityId then
        return ANTIQUITY_DATA_MANAGER:GetAntiquityData(self.antiquityId)
    else
        return ANTIQUITY_DATA_MANAGER:GetAntiquitySetData(self.antiquitySetId)
    end
end

function ZO_AntiquityLore_Keyboard:GetLoreEntryData()
    local data = self:GetData()
    return data:GetLoreEntries()
end

function ZO_AntiquityLore_Keyboard:SetLoreScrollEnabled(enabled)
    local scrollTexture = self.loreScroll:GetNamedChild("Backdrop")
    local color = enabled and 1 or 0.5
    scrollTexture:SetDesaturation(enabled and 0 or 1)
    scrollTexture:SetColor(color, color, color, 1)
    if not enabled then
        self.loreScrollTitle:SetText("")
        self.loreScrollBody:SetText("")
    end
end

function ZO_AntiquityLore_Keyboard:RefreshLoreSectionStates()
    local loreEntry = self:GetLoreEntryData()[self.selectedLoreEntryIndex]
    if loreEntry then
        self.loreScrollTitle:SetText(loreEntry.displayName)
        self.loreScrollBody:SetText(loreEntry.description)
        self.loreScrollBody:SetHidden(false)
    else
        self.loreScrollBody:SetHidden(true)
    end
end

function ZO_AntiquityLore_Keyboard:Refresh()
    local antiquityData = self:GetData()
    local loreEntries = self:GetLoreEntryData()

    self.antiquityIcon:SetTexture(antiquityData:GetIcon())
    self.antiquityName:SetText(antiquityData:GetColorizedFormattedName())
    self.loreEntryTree:Reset()
    self:SetLoreScrollEnabled(false)

    if loreEntries then
        local numUnlockedLoreEntries = antiquityData:GetNumUnlockedLoreEntries()
        local numLoreEntries = antiquityData:GetNumLoreEntries()

        self.loreEntryCount:SetText(zo_strformat(SI_ANTIQUITY_CODEX_ENTRIES_FOUND, numUnlockedLoreEntries, numLoreEntries))
        for loreEntryIndex, loreEntryData in ipairs(loreEntries) do
            local data =
            {
                title = loreEntryData.displayName,
                loreEntryIndex = loreEntryIndex,
                unlocked = loreEntryData.unlocked,
                subTitle = loreEntryData.fragmentName,
            }
            self.loreEntryTree:AddNode("ZO_AntiquityLore_IconChildlessHeader", data, nil, nil, false)
        end
    end

    self.loreEntryTree:Commit()
end

function ZO_AntiquityLore_Keyboard:ShowAntiquity(antiquityId)
    self.antiquityId = antiquityId
    self.antiquitySetId = nil
    self:Refresh()
    SCENE_MANAGER:Show("antiquityLoreKeyboard")
end

function ZO_AntiquityLore_Keyboard:ShowAntiquitySet(antiquitySetId)
    self.antiquitySetId = antiquitySetId
    self.antiquityId = nil
    self:Refresh()
    SCENE_MANAGER:Show("antiquityLoreKeyboard")
end

function ZO_AntiquityLore_Keyboard:ShowAntiquityLoreEntry(loreEntryIndex)
    self.selectedLoreEntryIndex = loreEntryIndex
    self:RefreshLoreSectionStates()
    PlaySound(SOUNDS.BOOK_PAGE_TURN)
end

-- Global XML --

function ZO_AntiquityLore_IconHeader_OnInitialized(control)
    ZO_IconHeader_OnInitialized(control)
    control.OnMouseUp = ZO_TreeEntry_OnMouseUp

    control.SetSelected = function(control, open, enabled, disableScaling)
        ZO_IconHeader_Setup(control, open, enabled, disableScaling)
        control.subText:SetSelected(open)
    end
    control.OnMouseEnter = function(...)
        ZO_IconHeader_OnMouseEnter(...)
        ZO_SelectableLabel_OnMouseEnter(control.subText)
    end
    control.OnMouseExit = function(...)
        ZO_IconHeader_OnMouseExit(...)
        ZO_SelectableLabel_OnMouseExit(control.subText)
    end
end

function ZO_AntiquityLore_Keyboard_OnInitialized(control)
    ANTIQUITY_LORE_KEYBOARD = ZO_AntiquityLore_Keyboard:New(control)
end
