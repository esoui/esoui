ZO_CraftAdvisor_Keyboard = ZO_Object:Subclass()

function ZO_CraftAdvisor_Keyboard:New(...)
    local object = ZO_Object.New(self)
    object:Initialize(...)
    return object
end

function ZO_CraftAdvisor_Keyboard:Initialize(control)
    self.control = control
    self.tabBar = control:GetNamedChild("SelectionTabBar")
    self.initializedTabs = false

    self:SetupTabs()

    CRAFT_ADVISOR_FRAGMENT = ZO_FadeSceneFragment:New(control)
    CRAFT_ADVISOR_FRAGMENT:RegisterCallback("StateChange", function(oldState, newState)
        if newState == SCENE_FRAGMENT_SHOWING then
            self:OnShowing()
        elseif newState == SCENE_FRAGMENT_HIDDEN then
            self:OnHidden()
        end
    end)

    CRAFT_ADVISOR_MANAGER:RegisterCallback("QuestMasterListUpdated", function()
        self:RefreshTabs()
    end)

    CALLBACK_MANAGER:RegisterCallback("CraftingAnimationsStopped", function()
        if self.dirty then
            self:RefreshTabs()
        end
    end)
end

function ZO_CraftAdvisor_Keyboard:SetupTabs()
    local MENU_BAR_DATA =
    {
        initialButtonAnchorPoint = RIGHT,
        buttonTemplate = "ZO_MenuBarTooltipButton",
        normalSize = 51,
        downSize = 64,
        buttonPadding = -15,
        animationDuration = 180,
    }
    ZO_MenuBar_SetData(self.tabBar, MENU_BAR_DATA)

    self.tabs = ZO_SceneFragmentBar:New(self.tabBar)
    local function CreateButtonData(normal, pressed, highlight, disabled, enabledFunction, alwaysShowTooltip, customTooltipFunction, callback)
        return 
        {
            normal = normal,
            pressed = pressed,
            highlight = highlight,
            disabled = disabled,
            enabled = enabledFunction,
            alwaysShowTooltip = alwaysShowTooltip,
            CustomTooltipFunction = customTooltipFunction,
            callback = callback,
        }
    end

    local ALWAYS_SHOW_EQUIP_TOOLTIP = true
    local DEFAULT_ENABLED_FUNCTION = nil

    local function LayoutEquipTabTooltip(informationTooltip)
        SetTooltipText(informationTooltip, zo_strformat(SI_MENU_BAR_TOOLTIP, GetString(SI_CRAFT_ADVISOR_TOOLTIP_EQUIP_TAB)))
    end

    self.equipmentData = CreateButtonData("EsoUI/Art/WritAdvisor/advisor_tabIcon_equip_up.dds", 
    "EsoUI/Art/WritAdvisor/advisor_tabIcon_equip_down.dds", 
    "EsoUI/Art/WritAdvisor/advisor_tabIcon_equip_over.dds", 
    "EsoUI/Art/WritAdvisor/advisor_tabIcon_equip_disabled.dds",
    DEFAULT_ENABLED_FUNCTION,
    ALWAYS_SHOW_EQUIP_TOOLTIP,
    LayoutEquipTabTooltip,
    function() 
        self.control:ClearAnchors()
        self.control:SetAnchor(TOPLEFT, ZO_SharedThinLeftPanelBackground, TOPLEFT)
        self.control:SetAnchor(BOTTOMRIGHT, ZO_SharedThinLeftPanelBackground, BOTTOMRIGHT, -20, -15)
    end)

    local ALWAYS_SHOW_CRAFT_TOOLTIP = true

    local function LayoutCraftAdvisorTooltip(informationTooltip)
        if CRAFT_ADVISOR_MANAGER:HasActiveWrits() then
            SetTooltipText(informationTooltip, zo_strformat(SI_MENU_BAR_TOOLTIP, GetString(SI_CRAFT_ADVISOR_TOOLTIP_WRIT_TAB)))
        else
            SetTooltipText(informationTooltip, zo_strformat(SI_MENU_BAR_TOOLTIP, GetString(SI_CRAFT_ADVISOR_TOOLTIP_WRIT_TAB)))
            informationTooltip:AddLine(GetString(SI_CRAFT_ADVISOR_TOOLTIP_WRIT_TAB_DISABLED_SUBTEXT))
        end
    end

    self.writData = CreateButtonData("EsoUI/Art/WritAdvisor/advisor_tabIcon_quests_up.dds", 
    "EsoUI/Art/WritAdvisor/advisor_tabIcon_quests_down.dds", 
    "EsoUI/Art/WritAdvisor/advisor_tabIcon_quests_over.dds", 
    "EsoUI/Art/WritAdvisor/advisor_tabIcon_quests_disabled.dds",
    function() return CRAFT_ADVISOR_MANAGER:HasActiveWrits() end,
    ALWAYS_SHOW_CRAFT_TOOLTIP,
    LayoutCraftAdvisorTooltip,
    function() 
        self.control:ClearAnchors()
        self.control:SetAnchor(TOPLEFT, ZO_SharedMediumLeftPanelBackground, TOPLEFT)
        self.control:SetAnchor(BOTTOMRIGHT, ZO_SharedMediumLeftPanelBackground, BOTTOMRIGHT, -20, -15)
    end)

    ZO_CraftingUtils_ConnectMenuBarToCraftingProcess(self.tabBar)
end

function ZO_CraftAdvisor_Keyboard:SelectDefaultTab()
    --If the writ tab is enabled, we want to default to it, otherwise, default to the equip tab
    if CRAFT_ADVISOR_MANAGER:HasActiveWrits() then
        self.tabs:SelectFragment(SI_CRAFT_ADVISOR_WRITS_TITLE)
    else
       self.tabs:SelectFragment(SI_CHARACTER_EQUIP_TITLE)
    end
end

function ZO_CraftAdvisor_Keyboard:RefreshTabs()
    if CRAFT_ADVISOR_FRAGMENT:IsShowing() and not ZO_CraftingUtils_IsPerformingCraftProcess() then
        self.tabs:UpdateButtons()
        self:SelectDefaultTab()
        self.dirty = false
    else
        self.dirty = true
    end
end

function ZO_CraftAdvisor_Keyboard:OnShowing()
    --If this is the first time showing the craft advisor, we need to do a bit of extra setup
    if not self.initializedTabs then
        self.tabs:Add(SI_CRAFT_ADVISOR_WRITS_TITLE, { WRIT_ADVISOR_FRAGMENT, MEDIUM_LEFT_PANEL_BG_FRAGMENT}, self.writData)
        self.tabs:Add(SI_CHARACTER_EQUIP_TITLE, { READ_ONLY_CHARACTER_WINDOW_FRAGMENT, THIN_LEFT_PANEL_BG_FRAGMENT}, self.equipmentData)
        self.initializedTabs = true
    end

    self:RefreshTabs()
end

function ZO_CraftAdvisor_Keyboard:OnHidden()
    self.tabs:Clear()
end

function ZO_CraftAdvisor_Keyboard_OnInitialized(control)
    CRAFT_ADVISOR_WINDOW = ZO_CraftAdvisor_Keyboard:New(control)
end