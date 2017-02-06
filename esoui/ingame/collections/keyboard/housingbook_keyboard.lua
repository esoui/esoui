--Layout constants--
local BACKGROUND_IMAGE_FILE_WIDTH = 1024
local BACKGROUND_IMAGE_FILE_HEIGHT = 512
local BACKGROUND_IMAGE_CONTENT_WIDTH = 700
local BACKGROUND_IMAGE_CONTENT_HEIGHT = 350
local INFO_PANEL_WIDTH = 614
ZO_HOUSING_BOOK_IMAGE_TEXTURE_COORD_RIGHT = BACKGROUND_IMAGE_CONTENT_WIDTH / BACKGROUND_IMAGE_FILE_WIDTH
ZO_HOUSING_BOOK_IMAGE_TEXTURE_COORD_BOTTOM = BACKGROUND_IMAGE_CONTENT_HEIGHT / BACKGROUND_IMAGE_FILE_HEIGHT
ZO_HOUSING_BOOK_IMAGE_HEIGHT = (INFO_PANEL_WIDTH / BACKGROUND_IMAGE_CONTENT_WIDTH) * BACKGROUND_IMAGE_CONTENT_HEIGHT

local NOTIFICATIONS_PROVIDER = NOTIFICATIONS:GetCollectionsProvider()

--Housing Book

local HousingBook_Keyboard = ZO_SpecializedCollectionsBook_Keyboard:Subclass()

function HousingBook_Keyboard:New(...)
    return ZO_SpecializedCollectionsBook_Keyboard.New(self, ...)
end

function HousingBook_Keyboard:InitializeControls()
    ZO_SpecializedCollectionsBook_Keyboard.InitializeControls(self)
    
    local contents = self.control:GetNamedChild("Contents")
    self.nicknameLabel = contents:GetNamedChild("Nickname")

    local scrollSection = contents:GetNamedChild("ScrollContainer"):GetNamedChild("ScrollChild")
    self.locationLabel = scrollSection:GetNamedChild("LocationLabel")
    self.houseTypeLabel = scrollSection:GetNamedChild("HouseTypeLabel")
    self.primaryResidenceLabel = scrollSection:GetNamedChild("PrimaryResidenceLabel")
    self.hintLabel = scrollSection:GetNamedChild("HintLabel")

    local buttons = contents:GetNamedChild("HousingInteractButtons")
    self.travelToHouseButton = buttons:GetNamedChild("TravelToHouse")
    self.changeNicknameButton = buttons:GetNamedChild("ChangeNickname")

    self.previewHouseButton = contents:GetNamedChild("PreviewHouseButton")
end

function HousingBook_Keyboard:InitializeEvents()
    ZO_SpecializedCollectionsBook_Keyboard.InitializeEvents(self)
    self.control:RegisterForEvent(EVENT_HOUSING_PRIMARY_RESIDENCE_SET, function(_, ...) self:OnPrimaryResidenceSet(...) end)
end

function HousingBook_Keyboard:DoesCollectibleHaveAlert(data)
    return IsCollectibleNew(data.collectibleId)
end

function HousingBook_Keyboard:OnPrimaryResidenceSet(houseId)
    self:RefreshList()
end

function HousingBook_Keyboard:SortCollectibleData(collectibleData)
    local primaryHouseId = GetHousingPrimaryHouse()
    table.sort(collectibleData, function(a, b)
        if primaryHouseId ~= 0 then
            local houseIdA = GetCollectibleReferenceId(a.collectibleId)
            local houseIdB = GetCollectibleReferenceId(b.collectibleId)

            if primaryHouseId == houseIdA then
                return true
            elseif primaryHouseId == houseIdB then
                return false
            end
        end

        return a.name < b.name
    end)
end

function HousingBook_Keyboard:SetupAdditionalCollectibleData(data, collectibleId)
    local houseFoundInZoneId = GetHouseFoundInZoneId(data.referenceId)
    data.location = GetZoneNameById(houseFoundInZoneId)
    data.houseCategoryType = GetHouseCategoryType(data.referenceId)
    data.isPrimaryResidence = IsPrimaryHouse(data.referenceId)

    if data.hint == "" then
        data.hint = GetString(SI_HOUSING_BOOK_AVAILABLE_FOR_PURCHASE)
    end
end

function HousingBook_Keyboard:RefreshDetails()
    ZO_SpecializedCollectionsBook_Keyboard.RefreshDetails(self)
    local data = self.navigationTree:GetSelectedData()

    if data then
        local hasNickname = data.nickname ~= ""
        if hasNickname then
            self.nicknameLabel:SetText(ZO_CachedStrFormat(SI_TOOLTIP_COLLECTIBLE_NICKNAME, data.nickname))
        end
        self.nicknameLabel:SetHidden(not hasNickname)
        
        self.locationLabel:SetText(zo_strformat(SI_HOUSING_BOOK_LOCATION_FORMATTER, data.location))
        self.houseTypeLabel:SetText(zo_strformat(SI_HOUSING_BOOK_HOUSE_TYPE_FORMATTER, GetString("SI_HOUSECATEGORYTYPE", data.houseCategoryType)))
        if data.unlocked then
            local isPrimaryResidence = data.isPrimaryResidence and GetString(SI_YES) or GetString(SI_NO)
            self.primaryResidenceLabel:SetText(zo_strformat(SI_HOUSING_BOOK_PRIMARY_RESIDENCE_FORMATTER, isPrimaryResidence))
            
            self.primaryResidenceLabel:SetHidden(false)
            self.hintLabel:SetHidden(true)
        else
            self.hintLabel:SetText(data.hint)
            
            self.hintLabel:SetHidden(false)
            self.primaryResidenceLabel:SetHidden(true)
        end

        self.travelToHouseButton:SetHidden(not data.unlocked)
        self.changeNicknameButton:SetHidden(not data.unlocked)
        self.previewHouseButton:SetHidden(data.unlocked)
    end
end

function HousingBook_Keyboard:RenameCurrentHouse()
    local data = self.navigationTree:GetSelectedData()
    if data then
        ZO_Dialogs_ShowDialog("COLLECTIONS_INVENTORY_RENAME_COLLECTIBLE", { collectibleId = data.collectibleId })
    end
end

function HousingBook_Keyboard:RequestJumpToCurrentHouse()
    local data = self.navigationTree:GetSelectedData()
    if data then
        RequestJumpToHouse(data.referenceId)
    end
end

function ZO_HousingBook_Keyboard_OnRequestJumpToHouseClicked(control)
    HOUSING_BOOK_KEYBOARD:RequestJumpToCurrentHouse()
    SCENE_MANAGER:ShowBaseScene()
end

function ZO_HousingBook_Keyboard_OnChangNicknameClicked(control)
    HOUSING_BOOK_KEYBOARD:RenameCurrentHouse()
end

function ZO_HousingBook_Keyboard_OnInitialized(control)
    HOUSING_BOOK_KEYBOARD = HousingBook_Keyboard:New(control, "housingBook", COLLECTIBLE_CATEGORY_TYPE_HOUSE)
end