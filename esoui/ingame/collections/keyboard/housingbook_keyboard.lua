--Layout constants--
local BACKGROUND_IMAGE_FILE_WIDTH = 1024
local BACKGROUND_IMAGE_FILE_HEIGHT = 512
local BACKGROUND_IMAGE_CONTENT_WIDTH = 700
local BACKGROUND_IMAGE_CONTENT_HEIGHT = 350
local INFO_PANEL_WIDTH = 614
ZO_HOUSING_BOOK_IMAGE_TEXTURE_COORD_RIGHT = BACKGROUND_IMAGE_CONTENT_WIDTH / BACKGROUND_IMAGE_FILE_WIDTH
ZO_HOUSING_BOOK_IMAGE_TEXTURE_COORD_BOTTOM = BACKGROUND_IMAGE_CONTENT_HEIGHT / BACKGROUND_IMAGE_FILE_HEIGHT
ZO_HOUSING_BOOK_IMAGE_HEIGHT = (INFO_PANEL_WIDTH / BACKGROUND_IMAGE_CONTENT_WIDTH) * BACKGROUND_IMAGE_CONTENT_HEIGHT

--Housing Book

local HousingBook_Keyboard = ZO_SpecializedCollectionsBook_Keyboard:Subclass()

function HousingBook_Keyboard:InitializeControls()
    ZO_SpecializedCollectionsBook_Keyboard.InitializeControls(self)
    
    local contents = self.control:GetNamedChild("Contents")
    self.nicknameLabel = contents:GetNamedChild("Nickname")

    local scrollSection = contents:GetNamedChild("ScrollContainer"):GetNamedChild("ScrollChild")
    self.locationLabel = scrollSection:GetNamedChild("LocationLabel")
    self.houseTypeLabel = scrollSection:GetNamedChild("HouseTypeLabel")
    self.primaryResidenceLabel = scrollSection:GetNamedChild("PrimaryResidenceLabel")
    self.supportsWeatherControlLabel = scrollSection:GetNamedChild("SupportsWeatherControlLabel")
    self.recommendCountLabel = scrollSection:GetNamedChild("RecommendCountLabel")
    self.hintLabel = scrollSection:GetNamedChild("HintLabel")

    local buttons = contents:GetNamedChild("HousingInteractButtons")
    self.travelToHouseButton = buttons:GetNamedChild("TravelToHouse")
    self.changeNicknameButton = buttons:GetNamedChild("ChangeNickname")
    self.linkInChatButton = buttons:GetNamedChild("LinkInChat")

    self.previewHouseButton = contents:GetNamedChild("PreviewHouseButton")
end

function HousingBook_Keyboard:InitializeEvents()
    ZO_SpecializedCollectionsBook_Keyboard.InitializeEvents(self)

    local function OnDataUpdated()
        self.categoryLayoutObject:BuildData()
        self:RefreshList()
    end
    
    ZO_COLLECTIBLE_DATA_MANAGER:RegisterCallback("PrimaryResidenceSet", OnDataUpdated)
    ZO_COLLECTIBLE_DATA_MANAGER:RegisterCallback("OnCollectibleUserFlagsUpdated", OnDataUpdated)

    local function OnZoneChanged()
        self.refreshGroups:RefreshSingle("ZoneChanged")
    end
    self.control:RegisterForEvent(EVENT_PLAYER_ACTIVATED, OnZoneChanged)
    self.control:RegisterForEvent(EVENT_ZONE_CHANGED, OnZoneChanged)

    local function OnHouseToursStatusUpdated()
        if self.keybindStripDescriptor then
            KEYBIND_STRIP:UpdateKeybindButtonGroup(self.keybindStripDescriptor)
        end
    end
    self.control:RegisterForEvent(EVENT_HOUSE_TOURS_STATUS_UPDATED, OnHouseToursStatusUpdated)
end

