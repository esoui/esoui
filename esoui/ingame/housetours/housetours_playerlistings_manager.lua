--------------------------------------------
-- House Tours Player Listings Manager -----
--------------------------------------------

ZO_HouseToursPlayerListings_Manager = ZO_InitializingCallbackObject:Subclass()

function ZO_HouseToursPlayerListings_Manager:Initialize()
    self.isListingOperationOnCooldown = false
    self.sortedListingData = {}
    self.listingDataByCollectibleId = {}
    self.currentListingOperation = HOUSE_TOURS_LISTING_OPERATION_TYPE_NONE

    self:MarkDirty()
    self:RegisterForEvents()
    self:RegisterDialogs()
end

function ZO_HouseToursPlayerListings_Manager:RegisterForEvents()
    ZO_COLLECTIBLE_DATA_MANAGER:RegisterCallback("PrimaryResidenceSet", function() self:MarkDirty() end)
    ZO_COLLECTIBLE_DATA_MANAGER:RegisterCallback("OnCollectibleUserFlagsUpdated", function(collectibleId)
        local collectibleData = ZO_COLLECTIBLE_DATA_MANAGER:GetCollectibleDataById(collectibleId)
        if collectibleData and collectibleData:IsHouse() then
            self:MarkDirty()
        end
    end)
    ZO_COLLECTIBLE_DATA_MANAGER:RegisterCallback("OnCollectionUpdated", function() self:MarkDirty() end)

    EVENT_MANAGER:RegisterForEvent("HouseTours_PlayerListings_Manager", EVENT_HOUSE_TOURS_LISTING_OPERATION_COOLDOWN_STATE_CHANGED, ZO_GetEventForwardingFunction(self, self.OnListingOperationCooldownStateChanged))
    EVENT_MANAGER:RegisterForEvent("HouseTours_PlayerListings_Manager", EVENT_HOUSE_TOURS_LISTING_OPERATION_RESPONSE, ZO_GetEventForwardingFunction(self, self.OnListingOperationResponse))
    EVENT_MANAGER:RegisterForEvent("HouseTours_PlayerListings_Manager", EVENT_HOUSE_TOURS_LISTING_OPERATION_STARTED, ZO_GetEventForwardingFunction(self, self.OnListingOperationStarted))
    EVENT_MANAGER:RegisterForEvent("HouseTours_PlayerListings_Manager", EVENT_PLAYER_ACTIVATED, ZO_GetEventForwardingFunction(self, self.OnPlayerActivated))
end

function ZO_HouseToursPlayerListings_Manager:RegisterDialogs()
    --The loading spinner dialog
    ZO_Dialogs_RegisterCustomDialog("HOUSE_TOURS_LISTING_OPERATION_DIALOG",
    {
        canQueue = true,
        gamepadInfo =
        {
            dialogType = GAMEPAD_DIALOGS.COOLDOWN,
            allowShowOnNextScene = true,
        },
        title = 
        {
            text = SI_HOUSE_TOURS_LISTING_DIALOG_TITLE_FORMATTER,
        },
        mainText =
        {
            align = TEXT_ALIGN_CENTER,
            text = SI_HOUSE_TOURS_LISTING_DIALOG_BODY_FORMATTER,
        },
        showLoadingIcon = true,
        --Since no choices are provided this forces the dialog to remain shown until programmaticly closed
        mustChoose = true,
        buttons = {},
    })

    --The operation result dialog
    ZO_Dialogs_RegisterCustomDialog("HOUSE_TOURS_LISTING_OPERATION_RESPONSE_DIALOG",
    {
        canQueue = true,
        gamepadInfo =
        {
            dialogType = GAMEPAD_DIALOGS.BASIC,
        },
        title =
        {
            text = SI_HOUSE_TOURS_LISTING_DIALOG_TITLE_FORMATTER,
        },
        mainText =
        {
            align = TEXT_ALIGN_CENTER,
            text = SI_HOUSE_TOURS_LISTING_DIALOG_BODY_FORMATTER,
        },
        buttons =
        {
            {
                text = SI_OK,
                keybind = "DIALOG_NEGATIVE",
                gamepadPreferredKeybind = "DIALOG_PRIMARY",
                clickSound = SOUNDS.DIALOG_ACCEPT,
            }
        },
        finishedCallback = function()
            --TODO House Tours: Do we need this?
        end,
    })
end

function ZO_HouseToursPlayerListings_Manager:MarkDirty()
    self.dirty = true
end

function ZO_HouseToursPlayerListings_Manager:CleanDirty()
    if self.dirty then
        self:RefreshListingData()
        self.dirty = false
    end
end

function ZO_HouseToursPlayerListings_Manager:OnListingOperationCooldownStateChanged(isListingOperationOnCooldown)
    self:SetIsListingOperationOnCooldown(isListingOperationOnCooldown)
