local GAMEPAD_CRAFTING_RESULTS_TEMPLATE = "ZO_GamepadCraftingResultsTemplate"

ZO_CraftingResults_Gamepad = ZO_CraftingResults_Base:Subclass()

function ZO_CraftingResults_Gamepad:New(...)
    return ZO_CraftingResults_Base.New(self, ...)
end

function ZO_CraftingResults_Gamepad:Initialize(control)
    local SHOW_IN_GAMEPAD_PREFERRED_MODE = true
    ZO_CraftingResults_Base.Initialize(self, control, SHOW_IN_GAMEPAD_PREFERRED_MODE)
end

function ZO_CraftingResults_Gamepad:ModifyAnchor(newAnchor)
    ZO_CraftingResults_Base.ModifyAnchor(self, ZO_CraftingResultsTopLevel_Gamepad, newAnchor)
end

function ZO_CraftingResults_Gamepad:RestoreAnchor()
    ZO_CraftingResults_Base.RestoreAnchor(self, ZO_CraftingResultsTopLevel_Gamepad)
end

do
    local function SetupHeader(control, data)
        control:SetText(data.text)
    end

    local function Setup(control, data)
        local label = control:GetNamedChild("Label")
        if label then
            label:SetText(data.text)

            if data.color then
                label:SetColor(data.color:UnpackRGBA())
            else
                label:SetColor(ZO_SELECTED_TEXT:UnpackRGBA())
            end
        end

        local icon = control:GetNamedChild("Icon")
        if icon then
            if data.icon then
                icon:SetTexture(data.icon)
            end
            icon:SetHidden(not data.icon)
        end

        local stackCount = control:GetNamedChild("StackCount")
        if stackCount then
            if data.stack then
                stackCount:SetText(data.stack)
                stackCount:SetHidden(data.stack == 0)
            else
                stackCount:SetHidden(true)
            end
        end
    end

    local function NarrationFunction(data)
        local narration = SCREEN_NARRATION_MANAGER:CreateNarratableObject(data.text)
        if data.stack and data.stack > 0 then
            narration:AddNarrationText(data.stack)
        end
        return narration
    end

    function ZO_CraftingResults_Gamepad:AreCraftingResultLinesEqual(oldLines, newLines)
        -- all old lines must be checked against all new lines, as they can show up in any order
        for _, oldLine in ipairs(oldLines) do
            for _, newLine in ipairs(newLines) do
                if self:AreCraftingResultsEqual(oldLine, newLine) then
                    return true
                end
            end
        end

        return false
    end

    local function AreHeadersEqual(oldHeader, newHeader)
        return (oldHeader.text == newHeader.text)
    end

    function ZO_CraftingResults_Gamepad:EqualitySetup(fadingControlBuffer, oldEntry, newEntry)
        -- unfortunately all we know is that something matched, but we don't know which did...find the matches again
        for _, oldLine in ipairs(oldEntry.lines) do
            for _, newLine in ipairs(newEntry.lines) do
                if self:AreCraftingResultsEqual(oldLine, newLine) then
                    -- match!  play animation, add to stack count / set stack text to new amount
                    local lineControl = ZO_FadingControlBuffer_GetLineControl(oldLine)
                    ZO_CraftingResults_Base_PlayPulse(lineControl)
                    oldLine.stack = oldLine.stack + newLine.stack
                    lineControl:GetNamedChild("StackCount"):SetText(oldLine.stack)

                    break
                end
            end
        end
    end

    function ZO_CraftingResults_Gamepad:InitializeResultBuffer()
        local templateData =
        {
            setup = Setup,
            equalityCheck = function(...) return self:AreCraftingResultLinesEqual(...) end,
            equalitySetup = function(...) self:EqualitySetup(...) end,
            headerTemplateName = "ZO_GamepadCraftingResultsHeaderTemplate",
            headerSetup = SetupHeader,
            headerEqualityCheck = AreHeadersEqual,
            narrationText = NarrationFunction,
            displayOlderLinesFirst = true,
        }
        ZO_CraftingAlertAddTemplate_Gamepad(GAMEPAD_CRAFTING_RESULTS_TEMPLATE, templateData)
    end
end

function ZO_CraftingResults_Gamepad:IsActive()
    return IsInGamepadPreferredMode()
end

