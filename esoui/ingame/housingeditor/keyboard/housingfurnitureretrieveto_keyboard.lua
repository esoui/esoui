ZO_HousingFurnitureRetrieveTo_Keyboard = ZO_HousingFurnitureRetrieveTo_Shared:Subclass()

function ZO_HousingFurnitureRetrieveTo_Keyboard:Initialize(control)
    local fragment = ZO_FadeSceneFragment:New(control)
    HOUSING_FURNITURE_RETRIEVE_TO_FRAGMENT = fragment
    ZO_HousingFurnitureRetrieveTo_Shared.Initialize(self, control, fragment)
end

function ZO_HousingFurnitureRetrieveTo_Keyboard:OnBagEntryMouseEnter(comboBox, entryControl)
    local bagInfo = entryControl.m_data.bagInfo
    local tooltipText = bagInfo:GetTooltipText()
    if tooltipText then
        -- Show the retrieve to bag tooltip.
        InitializeTooltip(InformationTooltip, self.control, LEFT, 15, 0)
        local r, g, b = ZO_NORMAL_TEXT:UnpackRGB()
        local FULL_SIZE = true
        InformationTooltip:AddLine(tooltipText, "", r, g, b, TOPLEFT, MODIFY_TEXT_TYPE_NONE, TEXT_ALIGN_LEFT, FULL_SIZE)
    else
        -- Clear the retrieve to bag tooltip, if any.
        ClearTooltip(InformationTooltip)
    end
end

function ZO_HousingFurnitureRetrieveTo_Keyboard:OnBagEntryMouseExit(comboBox, entryControl)
    -- Clear the retrieve to bag tooltip, if any.
    ClearTooltip(InformationTooltip)
end

-- ZO_HousingFurnitureRetrieveTo_Shared Methods

function ZO_HousingFurnitureRetrieveTo_Keyboard:InitializeControls()
    -- Initialize the retrieve to bag dropdown control.
    self.bagDropdownControl = self.control:GetNamedChild("Bag")
    self.bagComboBox = ZO_ComboBox_ObjectFromContainer(self.bagDropdownControl)
    self.bagComboBox:SetSortsItems(false)

    self.OnBagSelected = function(comboBox, _, item)
        local bagId = item.bagInfo:GetBagId()
        self:SetSelectedBag(bagId)
    end

    local function OnBagEntryMouseEnter(...)
        self:OnBagEntryMouseEnter(...)
    end

    local function OnBagEntryMouseExit(...)
        self:OnBagEntryMouseExit(...)
    end

    self.bagComboBox:SetEntryMouseOverCallbacks(OnBagEntryMouseEnter, OnBagEntryMouseExit)
end

function ZO_HousingFurnitureRetrieveTo_Keyboard:RefreshBagList()
    -- Refresh the Retrieve To bag list items.
    local bagComboBox = self.bagComboBox
    bagComboBox:ClearItems()

    local INCLUDE_BAG_SLOTS = true
    for _, bagInfo in ipairs(self.bags) do
        if bagInfo:IsVisible() then
            local enabled = bagInfo:IsEnabled()
            local bagName = bagInfo:GetFormattedDisplayName(INCLUDE_BAG_SLOTS)
            if not enabled then
                bagName = bagName .. " " .. zo_iconFormat("/EsoUI/Art/Miscellaneous/status_locked.dds", 16, 16)
            end

            local item = bagComboBox:CreateItemEntry(bagName, self.OnBagSelected)
            item.bagInfo = bagInfo
            bagComboBox:AddItem(item)
            bagComboBox:SetItemEnabled(item, enabled)
        end
    end

    -- Update the currently selected bag.
    local selectedBagId = self:GetSelectedBagId()
    bagComboBox:SetSelectedItemByEval(function(item)
        return item.bagInfo:GetBagId() == selectedBagId
    end)
end

function ZO_HousingFurnitureRetrieveTo_Keyboard:GetFreeSpaceDescription()
    local bagDisplayName, numUsedSlots, numSlots
    local bagInfo = self:GetSelectedBagInfo()
    if bagInfo then
        bagDisplayName = bagInfo:GetDisplayName()
        numUsedSlots, numSlots = bagInfo:GetNumUsedAndTotalSlots()
    else
        bagDisplayName = GetString("SI_BAG", BAG_BACKPACK)
        numUsedSlots = GetNumBagUsedSlots(BAG_BACKPACK)
        numSlots = GetBagUseableSize(BAG_BACKPACK)
    end

    local formatString
    if numUsedSlots < numSlots then
        formatString = SI_INVENTORY_BAG_REMAINING_SPACES
    else
        formatString = SI_INVENTORY_BAG_COMPLETELY_FULL
    end
    return zo_strformat(formatString, numUsedSlots, numSlots, bagDisplayName)
end

-- Global XML

function ZO_HousingFurnitureRetrieveTo_Keyboard.OnControlInitialized(control)
    HOUSING_FURNITURE_RETRIEVE_TO_KEYBOARD = ZO_HousingFurnitureRetrieveTo_Keyboard:New(control)
end