end

function ZO_HouseToursPlayerListings_Manager:OnListingOperationResponse(operationType, houseId, result)
    local pendingListingOperation = self.currentListingOperation
    self.currentListingOperation = HOUSE_TOURS_LISTING_OPERATION_TYPE_NONE
    ZO_Dialogs_ReleaseDialog("HOUSE_TOURS_LISTING_OPERATION_DIALOG")

    local titleText
    local mainText
    if result == HOUSE_TOURS_LISTING_RESULT_SUCCESS then
        titleText = GetString("SI_HOUSETOURSLISTINGOPERATIONTYPE_SUCCESSDIALOGTITLE", operationType)
        mainText = GetString("SI_HOUSETOURSLISTINGOPERATIONTYPE_SUCCESSDIALOGMESSAGE", operationType)
    else
        -- The previously pending listing operation is used here to handle client-generated events properly.
        titleText = GetString("SI_HOUSETOURSLISTINGOPERATIONTYPE_FAILDIALOGTITLE", pendingListingOperation)
        mainText = GetString("SI_HOUSETOURLISTINGRESULT", result)
    end

    if pendingListingOperation ~= HOUSE_TOURS_LISTING_OPERATION_TYPE_NONE then
        -- We were awaiting a response to a request that we had submitted; show the appropriate dialog.
        local textParams = 
        {
            titleParams = { titleText },
            mainTextParams = { mainText },
        }
        ZO_Dialogs_ShowPlatformDialog("HOUSE_TOURS_LISTING_OPERATION_RESPONSE_DIALOG", nil, textParams)
    else
        -- The response was for a timed out request or a request not submitted by this UI.
        local NO_SOUND = nil
        ZO_Alert(UI_ALERT_CATEGORY_ALERT, NO_SOUND, mainText)
    end

    self:MarkDirty()
    self:FireCallbacks("ListingOperationCompleted", operationType, houseId, result)
end

function ZO_HouseToursPlayerListings_Manager:OnListingOperationStarted(operationType, houseId)
    internalassert(self.currentListingOperation == HOUSE_TOURS_LISTING_OPERATION_TYPE_NONE, "Attempting to start a listing operation when one is already in progress")
    self.currentListingOperation = operationType
    local textParams =
    {
        titleParams = { GetString("SI_HOUSETOURSLISTINGOPERATIONTYPE_LOADINGDIALOGTITLE", operationType) },
        mainTextParams = { GetString("SI_HOUSETOURSLISTINGOPERATIONTYPE_LOADINGDIALOGMESSAGE", operationType) },
    }
    ZO_Dialogs_ShowPlatformDialog("HOUSE_TOURS_LISTING_OPERATION_DIALOG", nil, textParams)
end

function ZO_HouseToursPlayerListings_Manager:OnPlayerActivated()
    local isListingOnCooldown = IsHouseToursListingOnCooldown()
    self:SetIsListingOperationOnCooldown(isListingOnCooldown)
end

function ZO_HouseToursPlayerListings_Manager:RefreshListingData()
    ZO_ClearNumericallyIndexedTable(self.sortedListingData)
    ZO_ClearTable(self.listingDataByCollectibleId)

    local unlockedHouses = COLLECTIONS_BOOK_SINGLETON:GetUnlockedHouses()
    for collectibleId, _ in pairs(unlockedHouses) do
        local listingData = ZO_HouseToursPlayerListingData:New(collectibleId)
        table.insert(self.sortedListingData, listingData)
        self.listingDataByCollectibleId[collectibleId] = listingData
    end

    table.sort(self.sortedListingData, ZO_HouseToursPlayerListingData.CompareTo)
end

function ZO_HouseToursPlayerListings_Manager:GetSortedListingData()
    self:CleanDirty()
    return self.sortedListingData
end

function ZO_HouseToursPlayerListings_Manager:GetListingDataByCollectibleId(collectibleId)
    self:CleanDirty()
    return self.listingDataByCollectibleId[collectibleId]
end

function ZO_HouseToursPlayerListings_Manager:SetIsListingOperationOnCooldown(isListingOperationOnCooldown)
    if isListingOperationOnCooldown ~= self.isListingOperationOnCooldown then
        self.isListingOperationOnCooldown = isListingOperationOnCooldown
        self:FireCallbacks("ListingOperationCooldownStateChanged", isListingOperationOnCooldown)
    end

    if not self.isListingOperationOnCooldown then
        -- Hide the processing dialog.
        ZO_Dialogs_ReleaseDialog("HOUSE_TOURS_LISTING_OPERATION_DIALOG")
    end
end

HOUSE_TOURS_PLAYER_LISTINGS_MANAGER = ZO_HouseToursPlayerListings_Manager:New()