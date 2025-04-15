ZO_HousingFurnitureRetrieveTo_Keyboard = ZO_HousingFurnitureRetrieveTo_Shared:Subclass()

function ZO_HousingFurnitureRetrieveTo_Keyboard:Initialize(control)
    self.fragment = ZO_FadeSceneFragment:New(control)
    HOUSING_FURNITURE_RETRIEVE_TO_FRAGMENT = self.fragment

    self.fragment:RegisterCallback("StateChange", function(oldState, newState)
        if newState == SCENE_FRAGMENT_SHOWING then
            self:RefreshRetrieveToBags()
        end
    end)

    ZO_HousingFurnitureRetrieveTo_Shared.Initialize(self, control)
end

function ZO_HousingFurnitureRetrieveTo_Keyboard:OnBagEntryMouseEnter(comboBox, entryControl)
    local tooltipText = self:GetRetrieveToBagTooltipText(entryControl.m_data.bagInfo.bagId)
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

    local function OnBagEntryMouseEnter(...)
        self:OnBagEntryMouseEnter(...)
    end

    local function OnBagEntryMouseExit(...)
        self:OnBagEntryMouseExit(...)
    end

    self.bagComboBox:SetEntryMouseOverCallbacks(OnBagEntryMouseEnter, OnBagEntryMouseExit)
end

function ZO_HousingFurnitureRetrieveTo_Keyboard:RefreshRetrieveToBagList()
    -- Refresh the retrieve to bag list items.
    local function OnBagSelected(comboBox, _, item)
        self:SetRetrieveToBag(item.bagInfo.bagId)
    end

    local bagComboBox = self.bagComboBox
    bagComboBox:ClearItems()
    for _, bagInfo in ipairs(self.bags) do
        local item = bagComboBox:CreateItemEntry(bagInfo.displayName, OnBagSelected)
        item.bagInfo = bagInfo
        bagComboBox:AddItem(item)
    end
end

function ZO_HousingFurnitureRetrieveTo_Keyboard:UpdateRetrieveToBagList()
    -- Update the enabled state of each combo box bag item.
    local bagComboBox = self.bagComboBox
    for _, bagItem in ipairs(bagComboBox:GetItems()) do
        local bagId = bagItem.bagInfo.bagId
        local bagInfo = self:GetRetrieveToBagInfo(bagId)
        if bagInfo then
            bagComboBox:SetItemEnabled(bagItem, bagInfo.enabled)
        end
    end

    -- Update the currently selected bag.
    local function IsSelectedBagItem(bagItem)
        return bagItem.bagInfo.bagId == self.selectedBag
    end
    bagComboBox:SetSelectedItemByEval(IsSelectedBagItem)
end

-- Global XML

function ZO_HousingFurnitureRetrieveTo_Keyboard.OnControlInitialized(control)
    HOUSING_FURNITURE_RETRIEVE_TO_KEYBOARD = ZO_HousingFurnitureRetrieveTo_Keyboard:New(control)
end