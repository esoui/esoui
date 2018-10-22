ZO_SmithingResearch = ZO_SharedSmithingResearch:Subclass()

function ZO_SmithingResearch:New(...)
    return ZO_SharedSmithingResearch.New(self, ...)
end

function ZO_SmithingResearch:Initialize(control, owner)
    ZO_SharedSmithingResearch.Initialize(self, control, owner, "ZO_SmithingResearchSlot")

    self.numResearchingLabel = control:GetNamedChild("NumResearching")

    self:InitializeResearchLineList(ZO_HorizontalScrollList, "ZO_SmithingResearchListSlot")
    self:InitializeFilterTypeBar()

    ZO_InventoryInfoBar_ConnectStandardBar(control:GetNamedChild("InfoBar"))
end

function ZO_SmithingResearch:SetHidden(hidden)
    self.control:SetHidden(hidden)
    if not hidden and self.dirty then
        self:Refresh()
    end
end

function ZO_SmithingResearch:InitializeFilterTypeBar()
    local MENU_BAR_DATA =
    {
        initialButtonAnchorPoint = RIGHT,
        buttonTemplate = "ZO_CraftingInventoryTab",
        normalSize = 51,
        downSize = 64,
        buttonPadding = -15,
        animationDuration = 180,
    }

    self.tabs = self.control:GetNamedChild("Tabs")
    self.activeTab = self.control:GetNamedChild("TabsActive")

    ZO_MenuBar_SetData(self.tabs, MENU_BAR_DATA)

    local function CreateNewTabFilterData(filterType, name, normal, pressed, highlight, disabled, visible)
        return {
            tooltipText = name,

            descriptor = filterType,
            normal = normal,
            pressed = pressed,
            highlight = highlight,
            disabled = disabled,
            visible = visible,
            callback = function(filterData) self.activeTab:SetText(name) self:ChangeTypeFilter(filterData) end,
        }
    end

    ZO_MenuBar_AddButton(self.tabs, CreateNewTabFilterData(SMITHING_FILTER_TYPE_JEWELRY, GetString("SI_SMITHINGFILTERTYPE", SMITHING_FILTER_TYPE_JEWELRY), "EsoUI/Art/Crafting/jewelry_tabIcon_icon_up.dds", "EsoUI/Art/Crafting/jewelry_tabIcon_down.dds", "EsoUI/Art/Crafting/jewelry_tabIcon_icon_over.dds", "EsoUI/Art/Inventory/inventory_tabIcon_jewelry_disabled.dds", CanSmithingJewelryPatternsBeCraftedHere))
    ZO_MenuBar_AddButton(self.tabs, CreateNewTabFilterData(SMITHING_FILTER_TYPE_ARMOR, GetString("SI_SMITHINGFILTERTYPE", SMITHING_FILTER_TYPE_ARMOR), "EsoUI/Art/Inventory/inventory_tabIcon_armor_up.dds", "EsoUI/Art/Inventory/inventory_tabIcon_armor_down.dds", "EsoUI/Art/Inventory/inventory_tabIcon_armor_over.dds", "EsoUI/Art/Inventory/inventory_tabIcon_armor_disabled.dds", CanSmithingApparelPatternsBeCraftedHere))
    ZO_MenuBar_AddButton(self.tabs, CreateNewTabFilterData(SMITHING_FILTER_TYPE_WEAPONS, GetString("SI_SMITHINGFILTERTYPE", SMITHING_FILTER_TYPE_WEAPONS), "EsoUI/Art/Inventory/inventory_tabIcon_weapons_up.dds", "EsoUI/Art/Inventory/inventory_tabIcon_weapons_down.dds", "EsoUI/Art/Inventory/inventory_tabIcon_weapons_over.dds", "EsoUI/Art/Inventory/inventory_tabIcon_weapons_disabled.dds", CanSmithingWeaponPatternsBeCraftedHere))

    ZO_CraftingUtils_ConnectMenuBarToCraftingProcess(self.tabs)
