ZO_ArmoryBuildOverview_Gamepad = ZO_InitializingObject:Subclass()

function ZO_ArmoryBuildOverview_Gamepad:Initialize(control)
    self.control = control

    ZO_GAMEPAD_ARMORY_BUILD_OVERVIEW_FRAGMENT = ZO_SimpleSceneFragment:New(control)
    ZO_GAMEPAD_ARMORY_BUILD_OVERVIEW_FRAGMENT:RegisterCallback("StateChange",
                                                function(oldState, newState)
                                                    if newState == SCENE_FRAGMENT_SHOWING then
                                                        self:OnShowing()
                                                    end
                                                end)

    self.scrollContainer = control:GetNamedChild("ScrollContainer")
    self.scrollChild = self.scrollContainer:GetNamedChild("ScrollChild")

    -- Set up the skill rows
    self.skillBarRow1 = self.scrollChild:GetNamedChild("SkillsActionBar1").object
    self.skillBarRow2 = self.scrollChild:GetNamedChild("SkillsActionBar2").object
    self.skillBarRow1:SetHotbarCategory(HOTBAR_CATEGORY_PRIMARY)
    self.skillBarRow2:SetHotbarCategory(HOTBAR_CATEGORY_BACKUP)

    -- Set up the champion bar
    self.championBar = ZO_ArmoryChampionActionBar:New(self.scrollChild:GetNamedChild("ChampionBar"))

    -- Set up the attribute bars
    self.attributes = self.scrollChild:GetNamedChild("Attributes")
    self.magickaAttribute = self.attributes:GetNamedChild("Magicka")
    self.healthAttribute = self.attributes:GetNamedChild("Health")
    self.staminaAttribute = self.attributes:GetNamedChild("Stamina")

    -- Set up the equipment element pools
    local function ResetControl(control)
        control:SetHidden(true)
    end
    self.equipmentPool = ZO_ControlPool:New("ZO_ArmoryEquipmentRow", self.scrollChild, "Equipment")
    self.headerPool = ZO_ControlPool:New("ZO_ArmoryStatValuePair", self.scrollChild, "Header")
    self.equipmentPool:SetCustomResetBehavior(ResetControl)
    self.headerPool:SetCustomResetBehavior(ResetControl)
    self.equipmentEntryData = {}
end

