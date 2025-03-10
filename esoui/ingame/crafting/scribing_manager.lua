ZO_Scribing_Manager = ZO_InitializingCallbackObject:Subclass()

function ZO_Scribing_Manager:Initialize()
   self:RegisterEvents()
   self:SetupOpenSkillsCustomConfirmDialog()

    -- Shared search for crafted abilities
    local craftedAbilitiesFilterTargetDescriptor =
    {
        [BACKGROUND_LIST_FILTER_TARGET_CRAFTED_ABILITY_ID] =
        {
            searchFilterList =
            {
                BACKGROUND_LIST_FILTER_TYPE_NAME,
            },
            primaryKeys = function()
                local craftedAbilityIdList = {}
                local craftedAbilityTable = SCRIBING_DATA_MANAGER:GetSortedBySkillTypeCraftedAbilityData()
                for i, craftedAbilityData in ipairs(craftedAbilityTable) do
                    table.insert(craftedAbilityIdList, craftedAbilityData:GetId())
                end
                return craftedAbilityIdList
            end,
        },
    }
    TEXT_SEARCH_MANAGER:SetupContextTextSearch("craftedAbilityTextSearch", craftedAbilitiesFilterTargetDescriptor)

    local craftedAbilityScriptsFilterTargetDescriptor =
    {
        [BACKGROUND_LIST_FILTER_TARGET_CRAFTED_ABILITY_SCRIPT_ID] =
        {
            searchFilterList =
            {
                BACKGROUND_LIST_FILTER_TYPE_NAME,
                BACKGROUND_LIST_FILTER_TYPE_DESCRIPTION,
            },
            primaryKeys = function()
                local scriptSets = {}
                local scriptSearchCraftedAbilityId = SCRIBING_MANAGER:GetScriptSearchCraftedAbility()
                local scriptIds = SCRIBING_DATA_MANAGER:GetAllCraftedAbilityScriptIds()
                for i, scriptId in ipairs(scriptIds) do
                    table.insert(scriptSets, { scriptId, scriptSearchCraftedAbilityId })
                end
                return scriptSets
            end,
        },
    }
    TEXT_SEARCH_MANAGER:SetupContextTextSearch("craftedAbilityScriptsTextSearch", craftedAbilityScriptsFilterTargetDescriptor)

    local scribedCraftedAbilitiesFilterTargetDescriptor =
    {
        [BACKGROUND_LIST_FILTER_TARGET_CRAFTED_ABILITY_COMBINATION] =
        {
            searchFilterList =
            {
                BACKGROUND_LIST_FILTER_TYPE_NAME,
            },
            primaryKeys = function()
                return self:GetRecentCraftedAbilities()
            end,
        },
    }
    TEXT_SEARCH_MANAGER:SetupContextTextSearch("scribedCraftedAbilityTextSearch", scribedCraftedAbilitiesFilterTargetDescriptor)
end

function ZO_Scribing_Manager:RegisterEvents()
    local function OnCraftingStationInteract(eventCode, craftingType, isCraftingSameAsPrevious)
        if craftingType == CRAFTING_TYPE_SCRIBING then
            SYSTEMS:ShowScene("scribing")
        end
    end
    EVENT_MANAGER:RegisterForEvent("ZO_Scribing_Manager", EVENT_CRAFTING_STATION_INTERACT, OnCraftingStationInteract)

    local function OnEndCraftingStationInteract(eventCode, craftingType)
        if craftingType == CRAFTING_TYPE_SCRIBING then
            SYSTEMS:HideScene("scribing")
        end
    end
    EVENT_MANAGER:RegisterForEvent("ZO_Scribing_Manager", EVENT_END_CRAFTING_STATION_INTERACT, OnEndCraftingStationInteract)

    local function OnAddOnLoaded(event, name)
        if name == "ZO_Ingame" then
            local defaults =
            {
                recentCraftedAbilities = {}
            }
            self.savedVars = ZO_SavedVars:New("ZO_Ingame_SavedVariables", 1, "CraftedAbilities", defaults)
            EVENT_MANAGER:UnregisterForEvent("ZO_Scribing_Manager", EVENT_ADD_ON_LOADED)
        end
    end
    EVENT_MANAGER:RegisterForEvent("ZO_Scribing_Manager", EVENT_ADD_ON_LOADED, OnAddOnLoaded)
