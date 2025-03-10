function ZO_Tooltip:GetRequiredScribingCollectibleText()
    local collectibleData = SCRIBING_DATA_MANAGER:GetScribingPurchasableCollectibleData()
    local collectibleName = GetCollectibleName(collectibleData:GetId())
    if collectibleName ~= "" then
        local formatterStringId
        local collectibleCategory = GetCollectibleCategoryType(collectibleData:GetId())
        if collectibleCategory == COLLECTIBLE_CATEGORY_TYPE_CHAPTER then
            formatterStringId = SI_COLLECTIBLE_REQUIRED_TO_USE_SCRIBING_UPGRADE
        else
            formatterStringId = SI_COLLECTIBLE_REQUIRED_TO_USE_SCRIBING_CROWN_STORE
        end
        return zo_strformat(formatterStringId, collectibleName, GetCollectibleCategoryNameByCollectibleId(collectibleData:GetId()))
    end

    return ""
end

function ZO_Tooltip:LayoutCraftedAbilityLink(link, options)
    local craftedAbilityId, primaryScriptId, secondaryScriptId, tertiaryScriptId = GetCraftedAbilityIdsFromLink(link)
    self:LayoutCraftedAbilityByIds(craftedAbilityId, primaryScriptId, secondaryScriptId, tertiaryScriptId)
end

function ZO_Tooltip:LayoutCraftedAbilityByIds(craftedAbilityId, primaryScriptId, secondaryScriptId, tertiaryScriptId, options)
    local craftedAbilityData = SCRIBING_DATA_MANAGER:GetCraftedAbilityData(craftedAbilityId)
    if craftedAbilityData then
        local primaryScriptData = SCRIBING_DATA_MANAGER:GetCraftedAbilityScriptData(primaryScriptId)
        local secondaryScriptData = SCRIBING_DATA_MANAGER:GetCraftedAbilityScriptData(secondaryScriptId)
        local tertiaryScriptData = SCRIBING_DATA_MANAGER:GetCraftedAbilityScriptData(tertiaryScriptId)
        self:LayoutCraftedAbility(craftedAbilityData, primaryScriptData, secondaryScriptData, tertiaryScriptData, options)
    end
end

