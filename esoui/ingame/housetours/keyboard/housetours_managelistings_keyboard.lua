local BACKGROUND_IMAGE_FILE_WIDTH = 1024
local BACKGROUND_IMAGE_FILE_HEIGHT = 512
local BACKGROUND_IMAGE_CONTENT_WIDTH = 700
local BACKGROUND_IMAGE_CONTENT_HEIGHT = 350
local PANEL_WIDTH = 628
ZO_HOUSE_TOURS_MANAGE_LISTINGS_PANEL_KEYBOARD_TEXTURE_COORD_RIGHT = BACKGROUND_IMAGE_CONTENT_WIDTH / BACKGROUND_IMAGE_FILE_WIDTH
ZO_HOUSE_TOURS_MANAGE_LISTINGS_PANEL_KEYBOARD_TEXTURE_COORD_BOTTOM = BACKGROUND_IMAGE_CONTENT_HEIGHT / BACKGROUND_IMAGE_FILE_HEIGHT
ZO_HOUSE_TOURS_MANAGE_LISTINGS_PANEL_KEYBOARD_TILE_HEIGHT = (PANEL_WIDTH / BACKGROUND_IMAGE_CONTENT_WIDTH) * BACKGROUND_IMAGE_CONTENT_HEIGHT

local PRESERVE_SELECTIONS = false
local RESET_SELECTIONS = true

-----------------------------
--House Tours Manage Listings
-----------------------------

ZO_HouseToursManageListings_Keyboard = ZO_DeferredInitializingObject:Subclass()

function ZO_HouseToursManageListings_Keyboard:Initialize(control)
    self.control = control

    local fragment = ZO_FadeSceneFragment:New(self.control)
    ZO_DeferredInitializingObject.Initialize(self, fragment)

    self:InitializeActivityFinderCategoryData()
end

function ZO_HouseToursManageListings_Keyboard:OnDeferredInitialize()
    self:RegisterForEvents()
    self:InitializeControls()
    self:InitializeKeybindStripDescriptor()
    self:SetIsListingOperationOnCooldown(IsHouseToursListingOnCooldown())
end

function ZO_HouseToursManageListings_Keyboard:SetIsListingOperationOnCooldown(isListingOperationOnCooldown)
    self.isListingOperationOnCooldown = isListingOperationOnCooldown

    self:RefreshDropdownEnabledStates()
    self:RefreshButtons()
end

function ZO_HouseToursManageListings_Keyboard:RefreshDropdownEnabledStates()
    local enabled = not self.isListingOperationOnCooldown and not AreHousingPermissionsChangesPending()
    local setComboBoxEnabledState = enabled and ZO_ComboBox_Enable or ZO_ComboBox_Disable
    setComboBoxEnabledState(self.houseDropdownControl)
    setComboBoxEnabledState(self.visitorAccessDropdownControl)
    setComboBoxEnabledState(self.tagsDropdownControl)
end

function ZO_HouseToursManageListings_Keyboard:RegisterForEvents()
    local function OnQuestsUpdated()
        if self:IsShowing() then
            self:RefreshButtons()
        end
    end
    
    EVENT_MANAGER:RegisterForEvent("HouseTours_ManageListings_Keyboard", EVENT_QUEST_ADDED, OnQuestsUpdated)
    EVENT_MANAGER:RegisterForEvent("HouseTours_ManageListings_Keyboard", EVENT_QUEST_REMOVED, OnQuestsUpdated)

    local function OnPendingPermissionsChangesUpdated()
        if self:IsShowing() then
            self:RefreshButtons()
            self:RefreshDropdownEnabledStates()
        end
    end

    EVENT_MANAGER:RegisterForEvent("HouseTours_ManageListings_Keyboard", EVENT_HOUSING_PERMISSIONS_SAVE_PENDING, OnPendingPermissionsChangesUpdated)
    EVENT_MANAGER:RegisterForEvent("HouseTours_ManageListings_Keyboard", EVENT_HOUSING_PERMISSIONS_SAVE_COMPLETE, OnPendingPermissionsChangesUpdated)

    HOUSE_TOURS_PLAYER_LISTINGS_MANAGER:RegisterCallback("ListingOperationCooldownStateChanged", ZO_GetCallbackForwardingFunction(self, self.SetIsListingOperationOnCooldown))
    HOUSE_TOURS_PLAYER_LISTINGS_MANAGER:RegisterCallback("ListingOperationCompleted", function(operationType, houseId, result)
        local selectedData = HOUSE_TOURS_PLAYER_LISTINGS_MANAGER:GetListingDataByCollectibleId(self.selectedCollectibleId)
        if selectedData and selectedData:GetHouseId() == houseId then
            if self:IsShowing() then
                self:RefreshListing(RESET_SELECTIONS)
                self:RefreshHouseDropdown()
            else
                --If the screen isn't currently showing, make sure the selections get reset next time we show
                self.selectionsDirty = true
            end
        end
    end)

    ZO_COLLECTIBLE_DATA_MANAGER:RegisterCallback("OnCollectibleUpdated", function() self:RefreshNickname() end)