function HousingBook_Keyboard:InitializeKeybindStripDescriptors()
    self.keybindStripDescriptor =
    {
        alignment = KEYBIND_STRIP_ALIGN_CENTER,
        -- Add/Remove Favorite
        {
            name = function()
                local data = self:GetSelectedData()
                return data:IsFavorite() and GetString(SI_COLLECTIBLE_ACTION_REMOVE_FAVORITE) or GetString(SI_COLLECTIBLE_ACTION_ADD_FAVORITE)
            end,
            keybind = "UI_SHORTCUT_TERTIARY",
            callback = function()
                local data = self:GetSelectedData()
                local shouldSetAsFavorite = not data:IsFavorite()
                SetOrClearCollectibleUserFlag(data:GetId(), COLLECTIBLE_USER_FLAG_FAVORITE, shouldSetAsFavorite)
            end,
            visible = function()
                local data = self:GetSelectedData()
                return data:IsUnlocked()
            end,
        },
        -- Set as Primary Residence
        {
            name = GetString(SI_HOUSING_FURNITURE_SETTINGS_GENERAL_PRIMARY_RESIDENCE_BUTTON_TEXT),
            keybind = "UI_SHORTCUT_SECONDARY",
            callback = function()
                local data = self:GetSelectedData()
                COLLECTIONS_BOOK_SINGLETON:SetPrimaryResidence(data:GetReferenceId())
            end,
            visible = function()
                local data = self:GetSelectedData()
                return data:IsUnlocked() and not data:IsPrimaryResidence()
            end,
        },
        -- Tour Home
        {
            name = GetString(SI_COLLECTIBLE_ACTION_TOUR_THIS_HOME),
            keybind = "UI_SHORTCUT_QUATERNARY",
            callback = function()
                local data = self:GetSelectedData()
                local houseId = data:GetReferenceId()
                --Order matters. Attempt to browse to the house before trying to show the category in the activity finder.
                HOUSE_TOURS_SEARCH_RESULTS_KEYBOARD:BrowseToSpecificHouse(houseId)
                GROUP_MENU_KEYBOARD:ShowCategoryByData(HOUSE_TOURS_SEARCH_RESULTS_KEYBOARD:GetActivityFinderCategoryData(HOUSE_TOURS_LISTING_TYPE_BROWSE))
            end,
            visible = ZO_IsHouseToursEnabled,
        }
    }
end

