local SCROLL_MAGNITUDE_THRESHOLD = 1

ZO_AntiquityLoreReader_Keyboard = ZO_Object:Subclass()

function ZO_AntiquityLoreReader_Keyboard:New(...)
    local object = ZO_Object.New(self)
    object:Initialize(...)
    return object
end

function ZO_AntiquityLoreReader_Keyboard:Initialize(control)
    self:InitializeControls(control)
end

function ZO_AntiquityLoreReader_Keyboard:InitializeControls(control)
    control.owner = self
    self.control = control
    self.loreEntryControls = {}
    self.loreScroll = self.control:GetNamedChild("Content")
    self.loreScrollChild = self.loreScroll:GetNamedChild("ScrollChild")

    -- Allow the lore reader's scroll control to scroll beyond the standard bounds
    -- in order to support the central display of all lore entries.
    self.accumulatedScrollMagnitude = 0
    self.loreScroll.scroll = self.loreScroll
    self.loreScroll:SetScrollBounding(SCROLL_BOUNDING_UNBOUND)
    self.loreScroll:SetFadeGradient(1, 0, 1, 50)
    self.loreScroll:SetFadeGradient(2, 0, -1, 100)
end

function ZO_AntiquityLoreReader_Keyboard:FocusLoreEntry(control)
    control.highlightAnimation:PlayForward()
end

function ZO_AntiquityLoreReader_Keyboard:UnfocusLoreEntry(control)
    control.highlightAnimation:PlayBackward()
end

function ZO_AntiquityLoreReader_Keyboard:Reset()
    for loreEntryControlIndex, loreEntryControl in ipairs(self.loreEntryControls) do
        self:FocusLoreEntry(loreEntryControl)
        loreEntryControl.treeNode = nil
        loreEntryControl:SetHandler("OnMouseDown", nil)
        loreEntryControl:SetMouseEnabled(false)
    end

    ANTIQUITY_LORE_DOCUMENT_MANAGER:ReleaseAllObjects(self.loreScrollChild)
    ZO_ClearNumericallyIndexedTable(self.loreEntryControls)
    self.previouslyAddedLoreEntryIndex = 0
    self.previouslyAddedLoreEntryControl = nil
    self.selectedLoreEntryControl = nil
end

function ZO_AntiquityLoreReader_Keyboard:AddLoreEntry(loreEntryData)
    local loreEntryIndex = self.previouslyAddedLoreEntryIndex + 1
    self.previouslyAddedLoreEntryIndex = loreEntryIndex

    -- Acquire and anchor lore entries in a back-and-forth (left, right, left, etc.) pattern.
    local loreEntryControl = ANTIQUITY_LORE_DOCUMENT_MANAGER:AcquireWideDocumentForLoreEntry(self.loreScrollChild, loreEntryData.antiquityId, loreEntryData.loreEntryIndex)
    loreEntryControl:ClearAnchors()
    if not self.previouslyAddedLoreEntryControl then
        loreEntryControl:SetAnchor(TOP)
    else
        local offsetX
        if loreEntryIndex % 2 == 0 then
            offsetX = 50
        else
            offsetX = -50
        end
        loreEntryControl:SetAnchor(TOPLEFT, self.previouslyAddedLoreEntryControl, BOTTOMLEFT, offsetX, -60)
    end
    loreEntryControl:SetHidden(false)
    loreEntryControl:SetMouseEnabled(true)
    loreEntryControl:SetHandler("OnMouseDown", ZO_AntiquityLoreEntry_OnClicked)
    self:UnfocusLoreEntry(loreEntryControl)

    self.previouslyAddedLoreEntryControl = loreEntryControl
    table.insert(self.loreEntryControls, loreEntryControl)

    return loreEntryControl
end