end

function ZO_HouseToursManageListings_Keyboard:InitializeControls()
    self.listingContainer = self.control:GetNamedChild("ListingContainer")
    self.questContainer = self.control:GetNamedChild("QuestContainer")

    self.questDescriptionLabel = self.questContainer:GetNamedChild("Description")

    self.houseDropdownControl = self.listingContainer:GetNamedChild("HouseSelector")
    self.houseDropdown = ZO_ComboBox_ObjectFromContainer(self.houseDropdownControl)
    self.houseDropdown:SetSortsItems(false)
    self.houseDropdown:SetFont("ZoFontWinT1")
    self.houseDropdown:SetSpacing(4)
    self.houseDropdown:SetPreshowDropdownCallback(function()
        TUTORIAL_SYSTEM:RemoveTutorialByTrigger(TUTORIAL_TYPE_POINTER_BOX, TUTORIAL_TRIGGER_HOUSE_TOURS_MANAGE_LISTINGS_OPENED_POINTER_BOX)
    end)

    self.houseDropdownTutorialAnchor = ZO_Anchor:New(RIGHT, self.houseDropdownControl, LEFT, -10, 0)

    self.visitorAccessLoadingIcon = self.listingContainer:GetNamedChild("VisitorAccessRowLoadingIcon")
    self.visitorAccessDropdownControl = self.listingContainer:GetNamedChild("VisitorAccessRowDropdown")
    self.visitorAccessDropdown = ZO_ComboBox_ObjectFromContainer(self.visitorAccessDropdownControl)
    self.visitorAccessDropdown:SetSortsItems(false)

    local function OnMouseEnter(comboBox, control)
        local data = control and control.m_data or comboBox.m_comboBox.m_selectedItemData
        if not IsHouseDefaultAccessSettingValidForHouseToursListing(data.defaultAccess) then
            InitializeTooltip(InformationTooltip)
            SetTooltipText(InformationTooltip, GetString(SI_HOUSE_TOURS_MANAGE_LISTING_INVALID_ACCESS_TOOLTIP_TEXT))
            local anchorTo = control and control or comboBox
            ZO_Tooltips_SetupDynamicTooltipAnchors(InformationTooltip, anchorTo)
        end
    end
    local function OnMouseExit(comboBox, control)
        ClearTooltip(InformationTooltip)
    end
    self.visitorAccessDropdown:SetMouseOverCallbacks(OnMouseEnter, OnMouseExit)
    self.visitorAccessDropdown:SetEntryMouseOverCallbacks(OnMouseEnter, OnMouseExit)

    local function OnVisitorAccessPresetSelected(comboBox, entryText, entry)
        local selectedData = HOUSE_TOURS_PLAYER_LISTINGS_MANAGER:GetListingDataByCollectibleId(self.selectedCollectibleId)
        if selectedData then
            local data =
            {
                houseId = selectedData:GetHouseId(),
                housePermissionDefaultAccessSetting = entry.defaultAccess,
                failureCallback = function()
                    self:RefreshListing(PRESERVE_SELECTIONS)
                end,
                successCallback = function()
                    self:RefreshButtons()
                end,
            }
            ZO_Dialogs_ShowPlatformDialog("CONFIRM_CHANGE_DEFAULT_HOUSING_PERMISSION", data)
        end
    end

    local allDefaultAccessSettings = HOUSE_SETTINGS_MANAGER:GetAllDefaultAccessSettings()
    for i = HOUSE_PERMISSION_DEFAULT_ACCESS_SETTING_ITERATION_BEGIN, HOUSE_PERMISSION_DEFAULT_ACCESS_SETTING_ITERATION_END do
        local entry = self.visitorAccessDropdown:CreateItemEntry(allDefaultAccessSettings[i], OnVisitorAccessPresetSelected)
        entry.defaultAccess = i
        if not IsHouseDefaultAccessSettingValidForHouseToursListing(i) then
            entry.name = ZO_ERROR_COLOR:Colorize(entry.name)
        end
        self.visitorAccessDropdown:AddItem(entry, ZO_COMBOBOX_SUPPRESS_UPDATE)
    end

    local function OnTagsDropdownHidden()
        self:RefreshButtons()
    end

    self.tagsRow = self.listingContainer:GetNamedChild("TagsRow")
    self.tagsDropdownControl = self.listingContainer:GetNamedChild("TagsRowDropdown")
    self.tagsDropdown = ZO_ComboBox_ObjectFromContainer(self.tagsDropdownControl)
    self.tagsDropdown:EnableMultiSelect()
    self.tagsDropdown:SetMaxSelections(MAX_HOUSE_TOURS_LISTING_TAGS)
    self.tagsDropdown:SetNoSelectionText(GetString(SI_HOUSE_TOURS_TAGS_DROPDOWN_NO_SELECTION_TEXT))
    self.tagsDropdown:SetMultiSelectionTextFormatter(SI_HOUSE_TOURS_TAGS_DROPDOWN_TEXT_FORMATTER)
    for i = HOUSE_TOURS_LISTING_TAG_ITERATION_BEGIN, HOUSE_TOURS_LISTING_TAG_ITERATION_END do
        local tagEntry = self.tagsDropdown:CreateItemEntry(GetString("SI_HOUSETOURLISTINGTAG", i))
        tagEntry.tagValue = i
        self.tagsDropdown:AddItem(tagEntry, ZO_COMBOBOX_SUPPRESS_UPDATE)
    end
    self.tagsDropdown:UpdateItems()
    self.tagsDropdown:SetHideDropdownCallback(OnTagsDropdownHidden)

    self.houseTileControl = self.listingContainer:GetNamedChild("HouseTile")
    self.houseTileBackground = self.houseTileControl:GetNamedChild("Background")
    self.houseTileNameLabel = self.houseTileControl:GetNamedChild("Name")
    self.houseTileNicknameLabel = self.houseTileControl:GetNamedChild("Nickname")
    self.houseTileStatusLabel = self.houseTileControl:GetNamedChild("StatusValue")
    self.houseTileFurnitureCountLabel = self.houseTileControl:GetNamedChild("FurnitureCount")
    self.houseTileRecommendationsControl = self.houseTileControl:GetNamedChild("Recommendations")
    self.houseTileRecommendationsLabel = self.houseTileControl:GetNamedChild("RecommendationsValue")

    self.nicknameRow = self.listingContainer:GetNamedChild("NicknameRow")
    self.currentNicknameLabel = self.listingContainer:GetNamedChild("NicknameRowValue")
    self.renameButton = self.listingContainer:GetNamedChild("RenameButton")

    local buttonContainer = self.control:GetNamedChild("ActionButtonContainer")
    self.submitButton = buttonContainer:GetNamedChild("SubmitButton")
    self.submitButton:SetHandler("OnClicked", function(buttonControl, button)
        if button == MOUSE_BUTTON_INDEX_LEFT then
            local selectedListingData = HOUSE_TOURS_PLAYER_LISTINGS_MANAGER:GetListingDataByCollectibleId(self.selectedCollectibleId)
            if selectedListingData then
                local tags = {}
                local selectedTagsData = self.tagsDropdown:GetSelectedItemData()
                for _, item in ipairs(selectedTagsData) do
                    table.insert(tags, item.tagValue)
                end
                ZO_Dialogs_ShowDialog("HOUSE_TOURS_SUBMIT_LISTING_KEYBOARD", { selectedListingData = selectedListingData, tags = tags })
            end
        end
    end)

    self.editButton = self.listingContainer:GetNamedChild("EditTagsButton")
    self.editButton:SetHandler("OnClicked", function(buttonControl, button)
        if button == MOUSE_BUTTON_INDEX_LEFT then
            local selectedListingData = HOUSE_TOURS_PLAYER_LISTINGS_MANAGER:GetListingDataByCollectibleId(self.selectedCollectibleId)
            if selectedListingData then
                local tags = {}
                local selectedTagsData = self.tagsDropdown:GetSelectedItemData()
                for _, item in ipairs(selectedTagsData) do
                    table.insert(tags, item.tagValue)
                end
                RequestUpdateHouseToursListing(selectedListingData:GetHouseId(), unpack(tags))
            end
        end
    end)

    self.removeButton = buttonContainer:GetNamedChild("RemoveListingButton")
    self.removeButton:SetHandler("OnClicked", function(buttonControl, button)
        if button == MOUSE_BUTTON_INDEX_LEFT then
            local selectedListingData = HOUSE_TOURS_PLAYER_LISTINGS_MANAGER:GetListingDataByCollectibleId(self.selectedCollectibleId)
            --TODO House Tours: Do we want a confirmation dialog for this case?
            if selectedListingData then
                RequestDeleteHouseToursListing(selectedListingData:GetHouseId())
            end
        end
    end)

    self.acceptQuestButton = buttonContainer:GetNamedChild("AcceptQuestButton")

    self.lockReasonLabel = self.control:GetNamedChild("LockReason")
