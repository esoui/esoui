local g_localPlayerDisplayName = GetDisplayName()

-- House Listing Base Data

ZO_HouseToursListingData_Base = ZO_InitializingObject:Subclass()

function ZO_HouseToursListingData_Base:GetCollectibleData()
    local collectibleId = self:GetCollectibleId()
    return ZO_COLLECTIBLE_DATA_MANAGER:GetCollectibleDataById(collectibleId)
end

function ZO_HouseToursListingData_Base:GetHouseName()
    local collectibleData = self:GetCollectibleData()
    if collectibleData then
        local houseName = collectibleData:GetName()
        return houseName
    end

    return ""
end

function ZO_HouseToursListingData_Base:GetFormattedHouseName()
    local collectibleData = self:GetCollectibleData()
    if collectibleData then
        return collectibleData:GetFormattedName()
    end

    return ""
end

function ZO_HouseToursListingData_Base:GetFormattedNickname()
    local nickname = self:GetNickname()
    if nickname ~= "" then
        return ZO_CachedStrFormat(SI_TOOLTIP_COLLECTIBLE_NICKNAME, nickname)
    else
        return ""
    end
end

function ZO_HouseToursListingData_Base:GetBackgroundImage()
    local collectibleData = self:GetCollectibleData()
    if collectibleData then
        if IsInGamepadPreferredMode() then
            return collectibleData:GetGamepadBackgroundImage()
        else
            return collectibleData:GetKeyboardBackgroundImage()
        end
    end
end

function ZO_HouseToursListingData_Base:GetFormattedOwnerDisplayName()
    return ZO_FormatUserFacingDisplayName(self:GetOwnerDisplayName())
end

function ZO_HouseToursListingData_Base:GetCollectibleIcon()
    local collectibleData = self:GetCollectibleData()
    if collectibleData then
        return collectibleData:GetIcon()
    end
end

function ZO_HouseToursListingData_Base:GetFormattedTagsText()
    local tags = self:GetTags()
    return ZO_FormatHouseToursTagsText(tags)
end

function ZO_HouseToursListingData_Base:GetHouseId()
    if not self.houseId then
        local collectibleData = self:GetCollectibleData()
        self.houseId = collectibleData and collectibleData:GetReferenceId() or 0
    end

    return self.houseId
end

function ZO_HouseToursListingData_Base:GetHouseLink()
    return ZO_HousingBook_GetHouseLink(self:GetHouseId(), self:GetOwnerDisplayName())
end

ZO_HouseToursListingData_Base.GetCollectibleId = ZO_HouseToursListingData_Base:MUST_IMPLEMENT()
ZO_HouseToursListingData_Base.GetFurnitureCount = ZO_HouseToursListingData_Base:MUST_IMPLEMENT()
ZO_HouseToursListingData_Base.GetTags = ZO_HouseToursListingData_Base:MUST_IMPLEMENT()
ZO_HouseToursListingData_Base.GetNickname = ZO_HouseToursListingData_Base:MUST_IMPLEMENT()
ZO_HouseToursListingData_Base.GetOwnerDisplayName = ZO_HouseToursListingData_Base:MUST_IMPLEMENT()
ZO_HouseToursListingData_Base.IsListed = ZO_HouseToursListingData_Base:MUST_IMPLEMENT()

-- House Listing Search Data
ZO_HouseToursListingSearchData = ZO_HouseToursListingData_Base:Subclass()

function ZO_HouseToursListingSearchData:Initialize(listingType, listingIndex)
    self.listingType = listingType
    self.listingIndex = listingIndex
end

function ZO_HouseToursListingSearchData:GetListingType()
    return self.listingType
end

function ZO_HouseToursListingSearchData:GetListingIndex()
    return self.listingIndex
end

function ZO_HouseToursListingSearchData:GetCollectibleId()
    return GetHouseToursListingCollectibleIdByIndex(self.listingType, self.listingIndex)
end

function ZO_HouseToursListingSearchData:GetFurnitureCount()
    return GetHouseToursListingFurnitureCountByIndex(self.listingType, self.listingIndex)
end

function ZO_HouseToursListingSearchData:GetTags()
    return { GetHouseToursListingTagsByIndex(self.listingType, self.listingIndex) }
end

