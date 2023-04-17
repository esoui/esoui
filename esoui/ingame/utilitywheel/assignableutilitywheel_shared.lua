--Data for hotbar categories that are supported by the assignable utility wheel. If a new category or action type is added that we want to support, this table needs to be updated
internalassert(HOTBAR_CATEGORY_MAX_VALUE == 14, "Update category data.")
internalassert(ACTION_TYPE_MAX_VALUE == 10, "Update category data.")
local SUPPORTED_HOTBAR_CATEGORY_DATA =
{
    [HOTBAR_CATEGORY_QUICKSLOT_WHEEL] = 
    {
        [ACTION_TYPE_ITEM] = true,
        [ACTION_TYPE_COLLECTIBLE] = true,
        [ACTION_TYPE_QUEST_ITEM] = true,
        [ACTION_TYPE_EMOTE] = true,
        [ACTION_TYPE_QUICK_CHAT] = true,
    },
    [HOTBAR_CATEGORY_EMOTE_WHEEL] = 
    {
        [ACTION_TYPE_EMOTE] = true,
        [ACTION_TYPE_QUICK_CHAT] = true,
    },
    [HOTBAR_CATEGORY_MEMENTO_WHEEL] =
    {
        [ACTION_TYPE_COLLECTIBLE] = true,
    },
    [HOTBAR_CATEGORY_ALLY_WHEEL] =
    {
        [ACTION_TYPE_COLLECTIBLE] = true,
    },
    [HOTBAR_CATEGORY_TOOL_WHEEL] =
    {
        [ACTION_TYPE_COLLECTIBLE] = true,
    },
}

--Fake hotbar category used to denote that the wheel is currently hidden
ZO_UTILITY_WHEEL_HOTBAR_CATEGORY_HIDDEN = -1

ZO_UTILITY_SLOT_EMPTY_STRING = GetString(SI_QUICKSLOTS_EMPTY)
ZO_UTILITY_SLOT_EMPTY_TEXTURE = "EsoUI/Art/Quickslots/quickslot_emptySlot.dds"

ZO_AssignableUtilityWheel_Shared = ZO_InitializingObject:Subclass()

--[[
    The data table can support the following fields:
        -hotbarCategories: Which hotbars this wheel represents. The order of the categories displayed is based off of the order of the categories here.
        -numSlots: The number of slots that are in this wheel. Should match up with the size of the bar that the slots are stored in.
        -startSlotIndex: The index that this wheel starts at on the hotbar(s). Example:
            startSlotIndex = ACTION_BAR_FIRST_UTILITY_BAR_SLOT
        -overrideShowNameLabels: Whether or not to show the names of each slot. This overrides the default behavior for all hotbar categories used in this wheel. 
            -By default, the emote wheel category will show name labels and the rest will not.
        -showKeybinds: Whether or not to show the accessibility keybinds underneath each slot. Can be a boolean or a function that returns a boolean
            -If this field is not set, we will not show the keybinds
            -If this is set to true, we will not display name labels, regardless of what overrideShowNameLabels is set to
        -showPendingIcon: Whether or not to show the icon of the item being slotted in the center of the wheel. Currently only supported for Gamepad
        -showCategoryLabel: Whether nor not to show the name of the wheel currently being displayed
        -includeHiddenState: Set this to true if we want one of the "Cycle Wheel" options to hide the wheel entirely
        -onSelectionChangedCallback: Function called when the selected entry on the wheel changes. Currently only supported for Gamepad
        -onHotbarCategoryChangedCallback: Function called when the current hotbar category on the wheel changes.
        -overrideGamepadTooltip: Overrides the tooltip used when an entry is selected. Currently only supported for Gamepad.
            -If this field is not set, GAMEPAD_QUAD1_TOOLTIP will be used
        -overrideTooltipScrollEnabled: Can be set to a boolean to indicate whether or not tooltip scrolling is enabled for this wheel. Currently only supported for Gamepad.
            -If this field is not set, whether or not tooltip scrolling is enabled will be controlled via a keybind that only appears if this field has not been set.
        -overrideActivateOnShow: Can be set to a boolean to indicate whether or not the radial menu for this wheel should activate on showing. Currently only supported for Gamepad.
            -If this field is not set, we assume true
        -customNarrationObjectName: The unique name to use when registering the wheel for narration. Currently only supported for Gamepad.
            -This field is required to be set for gamepad wheels in order for narration to function
        -headerNarrationFunction: Function used to determine the header narration for this wheel. Currently only supported for Gamepad.
            -If this field is not set, no header narration will be included
            -If customNarrationObjectName is not set, this will do nothing
]]
function ZO_AssignableUtilityWheel_Shared:Initialize(control, data)
    self.control = control
    self.categoryLabel = control:GetNamedChild("Category")
    if self.categoryLabel then
        self.categoryLabel:SetHidden(not data.showCategoryLabel)
    end
    self.data = data
    self.slots = {}
    self:SetupHotbarCategories(self.data.hotbarCategories)
    self:InitializeSlots()
    self:UpdateAllSlots()
    self:InitializeKeybindStripDescriptors()
    self:RegisterForEvents()