end

function ZO_HouseToursManageListings_Keyboard:InitializeActivityFinderCategoryData()
    self.categoryData =
    {
        priority = ZO_ACTIVITY_FINDER_SORT_PRIORITY.HOUSE_TOURS + 40,
        name = GetString(SI_HOUSE_TOURS_MANAGE_LISTINGS),
        categoryFragment = self:GetFragment(),
        onTreeEntrySelected = function() self:OnCategorySelected() end,
    }
end

function ZO_HouseToursManageListings_Keyboard:InitializeKeybindStripDescriptor()
    self.keybindStripDescriptor =
    {
        alignment = KEYBIND_STRIP_ALIGN_CENTER,
        {
            name = GetString(SI_HOUSE_TOURS_MANAGE_LISTING_TRAVEL_TO_HOUSE),
            keybind = "UI_SHORTCUT_PRIMARY",
            callback = function()
                local selectedListingData = HOUSE_TOURS_PLAYER_LISTINGS_MANAGER:GetListingDataByCollectibleId(self.selectedCollectibleId)
                if selectedListingData then
                    local TRAVEL_INSIDE = false
                    RequestJumpToHouse(selectedListingData:GetHouseId(), TRAVEL_INSIDE)
                end
            end,
            visible = function()
                return self.hasHouses
            end,
        },
    }
