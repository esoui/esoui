-----------------------------
-- Companion Root
-----------------------------
ZO_Companion_Keyboard = ZO_InitializingObject:Subclass()

function ZO_Companion_Keyboard:Initialize(control)
    self.control = control

    COMPANION_KEYBOARD_FRAGMENT = ZO_FadeSceneFragment:New(self.control)
    COMPANION_KEYBOARD_FRAGMENT:RegisterCallback("StateChange", function(oldState, newState)
        if newState == SCENE_FRAGMENT_SHOWING then
            self:UpdateSceneGroupButtons()
        elseif newState == SCENE_FRAGMENT_HIDDEN then
            self.tabs:SelectTab("companionCharacterKeyboard")
        end
    end)

    self:InitializeModeBar()

    local function OnOpenCompanionMenu()
        if not IsInGamepadPreferredMode() then
            local sceneGroup = SCENE_MANAGER:GetSceneGroup("companionSceneGroup")
            local specificScene = sceneGroup:GetActiveScene()
            SCENE_MANAGER:Show(specificScene)
        end
    end

    control:RegisterForEvent(EVENT_OPEN_COMPANION_MENU, OnOpenCompanionMenu)

    local function UpdateSceneGroupButtons()
        if COMPANION_KEYBOARD_FRAGMENT:IsShowing() then
            self:UpdateSceneGroupButtons()
        end
    end
    COMPANION_SKILLS_DATA_MANAGER:RegisterCallback("SkillLineNewStatusChanged", UpdateSceneGroupButtons)
    ACTION_BAR_ASSIGNMENT_MANAGER:RegisterCallback("SlotNewStatusChanged", UpdateSceneGroupButtons)
    SHARED_INVENTORY:RegisterCallback("SlotAdded", UpdateSceneGroupButtons)
    SHARED_INVENTORY:RegisterCallback("SlotRemoved", UpdateSceneGroupButtons)
    SHARED_INVENTORY:RegisterCallback("SlotUpdated", UpdateSceneGroupButtons)
end

do
    local function StatusIconForCompanionSkills()
        if COMPANION_SKILLS_DATA_MANAGER:AreAnySkillLinesNew() then
            return ZO_KEYBOARD_NEW_ICON
        end
        local companionHotbar = ACTION_BAR_ASSIGNMENT_MANAGER:GetHotbar(HOTBAR_CATEGORY_COMPANION)
        if companionHotbar:AreAnySlotsNew() then
            return ZO_KEYBOARD_NEW_ICON
        end
        return nil
    end

    local function StatusIconForSpecializedCategory(specializedCategoryType)
        for categoryIndex, categoryData in ZO_COLLECTIBLE_DATA_MANAGER:CategoryIterator() do
            if categoryData:IsSpecializedCategory(specializedCategoryType) and categoryData:HasAnyNewCompanionCollectibles() then
                return ZO_KEYBOARD_NEW_ICON
            end
        end
        return nil
    end

    function ZO_Companion_Keyboard:InitializeModeBar()
        self.menuHeader = self.control:GetNamedChild("MenuHeader")
        self.menuBar = self.menuHeader:GetNamedChild("Bar")
        self.tabs = ZO_SceneGroupBar:New(self.menuBar)

        self.iconData =
        {
            {
                categoryName = SI_COMPANION_MENU_CHARACTER_TITLE,
                descriptor = "companionCharacterKeyboard",
                normal = "EsoUI/Art/Companion/Keyboard/companion_character_up.dds",
                pressed = "EsoUI/Art/Companion/Keyboard/companion_character_down.dds",
                disabled = "EsoUI/Art/Companion/Keyboard/companion_character_disabled.dds",
                highlight = "EsoUI/Art/Companion/Keyboard/companion_character_over.dds",
                statusIcon = function()
                    if SHARED_INVENTORY and SHARED_INVENTORY:AreAnyItemsNew(ZO_InventoryUtils_DoesNewItemMatchFilterType, ITEMFILTERTYPE_COMPANION, BAG_BACKPACK) then
                        return ZO_KEYBOARD_NEW_ICON
                    end
                    return nil
                end,
            },
            {
                categoryName = SI_COMPANION_MENU_SKILLS_TITLE,
                descriptor = "companionSkillsKeyboard",
                normal = "EsoUI/Art/Companion/Keyboard/companion_skills_up.dds",
                pressed = "EsoUI/Art/Companion/Keyboard/companion_skills_down.dds",
                disabled = "EsoUI/Art/Companion/Keyboard/companion_skills_disabled.dds",
                highlight = "EsoUI/Art/Companion/Keyboard/companion_skills_over.dds",
                statusIcon = StatusIconForCompanionSkills,
            },
            {
                categoryName = SI_COMPANION_MENU_COLLECTIONS_TITLE,
                descriptor = "companionCollectionBookKeyboard",
                normal = "EsoUI/Art/Companion/Keyboard/companion_collections_up.dds",
                pressed = "EsoUI/Art/Companion/Keyboard/companion_collections_down.dds",
                disabled = "EsoUI/Art/Companion/Keyboard/companion_collections_disabled.dds",
                highlight = "EsoUI/Art/Companion/Keyboard/companion_collections_over.dds",
                statusIcon = function()
                    return StatusIconForSpecializedCategory(COLLECTIBLE_CATEGORY_SPECIALIZATION_NONE)
                end,
            },
        }

        self.tabs:CreateSceneGroup("companionSceneGroup", self.iconData)
    end
end

function ZO_Companion_Keyboard:UpdateSceneGroupButtons()
    if COMPANION_KEYBOARD_FRAGMENT:IsShowing() then
        ZO_MenuBar_UpdateButtons(self.menuBar)
        if not ZO_MenuBar_GetSelectedDescriptor(self.menuBar) then
            ZO_MenuBar_SelectFirstVisibleButton(self.menuBar, true)
        end
    end
end

-----------------------------
-- Global XML Functions
-----------------------------

function ZO_Companion_Keyboard_Initialize(control)
    COMPANION_KEYBOARD = ZO_Companion_Keyboard:New(control)
end