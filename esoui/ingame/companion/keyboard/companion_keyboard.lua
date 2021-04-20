-----------------------------
-- Companion Root
-----------------------------
ZO_Companion_Keyboard = ZO_InitializingObject:Subclass()

function ZO_Companion_Keyboard:Initialize(control)
    self.control = control

    COMPANION_KEYBOARD_FRAGMENT =  ZO_FadeSceneFragment:New(self.control)
    COMPANION_KEYBOARD_FRAGMENT:RegisterCallback("StateChange", function(oldState, newState)
        if newState == SCENE_FRAGMENT_HIDDEN then
            self.tabs:SelectTab("companionCharacterKeyboard")
        end
    end)

    self:InitializeModeBar()

    local function OnOpenCompanionMenu()
        if not IsInGamepadPreferredMode() then
            local sceneGroup = SCENE_MANAGER:GetSceneGroup("companionSceneGroup")
            specificScene = sceneGroup:GetActiveScene()
            SCENE_MANAGER:Show(specificScene)
        end
    end

    control:RegisterForEvent(EVENT_OPEN_COMPANION_MENU, OnOpenCompanionMenu)
end

function ZO_Companion_Keyboard:InitializeModeBar()
    self.menuHeader = self.control:GetNamedChild("MenuHeader")
    self.menuBar = self.menuHeader:GetNamedChild("Bar")

    local MENU_BAR_DATA =
    {
        initialButtonAnchorPoint = RIGHT,
        buttonTemplate = "ZO_MenuBarTooltipButton",
        normalSize = 51,
        downSize = 64,
        buttonPadding = -15,
        animationDuration = 180,
    }

    ZO_MenuBar_SetData(self.menuBar, MENU_BAR_DATA)
    self.tabs = ZO_SceneGroupBar:New(self.menuBar)

    local iconData =
    {
        {
            categoryName = SI_COMPANION_MENU_CHARACTER_TITLE,
            descriptor = "companionCharacterKeyboard",
            normal = "EsoUI/Art/Companion/Keyboard/companion_character_up.dds",
            pressed = "EsoUI/Art/Companion/Keyboard/companion_character_down.dds",
            disabled = "EsoUI/Art/Companion/Keyboard/companion_character_disabled.dds",
            highlight = "EsoUI/Art/Companion/Keyboard/companion_character_over.dds",
        },
        {
            categoryName = SI_COMPANION_MENU_SKILLS_TITLE,
            descriptor = "companionSkillsKeyboard",
            normal = "EsoUI/Art/Companion/Keyboard/companion_skills_up.dds",
            pressed = "EsoUI/Art/Companion/Keyboard/companion_skills_down.dds",
            disabled = "EsoUI/Art/Companion/Keyboard/companion_skills_disabled.dds",
            highlight = "EsoUI/Art/Companion/Keyboard/companion_skills_over.dds",
        },
        {
            categoryName = SI_COMPANION_MENU_COLLECTIONS_TITLE,
            descriptor = "companionCollectionBookKeyboard",
            normal = "EsoUI/Art/Companion/Keyboard/companion_collections_up.dds",
            pressed = "EsoUI/Art/Companion/Keyboard/companion_collections_down.dds",
            disabled = "EsoUI/Art/Companion/Keyboard/companion_collections_disabled.dds",
            highlight = "EsoUI/Art/Companion/Keyboard/companion_collections_over.dds",
        },
    }

    self.tabs:CreateSceneGroup("companionSceneGroup", iconData)
end

-----------------------------
-- Global XML Functions
-----------------------------

function ZO_Companion_Keyboard_Initialize(control)
    COMPANION_KEYBOARD = ZO_Companion_Keyboard:New(control)
end