function ZO_HouseToursListingSearchData:GetNickname()
    local nickname = GetHouseToursListingNicknameByIndex(self.listingType, self.listingIndex)
    --If there is no nickname, try to grab the default nickname for the house instead
    if nickname == "" then
        local collectibleData = self:GetCollectibleData()
        if collectibleData then
            nickname = collectibleData:GetDefaultNickname()
        end
    end

    return nickname
end

function ZO_HouseToursListingSearchData:GetOwnerDisplayName()
    return GetHouseToursListingOwnerDisplayNameByIndex(self.listingType, self.listingIndex)
end

function ZO_HouseToursListingSearchData:IsOwnedByLocalPlayer()
    return self:GetOwnerDisplayName() == GetDisplayName()
end

function ZO_HouseToursListingSearchData:IsOwnedByFriend()
    return IsFriend(self:GetOwnerDisplayName())
end

function ZO_HouseToursListingSearchData:IsOwnedByGuildMember()
    local ownerDisplayName = self:GetOwnerDisplayName()
    return ownerDisplayName ~= g_localPlayerDisplayName and IsGuildMate(ownerDisplayName)
end

function ZO_HouseToursListingSearchData:CanFavorite()
    return not self:IsOwnedByLocalPlayer()
end

function ZO_HouseToursListingSearchData:IsListed()
    return IsHouseToursListingListedByIndex(self:GetListingType(), self:GetListingIndex())
end

function ZO_HouseToursListingSearchData:CanReport()
    return not self:IsOwnedByLocalPlayer() and self:IsListed()
end

function ZO_HouseToursListingSearchData:IsFavorite()
    return IsHouseToursListingFavoriteByIndex(self:GetListingType(), self:GetListingIndex())
end

function ZO_HouseToursListingSearchData:RequestAddFavorite()
    RequestUpdateHouseToursListingFavoriteStatusByIndex(self:GetListingType(), self:GetListingIndex(), HOUSE_TOURS_FAVORITE_OPERATION_TYPE_CREATE)
end

function ZO_HouseToursListingSearchData:RequestRemoveFavorite()
    RequestUpdateHouseToursListingFavoriteStatusByIndex(self:GetListingType(), self:GetListingIndex(), HOUSE_TOURS_FAVORITE_OPERATION_TYPE_DELETE)
end

-- House Player Listing Data
ZO_HouseToursPlayerListingData = ZO_HouseToursListingData_Base:Subclass()

function ZO_HouseToursPlayerListingData:Initialize(collectibleId)
    self.collectibleId = collectibleId
end

function ZO_HouseToursPlayerListingData:GetCollectibleId()
    return self.collectibleId
end

function ZO_HouseToursPlayerListingData:GetFurnitureCount()
    local houseId = self:GetHouseId()
    return GetHouseFurnitureCount(houseId)
end

function ZO_HouseToursPlayerListingData:GetTags()
    return { GetHouseToursPlayerListingTagsByHouseId(self:GetHouseId()) }
end

function ZO_HouseToursPlayerListingData:GetNickname()
    local collectibleData = self:GetCollectibleData()
    if collectibleData then
        return collectibleData:GetNickname()
    end
    return ""
end

function ZO_HouseToursPlayerListingData:GetDefaultNickname()
    local collectibleData = self:GetCollectibleData()
    if collectibleData then
        return collectibleData:GetDefaultNickname()
    end
    return ""
end

function ZO_HouseToursPlayerListingData:GetOwnerDisplayName()
    return GetDisplayName()
end

function ZO_HouseToursPlayerListingData:GetNumRecommendations()
    return GetNumHouseToursPlayerListingRecommendations(self:GetHouseId())
end

function ZO_HouseToursPlayerListingData:IsListed()
    return IsHouseListed(self:GetHouseId())
end

