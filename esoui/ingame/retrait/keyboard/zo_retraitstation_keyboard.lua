local KEYBOARD_RETRAIT_ROOT_SCENE_NAME = "retrait_keyboard_root"

ZO_RetraitStation_Keyboard = ZO_RetraitStation_Base:Subclass()

function ZO_RetraitStation_Keyboard:Initialize(control)
    ZO_RetraitStation_Base.Initialize(self, control, KEYBOARD_RETRAIT_ROOT_SCENE_NAME)

    ZO_RETRAIT_KEYBOARD = ZO_RetraitStation_Retrait_Keyboard:New(self.control:GetNamedChild("RetraitPanel"), self)
    ZO_RECONSTRUCT_KEYBOARD = ZO_RetraitStation_Reconstruct_Keyboard:New(self.control:GetNamedChild("ReconstructPanel"), self)

    self:InitializeModeBar()
    self:InitializeInteractScene()
end

function ZO_RetraitStation_Keyboard:InitializeModeBar()
    self.modeMenu = self.control:GetNamedChild("ModeMenu")
    self.modeBar = self.modeMenu:GetNamedChild("Bar")

    local MENU_BAR_DATA =
    {
        initialButtonAnchorPoint = RIGHT,
        buttonTemplate = "ZO_MenuBarTooltipButton",
        normalSize = 51,
        downSize = 64,
        buttonPadding = -15,
        animationDuration = 180,
    }

    ZO_MenuBar_SetData(self.modeBar, MENU_BAR_DATA)
    self.tabs = ZO_SceneFragmentBar:New(self.modeBar)

    self.retraitTab =
    {
        categoryName = SI_RETRAIT_STATION_RETRAIT_MODE,
        descriptor = ZO_RETRAIT_MODE_RETRAIT,
        normal = "EsoUI/Art/Crafting/retrait_tabIcon_up.dds",
        pressed = "EsoUI/Art/Crafting/retrait_tabIcon_down.dds",
        highlight = "EsoUI/Art/Crafting/retrait_tabIcon_over.dds",
        disabled = "EsoUI/Art/Crafting/retrait_tabIcon_disabled.dds",
        callback = function() self:SetMode(ZO_RETRAIT_MODE_RETRAIT) end,
    }

    self.reconstructTab =
    {
        categoryName = SI_RETRAIT_STATION_RECONSTRUCT_MODE,
        descriptor = ZO_RETRAIT_MODE_RECONSTRUCT,
        normal = "EsoUI/Art/Crafting/reconstruct_tabIcon_up.dds",
        pressed = "EsoUI/Art/Crafting/reconstruct_tabIcon_down.dds",
        highlight = "EsoUI/Art/Crafting/reconstruct_tabIcon_over.dds",
        disabled = "EsoUI/Art/Crafting/reconstruct_tabIcon_disabled.dds",
        callback = function() self:SetMode(ZO_RETRAIT_MODE_RECONSTRUCT) end,
    }

    self.tabs:SetStartingFragment(self.retraitTab.categoryName)
    ZO_CraftingUtils_ConnectMenuBarToCraftingProcess(self.modeBar)
end

function ZO_RetraitStation_Keyboard:InitializeInteractScene()
    KEYBOARD_RETRAIT_ROOT_SCENE = self.interactScene

    local fragment = ZO_FadeSceneFragment:New(self.control)
    self.interactScene:AddFragment(fragment)

    SYSTEMS:RegisterKeyboardRootScene("retrait", self.interactScene)
end

function ZO_RetraitStation_Keyboard:OnInteractSceneShowing()
    if not self.initializedTabs then
        local retraitFragments =
        {
            RIGHT_PANEL_BG_FRAGMENT,
            RETRAIT_STATION_RETRAIT_FRAGMENT,
            CRAFTING_RESULTS_FRAGMENT,
        }
        ZO_CombineNumericallyIndexedTables(retraitFragments, FRAGMENT_GROUP.READ_ONLY_EQUIPPED_ITEMS)
        self.tabs:Add(self.retraitTab.categoryName, retraitFragments, self.retraitTab, ZO_RETRAIT_KEYBOARD:GetKeybindDescriptor())

        local reconstructFragments =
        {
            RIGHT_BG_FRAGMENT,
            RETRAIT_STATION_RECONSTRUCT_FRAGMENT,
            CRAFTING_RESULTS_FRAGMENT,
        }
        self.tabs:Add(self.reconstructTab.categoryName, reconstructFragments, self.reconstructTab, ZO_RECONSTRUCT_KEYBOARD:GetKeybindDescriptor())

        ZO_CraftingUtils_ConnectMenuBarToCraftingProcess(self.modeBar)
        self.initializedTabs = true
    end

    self.tabs:UpdateButtons()

    if self.mode == ZO_RETRAIT_MODE_RECONSTRUCT then
        self.tabs:SelectFragment(self.reconstructTab.categoryName)
    else
        self.tabs:SelectFragment(self.retraitTab.categoryName)
    end
end

function ZO_RetraitStation_Keyboard:OnInteractSceneHiding()
    self.tabs:Clear()
end

function ZO_RetraitStation_Keyboard:OnInteractSceneHidden()
    CRAFTING_RESULTS:SetCraftingTooltip(nil)
end

function ZO_RetraitStation_Keyboard:UpdateKeybinds()
    KEYBIND_STRIP:UpdateKeybindButtonGroup(self.tabs:GetActiveKeybind())
end

function ZO_RetraitStation_Keyboard:SetMode(mode)
    if self.mode ~= mode then
        self.mode = mode
        self:RefreshModeMenuAnchors()

        ZO_CraftingUtils_ConnectKeybindButtonGroupToCraftingProcess(self.tabs:GetActiveKeybind())
    end
end

function ZO_RetraitStation_Keyboard:RefreshModeMenuAnchors()
    local modeBackground

    if self.mode == ZO_RETRAIT_MODE_RETRAIT then
        modeBackground = ZO_SharedRightPanelBackground
    elseif self.mode == ZO_RETRAIT_MODE_RECONSTRUCT then
        modeBackground = ZO_SharedRightBackground
    end

    if modeBackground then
        self.modeMenu:ClearAnchors()

        local DIVIDER_OFFSET_X = 40
        self.modeMenu:SetAnchor(TOPLEFT, modeBackground, nil, DIVIDER_OFFSET_X)
        self.modeMenu:SetAnchor(TOPRIGHT, modeBackground, nil, -DIVIDER_OFFSET_X)
    end
end

-- Global XML functions

function ZO_RetraitStation_Keyboard_Initialize(control)
    ZO_RETRAIT_STATION_KEYBOARD = ZO_RetraitStation_Keyboard:New(control)
end