function ZO_AntiquityLoreReader_Keyboard:ShowAntiquityLoreEntry(data)
    if data then
        local loreEntryControl = data.loreEntryControl
        if loreEntryControl then
            local scrollControl = self.loreScroll
            local scrollHeight = scrollControl:GetHeight()
            scrollControl:SetVerticalScroll(0)

            -- Scroll the selected lore entry to the center of the scroll control's view.
            local controlOffset = loreEntryControl:GetTop()
            local controlHeight = loreEntryControl:GetHeight()
            local targetOffset = controlOffset - 0.5 * scrollHeight + 0.5 * controlHeight
            scrollControl:SetVerticalScroll(targetOffset)

            if self.selectedLoreEntryControl then
                self:UnfocusLoreEntry(self.selectedLoreEntryControl)
            end
            if data.unlocked then
                self:FocusLoreEntry(loreEntryControl)
            end
            self.selectedLoreEntryControl = loreEntryControl

            -- Update the lore entries' draw levels such that the focused control (loreEntryControl) is on top
            -- with the adjacent lore entries appearing in descending order in both directions (above and below).
            local currentDrawLevel = 100
            local drawLevelIncrement = 1
            for index, control in ipairs(self.loreEntryControls) do
                control:SetDrawLevel(currentDrawLevel)
                control.backgroundTexture:SetDrawLevel(currentDrawLevel)
                if control == loreEntryControl then
                    drawLevelIncrement = -1
                end
                currentDrawLevel = currentDrawLevel + drawLevelIncrement
            end

            PlaySound(SOUNDS.BOOK_PAGE_TURN)
        end
    end
end

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
    control.owner = self
    self.control = control
    self.antiquityIcon = self.control:GetNamedChild("AntiquityIcon")
    self.antiquityName = self.control:GetNamedChild("AntiquityName")
    self.loreEntryCount = self.control:GetNamedChild("LoreEntryCount")
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
            ANTIQUITY_LORE_READER_KEYBOARD:Reset()
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
        if control.subText then
            if data.subTitle then
                control.subText:SetText(data.subTitle)
            end
            control.subText:SetHidden(not data.subTitle)
            control.subText:SetSelected(open)
            control.subText:SetEnabled(data.unlocked)

            local DISABLE_SCALING = false
            ZO_IconHeader_Setup(control, open, data.unlocked, DISABLE_SCALING, ZO_AntiquityLore_IconHeader_UpdateSize)
        else
            ZO_IconHeader_Setup(control, open, data.unlocked)
        end
    end

    local function TreeEntryOnSelected(control, data, selected, reselectingDuringRebuild)
        control:SetSelected(selected)
        if selected then
            ANTIQUITY_LORE_READER_KEYBOARD:ShowAntiquityLoreEntry(data)
        end
        SetTreeEntryState(control, data.unlocked, selected)
    end

    self.selectedLoreEntryIndex = 0
    local DEFAULT_INDENT = 0
    local DEFAULT_SPACING = -10
    local TREE_WIDTH = 400
    self.loreEntryTreeScroll = GetControl(self.control, "LoreEntryContainer")
    self.loreEntryTree = ZO_Tree:New(GetControl(self.control, "LoreEntryContainerScrollChild"), DEFAULT_INDENT, DEFAULT_SPACING, TREE_WIDTH)
    self.loreEntryTree:AddTemplate("ZO_IconChildlessHeader", TreeEntrySetup, TreeEntryOnSelected, TreeEntryEquality)
    self.loreEntryTree:AddTemplate("ZO_AntiquityLore_SetIconChildlessHeader", TreeEntrySetup, TreeEntryOnSelected, TreeEntryEquality)
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

function ZO_AntiquityLore_Keyboard:Reset()
    self.antiquityId = nil
    self.antiquitySetId = nil
    self.accumulatedScrollMagnitude = 0
    self.loreEntryTree:Reset()
    ANTIQUITY_LORE_READER_KEYBOARD:Reset()
end

function ZO_AntiquityLore_Keyboard:Refresh()
    local antiquityData = self:GetData()
    local loreEntries = self:GetLoreEntryData()

    self.antiquityIcon:SetTexture(antiquityData:GetIcon())
    self.antiquityName:SetText(antiquityData:GetColorizedFormattedName())

    if loreEntries then
        local numUnlockedLoreEntries = antiquityData:GetNumUnlockedLoreEntries()
        local numLoreEntries = antiquityData:GetNumLoreEntries()
        self.loreEntries = loreEntries
        self.loreEntryCount:SetText(zo_strformat(SI_ANTIQUITY_CODEX_ENTRIES_FOUND, numUnlockedLoreEntries, numLoreEntries))

        local firstNode
        for loreEntryIndex, loreEntryData in ipairs(loreEntries) do
            local loreEntryControl
            if loreEntryData.unlocked then
                loreEntryControl = ANTIQUITY_LORE_READER_KEYBOARD:AddLoreEntry(loreEntryData)
            end

            local data =
            {
                title = loreEntryData.displayName,
                loreEntryIndex = loreEntryIndex,
                loreEntryControl = loreEntryControl,
                unlocked = loreEntryData.unlocked,
                subTitle = loreEntryData.fragmentName and ZO_CachedStrFormat(SI_ANTIQUITY_NAME_FORMATTER, loreEntryData.fragmentName),
            }

            local template = antiquityData.antiquitySetId and "ZO_AntiquityLore_SetIconChildlessHeader" or "ZO_IconChildlessHeader"
            local node = self.loreEntryTree:AddNode(template, data)

            if loreEntryControl then
                loreEntryControl.treeNode = node
			    firstNode = firstNode or node
            end
        end

        -- Select the first node in the tree.
        self.loreEntryTree:Commit(firstNode)
        -- Force the first node to be focused, even if it is locked.
        ANTIQUITY_LORE_READER_KEYBOARD:ShowAntiquityLoreEntry(firstNode)
    end