end

function ZO_HouseToursManageListings_Keyboard:GetActivityFinderCategoryData()
    return self.categoryData
end

function ZO_HouseToursManageListings_Keyboard:OnCategorySelected()
    --TODO House Tours: Implement
end

function ZO_HouseToursManageListings_Keyboard:OnShowing()
    TUTORIAL_SYSTEM:RegisterTriggerLayoutInfo(TUTORIAL_TYPE_POINTER_BOX, TUTORIAL_TRIGGER_HOUSE_TOURS_MANAGE_LISTINGS_OPENED_POINTER_BOX, self.control, self:GetFragment(), self.houseDropdownTutorialAnchor)
    --Order matters: Determine if we have houses before refreshing the visuals
    local sortedListingData = HOUSE_TOURS_PLAYER_LISTINGS_MANAGER:GetSortedListingData()
    self.hasHouses = #sortedListingData > 0
    if self.queuedSelectedCollectibleId then
        self:SetSelectedHouse(self.queuedSelectedCollectibleId)
        self.queuedSelectedCollectibleId = nil
    elseif IsOwnerOfCurrentHouse() then
        self:SetSelectedHouse(GetCollectibleIdForHouse(GetCurrentZoneHouseId()))
    end
    self:RefreshHouseDropdown()
    self:RefreshListing(self.selectionsDirty)
    self.selectionsDirty = false
    self:RefreshStarterQuest()
    KEYBIND_STRIP:AddKeybindButtonGroup(self.keybindStripDescriptor)

    if self.hasHouses then
        TriggerTutorial(TUTORIAL_TRIGGER_HOUSE_TOURS_MANAGE_LISTINGS_OPENED_POINTER_BOX)
    end
