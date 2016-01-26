local CRAFTING_RESULTS_TEMPLATE = "ZO_CraftingResultItem"

ZO_CraftingResults_Keyboard = ZO_CraftingResults_Base:Subclass()

function ZO_CraftingResults_Keyboard:New(...)
    return ZO_CraftingResults_Base.New(self, ...)
end

local MAX_RUNE_ROWS = 3
local function RegisterEnchantDialog(dialogName, control)
    local function SetupEnchantDialog(dialog)
        local numTranslation = GetNumLastCraftingResultLearnedTranslations()
        for i = 1, numTranslation do
            local translationName, itemName, icon, _, _, _, _, quality = GetLastCraftingResultLearnedTranslationInfo(i)

            local row = control:GetNamedChild("Row" .. i)
            row:SetHidden(false)

            row.icon:SetTexture(icon)

            row.itemName:SetText(zo_strformat(SI_TOOLTIP_ITEM_NAME, itemName))
            local r, g, b = GetInterfaceColor(INTERFACE_COLOR_TYPE_ITEM_QUALITY_COLORS, quality)
            row.itemName:SetColor(r, g, b, 1)

            row.translatedName:SetText(translationName)
        end

        for i = numTranslation + 1, MAX_RUNE_ROWS do
            control:GetNamedChild("Row" .. i):SetHidden(true)
        end
    end

    ZO_Dialogs_RegisterCustomDialog(dialogName,
    {
        customControl = control,
        setup = SetupEnchantDialog,
        title =
        {
            text = SI_ENCHANTING_TRANSLATION_LEARNED_DIALOG_TITLE,
        },
        buttons =
        {
            {
                keybind = "DIALOG_NEGATIVE",
                control = control:GetNamedChild("Exit"),
                text = SI_EXIT_BUTTON,
            },
        }
    })
end

local MAX_ALCHEMY_ROWS = 3
local MAX_ITEM_TRAITS = 4

local function SetDefaultOptionValue(options, optionName, defaultValue)
    if options[optionName] == nil then
        options[optionName] = defaultValue
    end
end