end

function ZO_Scribing_Manager:SetScriptSearchCraftedAbility(craftedAbilityId)
    self.scriptSearchCraftedAbilityId = craftedAbilityId
end

function ZO_Scribing_Manager:GetScriptSearchCraftedAbility()
    return self.scriptSearchCraftedAbilityId
end

function ZO_Scribing_Manager:GetRecentCraftedAbilities()
    return self.savedVars.recentCraftedAbilities
end

function ZO_Scribing_Manager:HasAnyRecentCraftedAbilities()
    return #self:GetRecentCraftedAbilities() > 0
end

function ZO_Scribing_Manager:HasAnyUnscribedRecentCraftedAbilities()
    local recentCraftedAbilities = self:GetRecentCraftedAbilities()
    for i, recentCraftedAbility in ipairs(recentCraftedAbilities) do
        local craftedAbilityId = recentCraftedAbility[ZO_RECENT_SCRIBE_SAVED_VAR_INDEX.CRAFTED_ABILITY]
        local craftedAbilityData = SCRIBING_DATA_MANAGER:GetCraftedAbilityData(craftedAbilityId)
        if craftedAbilityData then
            local primaryScriptId = recentCraftedAbility[ZO_RECENT_SCRIBE_SAVED_VAR_INDEX.PRIMARY_SCRIPT]
            local secondaryScriptId = recentCraftedAbility[ZO_RECENT_SCRIBE_SAVED_VAR_INDEX.SECONDARY_SCRIPT]
            local tertiaryScriptId = recentCraftedAbility[ZO_RECENT_SCRIBE_SAVED_VAR_INDEX.TERTIARY_SCRIPT]
            if not craftedAbilityData:AreScriptIdsActive(primaryScriptId, secondaryScriptId, tertiaryScriptId) then
                return true
            end
        end
    end

    return false
end

function ZO_Scribing_Manager:IsRecentCraftedAbilityIndexEqual(index, craftedAbilityId, primaryScriptId, secondaryScriptId, tertiaryScriptId)
    local recentCraftedAbilities = self:GetRecentCraftedAbilities()
    local recentCraftedAbility = recentCraftedAbilities[index]
    return recentCraftedAbility[ZO_RECENT_SCRIBE_SAVED_VAR_INDEX.CRAFTED_ABILITY] == craftedAbilityId
        and recentCraftedAbility[ZO_RECENT_SCRIBE_SAVED_VAR_INDEX.PRIMARY_SCRIPT] == primaryScriptId
        and recentCraftedAbility[ZO_RECENT_SCRIBE_SAVED_VAR_INDEX.SECONDARY_SCRIPT] == secondaryScriptId
        and recentCraftedAbility[ZO_RECENT_SCRIBE_SAVED_VAR_INDEX.TERTIARY_SCRIPT] == tertiaryScriptId
end

function ZO_Scribing_Manager:GetAvailableScriptsForCraftedAbilityAndScribingSlot(craftedAbilityId, scribingSlot)
    local availableScripts = {}
    local numScriptsInCurrentSlot = GetNumScriptsInSlotForCraftedAbility(craftedAbilityId, scribingSlot)
    for i = 1, numScriptsInCurrentSlot do
        table.insert(availableScripts, GetScriptIdAtSlotIndexForCraftedAbility(craftedAbilityId, scribingSlot, i))
    end

    return availableScripts
end

function ZO_Scribing_Manager:GetUnlockedScriptsForCraftedAbilityAndScribingSlot(craftedAbilityId, scribingSlot)
    local availableScripts = {}
    local numScriptsInCurrentSlot = GetNumScriptsInSlotForCraftedAbility(craftedAbilityId, scribingSlot)
    for i = 1, numScriptsInCurrentSlot do
        local scriptId = GetScriptIdAtSlotIndexForCraftedAbility(craftedAbilityId, scribingSlot, i)
        if IsCraftedAbilityScriptUnlocked(scriptId) then
            table.insert(availableScripts, scriptId)
        end
    end

    return availableScripts