end

function ZO_HouseToursManageListings_Keyboard:OnHidden()
    KEYBIND_STRIP:RemoveKeybindButtonGroup(self.keybindStripDescriptor)
end

function ZO_HouseToursManageListings_Keyboard:SetSelectedHouse(collectibleId)
    if self.selectedCollectibleId ~= collectibleId then
        self.selectedCollectibleId = collectibleId
        self:RefreshListing(RESET_SELECTIONS)
    end
end

function ZO_HouseToursManageListings_Keyboard:RefreshStarterQuest()
    if self.hasHouses then
        self.questContainer:SetHidden(true)
    else
        local questId = GetHousingStarterQuestId()
        local questName = GetQuestName(questId)
        local formattedQuestText = zo_strformat(SI_HOUSE_TOURS_MANAGE_LISTING_NO_HOUSES_STARTER_QUEST, ZO_SELECTED_TEXT:Colorize(questName))
        local descriptionText = ZO_GenerateParagraphSeparatedList({ GetString(SI_HOUSE_TOURS_MANAGE_LISTING_NO_HOUSES), formattedQuestText })
        self.questDescriptionLabel:SetText(descriptionText)

        self.questContainer:SetHidden(false)
        self:RefreshButtons()
    end
end

do
    local FURNITURE_COUNT_TEXTURE = "EsoUI/Art/HouseTours/houseTours_furnitureCount.dds"
    local IS_LISTED_TEXTURE = "EsoUI/Art/HouseTours/houseTours_listed.dds"

    function ZO_HouseToursManageListings_Keyboard:RefreshListing(resetSelections)
        local selectedListingData = HOUSE_TOURS_PLAYER_LISTINGS_MANAGER:GetListingDataByCollectibleId(self.selectedCollectibleId)
        if self.hasHouses and selectedListingData then
            self.houseTileBackground:SetTexture(selectedListingData:GetBackgroundImage())
            self.houseTileNameLabel:SetText(selectedListingData:GetFormattedHouseName())
            self:RefreshNickname()

            local furnitureCountText
            local furnitureCount = selectedListingData:GetFurnitureCount()
            if furnitureCount ~= nil then
                furnitureCountText = zo_iconTextFormat(FURNITURE_COUNT_TEXTURE, 32, 32, furnitureCount)
            else
                furnitureCountText = zo_iconTextFormat(FURNITURE_COUNT_TEXTURE, 32, 32, GetString(SI_HOUSE_TOURS_LISTING_FURNITURE_COUNT_UNKNOWN))
            end
            self.houseTileFurnitureCountLabel:SetText(furnitureCountText)

            local statusText
            if selectedListingData:IsListed() then
                statusText = zo_iconTextFormat(IS_LISTED_TEXTURE, 32, 32, GetString(SI_HOUSE_TOURS_MANAGE_LISTING_STATUS_LISTED))
            else
                statusText = GetString(SI_HOUSE_TOURS_MANAGE_LISTING_STATUS_NOT_LISTED)
            end
            self.houseTileStatusLabel:SetText(statusText)

            local numRecommendations = selectedListingData:GetNumRecommendations() or 0
            if numRecommendations > 0 then
                self.houseTileRecommendationsControl:SetHidden(false)
                self.houseTileRecommendationsLabel:SetText(ZO_CommaDelimitNumber(numRecommendations))
            else
                self.houseTileRecommendationsControl:SetHidden(true)
            end

            local function ShouldAutoSelectEntry(entry)
                local defaultAccess = HOUSE_SETTINGS_MANAGER:GetDefaultHousingPermission(selectedListingData:GetHouseId())
                return entry.defaultAccess == defaultAccess
            end

            local IGNORE_CALLBACK = true
            if not self.visitorAccessDropdown:SetSelectedItemByEval(ShouldAutoSelectEntry, IGNORE_CALLBACK) then
                self.visitorAccessDropdown:SelectFirstItem(IGNORE_CALLBACK)
            end

            if resetSelections then
                --Reset the selected tags back to their currently saved values
                self.tagsDropdown:ClearAllSelections()
                local tags = selectedListingData:GetTags()
                for _, item in ipairs(self.tagsDropdown:GetItems()) do
                    if ZO_IsElementInNumericallyIndexedTable(tags, item.tagValue) then
                        self.tagsDropdown:SelectItem(item, IGNORE_CALLBACK)
                    end
                end
            end

            self:RefreshDropdownEnabledStates()
            self:RefreshButtons()
            self.listingContainer:SetHidden(false)
        else
            self.listingContainer:SetHidden(true)
        end
    end