do
    local MAIN_HAND_EQUIP_SLOT =
    {
        [EQUIP_SLOT_MAIN_HAND] = true,
        [EQUIP_SLOT_BACKUP_MAIN] = true,
    }

    local OFF_HAND_TO_MAIN_HAND_MAP =
    {
        [EQUIP_SLOT_OFF_HAND] = EQUIP_SLOT_MAIN_HAND,
        [EQUIP_SLOT_BACKUP_OFF] = EQUIP_SLOT_BACKUP_MAIN,
    }

    local BACKBAR_SLOTS =
    {
        [EQUIP_SLOT_BACKUP_MAIN] = true,
        [EQUIP_SLOT_BACKUP_OFF] = true,
        [EQUIP_SLOT_BACKUP_POISON] = true,
    }

    function ZO_ArmoryBuildOverview_Gamepad:OnShowing()
        if self.armoryBuildData then
            self:ReleaseAllHeaderControls()
            self:ReleaseAllEquipmentControls()

            ZO_ClearNumericallyIndexedTable(self.equipmentEntryData)

            -- Setup the skills row data
            local totalSkillPoints = self.armoryBuildData:GetSkillsTotalSpentPoints()
            local previousControl = self:AddStatValuePair(self.scrollChild, GetString(SI_GAMEPAD_ARMORY_SKILLS_CATEGORY), totalSkillPoints, 50, 0)
            self.skillBarRow1.control:ClearAnchors()
            self.skillBarRow1.control:SetAnchor(TOPLEFT, previousControl, BOTTOMLEFT, -50, -30)

            self.skillBarRow1:AssignArmoryBuildData(self.armoryBuildData)
            self.skillBarRow2:AssignArmoryBuildData(self.armoryBuildData)

            -- Setup the champion bar data
            local totalChampionPoints = self.armoryBuildData:GetChampionTotalSpentPoints()
            previousControl = self:AddStatValuePair(self.skillBarRow2.control, GetString(SI_GAMEPAD_ARMORY_CHAMPION_CATEGORY), totalChampionPoints, 50, 20)
            self.championBar.control:ClearAnchors()
            self.championBar.control:SetAnchor(TOPLEFT, previousControl, BOTTOMLEFT, -5, 20)
            self.championBar:AssignArmoryBuildData(self.armoryBuildData)

            -- Setup the attributes row data
            local attributeDataList =
            {
                {
                    type = ATTRIBUTE_MAGICKA,
                    icon = "/esoui/art/characterwindow/Gamepad/gp_characterSheet_magickaIcon.dds",
                    control = self.magickaAttribute,
                },
                {
                    type = ATTRIBUTE_HEALTH,
                    icon = "/esoui/art/characterwindow/Gamepad/gp_characterSheet_healthIcon.dds",
                    control = self.healthAttribute,
                },
                {
                    type = ATTRIBUTE_STAMINA,
                    icon = "/esoui/art/characterwindow/Gamepad/gp_characterSheet_staminaIcon.dds",
                    control = self.staminaAttribute,
                },
            }

            local SELECTED = true
            local NOT_SELECTED = false
            local DISABLED = false
            local NOT_ACTIVE = false
            for i, attribute in ipairs(attributeDataList) do
                local attributeData = ZO_GamepadEntryData:New(GetString("SI_ATTRIBUTES", attribute.type), attribute.icon)
                ZO_SharedGamepadEntry_OnSetup(attribute.control, attributeData, SELECTED, NOT_SELECTED, DISABLED, NOT_ACTIVE)
                local spinnerDisplayControl = attribute.control:GetNamedChild("SpinnerDisplay")
                spinnerDisplayControl:SetText(self.armoryBuildData:GetAttributeSpentPoints(attribute.type))
            end

            -- Setup the equipment row data
            local headersUsed = {}
            local equipmentSlots = {}
            local mainHandLinks = {}
            local equipmentSlotTypes = ZO_ARMORY_MANAGER:GetEquipmentSlotTypes()
            previousControl = nil
            local isWeaponSwapLocked = GetUnitLevel("player") < GetWeaponSwapUnlockedLevel()
            for index, equipmentType in ipairs(equipmentSlotTypes) do
                local entryData = ZO_GamepadEntryData:New()
                local slotState, itemLink = self.armoryBuildData:GetEquipSlotItemLinkInfo(equipmentType)
                entryData:SetFontScaleOnSelection(false)
                local mainHandEquipType = OFF_HAND_TO_MAIN_HAND_MAP[equipmentType]
                local shouldHideEquipType = isWeaponSwapLocked and BACKBAR_SLOTS[equipmentType]
                if mainHandEquipType then
                    shouldHideEquipType = shouldHideEquipType or GetItemLinkEquipType(mainHandLinks[mainHandEquipType]) == EQUIP_TYPE_TWO_HAND
                end

                if not shouldHideEquipType then
                    local slotName = zo_strformat(SI_GAMEPAD_ARMORY_EQUIPMENT_FORMATTER, GetString("SI_EQUIPSLOT", equipmentType))
                    entryData.slotState = slotState
                    entryData.slotName = slotName
                    if slotState == ARMORY_BUILD_EQUIP_SLOT_STATE_VALID then
                        entryData:AddIcon(GetItemLinkIcon(itemLink))
                        entryData:SetText(zo_strformat(SI_TOOLTIP_ITEM_NAME, GetItemLinkName(itemLink)))
                        entryData:SetNameColors(entryData:GetColorsBasedOnQuality(GetItemLinkDisplayQuality(itemLink)))
                        if MAIN_HAND_EQUIP_SLOT[equipmentType] then
                            mainHandLinks[equipmentType] = itemLink
                        end
                     elseif slotState == ARMORY_BUILD_EQUIP_SLOT_STATE_MISSING or slotState == ARMORY_BUILD_EQUIP_SLOT_STATE_INACCESSIBLE then
                        local unselectedErrorColor = ZO_ERROR_COLOR:GetDim()
                        entryData:AddIcon(ZO_Character_GetEmptyEquipSlotTexture(equipmentType))
                        entryData:SetIconTint(ZO_ERROR_COLOR, unselectedErrorColor)
                        entryData:SetText(slotName)
                        entryData:SetNameColors(ZO_ERROR_COLOR, unselectedErrorColor)
                    else
                        entryData:AddIcon(ZO_Character_GetEmptyEquipSlotTexture(equipmentType))
                        entryData:SetText(slotName)
                    end

                    --Headers for Equipment Visual Categories (Weapons, Apparel): display header for the first equip slot of a category to be visible
                    local equipmentControl = self:AcquireEquipmentControl()
                    local visualCategory = ZO_Character_GetEquipSlotVisualCategory(equipmentType)
                    if headersUsed[visualCategory] == nil then
                        local headerControl = self:AcquireHeaderControl()
                        local headerText = GetString("SI_EQUIPSLOTVISUALCATEGORY", visualCategory)
                        entryData.headerText = headerText
                        headerControl:GetNamedChild("Stat"):SetText(headerText)
                        ZO_SharedGamepadEntry_OnSetup(equipmentControl, entryData)
                        if previousControl then
                            headerControl:SetAnchor(TOPLEFT, previousControl, BOTTOMLEFT, 0, 5)
                        else
                            headerControl:SetAnchor(TOPLEFT, self.attributes, BOTTOMLEFT, 0, 10)
                        end
                        previousControl = headerControl
                        headersUsed[visualCategory] = true
                    else
                        ZO_SharedGamepadEntry_OnSetup(equipmentControl, entryData)
                    end

                    if previousControl then
                        equipmentControl:SetAnchor(TOPLEFT, previousControl, BOTTOMLEFT, 0, 5)
                    else
                        equipmentControl:SetAnchor(TOPLEFT, self.attributes, BOTTOMLEFT, 0, 10)
                    end
                    previousControl = equipmentControl
                    table.insert(self.equipmentEntryData, entryData)
                end
            end

            --Setup the mundus stone data
            local mundusStoneList = self.armoryBuildData:GetEquippedMundusStoneNames()
            for _, mundusName in ipairs(mundusStoneList) do
                previousControl = self:AddStatValuePair(previousControl, GetString(SI_GAMEPAD_ARMORY_MUNDUS_HEADER), mundusName, 0, 20)
            end

            -- Setup the curse data
            previousControl = self:AddStatValuePair(previousControl, GetString(SI_GAMEPAD_ARMORY_CURSE_HEADER), GetString("SI_CURSETYPE", self.armoryBuildData:GetCurseType()), 0, 20)

            -- Setup outfit row data
            previousControl = self:AddStatValuePair(previousControl, GetString(SI_OUTFIT_SELECTOR_TITLE), self.armoryBuildData:GetEquippedOutfitName(), 0, 20)
        end
    end
