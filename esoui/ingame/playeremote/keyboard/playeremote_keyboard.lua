local TOTALS_EMOTES_IN_ONE_COLUMN = 22
local NUM_OF_COLUMNS = 4

local KEYBOARD_EMOTE_ICON_PATH = "EsoUI/Art/Emotes/emotes_indexIcon_"

local KEYBOARD_EMOTE_ICONS = {
    [EMOTE_CATEGORY_INVALID] = {
        up = "EsoUI/Art/Inventory/inventory_tabIcon_quickslot_up.dds",
        down = "EsoUI/Art/Inventory/inventory_tabIcon_quickslot_down.dds",
        over = "EsoUI/Art/Inventory/inventory_tabIcon_quickslot_over.dds",
    },
    [EMOTE_CATEGORY_CEREMONIAL] = {
        up = KEYBOARD_EMOTE_ICON_PATH .. "ceremonial_up.dds",
        down = KEYBOARD_EMOTE_ICON_PATH .. "ceremonial_down.dds",
        over = KEYBOARD_EMOTE_ICON_PATH .. "ceremonial_over.dds",
    },
    [EMOTE_CATEGORY_CHEERS_AND_JEERS] = {
        up = KEYBOARD_EMOTE_ICON_PATH .. "cheersJeers_up.dds",
        down = KEYBOARD_EMOTE_ICON_PATH .. "cheersJeers_down.dds",
        over = KEYBOARD_EMOTE_ICON_PATH .. "cheersJeers_over.dds",
    },
    [EMOTE_CATEGORY_DEPRECATED] = {
        up = "EsoUI/Art/Inventory/inventory_tabIcon_quickslot_up.dds",
        down = "EsoUI/Art/Inventory/inventory_tabIcon_quickslot_down.dds",
        over = "EsoUI/Art/Inventory/inventory_tabIcon_quickslot_over.dds",
    },
    [EMOTE_CATEGORY_EMOTION] = {
        up = KEYBOARD_EMOTE_ICON_PATH .. "emotion_up.dds",
        down = KEYBOARD_EMOTE_ICON_PATH .. "emotion_down.dds",
        over = KEYBOARD_EMOTE_ICON_PATH .. "emotion_over.dds",
    },
    [EMOTE_CATEGORY_ENTERTAINMENT] = {
        up = KEYBOARD_EMOTE_ICON_PATH .. "entertain_up.dds",
        down = KEYBOARD_EMOTE_ICON_PATH .. "entertain_down.dds",
        over = KEYBOARD_EMOTE_ICON_PATH .. "entertain_over.dds",
    },
    [EMOTE_CATEGORY_FOOD_AND_DRINK] = {
        up = KEYBOARD_EMOTE_ICON_PATH .. "eatDrink_up.dds",
        down = KEYBOARD_EMOTE_ICON_PATH .. "eatDrink_down.dds",
        over = KEYBOARD_EMOTE_ICON_PATH .. "eatDrink_over.dds",
    },
    [EMOTE_CATEGORY_GIVE_DIRECTIONS] = {
        up = KEYBOARD_EMOTE_ICON_PATH .. "directions_up.dds",
        down = KEYBOARD_EMOTE_ICON_PATH .. "directions_down.dds",
        over = KEYBOARD_EMOTE_ICON_PATH .. "directions_over.dds",
    },
    [EMOTE_CATEGORY_PERPETUAL] = {
        up = KEYBOARD_EMOTE_ICON_PATH .. "perpetual_up.dds",
        down = KEYBOARD_EMOTE_ICON_PATH .. "perpetual_down.dds",
        over = KEYBOARD_EMOTE_ICON_PATH .. "perpetual_over.dds",
    },
    [EMOTE_CATEGORY_PHYSICAL] = {
        up = KEYBOARD_EMOTE_ICON_PATH .. "physical_up.dds",
        down = KEYBOARD_EMOTE_ICON_PATH .. "physical_down.dds",
        over = KEYBOARD_EMOTE_ICON_PATH .. "physical_over.dds",
    },
    [EMOTE_CATEGORY_POSES_AND_FIDGETS] = {
        up = KEYBOARD_EMOTE_ICON_PATH .. "fidget_up.dds",
        down = KEYBOARD_EMOTE_ICON_PATH .. "fidget_down.dds",
        over = KEYBOARD_EMOTE_ICON_PATH .. "fidget_over.dds",
    },
    [EMOTE_CATEGORY_PROP] = {
        up = KEYBOARD_EMOTE_ICON_PATH .. "prop_up.dds",
        down = KEYBOARD_EMOTE_ICON_PATH .. "prop_down.dds",
        over = KEYBOARD_EMOTE_ICON_PATH .. "prop_over.dds",
    },
    [EMOTE_CATEGORY_SOCIAL] = {
        up = KEYBOARD_EMOTE_ICON_PATH .. "social_up.dds",
        down = KEYBOARD_EMOTE_ICON_PATH .. "social_down.dds",
        over = KEYBOARD_EMOTE_ICON_PATH .. "social_over.dds",
    },
    [EMOTE_CATEGORY_PERSONALITY_OVERRIDE] = {
        up = KEYBOARD_EMOTE_ICON_PATH .. "personality_up.dds",
        down = KEYBOARD_EMOTE_ICON_PATH .. "personality_down.dds",
        over = KEYBOARD_EMOTE_ICON_PATH .. "personality_over.dds",
    },
}

local PlayerEmote_Keyboard = ZO_Object:Subclass()

function PlayerEmote_Keyboard:New(...)
    local playerEmote = ZO_Object.New(self)
    playerEmote:Initialize(...)
    return playerEmote