end

function ZO_HouseToursManageListings_Keyboard:RefreshButtons()
    local lockReasonText
    local enableSubmit = false
    local enableEdit = false
    local showSubmit = false
    local showEdit = false
    local showRemove = false
    local showQuest = false

    local permissionsChangesPending = AreHousingPermissionsChangesPending()

    if self.hasHouses then
        local selectedListingData = HOUSE_TOURS_PLAYER_LISTINGS_MANAGER:GetListingDataByCollectibleId(self.selectedCollectibleId)
        if selectedListingData then
            local isListed = selectedListingData:IsListed()
            showSubmit = not isListed
            showEdit = isListed
            showRemove = isListed

            if isListed then
                --Grab a copy of the currently saved tags
                local currentTags = {}
                ZO_ShallowNumericallyIndexedTableCopy(selectedListingData:GetTags(), currentTags)

                --Grab the currently selected tags in the UI
                local newTags = {}
                local selectedTagsData = self.tagsDropdown:GetSelectedItemData()
                for _, item in ipairs(selectedTagsData) do
                    table.insert(newTags, item.tagValue)
                end

                --Sort both the current and new tags to make sure they are in the same order when we compare them
                table.sort(currentTags)
                table.sort(newTags)

                enableEdit = not ZO_AreNumericallyIndexedTablesEqual(currentTags, newTags)
            else
                enableSubmit = selectedListingData:HasValidPermissions()
            end

            lockReasonText = selectedListingData:GetLockReasonText()
        end
    else
        --If we do not have any houses, we should show the quest button
        showQuest = true
        local questId = GetHousingStarterQuestId()
        if HasQuest(questId) then
            self.acceptQuestButton:SetEnabled(false)
            self.acceptQuestButton:SetText(GetString(SI_DLC_BOOK_ACTION_QUEST_ACCEPTED))
        else
            self.acceptQuestButton:SetEnabled(true)
            self.acceptQuestButton:SetText(GetString(SI_COLLECTIBLE_ACTION_ACCEPT_QUEST))
        end
    end

    self.acceptQuestButton:SetHidden(not showQuest)
    self.editButton:SetHidden(not showEdit)

    --The nickname row needs to anchor slightly differently depending on if the edit button is showing or not
    self.nicknameRow:ClearAnchors()
    self.nicknameRow:SetAnchor(TOPLEFT, self.tagsRow, BOTTOMLEFT)
    if showEdit then
        self.nicknameRow:SetAnchor(TOPRIGHT, self.editButton, BOTTOMRIGHT, 0, 10)
    else
        self.nicknameRow:SetAnchor(TOPRIGHT, self.tagsRow, BOTTOMRIGHT, 0, 10)
    end
    self.removeButton:SetHidden(not showRemove)
    self.submitButton:SetHidden(not showSubmit)

    local enableButtons = self.hasHouses and not self.isListingOperationOnCooldown and not permissionsChangesPending
    self.editButton:SetEnabled(enableButtons and enableEdit)
    self.removeButton:SetEnabled(enableButtons)
    self.renameButton:SetEnabled(enableButtons)
    self.submitButton:SetEnabled(enableButtons and enableSubmit)

    if permissionsChangesPending then
        self.visitorAccessLoadingIcon:Show()
    else
        self.visitorAccessLoadingIcon:Hide()
    end

    if lockReasonText then
        self.lockReasonLabel:SetText(zo_iconTextFormat("EsoUI/Art/Miscellaneous/locked_disabled.dds", 16, 16, lockReasonText))
        self.lockReasonLabel:SetHidden(false)
    else
        self.lockReasonLabel:SetHidden(true)
    end