end

function ZO_AssignableUtilityWheel_Shared:RegisterForEvents()
    local function OnSlotUpdated(eventCode, physicalSlot, hotbarCategory)
        if self:GetHotbarCategory() == hotbarCategory then
            local PLAY_ANIMATION = true
            self:DoSlotUpdate(physicalSlot, PLAY_ANIMATION)
        end
    end

    self.control:RegisterForEvent(EVENT_HOTBAR_SLOT_UPDATED, OnSlotUpdated)

    self.control:RegisterForEvent(EVENT_PERSONALITY_CHANGED, function()
        --This event is only relevant if this wheel supports emotes
        if self:IsActionTypeSupported(ACTION_TYPE_EMOTE) then
            self:UpdateAllSlots()
        end
    end)
end

function ZO_AssignableUtilityWheel_Shared:GetNumSlotted()
    local numSlots = self.data.numSlots
    local actionBarOffset = self.data.startSlotIndex or 0
    local numSlotted = 0
    local hotbarCategory = self:GetHotbarCategory()
    for i = actionBarOffset + 1, actionBarOffset + numSlots do
        if GetSlotType(i, hotbarCategory) ~= ACTION_TYPE_NOTHING then
            numSlotted = numSlotted + 1
        end
    end

    return numSlotted
end

function ZO_AssignableUtilityWheel_Shared:GetHotbarCategory()
    return self.hotbarCategories[self.currentHotbarCategoryIndex]
end

function ZO_AssignableUtilityWheel_Shared:UpdateAllSlots()
    if self:GetHotbarCategory() ~= ZO_UTILITY_WHEEL_HOTBAR_CATEGORY_HIDDEN then
        for physicalSlot in pairs(self.slots) do
            self:DoSlotUpdate(physicalSlot)
        end
    end
end

function ZO_AssignableUtilityWheel_Shared:CycleHotbarCategory()
    local nextHotbarCategoryIndex = self.currentHotbarCategoryIndex % self.numHotbars + 1
    if nextHotbarCategoryIndex ~= self.currentHotbarCategoryIndex then
        self.currentHotbarCategoryIndex = nextHotbarCategoryIndex
        self:RefreshHotbarCategory()
        if self.data.onHotbarCategoryChangedCallback then
            self.data:onHotbarCategoryChangedCallback(nextHotbarCategoryIndex)
        end
    end
end

function ZO_AssignableUtilityWheel_Shared:RefreshHotbarCategory()
    local hotbarCategory = self:GetHotbarCategory()
    if hotbarCategory == ZO_UTILITY_WHEEL_HOTBAR_CATEGORY_HIDDEN then
        self.control:SetHidden(true)
        if self.categoryLabel then
            self.categoryLabel:SetText("")
        end
    else
        self.control:SetHidden(false)
        self:UpdateAllSlots()
        if self.categoryLabel then
            local categoryName = GetString("SI_HOTBARCATEGORY", hotbarCategory)
            self.categoryLabel:SetText(categoryName)
        end
    end
end