end

function ZO_SmithingResearch:RefreshAvailableFilters()
    ZO_MenuBar_ClearSelection(self.tabs)
    ZO_MenuBar_UpdateButtons(self.tabs)
    ZO_MenuBar_SelectLastVisibleButton(self.tabs, true)
end

function ZO_SmithingResearch:SetupTooltip(row)
    InitializeTooltip(InformationTooltip, row, RIGHT, -10)

    SetTooltipText(InformationTooltip, GetString("SI_ITEMTRAITTYPE", row.traitType))
    ZO_Tooltip_AddDivider(InformationTooltip)

    local r, g, b = ZO_SELECTED_TEXT:UnpackRGB()
    local SET_TO_FULL_SIZE = true
    InformationTooltip:AddLine(row.traitDescription, "", r, g, b, CENTER, MODIFY_TEXT_TYPE_NONE, TEXT_ALIGN_CENTER, SET_TO_FULL_SIZE)
    if row.traitResearchSourceDescription then
        InformationTooltip:AddLine(zo_strformat(SI_SMITHING_TRAIT_RESEARCH_SOURCE_DESCRIPTION, row.traitResearchSourceDescription), "", r, g, b, CENTER, MODIFY_TEXT_TYPE_NONE, TEXT_ALIGN_CENTER, SET_TO_FULL_SIZE)
        InformationTooltip:AddLine(zo_strformat(SI_SMITHING_TRAIT_MATERIAL_SOURCE_DESCRIPTION, row.traitMaterialSourceDescription), "", r, g, b, CENTER, MODIFY_TEXT_TYPE_NONE, TEXT_ALIGN_CENTER, SET_TO_FULL_SIZE)
    end
end

function ZO_SmithingResearch:ClearTooltip(row)
    ClearTooltip(InformationTooltip)
end

function ZO_SmithingResearch:Research(overrideRow)
    local canResearchCurrentTrait = self:CanResearchCurrentTraitLine()

    if self.atMaxResearchLimit then
        local craftingSkillLineData = SKILLS_DATA_MANAGER:GetCraftingSkillLineData(GetCraftingInteractionType())
        ZO_Alert(UI_ALERT_CATEGORY_ALERT, SOUNDS.NEGATIVE_CLICK, SI_SMITHING_RESEARCH_ALL_SLOTS_IN_USE, craftingSkillLineData:GetName())
    elseif not canResearchCurrentTrait then
        ZO_Alert(UI_ALERT_CATEGORY_ALERT, SOUNDS.NEGATIVE_CLICK, SI_SMITHING_RESEARCH_TRAIT_ALREADY_BEING_RESEARCHED, self.traitLineText)
    else
        ZO_Dialogs_ShowDialog("SMITHING_RESEARCH_SELECT", overrideRow or self.activeRow)
    end
end

do
    local TRAIT_COLORS = {
        ZO_SELECTED_TEXT,
        ZO_NORMAL_TEXT,
    }

    function ZO_SmithingResearch:GetTraitColors()
        return TRAIT_COLORS[1], TRAIT_COLORS[2]
    end
end

function ZO_SmithingResearch:GetResearchTimeString(...)
    return zo_strformat(SI_SMITHING_RESEARCH_TIME_FOR_NEXT, ...)
end

function ZO_SmithingResearch:GetExtraInfoColor()
    return ZO_NORMAL_TEXT:UnpackRGBA()
end