end

function ZO_HouseToursManageListings_Keyboard:RefreshHouseDropdown()
    self.houseDropdown:ClearItems()
    local sortedListingData = HOUSE_TOURS_PLAYER_LISTINGS_MANAGER:GetSortedListingData()
    local selectedEntry = nil
    local selectedData = HOUSE_TOURS_PLAYER_LISTINGS_MANAGER:GetListingDataByCollectibleId(self.selectedCollectibleId)

    for _, listingData in ipairs(sortedListingData) do
        local houseName
        if listingData:IsListed() then
            houseName = zo_iconTextFormat("EsoUI/Art/HouseTours/houseTours_listed.dds", "100%", "100%", listingData:GetFormattedHouseName())
        elseif listingData:IsPrimaryResidence() then
            houseName = zo_iconTextFormat("EsoUI/Art/Collections/PrimaryHouse.dds", "100%", "100%", listingData:GetFormattedHouseName())
        elseif listingData:IsCollectibleFavorite() then
            houseName = zo_iconTextFormat("EsoUI/Art/Collections/Favorite_StarOnly.dds", "100%", "100%", listingData:GetFormattedHouseName())
        else
            houseName = listingData:GetFormattedHouseName()
        end

        local entry = self.houseDropdown:CreateItemEntry(houseName, function(comboBox, entryText, entry) self:SetSelectedHouse(entry.data:GetCollectibleId()) end)
        entry.data = listingData
        if selectedData and selectedData:Equals(listingData) then
            selectedEntry = entry
        end

        self.houseDropdown:AddItem(entry, ZO_COMBOBOX_SUPPRESS_UPDATE)
    end

    --Attempt to reselect the previously selected entry
    local IGNORE_CALLBACK = true
    if selectedEntry then
        self.houseDropdown:SelectItem(selectedEntry, IGNORE_CALLBACK)
    else
        self.houseDropdown:SelectFirstItem()
    end
end

function ZO_HouseToursManageListings_Keyboard:RefreshNickname()
    local selectedListingData = HOUSE_TOURS_PLAYER_LISTINGS_MANAGER:GetListingDataByCollectibleId(self.selectedCollectibleId)
    if self.hasHouses and selectedListingData then
        local formattedNickname = selectedListingData:GetFormattedNickname()
        self.houseTileNicknameLabel:SetText(formattedNickname)
        self.currentNicknameLabel:SetText(formattedNickname)
    end
end

function ZO_HouseToursManageListings_Keyboard:RenameSelectedHouse()
    ZO_CollectionsBook.ShowRenameDialog(self.selectedCollectibleId)
end

function ZO_HouseToursManageListings_Keyboard:ManageSpecificHouse(houseId)
    local collectibleId = GetCollectibleIdForHouse(houseId)

    if self:IsShowing() then
        -- Switch to the specified house.
        self:SetSelectedHouse(collectibleId)
    else
        -- Queue the specified house for selection and show the UI.
        self.queuedSelectedCollectibleId = collectibleId
        GROUP_MENU_KEYBOARD:ShowCategoryByData(self:GetActivityFinderCategoryData())
    end
