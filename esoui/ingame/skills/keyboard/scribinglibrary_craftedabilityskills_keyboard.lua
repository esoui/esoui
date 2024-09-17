ZO_ScribingLibrary_CraftedAbilitySkills_Keyboard = ZO_DeferredInitializingObject:Subclass()

local CRAFTED_ABILITY_SKILL_DATA_TYPE = 1
local CRAFTED_ABILITY_SKILL_LABEL_TYPE = 2

function ZO_ScribingLibrary_CraftedAbilitySkills_Keyboard:Initialize(control)
    control.owner = self
    self.control = control
    self.craftedAbilitySkillsListControl = control:GetNamedChild("List")

    SCRIBING_LIBRARY_CRAFTED_ABILITY_SKILLS_FRAGMENT = ZO_FadeSceneFragment:New(control)
    ZO_DeferredInitializingObject.Initialize(self, SCRIBING_LIBRARY_CRAFTED_ABILITY_SKILLS_FRAGMENT)
end

function ZO_ScribingLibrary_CraftedAbilitySkills_Keyboard:OnDeferredInitialize()
    ZO_ScrollList_Initialize(self.craftedAbilitySkillsListControl)
    ZO_ScrollList_AddDataType(self.craftedAbilitySkillsListControl, CRAFTED_ABILITY_SKILL_DATA_TYPE, "ZO_ScribingLibrary_CraftedAbilitySkills_Entry", 70, function(entryControl, data) self:SetupAbilityEntry(entryControl, data) end)
    ZO_ScrollList_AddDataType(self.craftedAbilitySkillsListControl, CRAFTED_ABILITY_SKILL_LABEL_TYPE, "ZO_ScribingLibrary_CraftedAbilitySkills_Label", 30, function(entryControl, data) self:SetupHeadingLabel(entryControl, data) end)
end

function ZO_ScribingLibrary_CraftedAbilitySkills_Keyboard:OnShowing()
    SCENE_MANAGER:AddFragment(MEDIUM_LEFT_PANEL_BG_FRAGMENT)

    self:RefreshList()

    TriggerTutorial(TUTORIAL_TRIGGER_SKILLS_SCRIBING_OPENED)
end

function ZO_ScribingLibrary_CraftedAbilitySkills_Keyboard:OnHidden()
    SCENE_MANAGER:RemoveFragment(MEDIUM_LEFT_PANEL_BG_FRAGMENT)
end

function ZO_ScribingLibrary_CraftedAbilitySkills_Keyboard:SetupHeadingLabel(control, data)
    local textControl = control:GetNamedChild("Text")
    textControl:SetText(data.text)
end

function ZO_ScribingLibrary_CraftedAbilitySkills_Keyboard:SetupAbilityEntry(control, skillData)
    local progressionData = skillData and skillData:GetCurrentProgressionData()
    if progressionData then
        control.slotIcon:SetTexture(progressionData:GetIcon())
        control.nameLabel:SetText(progressionData:GetFormattedName())
        control.nameLabel:SetColor(PURCHASED_COLOR:UnpackRGBA())
    end
end

function ZO_ScribingLibrary_CraftedAbilitySkills_Keyboard:RefreshList()
    local scrollData = ZO_ScrollList_GetDataList(self.craftedAbilitySkillsListControl)
    ZO_ScrollList_Clear(self.craftedAbilitySkillsListControl)

    local headerText = nil
    local scribedCraftedAbilitySkills = SCRIBING_DATA_MANAGER:GetScribedCraftedAbilitySkillsData()
    if #scribedCraftedAbilitySkills > 0 then
        for i, skillData in ipairs(scribedCraftedAbilitySkills) do
            if skillData:IsUltimate() then
                local ultimateText = GetString(SI_SKILLS_ULTIMATE_ABILITIES)
                if not headerText or headerText ~= ultimateText then
                    headerText = ultimateText
                    table.insert(scrollData, ZO_ScrollList_CreateDataEntry(CRAFTED_ABILITY_SKILL_LABEL_TYPE, { text = headerText }))
                end
            else
                local activeText = GetString(SI_SKILLS_ACTIVE_ABILITIES)
                if not headerText or headerText ~= activeText then
                    headerText = GetString(SI_SKILLS_ACTIVE_ABILITIES)
                    table.insert(scrollData, ZO_ScrollList_CreateDataEntry(CRAFTED_ABILITY_SKILL_LABEL_TYPE, { text = headerText }))
                end
            end
            table.insert(scrollData, ZO_ScrollList_CreateDataEntry(CRAFTED_ABILITY_SKILL_DATA_TYPE, skillData))
        end
    end

    ZO_ScrollList_Commit(self.craftedAbilitySkillsListControl)
end

-- Global XML Functions --

function ZO_ScribingLibrary_CraftedAbilitySkills_Keyboard.OnMouseEnter(control)
    local skillData = control.dataEntry and control.dataEntry.data
    if skillData then
        local progressionData = skillData and skillData:GetCurrentProgressionData()
        if progressionData then
            InitializeTooltip(SkillTooltip, control, TOPLEFT, 5, -5, TOPRIGHT)
            progressionData:SetKeyboardTooltip(SkillTooltip)
        end
    end
end

function ZO_ScribingLibrary_CraftedAbilitySkills_Keyboard.OnMouseUp(control, button, upInside)
    if upInside then
        local skillData = control.dataEntry and control.dataEntry.data
        if button == MOUSE_BUTTON_INDEX_LEFT then
            if skillData then
                MAIN_MENU_KEYBOARD:ShowScene("skills")
                SKILLS_WINDOW:BrowseToSkill(skillData)
            end
        else
            local function OnLinkInChat()
                local link = skillData:GetCurrentProgressionLink()
                if internalassert(link, "Unable to generate link for skill.") then
                    ZO_LinkHandler_InsertLink(link)
                end
            end
            ClearMenu()
            AddMenuItem(GetString(SI_ITEM_ACTION_LINK_TO_CHAT), OnLinkInChat)
            ShowMenu(control)
        end
    end
end

function ZO_ScribingLibrary_CraftedAbilitySkills_Keyboard.OnControlInitialized(control)
    SCRIBING_LIBRARY_CRAFTED_ABILITY_SKILLS_KEYBOARD = ZO_ScribingLibrary_CraftedAbilitySkills_Keyboard:New(control)
end