function ZO_Tooltip:LayoutCraftedAbility(craftedAbilityData, primaryScriptData, secondaryScriptData, tertiaryScriptData, options)
    craftedAbilityData:SetScriptDataSelectionOverride(primaryScriptData, secondaryScriptData, tertiaryScriptData)

    local representativeAbilityId = craftedAbilityData:GetRepresentativeAbilityId()
    if representativeAbilityId == 0 then
        return
    end

    local headerSection = self:AcquireSection(self:GetStyle("abilityHeaderSection"))
    local headerStyle = self:GetStyle("abilityHeader")
    local descriptionStyle = self:GetStyle("bodyDescription")
    local skillData = craftedAbilityData:GetSkillData()
    local skillLineData = skillData and skillData:GetSkillLineData()
    local skillTypeData = skillLineData and skillLineData:GetSkillTypeData()
    local displayFlags = options and options.displayFlags or SCRIBING_TOOLTIP_DISPLAY_FLAGS_NONE

    -- Things added to the top section stack updward
    if skillLineData and skillTypeData then
        headerSection:AddLine(skillLineData:GetFormattedName(), headerStyle)
        headerSection:AddLine(skillTypeData:GetName(), headerStyle)
        -- Header section will be added later
    end

    local isLocked = not craftedAbilityData:IsUnlocked()
    if isLocked then
        -- Mutually exclusive with isAlreadyScribed
        headerSection:AddLine(GetString(SI_CRAFTED_ABILITY_UNOWNED_TOOLTIP_HEADER), headerStyle)
    end
    
    local selectedScripts = 
    {
        [SCRIBING_SLOT_PRIMARY] = primaryScriptData,
        [SCRIBING_SLOT_SECONDARY] = secondaryScriptData,
        [SCRIBING_SLOT_TERTIARY] = tertiaryScriptData,
    }
    local selectedScriptIds = {}
    for slot = SCRIBING_SLOT_ITERATION_BEGIN, SCRIBING_SLOT_ITERATION_END do
        local scriptData = selectedScripts[slot]
        table.insert(selectedScriptIds, scriptData and scriptData:GetId() or 0)
    end

    local isScribableCombination = craftedAbilityData:IsScribableScriptDataCombination(primaryScriptData, secondaryScriptData, tertiaryScriptData)
    if isScribableCombination then
        local activeScriptIds = { craftedAbilityData:GetActiveScriptIds() }
        local isAlreadyScribed = ZO_AreNumericallyIndexedTablesEqual(selectedScriptIds, activeScriptIds)
        if isAlreadyScribed then
            -- Mutually exclusive with isLocked
            if craftedAbilityData:IsSlottedOnHotBar() then
                headerSection:AddLine(GetString(SI_CRAFTED_ABILITY_SLOTTED_TOOLTIP_HEADER), headerStyle)
            else
                headerSection:AddLine(GetString(SI_CRAFTED_ABILITY_CONFIGURED_TOOLTIP_HEADER), headerStyle)
            end
        end
        -- Finish adding the header section before moving on to the actual ability
        self:AddSection(headerSection)

        local SIMPLE_ABILITY_OPTIONS = { omitHeader = true }
        self:LayoutSimpleAbility(representativeAbilityId, SIMPLE_ABILITY_OPTIONS)

        -- Add errors after the actual ability
        if ZO_FlagHelpers.MaskHasFlag(displayFlags, SCRIBING_TOOLTIP_DISPLAY_FLAGS_SHOW_ERRORS) then
            local errorsSection = nil
            local lockedScriptSlotNames = {}
            for slot = SCRIBING_SLOT_ITERATION_BEGIN, SCRIBING_SLOT_ITERATION_END do
                -- Shouldn't be possible for scriptData to be nil here
                local scriptData = selectedScripts[slot]
                if not scriptData:IsUnlocked() then
                    table.insert(lockedScriptSlotNames, GetString("SI_SCRIBINGSLOT_SHORT", scriptData:GetScribingSlot()))
                end
            end
            if #lockedScriptSlotNames > 0 then
                errorsSection = self:AcquireSection(self:GetStyle("bodySection"))
                local lockScriptNamesText = ZO_GenerateCommaSeparatedListWithoutAnd(lockedScriptSlotNames)
                local lockedScriptErrorText = zo_strformat(SI_CRAFTED_ABILITY_TOOLTIP_FAILED_REQUIREMENT_UNOWNED_SCRIPTS, lockScriptNamesText)
                errorsSection:AddLine(lockedScriptErrorText, descriptionStyle, self:GetStyle("failed"))
            end
            if isAlreadyScribed then
                errorsSection = errorsSection or self:AcquireSection(self:GetStyle("bodySection"))
                errorsSection:AddLine(GetString(SI_CRAFTED_ABILITY_TOOLTIP_FAILED_REQUIREMENT_ALREADY_SCRIBED), descriptionStyle, self:GetStyle("failed"))
            end
            if errorsSection then
                self:AddSection(errorsSection)
            end
        end
        return
    else
        -- Finish adding the header section before moving on to the body
        self:AddSection(headerSection)
    end

    self:AddLine(craftedAbilityData:GetFormattedName(), self:GetStyle("title"))

    self:AddAbilityStats(representativeAbilityId)

    local descriptionSection = self:AcquireSection(self:GetStyle("bodySection"))

    local description = craftedAbilityData:GetDescription()
    descriptionSection:AddLine(description, descriptionStyle)
    self:AddSection(descriptionSection)

    if isLocked and ZO_FlagHelpers.MaskHasFlag(displayFlags, SCRIBING_TOOLTIP_DISPLAY_FLAGS_SHOW_ACQUIRE_HINT) then
        local acquireHint = craftedAbilityData:GetAcquireHint()
        if acquireHint ~= "" then
            local acquireHintSection = self:AcquireSection(self:GetStyle("bodySection"))
            acquireHintSection:AddLine(acquireHint, descriptionStyle)
            self:AddSection(acquireHintSection)
        end
    end

    if ZO_FlagHelpers.MaskHasFlag(displayFlags, SCRIBING_TOOLTIP_DISPLAY_FLAGS_SHOW_SELECTED_SCRIPTS) then
        local craftedAbilityId = craftedAbilityData:GetId()
        local primaryScriptId = primaryScriptData and primaryScriptData:GetId() or nil
        local secondaryScriptId = secondaryScriptData and secondaryScriptData:GetId() or nil
        local tertiaryScriptId = tertiaryScriptData and tertiaryScriptData:GetId() or nil

        for slot = SCRIBING_SLOT_ITERATION_BEGIN, SCRIBING_SLOT_ITERATION_END do
            local scriptData = selectedScripts[slot]
            local compatible = scriptData and scriptData:IsCompatibleWithSelections(craftedAbilityId, primaryScriptId, secondaryScriptId, tertiaryScriptId)
            local displayFlags = compatible and displayFlags or ZO_FlagHelpers.SetMaskFlag(displayFlags, SCRIBING_TOOLTIP_DISPLAY_FLAGS_SCRIPT_COMPATIBILITY_ERROR)
            local scriptOptions = { displayFlags = displayFlags }
            self:AppendCraftedAbilityScriptDescription(craftedAbilityData, scriptData, scriptOptions, descriptionStyle)
        end
    end
end