end

function ZO_HouseToursManageListings_Keyboard.OnControlInitialized(control)
    HOUSE_TOURS_MANAGE_LISTINGS_KEYBOARD = ZO_HouseToursManageListings_Keyboard:New(control)
end

do
    local FURNITURE_COUNT_TEXTURE = "EsoUI/Art/HouseTours/houseTours_furnitureCount.dds"

    function ZO_HouseToursManageListings_Keyboard.OnSubmitDialogInitialized(control)
        ZO_Dialogs_RegisterCustomDialog("HOUSE_TOURS_SUBMIT_LISTING_KEYBOARD",
        {
            customControl = control,
            setup = function(dialog, data)
                local selectedListingData = data.selectedListingData
                if selectedListingData then
                    local houseTileControl = dialog:GetNamedChild("HouseTile")
                    houseTileControl:SetHandler("OnMouseEnter", function()
                        ClearTooltip(InformationTooltip)
                        InitializeTooltip(InformationTooltip, houseTileControl, RIGHT, -5)
                        local DEFAULT_FONT = ""
                        local tagsText = ZO_FormatHouseToursTagsText(data.tags)
                        InformationTooltip:AddLine(zo_strformat(SI_HOUSE_TOURS_LISTING_TAGS_TOOLTIP_FORMATTER, ZO_SELECTED_TEXT:Colorize(tagsText)), DEFAULT_FONT, ZO_NORMAL_TEXT:UnpackRGBA())
                    end)

                    houseTileControl:SetHandler("OnMouseExit", function()
                        ClearTooltip(InformationTooltip)
                    end)

                    local background = houseTileControl:GetNamedChild("Background")
                    local nicknameLabel = houseTileControl:GetNamedChild("Nickname")
                    local houseNameLabel = houseTileControl:GetNamedChild("HouseName")
                    local furnitureCountLabel = houseTileControl:GetNamedChild("FurnitureCount")
                    local displayNameLabel = houseTileControl:GetNamedChild("DisplayName")

                    background:SetTexture(selectedListingData:GetBackgroundImage())
                    houseNameLabel:SetText(selectedListingData:GetFormattedHouseName())
                    nicknameLabel:SetText(selectedListingData:GetFormattedNickname())

                    local furnitureCountText
                    local furnitureCount = selectedListingData:GetFurnitureCount()
                    if furnitureCount ~= nil then
                        furnitureCountText = zo_iconTextFormat(FURNITURE_COUNT_TEXTURE, 32, 32, furnitureCount)
                    else
                        furnitureCountText = zo_iconTextFormat(FURNITURE_COUNT_TEXTURE, 32, 32, GetString(SI_HOUSE_TOURS_LISTING_FURNITURE_COUNT_UNKNOWN))
                    end
                    furnitureCountLabel:SetText(furnitureCountText)

                    displayNameLabel:SetText(selectedListingData:GetFormattedOwnerDisplayName())
                end
            end,
            title =
            {
                text = SI_HOUSE_TOURS_SUBMIT_HOME,
            },
            mainText =
            {
                text = SI_HOUSE_TOURS_SUBMIT_DIALOG_TEXT,
            },
            buttons =
            {
                {
                    control = control:GetNamedChild("Confirm"),
                    keybind = "DIALOG_PRIMARY",
                    text = SI_DIALOG_CONFIRM,
                    callback = function(dialog)
                        local data = dialog.data
                        if data and data.selectedListingData and data.tags then
                            local houseId = data.selectedListingData:GetHouseId()
                            RequestCreateHouseToursListing(houseId, unpack(data.tags))
                        end
                    end,
                },
                {
                    control = control:GetNamedChild("Cancel"),
                    keybind = "DIALOG_NEGATIVE",
                    text = SI_DIALOG_CANCEL,
                },
            }
        })
    end
end