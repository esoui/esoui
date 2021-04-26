ZO_COMPANION_CHARACTER_KEYBOARD_TREE_WIDTH = 243
-- 75 is the inset from the multiIcon plus the icon and spacing from ZO_IconHeader
ZO_COMPANION_CHARACTER_KEYBOARD_TREE_LABEL_WIDTH = ZO_COMPANION_CHARACTER_KEYBOARD_TREE_WIDTH - 75

ZO_CompanionCharacter_Keyboard = ZO_InitializingObject:Subclass()

function ZO_CompanionCharacter_Keyboard:Initialize(control)
    self.control = control

    self.scene = ZO_COMPANION_MANAGER:CreateInteractScene("companionCharacterKeyboard")
    self.scene:RegisterCallback("StateChange", function(oldState, newState)
        if newState == SCENE_SHOWING then
            self:BuildNavigationTree()
        elseif newState == SCENE_HIDDEN then
            self:SelectNavigationFragment(nil)
        end
    end)

    COMPANION_CHARACTER_KEYBOARD_SCENE = self.scene
    COMPANION_CHARACTER_KEYBOARD_FRAGMENT = ZO_FadeSceneFragment:New(control)

    self.currentNavigationFragment = nil
    self:InitializeNavigationTree()
end

function ZO_CompanionCharacter_Keyboard:InitializeNavigationTree()
    local DEFAULT_INDENT = 60
    local DEFAULT_SPACING = -10
    self.navigationTree = ZO_Tree:New(self.control:GetNamedChild("NavigationContainer"), DEFAULT_INDENT, DEFAULT_SPACING, ZO_COMPANION_CHARACTER_KEYBOARD_TREE_WIDTH)
    self.navigationTree:SetExclusive(true)
    self.navigationTree:SetOpenAnimation("ZO_TreeOpenAnimation")

    -- ZO_CompanionCharacter_Keyboard_TreeCategory
    local function TreeCategoryEntrySetup(node, control, entryData, open)
        control.text:SetText(entryData.name)

        local iconTexture = open and entryData.pressedIcon or entryData.normalIcon
        control.icon:SetTexture(iconTexture)

        local mouseoverTexture = entryData.mouseoverIcon
        control.iconHighlight:SetTexture(mouseoverTexture)

        ZO_IconHeader_Setup(control, open, entryData.unlocked)
    end

    local function OnTreeCategorySelected(control, entryData, selected, reselectingDuringRebuild)
        control.icon:SetTexture(selected and entryData.pressedIcon or entryData.normalIcon)
        ZO_IconHeader_Setup(control, selected)

        if selected then
            self:SelectNavigationFragment(entryData.fragment)
        end
    end

    self.navigationTree:AddTemplate("ZO_CompanionCharacter_Keyboard_TreeCategory", TreeCategoryEntrySetup, OnTreeCategorySelected)
end

function ZO_CompanionCharacter_Keyboard:BuildNavigationTree()
    self.navigationTree:Reset()
    local NAVIGATION_ENTRY_DATA =
    {
        {
            name = GetString(SI_COMPANION_MENU_OVERVIEW_TITLE),
            fragment = COMPANION_OVERVIEW_KEYBOARD_FRAGMENT,
            normalIcon = "EsoUI/Art/Companion/Keyboard/companion_overview_up.dds",
            pressedIcon = "EsoUI/Art/Companion/Keyboard/companion_overview_down.dds",
            mouseoverIcon = "EsoUI/Art/Companion/Keyboard/companion_overview_over.dds",
        },
        {
            name = GetString(SI_COMPANION_MENU_EQUIPMENT_TITLE),
            fragment = COMPANION_EQUIPMENT_KEYBOARD_FRAGMENT,
            normalIcon = "EsoUI/Art/Companion/Keyboard/companion_inventory_up.dds",
            pressedIcon = "EsoUI/Art/Companion/Keyboard/companion_inventory_down.dds",
            mouseoverIcon = "EsoUI/Art/Companion/Keyboard/companion_inventory_over.dds",
        },
    }

    for _, entryData in ipairs(NAVIGATION_ENTRY_DATA) do
        self.navigationTree:AddNode("ZO_CompanionCharacter_Keyboard_TreeCategory", entryData)
    end

    self.navigationTree:Commit()
end

function ZO_CompanionCharacter_Keyboard:SelectNavigationFragment(fragment)
    if fragment == self.currentNavigationFragment then
        return
    end

    if self.currentNavigationFragment then
        self.scene:RemoveFragment(self.currentNavigationFragment)
    end

    if fragment then
        self.scene:AddFragment(fragment)
    end

    self.currentNavigationFragment = fragment
end

-----------------------------
-- Global XML Functions
-----------------------------

function ZO_CompanionCharacter_Keyboard_TopLevel_OnInitialized(control)
    COMPANION_CHARACTER_KEYBOARD = ZO_CompanionCharacter_Keyboard:New(control)
end