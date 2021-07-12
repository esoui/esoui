ZO_COMPANION_CHARACTER_KEYBOARD_TREE_WIDTH = 243
-- 75 is the inset from the multiIcon plus the icon and spacing from ZO_IconHeader
ZO_COMPANION_CHARACTER_KEYBOARD_TREE_LABEL_WIDTH = ZO_COMPANION_CHARACTER_KEYBOARD_TREE_WIDTH - 75

ZO_CompanionCharacter_Keyboard = ZO_InitializingObject:Subclass()

function ZO_CompanionCharacter_Keyboard:Initialize(control)
    self.control = control

    self.scene = ZO_InteractScene:New("companionCharacterKeyboard", SCENE_MANAGER, ZO_COMPANION_MANAGER:GetInteraction())
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
    self.categoryNodes = {}
    self:InitializeNavigationTree()

    local function RefreshCategoryStatusIcons()
        if self.scene:IsShowing() then
            self:RefreshCategoryStatusIcons()
        end
    end
    SHARED_INVENTORY:RegisterCallback("SlotAdded", RefreshCategoryStatusIcons)
    SHARED_INVENTORY:RegisterCallback("SlotRemoved", RefreshCategoryStatusIcons)
    SHARED_INVENTORY:RegisterCallback("SlotUpdated", RefreshCategoryStatusIcons)
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

        self:UpdateCategoryNodeStatusIcon(node)
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

function ZO_CompanionCharacter_Keyboard:RefreshCategoryStatusIcons()
    if self.scene:IsShowing() then
        for _, categoryNode in pairs(self.categoryNodes) do
            self:UpdateCategoryNodeStatusIcon(categoryNode)
        end
    end
end

function ZO_CompanionCharacter_Keyboard:UpdateCategoryNodeStatusIcon(categoryNode)
    if categoryNode then
        local categoryControl = categoryNode.control
        if not categoryControl.statusIcon then
            categoryControl.statusIcon = categoryControl:GetNamedChild("StatusIcon")
        end
        categoryControl.statusIcon:ClearIcons()
        local categoryData = categoryNode.data
        local statusIcon = nil
        if type(categoryData.statusIcon) == "function" then
            statusIcon = categoryData.statusIcon()
        else
            statusIcon = categoryData.statusIcon
        end

        if statusIcon then
            categoryControl.statusIcon:AddIcon(statusIcon)
        end
        categoryControl.statusIcon:Show()
    end
end

function ZO_CompanionCharacter_Keyboard:BuildNavigationTree()
    self.navigationTree:Reset()
    ZO_ClearTable(self.categoryNodes)
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
            statusIcon = function()
                if SHARED_INVENTORY and SHARED_INVENTORY:AreAnyItemsNew(ZO_InventoryUtils_DoesNewItemMatchFilterType, ITEMFILTERTYPE_COMPANION, BAG_BACKPACK) then
                    return ZO_KEYBOARD_NEW_ICON
                end
                return nil
            end,
        },
    }

    for _, entryData in ipairs(NAVIGATION_ENTRY_DATA) do
        local treeNode = self.navigationTree:AddNode("ZO_CompanionCharacter_Keyboard_TreeCategory", entryData)
        self.categoryNodes[entryData] = treeNode
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