function ZO_AssignableUtilityWheel_Shared:SetupHotbarCategories(categoryList)
    local validCategories = {}
    local numValidCategories = 0
    for _, hotbarCategory in ipairs(categoryList) do
        if SUPPORTED_HOTBAR_CATEGORY_DATA[hotbarCategory] ~= nil then
            table.insert(validCategories, hotbarCategory)
            numValidCategories = numValidCategories + 1
        end
    end

    if numValidCategories > 0 then
        if self.data.includeHiddenState then
            table.insert(validCategories, ZO_UTILITY_WHEEL_HOTBAR_CATEGORY_HIDDEN)
            numValidCategories = numValidCategories + 1
        end
        self.numHotbars = numValidCategories
        self.hotbarCategories = validCategories
        self.currentHotbarCategoryIndex = 1
        return true
    else
        internalassert(false, "No valid hotbar categories found")
        return false
    end
end

function ZO_AssignableUtilityWheel_Shared:SetHotbarCategories(hotbarCategories)
    -- We use self.data.hotbarCategories instead of self.hotbarCategories for the comparison because self.hotbarCategories includes the hidden state
    if not ZO_AreNumericallyIndexedTablesEqual(hotbarCategories, self.data.hotbarCategories) then
        if self:SetupHotbarCategories(hotbarCategories) then
            ClearCursor()
            self.data.hotbarCategories = hotbarCategories
            self:RefreshHotbarCategory()
            KEYBIND_STRIP:UpdateKeybindButtonGroup(self.keybindStripDescriptor)
            --If we are setting the hotbar categories this wheel supports to something new, assume the hotbar category changed
            if self.data.onHotbarCategoryChangedCallback then
                self.data:onHotbarCategoryChangedCallback(self.currentHotbarCategoryIndex)
            end
        end
    end
end

function ZO_AssignableUtilityWheel_Shared:IsActionTypeSupported(actionType)
    local categoryData = SUPPORTED_HOTBAR_CATEGORY_DATA[self:GetHotbarCategory()]
    if categoryData and categoryData[actionType] then
        return true
    else
        return false
    end
end

function ZO_AssignableUtilityWheel_Shared:Activate()
    if self.categoryLabel then
        local hotbarCategory = self:GetHotbarCategory()
        if hotbarCategory ~= ZO_UTILITY_WHEEL_HOTBAR_CATEGORY_HIDDEN then
            local categoryName = GetString("SI_HOTBARCATEGORY", hotbarCategory)
            self.categoryLabel:SetText(categoryName)
        else
            self.categoryLabel:SetText("")
        end
    end

    self:UpdateAllSlots()
    KEYBIND_STRIP:AddKeybindButtonGroup(self.keybindStripDescriptor)
end

function ZO_AssignableUtilityWheel_Shared:Deactivate()
    KEYBIND_STRIP:RemoveKeybindButtonGroup(self.keybindStripDescriptor)
end

function ZO_AssignableUtilityWheel_Shared:ShouldShowKeybinds()
    if type(self.data.showKeybinds) == "function" then
        return self.data.showKeybinds()
    else
        return self.data.showKeybinds
    end
end

function ZO_AssignableUtilityWheel_Shared:CreateSlots()
    --To be overridden
end

function ZO_AssignableUtilityWheel_Shared:DoSlotUpdate(physicalSlot, playAnimation)
    --To be overridden
end

function ZO_AssignableUtilityWheel_Shared:InitializeKeybindStripDescriptors()
    local function AlignLeftOnGamepadCenterOnKeyboard()
        if IsInGamepadPreferredMode() then
            return KEYBIND_STRIP_ALIGN_LEFT
        else
            return KEYBIND_STRIP_ALIGN_CENTER
        end
    end

    self.keybindStripDescriptor =
    {
        alignment = AlignLeftOnGamepadCenterOnKeyboard,

        -- Cycle
        {
            name = GetString(SI_UTILITY_WHEEL_CYCLE_WHEEL),
            keybind = "UI_SHORTCUT_QUATERNARY",
            visible = function()
                return self.numHotbars > 1
            end,
            callback = function()
                ClearCursor()
                self:CycleHotbarCategory()
            end,
        },
    }
end