function HousingBook_Keyboard:RefreshDetails()
    ZO_SpecializedCollectionsBook_Keyboard.RefreshDetails(self)
    local collectibleData = self.navigationTree:GetSelectedData()

    if collectibleData then
        local nickname = collectibleData:GetFormattedNickname()
        local hasNickname = nickname ~= ""
        if hasNickname then
            self.nicknameLabel:SetText(nickname)
        end
        self.nicknameLabel:SetHidden(not hasNickname)

        local houseFlags = collectibleData:GetHouseFlags()
        local hasWeatherControlSupport = ZO_FlagHelpers.MaskHasFlag(houseFlags, HOUSE_FLAGS_SUPPORTS_WEATHER_CONTROL)
        local hasWeatherControlSupportString = hasWeatherControlSupport and GetString(SI_YES) or GetString(SI_NO)
        self.supportsWeatherControlLabel:SetText(zo_strformat(SI_HOUSING_BOOK_SUPPORTS_WEATHER_CONTROL_FORMATTER, hasWeatherControlSupportString))

        local houseId = collectibleData:GetReferenceId()
        local recommendCount = GetNumHouseToursPlayerListingRecommendations(houseId)

        --We need to re-anchor the primaryResidenceLabel depending on whether or not we will be showing the recommendation count
        self.primaryResidenceLabel:ClearAnchors()

        if recommendCount > 0 then
            self.primaryResidenceLabel:SetAnchor(TOPLEFT, self.recommendCountLabel, BOTTOMLEFT, 0, 5)
            self.recommendCountLabel:SetText(zo_strformat(SI_HOUSING_BOOK_HOUSE_TOURS_RECOMMEND_COUNT_FORMATTER, ZO_CommaDelimitNumber(recommendCount)))
            self.recommendCountLabel:SetHidden(false)
        else
            self.primaryResidenceLabel:SetAnchor(TOPLEFT, self.houseTypeLabel, BOTTOMLEFT, 0, 5)
            self.recommendCountLabel:SetHidden(true)
        end

        local isUnlocked = collectibleData:IsUnlocked()
        local canJumpToHouse = CanJumpToHouseFromCurrentLocation()
        self.locationLabel:SetText(zo_strformat(SI_HOUSING_BOOK_LOCATION_FORMATTER, collectibleData:GetHouseLocation()))
        self.houseTypeLabel:SetText(zo_strformat(SI_HOUSING_BOOK_HOUSE_TYPE_FORMATTER, GetString("SI_HOUSECATEGORYTYPE", collectibleData:GetHouseCategoryType())))

        local hintText = nil
        local primaryResidenceText = nil
        if not canJumpToHouse then
            -- Show Inaccessible Hint.
            local disableReason = isUnlocked and GetString(SI_COLLECTIONS_CANNOT_JUMP_TO_HOUSE_FROM_LOCATION) or GetString(SI_COLLECTIONS_CANNOT_PREVIEW_HOUSE_FROM_LOCATION)
            hintText = ZO_ERROR_COLOR:Colorize(disableReason)
        elseif isUnlocked then
            -- Show Primary Residence.
            local isPrimaryResidence = collectibleData:IsPrimaryResidence() and GetString(SI_YES) or GetString(SI_NO)
            primaryResidenceText = zo_strformat(SI_HOUSING_BOOK_PRIMARY_RESIDENCE_FORMATTER, isPrimaryResidence)
        else
            -- Show Acquisition Hint.
            hintText = zo_strformat(SI_COLLECTIBLE_ACQUIRE_HINT_FORMATTER, collectibleData:GetHint())
        end

        -- Update the Hint label.
        if hintText then
            self.hintLabel:SetText(hintText)
            self.hintLabel:SetHidden(false)
        else
            self.hintLabel:SetHidden(true)
        end

        -- Update the Primary Residence label.
        if primaryResidenceText then
            self.primaryResidenceLabel:SetText(primaryResidenceText)
            self.primaryResidenceLabel:SetHidden(false)
        else
            self.primaryResidenceLabel:SetHidden(true)
        end

        -- Reanchor the Supports Weather Control label to the bottommost label.
        self.supportsWeatherControlLabel:ClearAnchors()
        if primaryResidenceText then
            self.supportsWeatherControlLabel:SetAnchor(TOPLEFT, self.primaryResidenceLabel, BOTTOMLEFT, 0, 5)
        elseif recommendCount > 0 then
            self.supportsWeatherControlLabel:SetAnchor(TOPLEFT, self.recommendCountLabel, BOTTOMLEFT, 0, 5)
        else
            self.supportsWeatherControlLabel:SetAnchor(TOPLEFT, self.houseTypeLabel, BOTTOMLEFT, 0, 5)
        end

        self.travelToHouseButton:SetHidden(not isUnlocked)
        self.travelToHouseButton:SetEnabled(canJumpToHouse)

        self.changeNicknameButton:SetHidden(not isUnlocked)

        self.linkInChatButton:SetHidden(not isUnlocked)

        self.previewHouseButton:SetHidden(isUnlocked)
        self.previewHouseButton:SetEnabled(canJumpToHouse)
    end
end

function HousingBook_Keyboard:RenameCurrentHouse()
    local collectibleData = self.navigationTree:GetSelectedData()
    if collectibleData then
        ZO_CollectionsBook.ShowRenameDialog(collectibleData:GetId())
    end
end