end

function ZO_AntiquityLore_Keyboard:ShowAntiquity(antiquityId)
    self:Reset()
    self.antiquityId = antiquityId
    self:Refresh()
    SCENE_MANAGER:Show("antiquityLoreKeyboard")
end

function ZO_AntiquityLore_Keyboard:ShowAntiquitySet(antiquitySetId)
    self:Reset()
    self.antiquitySetId = antiquitySetId
    self:Refresh()
    SCENE_MANAGER:Show("antiquityLoreKeyboard")
end

function ZO_AntiquityLore_Keyboard:SelectTreeNodeControl(control)
    if control and control.treeNode then
        self.loreEntryTree:SelectNode(control.treeNode)
        ZO_Scroll_ScrollControlIntoCentralView(self.loreEntryTreeScroll, control.treeNode.control)
    end
end

function ZO_AntiquityLore_Keyboard:ScrollLoreEntries(directionMagnitude)
    self.accumulatedScrollMagnitude = self.accumulatedScrollMagnitude + directionMagnitude

    local direction
    if self.accumulatedScrollMagnitude >= SCROLL_MAGNITUDE_THRESHOLD then
        direction = 1
        self.accumulatedScrollMagnitude = 0
    elseif self.accumulatedScrollMagnitude <= -SCROLL_MAGNITUDE_THRESHOLD then
        direction = -1
        self.accumulatedScrollMagnitude = 0
    end

    if direction then
        local currentNode = self.loreEntryTree:GetSelectedNode()
        if currentNode then
            local targetNode
            if direction > 0 then
                targetNode = currentNode:GetPreviousSiblingNode()
            else
                targetNode = currentNode:GetNextSiblingNode()
            end
            if targetNode then
                self.loreEntryTree:SelectNode(targetNode)
                ZO_Scroll_ScrollControlIntoCentralView(self.loreEntryTreeScroll, currentNode.control)
            end
        end
    end
end

-- Global XML --

function ZO_AntiquityLoreReader_OnMouseWheel(control, delta, ctrl, alt, shift)
    ANTIQUITY_LORE_KEYBOARD:ScrollLoreEntries(delta)
end

function ZO_AntiquityLoreEntry_OnClicked(control)
    ANTIQUITY_LORE_KEYBOARD:SelectTreeNodeControl(control)
end

function ZO_AntiquityLore_IconHeader_UpdateSize(control)
    local textWidth, textHeight = control.text:GetTextDimensions()
    local height = textHeight + ZO_TREE_ENTRY_ICON_HEADER_TEXT_PADDING_Y * 2
    local subTextWidth, subTextHeight = control.subText:GetTextDimensions()
    height = height + subTextHeight
    height = zo_max(height, ZO_TREE_ENTRY_ICON_HEADER_ICON_MAX_DIMENSIONS)
    local width = zo_max(textWidth, subTextWidth) + ZO_TREE_ENTRY_ICON_HEADER_TEXT_OFFSET_X
    control:SetDimensions(width, height)
end

function ZO_AntiquityLore_IconHeader_OnInitialized(control)
    ZO_IconHeader_OnInitialized(control)
    control.OnMouseUp = ZO_TreeEntry_OnMouseUp

    control.SetSelected = function(control, open, enabled, disableScaling)
        ZO_IconHeader_Setup(control, open, enabled, disableScaling, ZO_AntiquityLore_IconHeader_UpdateSize)
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

function ZO_AntiquityLoreReader_Keyboard_OnInitialized(control)
    ANTIQUITY_LORE_READER_KEYBOARD = ZO_AntiquityLoreReader_Keyboard:New(control)
end