end

do
    local g_inkItemLink
    local function GetInkItemLink()
        if g_inkItemLink == nil then
            g_inkItemLink = GetScribingInkItemLink()
        end

        return g_inkItemLink
    end

    function ZO_Scribing_Manager.GetScribingInkName()
        local itemLink = GetInkItemLink()
        return GetItemLinkName(itemLink)
    end

    function ZO_Scribing_Manager.GetFormattedScribingInkName()
        return zo_strformat(SI_TOOLTIP_ITEM_NAME, ZO_Scribing_Manager.GetScribingInkName())
    end

    function ZO_Scribing_Manager.GetScribingInkIcon()
        local itemLink = GetInkItemLink()
        return GetItemLinkIcon(itemLink)
    end

    function ZO_Scribing_Manager.GetScribingInkAmount()
        local itemLink = GetInkItemLink()
        return GetItemLinkInventoryCount(itemLink, INVENTORY_COUNT_BAG_OPTION_BACKPACK_AND_BANK_AND_CRAFT_BAG)
    end
end

function ZO_Scribing_Manager.GetFormattedNoSpaceAlignedRightScribingInkAmount()
    local inkIcon = ZO_Scribing_Manager.GetScribingInkIcon()
    local inkAmount = ZO_Scribing_Manager.GetScribingInkAmount()
    return zo_iconTextFormatNoSpaceAlignedRight(inkIcon, "100%", "100%", inkAmount)
end

function ZO_Scribing_Manager:SetupOpenSkillsCustomConfirmDialog()
    local customControl = ZO_InitialScribeOpenSkillsConfirmationDialog

    ZO_Dialogs_RegisterCustomDialog("SCRIBING_OPEN_SKILLS_CONFIRM",
    {
        gamepadInfo =
        {
            dialogType = GAMEPAD_DIALOGS.STATIC_LIST,
        },
        customControl = customControl,
        canQueue = true,
        title =
        {
            text = function(dialog)
                local skillData = dialog.data.skillsData
                return zo_strformat(SI_SCRIBING_OPEN_SKILL_DIALOG_TITLE, skillData.skillProgressionData:GetName())
            end,
        },
        mainText =
        {
            text = SI_SCRIBING_OPEN_SKILL_DIALOG_DESCRIPTION,
        },
        setup = function(dialog, data)
            if IsInGamepadPreferredMode() then
                dialog:setupFunc()
            else
                local skillsData = dialog.data.skillsData
                local iconControl = customControl:GetNamedChild("ScribedSkill")
                iconControl:SetTexture(skillsData.skillProgressionData:GetIcon())
            end
        end,
        itemInfo = function(dialog)
            local skillsData = dialog.data.skillsData
            local iconTable =
            {
                {
                    icon = skillsData.skillProgressionData:GetIcon(),
                    iconSize = 64,
                }
            }
            return iconTable
        end,
        buttons =
        {
            {
                control = customControl:GetNamedChild("Confirm"),
                text = SI_DIALOG_CONFIRM,
                callback = function(dialog)
                    local skillsData = dialog.data.skillsData
                    if skillsData then
                        if IsInGamepadPreferredMode() then
                            MAIN_MENU_GAMEPAD:ShowScene("gamepad_skills_root")
                            GAMEPAD_SKILLS:SelectSkillLineBySkillData(skillsData)
                        else
                            MAIN_MENU_KEYBOARD:ShowScene("skills")
                            SKILLS_WINDOW:BrowseToSkill(skillsData)
                        end
                    end
                end,
            },
            {
                control = customControl:GetNamedChild("Cancel"),
                text = SI_DIALOG_CANCEL,
            }
        }
    })
end

SCRIBING_MANAGER = ZO_Scribing_Manager:New()