function HousingBook_Keyboard:LinkInChat()
    local collectibleData = self.navigationTree:GetSelectedData()
    if not collectibleData then
        return
    end

    local houseId = collectibleData:GetReferenceId()
    local ownerDisplayName = GetDisplayName()
    ZO_HousingBook_LinkHouseInChat(houseId, ownerDisplayName)
end

function HousingBook_Keyboard:RequestJumpToCurrentHouse()
    local collectibleData = self.navigationTree:GetSelectedData()
    if collectibleData then
        local houseId = collectibleData:GetReferenceId()
        if collectibleData:IsLocked() then
            -- Preview, behavior will always be inside
            RequestJumpToHouse(houseId)
            SCENE_MANAGER:ShowBaseScene()
        else
            ClearMenu()

            AddMenuItem(GetString(SI_HOUSING_BOOK_ACTION_TRAVEL_TO_HOUSE_INSIDE), function()
                local TRAVEL_INSIDE = false
                RequestJumpToHouse(houseId, TRAVEL_INSIDE)
                SCENE_MANAGER:ShowBaseScene()
            end)
            AddMenuItem(GetString(SI_HOUSING_BOOK_ACTION_TRAVEL_TO_HOUSE_OUTSIDE), function()
                local TRAVEL_OUTSIDE = true
                RequestJumpToHouse(houseId, TRAVEL_OUTSIDE)
                SCENE_MANAGER:ShowBaseScene()
            end)

            ShowMenu(self.travelToHouseButton)
        end
    end
end

function HousingBook_Keyboard:GetCategoryFilterFunctions()
    return { ZO_CollectibleCategoryData.IsHousingCategory }
end

function HousingBook_Keyboard:IsCollectibleRelevant(collectibleData)
    return collectibleData:IsHouse()
end

function HousingBook_Keyboard:TreeEntry_OnMouseUp(control, upInside, button)
    if button == MOUSE_BUTTON_INDEX_RIGHT and upInside then
        local nodeData = control.node.data

        ClearMenu()
        if nodeData:IsUnlocked() then
            local entryString = nodeData:IsFavorite() and GetString(SI_COLLECTIBLE_ACTION_REMOVE_FAVORITE) or GetString(SI_COLLECTIBLE_ACTION_ADD_FAVORITE)
            local shouldSetAsFavorite = not nodeData:IsFavorite()
            AddMenuItem(entryString, function()
                SetOrClearCollectibleUserFlag(nodeData:GetId(), COLLECTIBLE_USER_FLAG_FAVORITE, shouldSetAsFavorite)
            end)

            if not nodeData:IsPrimaryResidence() then
                AddMenuItem(GetString(SI_HOUSING_FURNITURE_SETTINGS_GENERAL_PRIMARY_RESIDENCE_BUTTON_TEXT), function()
                    COLLECTIONS_BOOK_SINGLETON:SetPrimaryResidence(nodeData:GetReferenceId())
                end)
            end
        end
        ShowMenu(control)
    else
        ZO_SpecializedCollectionsBook_Keyboard.TreeEntry_OnMouseUp(self, control, upInside, button)
    end
end

function ZO_HousingBook_Keyboard_OnRequestJumpToHouseClicked(control)
    HOUSING_BOOK_KEYBOARD:RequestJumpToCurrentHouse()
end

function ZO_HousingBook_Keyboard_OnChangNicknameClicked(control)
    HOUSING_BOOK_KEYBOARD:RenameCurrentHouse()
end

function ZO_HousingBook_Keyboard_OnLinkInChatClicked(control)
    HOUSING_BOOK_KEYBOARD:LinkInChat()
end

function ZO_HousingBook_Keyboard_OnInitialized(control)
    HOUSING_BOOK_KEYBOARD = HousingBook_Keyboard:New(control, "housingBook", ZO_SpecializedCollectionsBook_Keyboard_CategoryLayout_UnlockState)
end