-- The options parameter is a table that can contain any of the following values:
--  colorItemName:  Whether to apply the quality color for the reagent name label (defaults to true)
--  centerAlignTraits:  Whether to center-align traits relative to reagent label (defaults to true)
--  rowSpacing:  The amount of spacing between reagent rows (defaults to 40)
function ZO_CraftingResults_SetupAlchemyDialogLayout(control, options)
    -- Set default values for options
    if not options then
        options = {}
    end

    SetDefaultOptionValue(options, "colorItemName", true)
    SetDefaultOptionValue(options, "centerAlignTraits", true)
    SetDefaultOptionValue(options, "rowSpacing", 40)

    local numLearnedTraits = GetNumLastCraftingResultLearnedTraits()
    local itemNameToRow = {}
    local currentRowIndex = 1

    for i = 1, numLearnedTraits do
        local traitName, itemName, icon, sellPrice, meetsUsageRequirement, equipType, itemStyle, quality = GetLastCraftingResultLearnedTraitInfo(i)

        if not itemNameToRow[itemName] then
            local row = control:GetNamedChild("Row" .. currentRowIndex)
            currentRowIndex = currentRowIndex + 1

            itemNameToRow[itemName] = row

            row:SetHidden(false)

            row.icon:SetTexture(icon)

            row.itemName:SetText(zo_strformat(SI_TOOLTIP_ITEM_NAME, itemName))

            if options.colorItemName then
                local r, g, b = GetInterfaceColor(INTERFACE_COLOR_TYPE_ITEM_QUALITY_COLORS, quality)
                row.itemName:SetColor(r, g, b, 1)
            end

            row.containerHeight = 0

            for traitIndex = 2, MAX_ITEM_TRAITS do
                row.traits[traitIndex]:SetHidden(true)
            end

            row.currentTraitIndex = 1
        end

        local row = itemNameToRow[itemName]

        local currentTraitIndex = row.currentTraitIndex
        row.traits[currentTraitIndex]:SetText(zo_strformat(SI_ALCHEMY_REAGENT_TRAIT_FORMATTER, traitName))
        row.traits[currentTraitIndex]:SetHidden(false)

        row.currentTraitIndex = currentTraitIndex + 1
        row.containerHeight = row.containerHeight + select(2, row.traits[currentTraitIndex]:GetTextDimensions())
    end

    for i = currentRowIndex, MAX_ALCHEMY_ROWS do
        control:GetNamedChild("Row" .. i):SetHidden(true)
    end

    local prevRow
    for i = 1, currentRowIndex - 1 do
        local row = control:GetNamedChild("Row" .. i)
        row.traitContainer:SetHeight(row.containerHeight)
        local currentOffset = zo_max(row.containerHeight - row:GetHeight(), 0) * .5 + 10

        if i == 1 then
            if options.centerAlignTraits then
                row:SetAnchor(TOP, control:GetNamedChild("Description"), BOTTOM, 0, currentOffset)
            else
                currentOffset = 60
                row:SetAnchor(TOPLEFT, control:GetNamedChild("Description"), BOTTOMLEFT, 0, currentOffset)
            end
        else
            local totalOffset

            if options.centerAlignTraits then
                local prevOffset = zo_max(prevRow.containerHeight - prevRow:GetHeight(), 0) * .5 + 10
                totalOffset = prevOffset + currentOffset
            else
                totalOffset = prevRow.containerHeight + options.rowSpacing
            end

            row:SetAnchor(TOP, prevRow, BOTTOM, 0, totalOffset)
        end

        prevRow = row
    end

    if not options.centerAlignTraits then
        control:GetNamedChild("Exit"):SetAnchor(TOPLEFT, prevRow, BOTTOMLEFT, 0, prevRow.containerHeight + options.rowSpacing)
    end
end

local function RegisterAlchemyDialog(dialogName, control, options)
    local function SetupAlchemyDialog(dialog)
        ZO_CraftingResults_SetupAlchemyDialogLayout(control, options)
    end

    ZO_Dialogs_RegisterCustomDialog(dialogName,
    {
        customControl = control,
        setup = SetupAlchemyDialog,
        title =
        {
            text = SI_ALCHEMY_REAGENT_TRAIT_LEARNED_DIALOG_TITLE,
        },
        buttons =
        {
            {
                keybind = "DIALOG_NEGATIVE",
                control = control:GetNamedChild("Exit"),
                text = SI_EXIT_BUTTON,
            },
        }
    })
end

function ZO_CraftingResults_Keyboard:Initialize(control)
    local DONT_SHOW_IN_GAMEPAD_PREFERRED_MODE = false
    ZO_CraftingResults_Base.Initialize(self, control, DONT_SHOW_IN_GAMEPAD_PREFERRED_MODE)

    RegisterEnchantDialog("ENCHANT_TRANSLATION_LEARNED", ZO_CraftingResultEnchantDialog)

    local options = {
        colorItemName = true,
        centerAlignTraits = true,
        rowSpacing = 40,
    }

    RegisterAlchemyDialog("ALCHEMY_TRAITS_LEARNED", ZO_CraftingResultAlchemyDialog, options)
end

function ZO_CraftingResults_Keyboard:ModifyAnchor(newAnchor)
    ZO_CraftingResults_Base.ModifyAnchor(self, ZO_CraftingResultsTopLevel, newAnchor)
end

function ZO_CraftingResults_Keyboard:RestoreAnchor()
    ZO_CraftingResults_Base.RestoreAnchor(self, ZO_CraftingResultsTopLevel)
end