do
    local NO_SCRIPT_DENOTATION = "-"

    function ZO_Tooltip:AppendCraftedAbilityScriptDescription(craftedAbilityData, scriptData, options, ...)
        local descriptionSection = self:AcquireSection(self:GetStyle("bodySection"))
        if scriptData then
            local displayFlags = options and options.displayFlags
            local errorStyle = nil
            if displayFlags then
                if ZO_FlagHelpers.MaskHasFlag(displayFlags, SCRIBING_TOOLTIP_DISPLAY_FLAGS_SHOW_ERRORS) then
                    if not scriptData:IsUnlocked() then
                        displayFlags = ZO_FlagHelpers.SetMaskFlag(displayFlags, SCRIBING_TOOLTIP_DISPLAY_FLAGS_SCRIPT_LOCKED_ERROR)
                    end
                end

                if ZO_FlagHelpers.MaskHasFlag(displayFlags, SCRIBING_TOOLTIP_DISPLAY_FLAGS_SCRIPT_COMPATIBILITY_ERROR) then
                    errorStyle = self:GetStyle("failed")
                elseif ZO_FlagHelpers.MaskHasFlag(displayFlags, SCRIBING_TOOLTIP_DISPLAY_FLAGS_SCRIPT_LOCKED_ERROR) then
                    errorStyle = self:GetStyle("disabled")
                end
            end

            local scriptDescription = scriptData:GetDescription(craftedAbilityData)
            descriptionSection:AddLine(scriptDescription, ..., errorStyle)
        else
            descriptionSection:AddLine(NO_SCRIPT_DENOTATION, ...)
        end
        self:AddSection(descriptionSection)
    end
end

function ZO_Tooltip:LayoutCraftedAbilityScriptByIds(craftedAbilityId, scriptId, primaryScriptId, secondaryScriptId, tertiaryScriptId, options)
    local craftedAbilityData = SCRIBING_DATA_MANAGER:GetCraftedAbilityData(craftedAbilityId)
    if craftedAbilityData then
        local scriptData = SCRIBING_DATA_MANAGER:GetCraftedAbilityScriptData(scriptId)
        local primaryScriptData = SCRIBING_DATA_MANAGER:GetCraftedAbilityScriptData(primaryScriptId)
        local secondaryScriptData = SCRIBING_DATA_MANAGER:GetCraftedAbilityScriptData(secondaryScriptId)
        local tertiaryScriptData = SCRIBING_DATA_MANAGER:GetCraftedAbilityScriptData(tertiaryScriptId)
        self:LayoutCraftedAbilityScript(craftedAbilityData, scriptData, primaryScriptData, secondaryScriptData, tertiaryScriptData, options)
    end
end

function ZO_Tooltip:LayoutCraftedAbilityScript(craftedAbilityData, scriptData, primaryScriptData, secondaryScriptData, tertiaryScriptData, options)
    local slot = scriptData:GetScribingSlot()
    if slot == SCRIBING_SLOT_PRIMARY then
        primaryScriptData = scriptData
    elseif slot == SCRIBING_SLOT_SECONDARY then
        secondaryScriptData = scriptData
    else
        tertiaryScriptData = scriptData
    end
    craftedAbilityData:SetScriptDataSelectionOverride(primaryScriptData, secondaryScriptData, tertiaryScriptData)

    local displayFlags = options and options.displayFlags or SCRIBING_TOOLTIP_DISPLAY_FLAGS_NONE
    local headerSection = self:AcquireSection(self:GetStyle("abilityHeaderSection"))
    local headerStyle = self:GetStyle("abilityHeader")
    headerSection:AddLine(GetString("SI_SCRIBINGSLOT", scriptData:GetScribingSlot()), headerStyle)
    if craftedAbilityData:IsScriptActive(scriptData) then
        headerSection:AddLine(GetString(SI_CRAFTED_ABILITY_SCRIPT_ACTIVE_TOOLTIP_HEADER), headerStyle)
    end
    self:AddSection(headerSection)

    local name = scriptData:GetFormattedName()
    self:AddLine(name, self:GetStyle("title"))

    local descriptionStyle = self:GetStyle("bodyDescription")
    local NO_OPTIONS = nil
    self:AppendCraftedAbilityScriptDescription(craftedAbilityData, scriptData, NO_OPTIONS, descriptionStyle)

    local isLocked = not scriptData:IsUnlocked()
    if isLocked then
        if ZO_FlagHelpers.MaskHasFlag(displayFlags, SCRIBING_TOOLTIP_DISPLAY_FLAGS_SHOW_ACQUIRE_HINT) then
            local acquireHint = scriptData:GetAcquireHint()
            if acquireHint ~= "" then
                local acquireHintSection = self:AcquireSection(self:GetStyle("bodySection"))
                acquireHintSection:AddLine(acquireHint, descriptionStyle)
                self:AddSection(acquireHintSection)
            end
        end

        if ZO_FlagHelpers.MaskHasFlag(displayFlags, SCRIBING_TOOLTIP_DISPLAY_FLAGS_SHOW_ERRORS) then
            displayFlags = ZO_FlagHelpers.SetMaskFlag(displayFlags, SCRIBING_TOOLTIP_DISPLAY_FLAGS_SCRIPT_LOCKED_ERROR)
        end
    end

    local errorStyle = self:GetStyle("failed")
    for displayFlag in ZO_FlagHelpers.MaskHasFlagsIterator(displayFlags) do
        local text = GetString("SI_SCRIBINGTOOLTIPDISPLAYFLAGS", displayFlag)
        if text ~= "" then
            local errorSection = self:AcquireSection(self:GetStyle("bodySection"))
            errorSection:AddLine(text, descriptionStyle, errorStyle)
            self:AddSection(errorSection)
        end
    end
end