function ZO_SmithingResearch:SetupTraitDisplay(slotControl, researchLine, known, duration, traitIndex)
    local iconControl = GetControl(slotControl, "Icon")

    local selectedColor, normalColor = self:GetTraitColors()

    if known then
        iconControl:SetAlpha(1)
        slotControl.nameLabel:SetColor(selectedColor:UnpackRGBA())
    else
        iconControl:SetAlpha(.3)
        slotControl.nameLabel:SetColor(ZO_DISABLED_TEXT:UnpackRGBA())
    end

    if known then
        slotControl.statusLabel:SetText("")
        slotControl.lockIcon:SetHidden(true)
        slotControl.timerIcon:SetHidden(true)
    elseif duration then
        slotControl.statusLabel:SetText(GetString(SI_SMITHING_RESEARCH_IN_PROGRESS))
        slotControl.statusLabel:SetColor(ZO_SECOND_CONTRAST_TEXT:UnpackRGBA())
		slotControl.nameLabel:SetColor(ZO_SECOND_CONTRAST_TEXT:UnpackRGBA())
        slotControl.lockIcon:SetHidden(true)
        slotControl.timerIcon:SetHidden(false)
		slotControl.timerIcon:SetAlpha(1)
		slotControl.timerIcon:SetColor(ZO_SECOND_CONTRAST_TEXT:UnpackRGBA())
    elseif researchLine.itemTraitCounts and researchLine.itemTraitCounts[traitIndex] then
        slotControl.statusLabel:SetText(GetString(SI_SMITHING_RESEARCH_RESEARCHABLE))
        slotControl.statusLabel:SetColor(normalColor:UnpackRGBA())
        slotControl.researchable = true
        slotControl.lockIcon:SetHidden(true)
		slotControl.nameLabel:SetColor(normalColor:UnpackRGBA())
        slotControl.timerIcon:SetHidden(true)
    else
        slotControl.statusLabel:SetText(GetString(SI_SMITHING_RESEARCH_UNKNOWN))
        slotControl.statusLabel:SetColor(ZO_DISABLED_TEXT:UnpackRGBA())
        slotControl.lockIcon:SetHidden(false)
        slotControl.timerIcon:SetHidden(true)
    end
end

function ZO_SmithingResearch:RefreshCurrentResearchStatusDisplay(currentlyResearching, maxResearchable)
    if currentlyResearching >= maxResearchable then
        self.numResearchingLabel:SetText(zo_strformat(SI_SMITHING_RESEARCH_SLOTS_FULL, maxResearchable))
    else
        self.numResearchingLabel:SetText(zo_strformat(SI_SMITHING_RESEARCH_USED_SLOTS, currentlyResearching, maxResearchable))
    end
end


ZO_SmithingResearchSelect = ZO_SharedSmithingResearchSelect:Subclass()

function ZO_SmithingResearchSelect:New(...)
    return ZO_SharedSmithingResearchSelect.New(self, ...)
end

function ZO_SmithingResearchSelect:Initialize(control)
    ZO_SharedSmithingResearchSelect.Initialize(self, control)

    ZO_Dialogs_RegisterCustomDialog("SMITHING_RESEARCH_SELECT",
    {
        customControl = function() return ZO_InventorySlot_GetItemListDialog():GetControl() end,
        setup = function(dialog, data) self:SetupDialog(data.craftingType, data.researchLineIndex, data.traitIndex) end,

        title =
        {
            text = SI_SMITHING_RESEARCH_DIALOG_TITLE,
        },        
        buttons =
        {
            {
                control = ZO_InventorySlot_GetItemListDialog():GetButton(1),
                text = SI_SMITHING_RESEARCH_DIALOG_CONFIRM,
                clickSound = SOUNDS.SMITHING_START_RESEARCH,
                callback = function()
                    local selectedData = ZO_InventorySlot_GetItemListDialog():GetSelectedItem()
                    if selectedData then
                        ResearchSmithingTrait(selectedData.bag, selectedData.index)
                    end
                end,
            },

            {
                control = ZO_InventorySlot_GetItemListDialog():GetButton(2),
                text = SI_DIALOG_CANCEL,
            }
        }
    })
end

local function SortComparator(left, right)
    return left.data.name < right.data.name
end