end

function PlayerEmote_Keyboard:Initialize(control)
    self.control = control
    control.owner = self

    HELP_EMOTES_SCENE = ZO_Scene:New("helpEmotes", SCENE_MANAGER)
    local keyboardPlayerEmoteFragment = ZO_FadeSceneFragment:New(control)
    keyboardPlayerEmoteFragment:RegisterCallback("StateChange", function(oldState, newState)
                                                                    if newState == SCENE_SHOWING then
                                                                        TriggerTutorial(TUTORIAL_TRIGGER_EMOTES_MENU_OPENED)
                                                                        if self.isDirty then
                                                                            self:UpdateCategories()
                                                                        end
                                                                    end
                                                                end)
    HELP_EMOTES_SCENE:AddFragment(keyboardPlayerEmoteFragment)

    self.control:RegisterForEvent(EVENT_PERSONALITY_CHANGED,
                                    function()
                                        if keyboardPlayerEmoteFragment:IsShowing() then
                                            self:UpdateCategories()
                                        else
                                            self:MarkDirty()
                                        end
                                    end)

    self:InitializeTree()
    self:InitializeEmoteControlPool()
    self:UpdateCategories()
end

function PlayerEmote_Keyboard:InitializeTree()
    self.categoryTree = ZO_Tree:New(GetControl(self.control, "Categories"), 60, -10, 280)

    local function CategorySetup(node, control, data, down)
        control.text:SetModifyTextType(MODIFY_TEXT_TYPE_UPPERCASE)
        control.text:SetText(data.name)

        control.icon:SetTexture(down and data.down or data.up)
        control.iconHighlight:SetTexture(data.over)

        ZO_IconHeader_Setup(control, down)
    end

    local function CategorySelected(control, data, selected, reselectingDuringRebuild)
        if selected then
            self:UpdateEmotes(data.emoteCategory)
        end
        CategorySetup(nil, control, data, selected)
    end

    self.categoryTree:AddTemplate("ZO_IconChildlessHeader", CategorySetup, CategorySelected, nil)
    self.categoryTree:SetExclusive(true)
end

function PlayerEmote_Keyboard:InitializeEmoteControlPool()
    local function EmoteTextControlFactory(control)
        if not self.firstEmoteInColumn then
            self.firstEmoteInColumn = control
            self.totalEmotesInCurrentColumn = 1
            control:SetAnchor(TOPLEFT, self.control:GetNamedChild("EmoteContainer"), TOPLEFT)
        else
            if self.totalEmotesInCurrentColumn > TOTALS_EMOTES_IN_ONE_COLUMN then
                self.totalEmotesInCurrentColumn = 1
                control:SetAnchor(TOPLEFT, self.firstEmoteInColumn, TOPRIGHT)
                self.firstEmoteInColumn = control
            else
                self.totalEmotesInCurrentColumn = self.totalEmotesInCurrentColumn + 1
                control:SetAnchor(TOPLEFT, self.lastEmote, BOTTOMLEFT, 0, 2)
            end
        end

        self.lastEmote = control
    end

    local function EmoteTextControlReset(control)
        control:SetText("")
    end

    self.emoteControlPool = ZO_ControlPool:New("ZO_PlayerEmote_Keyboard_EmoteText", self.control)
    self.emoteControlPool:SetCustomFactoryBehavior(EmoteTextControlFactory)
    self.emoteControlPool:SetCustomResetBehavior(EmoteTextControlReset)
end

function PlayerEmote_Keyboard:UpdateCategories()
    self.categoryTree:Reset()

    local categories = PLAYER_EMOTE_MANAGER:GetEmoteCategories()

    local function GetEmoteIconForCategory(category)
        local icons = KEYBOARD_EMOTE_ICONS[category] or KEYBOARD_EMOTE_ICONS[EMOTE_CATEGORY_INVALID]
        return icons.up, icons.down, icons.over
    end

    for _, category in ipairs(categories) do
        if category ~= EMOTE_CATEGORY_INVALID then
            local upIcon, downIcon, overIcon = GetEmoteIconForCategory(category)
            local data = {
                name = GetString("SI_EMOTECATEGORY", category),
                up = upIcon,
                down = downIcon,
                over = overIcon,
            }
            data.emoteCategory = category
            self.categoryTree:AddNode("ZO_IconChildlessHeader", data, nil, SOUNDS.HELP_BLADE_SELECTED)
        end
    end

    self.categoryTree:Commit()

    self.isDirty = false
end

function PlayerEmote_Keyboard:MarkDirty()
    self.isDirty = true
end

function PlayerEmote_Keyboard:UpdateEmotes(category)
    local emoteList = PLAYER_EMOTE_MANAGER:GetEmoteListForType(category)

    self.emoteControlPool:ReleaseAllObjects()

    for i, emote in ipairs(emoteList) do
        if i <= NUM_OF_COLUMNS * TOTALS_EMOTES_IN_ONE_COLUMN then
            local emoteInfo = PLAYER_EMOTE_MANAGER:GetEmoteItemInfo(emote)

            local emoteControl = self.emoteControlPool:AcquireObject(i)

            if emoteInfo.isOverriddenByPersonality then
                emoteControl:SetText(ZO_PERSONALITY_EMOTES_COLOR:Colorize(emoteInfo.emoteSlashName))
            else
                emoteControl:SetText(emoteInfo.emoteSlashName)
            end
        else
            break
        end
    end
end

-- Global XML --

function ZO_PlayerEmote_Keyboard_Initialize(control)
    KEYBOARD_PLAYER_EMOTE = PlayerEmote_Keyboard:New(control)
end