end

function ZO_ArmoryBuildOverview_Gamepad:AddStatValuePair(parent, statText, valueText, offsetX, offsetY)
    local control = self:AcquireHeaderControl()
    local statControl = control:GetNamedChild("Stat")
    local valueControl = control:GetNamedChild("Value")
    statControl:SetText(statText)
    valueControl:SetHidden(false)
    valueControl:SetText(valueText)
    control:ClearAnchors()
    if parent == self.scrollChild then
        control:SetAnchor(TOPLEFT, parent, TOPLEFT, offsetX, offsetY)
    else
        control:SetAnchor(TOPLEFT, parent, BOTTOMLEFT, offsetX, offsetY)
    end
    return control
end

function ZO_ArmoryBuildOverview_Gamepad:AcquireEquipmentControl()
    return self.equipmentPool:AcquireObject()
end

function ZO_ArmoryBuildOverview_Gamepad:ReleaseAllEquipmentControls()
    self.equipmentPool:ReleaseAllObjects()
end

function ZO_ArmoryBuildOverview_Gamepad:AcquireHeaderControl()
    return self.headerPool:AcquireObject()
end

function ZO_ArmoryBuildOverview_Gamepad:ReleaseAllHeaderControls()
    self.headerPool:ReleaseAllObjects()
end