do
    local IS_DECONSTRUCTION_SCENE_NAME =
    {
        ["gamepad_enchanting_extraction"] = true,
        ["gamepad_smithing_deconstruct"] = true,
        ["gamepad_smithing_refine"] = true,
    }
    function ZO_CraftingResults_Gamepad:DisplayCraftingResult(resultData)
        local currentSceneName = SCENE_MANAGER:GetCurrentSceneName()
        local headerTextId
        if ZO_RETRAIT_STATION_MANAGER:IsRetraitFragmentShowing() then
            headerTextId = SI_GAMEPAD_RETRAIT_COMPLETED_RESULT_HEADER
        elseif currentSceneName and IS_DECONSTRUCTION_SCENE_NAME[currentSceneName] then
            headerTextId = SI_GAMEPAD_CRAFTING_DECONSTRUCTED_ITEM
        else
            headerTextId = SI_GAMEPAD_CRAFTING_COMPLETED_ITEM
        end

        local resultEntryData = ZO_EntryData:New(resultData)
        resultEntryData.text = zo_strformat(SI_TOOLTIP_ITEM_NAME, resultData.name)

        local displayData =
        {
            header =
            {
                text = GetString(headerTextId)
            },
            lines =
            {
                resultEntryData
            }
        }
        local DEFAULT_SOUND_ID = nil
        ZO_CraftingAlertNoSuppressionTemplated_Gamepad(UI_ALERT_CATEGORY_ALERT, DEFAULT_SOUND_ID, displayData, GAMEPAD_CRAFTING_RESULTS_TEMPLATE)
    end
end

function ZO_CraftingResults_Gamepad:ClearAll()
    ZO_CraftingAlertClearAll_Gamepad()
end

function ZO_CraftingResults_Gamepad:FadeAll()
    ZO_CraftingAlertFadeAll_Gamepad()
end

function ZO_CraftingResults_Gamepad:DisplayDiscoveryHelper(titleString, numDiscoveries, lastLearnedDiscoveryFn)
    local displayData = {}
    displayData.header = {}
    displayData.lines = {}

    local headerText = GetString(titleString)
    displayData.header = { text = headerText }

    for i = 1, numDiscoveries do
        local discoveryName, itemName, icon, _, _, _, _, displayQuality = lastLearnedDiscoveryFn(i)

        local qualityColor = GetItemQualityColor(displayQuality)
        local itemString = zo_strformat(SI_GAMEPAD_ITEM_LEARNED_FROM, itemName)
        local colorizedItem = qualityColor:Colorize(itemString)

        local lineText = zo_strformat(SI_GAMEPAD_ITEM_TRAITS_LEARNED, discoveryName, colorizedItem)

        table.insert(displayData.lines, { text = lineText, icon = icon, resultType = ZO_CRAFTING_RESULT_TYPE.KNOWLEDGE })
    end

    ZO_CraftingAlertNoSuppressionTemplated_Gamepad(UI_ALERT_CATEGORY_ALERT, nil, displayData, GAMEPAD_CRAFTING_RESULTS_TEMPLATE)
end

function ZO_CraftingResults_Gamepad:DisplayDiscoveredTraits()
    self:DisplayDiscoveryHelper(SI_ALCHEMY_REAGENT_TRAIT_LEARNED_DIALOG_TITLE, GetNumLastCraftingResultLearnedTraits(), GetLastCraftingResultLearnedTraitInfo)
end

function ZO_CraftingResults_Gamepad:DisplayTranslatedRunes()
    self:DisplayDiscoveryHelper(SI_ENCHANTING_TRANSLATION_LEARNED_DIALOG_TITLE, GetNumLastCraftingResultLearnedTranslations(), GetLastCraftingResultLearnedTranslationInfo)
end

function ZO_CraftingResults_Gamepad:ShouldDisplayMessages()
    return true
end

function ZO_CraftingResults_Gamepad_Initialize(control)
    GAMEPAD_CRAFTING_RESULTS = ZO_CraftingResults_Gamepad:New(control)
    SYSTEMS:RegisterGamepadObject("craftingResults", GAMEPAD_CRAFTING_RESULTS)

    GAMEPAD_CRAFTING_RESULTS_FRAGMENT = ZO_FadeSceneFragment:New(control)
    GAMEPAD_CRAFTING_RESULTS_FRAGMENT:RegisterCallback("StateChange", function(oldState, newState)
        if newState == SCENE_HIDDEN then
            GAMEPAD_CRAFTING_RESULTS:ForceCompleteCraftProcess()
            GAMEPAD_CRAFTING_RESULTS:ClearAll()
        end
    end)
end