do
    local lockReasonTextInvalidPermissions = nil

    function ZO_HouseToursPlayerListingData:GetLockReasonText()
        local lockReasonText = nil

        if not self:IsListed() then
            if not self:HasValidPermissions() then
                -- If we get here, the default visitor access is set to something that can't be listed.
                if not lockReasonTextInvalidPermissions then
                    local allowedDefaultAcccessSettingStrings = {}
                    local allDefaultAccessSettings = HOUSE_SETTINGS_MANAGER:GetAllDefaultAccessSettings()

                    -- Generate a comma separated list of all of the allowed default visitor access values.
                    for accessSetting = HOUSE_PERMISSION_DEFAULT_ACCESS_SETTING_ITERATION_BEGIN, HOUSE_PERMISSION_DEFAULT_ACCESS_SETTING_ITERATION_END do
                        if IsHouseDefaultAccessSettingValidForHouseToursListing(accessSetting) then
                            table.insert(allowedDefaultAcccessSettingStrings, allDefaultAccessSettings[accessSetting])
                        end
                    end

                    -- Cache the "Invalid Permissions" Lock Reason text.
                    local allowedSettingsText = ZO_GenerateCommaSeparatedListWithOr(allowedDefaultAcccessSettingStrings)
                    lockReasonTextInvalidPermissions = zo_strformat(SI_HOUSE_TOURS_SUBMIT_LOCK_REASON_VISITOR_ACCESS, allowedSettingsText)
                end

                lockReasonText = lockReasonTextInvalidPermissions
            end
        end

        return lockReasonText
    end
end

function ZO_HouseToursPlayerListingData:HasValidPermissions()
    if not self:IsListed() then
        local accessSetting = HOUSE_SETTINGS_MANAGER:GetDefaultHousingPermission(self:GetHouseId())
        return IsHouseDefaultAccessSettingValidForHouseToursListing(accessSetting)
    end

    return true
end

function ZO_HouseToursPlayerListingData:IsPrimaryResidence()
    local collectibleData = self:GetCollectibleData()
    if collectibleData then
        return collectibleData:IsPrimaryResidence()
    end

    return false
end

function ZO_HouseToursPlayerListingData:IsCollectibleFavorite()
    local collectibleData = self:GetCollectibleData()
    if collectibleData then
        return collectibleData:IsFavorite()
    end

    return false
end

function ZO_HouseToursPlayerListingData:GetCollectibleSortOrder()
    local collectibleData = self:GetCollectibleData()
    if collectibleData then
        return collectibleData:GetSortOrder()
    end

    return 0
end

function ZO_HouseToursPlayerListingData:CompareTo(otherPlayerListingData)
    local isListed = self:IsListed()
    local otherIsListed = otherPlayerListingData:IsListed()
    if isListed ~= otherIsListed then
        return isListed
    end

    local isPrimaryResidence = self:IsPrimaryResidence()
    local otherIsPrimaryResidence = otherPlayerListingData:IsPrimaryResidence()
    if isPrimaryResidence ~= otherIsPrimaryResidence then
        return isPrimaryResidence
    end

    local isFavorite = self:IsCollectibleFavorite()
    local otherIsFavorite = otherPlayerListingData:IsCollectibleFavorite()
    if isFavorite ~= otherIsFavorite then
        return isFavorite
    end

    local sortOrder = self:GetCollectibleSortOrder()
    local otherSortOrder = otherPlayerListingData:GetCollectibleSortOrder()
    if sortOrder ~= otherSortOrder then
        return sortOrder < otherSortOrder
    else
        return self:GetHouseName() < otherPlayerListingData:GetHouseName()
    end
end

function ZO_HouseToursPlayerListingData:Equals(otherPlayerListingData)
    return self.collectibleId == otherPlayerListingData:GetCollectibleId()
end

-- Accepts a table containing zero or more House Tours Tag enum ids.
-- Returns either the "None" string, if no tags are specified, or a comma separated string of the tags in alphabetical order.
function ZO_FormatHouseToursTagsText(tags)
    if tags and #tags > 0 then
        -- Construct a table containing the localized name of each tag.
        local tagStrings = {zo_getEnumStrings("SI_HOUSETOURLISTINGTAG", unpack(tags))}
        -- Sort the tag names alphabetically.
        table.sort(tagStrings)
        -- Return the sorted tag names as a comma separated string.
        return ZO_GenerateCommaSeparatedListWithoutAnd(tagStrings)
    else
        --If there are no tags, return a special string indicating that
        return GetString(SI_HOUSE_TOURS_LISTING_TAGS_NONE)
    end
end

function ZO_IsHouseToursEnabled()
    if GetHouseToursStatus() ~= HOUSE_TOURS_STATUS_READY then
        return false, GetString(SI_HOUSE_TOURS_TOOLTIP_DISABLED)
    end

    if not CanJumpToHouseFromCurrentLocation() then
        return false, GetString(SI_HOUSE_TOURS_TOOLTIP_UNAVAILABLE_IN_ZONE)
    end

    return true
end