do
    local function SetupItem(control, data)
        local r, g, b = GetInterfaceColor(INTERFACE_COLOR_TYPE_ITEM_QUALITY_COLORS, data.quality)

        control:SetText(zo_strformat(SI_TOOLTIP_ITEM_NAME, data.text))
        control:SetColor(r, g, b, 1)

        local inventorySlot = GetControl(control, "Button")
        ZO_Inventory_SetupSlot(inventorySlot, data.stack, data.icon, data.meetsUsageRequirement)
    end

    local function EntryEqualitySetup(fadingControlBuffer, oldEntry, newEntry)
        local oldData = oldEntry.lines[1]
        local newData = newEntry.lines[1]
        oldData.stack = oldData.stack + newData.stack

        local inventorySlot = ZO_FadingControlBuffer_GetLineControl(oldData):GetNamedChild("Button")
        ZO_Inventory_SetupSlot(inventorySlot, oldData.stack, newData.icon, newData.meetsUsageRequirement)

        ZO_CraftingResults_Base_PlayPulse(inventorySlot)
    end

    local function AreLinesEqual(oldLines, newLines)
        return oldLines[1].itemInstanceId == newLines[1].itemInstanceId
    end

    function ZO_CraftingResults_Keyboard:InitializeResultBuffer()
        local anchor = ZO_Anchor:New(TOP)

        self.notifier = ZO_FadingControlBuffer:New(self.control, 5, nil, nil, "CraftingResultFade", "CraftingResultTranslate", anchor)
        self.notifier:SetTranslateDuration(500)
        self.notifier:SetHoldTimes(5000)
        self.notifier:SetFadesInImmediately(true)
        self.notifier:SetAdditionalVerticalSpacing(5)

        local templateData = {setup = SetupItem, equalityCheck = AreLinesEqual, equalitySetup = EntryEqualitySetup}
        self.notifier:AddTemplate(CRAFTING_RESULTS_TEMPLATE, templateData)
    end
end

function ZO_CraftingResults_Keyboard:IsActive()
    return not IsInGamepadPreferredMode()
end

function ZO_CraftingResults_Keyboard:DisplayCraftingResult(itemInfo)
    local entry = {
        lines = {
            {text = itemInfo.name, icon = itemInfo.icon, stack = itemInfo.stack, meetsUsageRequirement = itemInfo.meetsUsageRequirement, quality = itemInfo.quality, itemInstanceId = itemInfo.itemInstanceId}
        }
    }
    self.notifier:AddEntry(CRAFTING_RESULTS_TEMPLATE, entry)
end

function ZO_CraftingResults_Keyboard:ClearAll()
    self.notifier:ClearAll()
end

function ZO_CraftingResults_Keyboard:HasEntries()
    return self.notifier:HasEntries()
end

function ZO_CraftingResults_Keyboard:FadeAll()
    self.notifier:FadeAll()
end

function ZO_CraftingResults_Keyboard:DisplayDiscoveredTraits()
    ZO_Dialogs_ShowDialog("ALCHEMY_TRAITS_LEARNED")
end

function ZO_CraftingResults_Keyboard:DisplayTranslatedRunes()
    ZO_Dialogs_ShowDialog("ENCHANT_TRANSLATION_LEARNED")
end

function ZO_CraftingResults_Keyboard:ShouldDisplayMessages()
    return CENTER_SCREEN_ANNOUNCE:IsInactive()
end

function ZO_CraftingResults_Keyboard_Initialize(control)
    CRAFTING_RESULTS = ZO_CraftingResults_Keyboard:New(control)
    SYSTEMS:RegisterKeyboardObject("craftingResults", CRAFTING_RESULTS)

    CRAFTING_RESULTS_FRAGMENT = ZO_FadeSceneFragment:New(control)
    CRAFTING_RESULTS_FRAGMENT:RegisterCallback("StateChange", function(oldState, newState)
        if newState == SCENE_HIDDEN then
            CRAFTING_RESULTS:ClearAll()
        end
    end)
end