function ZO_SmithingResearchSelect:SetupDialog(craftingType, researchLineIndex, traitIndex)
    local listDialog = ZO_InventorySlot_GetItemListDialog()

    local _, _, _, timeRequiredForNextResearchSecs = GetSmithingResearchLineInfo(craftingType, researchLineIndex)
    local formattedTime = ZO_FormatTime(timeRequiredForNextResearchSecs, TIME_FORMAT_STYLE_COLONS, TIME_FORMAT_PRECISION_TWELVE_HOUR)

    listDialog:SetAboveText(GetString(SI_SMITHING_RESEARCH_DIALOG_SELECT))
    listDialog:SetBelowText(zo_strformat(SI_SMITHING_RESEARCH_DIALOG_CONSUME, formattedTime))
    listDialog:SetEmptyListText("")

    listDialog:ClearList()

    local function IsResearchableItem(bagId, slotIndex)
        return ZO_SharedSmithingResearch.IsResearchableItem(bagId, slotIndex, craftingType, researchLineIndex, traitIndex)
    end

    local virtualInventoryList = PLAYER_INVENTORY:GenerateListOfVirtualStackedItems(INVENTORY_BACKPACK, IsResearchableItem)
    PLAYER_INVENTORY:GenerateListOfVirtualStackedItems(INVENTORY_BANK, IsResearchableItem, virtualInventoryList)

    for itemId, itemInfo in pairs(virtualInventoryList) do
        itemInfo.name = zo_strformat(SI_TOOLTIP_ITEM_NAME, GetItemName(itemInfo.bag, itemInfo.index))
        listDialog:AddListItem(itemInfo)
    end

    listDialog:CommitList(SortComparator)

    listDialog:AddCustomControl(self.control, LIST_DIALOG_CUSTOM_CONTROL_LOCATION_BOTTOM)
end

--Global XML

function ZO_SmithingResearchSlot_OnInitialized(self)
    self.nameLabel = self:GetNamedChild("Name")
    self.statusLabel = self:GetNamedChild("Status")
    self.lockIcon = self:GetNamedChild("LockIcon")
    self.timerIcon = self:GetNamedChild("TimerIcon")
end

function ZO_SmithingResearchSlot_OnMouseDoubleClick(self)
    if self.owner:IsResearchable() then
        self.owner:Research()
    end
end

function ZO_SmithingResearchSlot_OnClicked(self, button)
    if button == MOUSE_BUTTON_INDEX_RIGHT then
        if self.owner:IsResearchable() then
            ClearMenu()
            AddMenuItem(GetString(SI_ITEM_ACTION_RESEARCH), function() self.owner:Research(self) end)
            ShowMenu(self)
        elseif self.owner:IsResearching() then
            ClearMenu()
            AddMenuItem(GetString(SI_CRAFTING_CANCEL_RESEARCH), function() self.owner:CancelResearch() end)
            ShowMenu(self)
        end
    end
end

function ZO_SmithingResearchSlot_OnMouseEnter(self)
    if not self.fadeAnimation then
        self.fadeAnimation = ANIMATION_MANAGER:CreateTimelineFromVirtual("ShowOnMouseOverLabelAnimation", self:GetNamedChild("Highlight"))
        self.scaleAnimation = ANIMATION_MANAGER:CreateTimelineFromVirtual("IconSlotMouseOverAnimation", self.icon)
    end
    self.fadeAnimation:PlayForward()
    self.scaleAnimation:PlayForward()

    self.owner:OnResearchRowActivate(self)
end

function ZO_SmithingResearchSlot_OnMouseExit(self)
    if self.fadeAnimation then
        self.fadeAnimation:PlayBackward()
        self.scaleAnimation:PlayBackward()
    end
                
    self.owner:OnResearchRowDeactivate(self)
end

function ZO_SmithingResearchSelect_OnInitialize(control)
    SMITHING_RESEARCH_SELECT = ZO_SmithingResearchSelect:New(control)
end