function ZO_ArmoryBuildOverview_Gamepad:SetSelectedArmoryBuildData(armoryBuildData)
    self.armoryBuildData = armoryBuildData
end

function ZO_ArmoryBuildOverview_Gamepad:GetNarrationText()
    local narrations = {}
    if self.armoryBuildData then
        --Skill points
        ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(GetString(SI_GAMEPAD_ARMORY_SKILLS_CATEGORY)))
        ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(self.armoryBuildData:GetSkillsTotalSpentPoints()))

        --Skill bars
        ZO_AppendNarration(narrations, self.skillBarRow1:GetNarrationText())
        ZO_AppendNarration(narrations, self.skillBarRow2:GetNarrationText())

        --Champion Points
        ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(GetString(SI_GAMEPAD_ARMORY_CHAMPION_CATEGORY)))
        ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(self.armoryBuildData:GetChampionTotalSpentPoints()))

        --Champion Bar
        ZO_AppendNarration(narrations, self.championBar:GetNarrationText())

        --Attributes
        ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(GetString(SI_GAMEPAD_ARMORY_ATTRIBUTES_CATEGORY)))

        ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(GetString("SI_ATTRIBUTES", ATTRIBUTE_MAGICKA)))
        ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(self.armoryBuildData:GetAttributeSpentPoints(ATTRIBUTE_MAGICKA)))

        ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(GetString("SI_ATTRIBUTES", ATTRIBUTE_HEALTH)))
        ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(self.armoryBuildData:GetAttributeSpentPoints(ATTRIBUTE_HEALTH)))

        ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(GetString("SI_ATTRIBUTES", ATTRIBUTE_STAMINA)))
        ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(self.armoryBuildData:GetAttributeSpentPoints(ATTRIBUTE_STAMINA)))


        --Equipment
        for _, equipmentData in ipairs(self.equipmentEntryData) do
            ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(equipmentData.headerText))
            ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(equipmentData.slotName))
            if equipmentData.slotState == ARMORY_BUILD_EQUIP_SLOT_STATE_VALID then
                ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(equipmentData.text))
            elseif equipmentData.slotState == ARMORY_BUILD_EQUIP_SLOT_STATE_MISSING or equipmentData.slotState == ARMORY_BUILD_EQUIP_SLOT_STATE_INACCESSIBLE then
                ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(GetString(SI_GAMEPAD_ARMORY_MISSING_ENTRY_NARRATION)))
            else
                ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(GetString(SI_GAMEPAD_ARMORY_EMPTY_ENTRY_NARRATION)))
            end
        end

        --Mundus
        local mundusStoneList = self.armoryBuildData:GetEquippedMundusStoneNames()
        for _, mundusName in ipairs(mundusStoneList) do
            ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(GetString(SI_GAMEPAD_ARMORY_MUNDUS_HEADER)))
            ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(mundusName))
        end

        --Curse
        ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(GetString(SI_GAMEPAD_ARMORY_CURSE_HEADER)))
        ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(GetString("SI_CURSETYPE", self.armoryBuildData:GetCurseType())))

        --Outfit
        ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(GetString(SI_OUTFIT_SELECTOR_TITLE)))
        ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(self.armoryBuildData:GetEquippedOutfitName()))
    end
    return narrations
end

-----------------------------
-- XML Functions
-----------------------------

function ZO_ArmoryBuildOverview_Gamepad_OnInitialized(control)
    GAMEPAD_ARMORY_BUILD_OVERVIEW = ZO_ArmoryBuildOverview_Gamepad:New(control)
end