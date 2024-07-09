---- Shared Base Dialog

ZO_HouseTours_Dialog_Shared = ZO_InitializingCallbackObject:Subclass()

function ZO_HouseTours_Dialog_Shared:Initialize(dialogName, control)
    -- Dialog Name Validation
    if not dialogName then
        assert(false, "Parameter \"dialogName\" is required.")
        return
    end
    if ZO_Dialogs_IsDialogRegistered(dialogName) then
        assert(false, string.format("Dialog %q is already registered.", dialogName))
        return
    end

    -- Properties
    self.dialogName = dialogName
    self.control = control
    if control then
        self.cancelButton = control:GetNamedChild("Cancel")
        self.confirmButton = control:GetNamedChild("Confirm")
    end
    self.isFavoriteChecked = false
    self.isRecommendChecked = false

    if self.RegisterDialog then
        -- Custom Dialog Registration
        self:RegisterDialog(self.dialogName)
    else
        -- Default Dialog Configuration
        self.dialog =
        {
            buttons =
            {
                {
                    callback = ZO_GetCallbackForwardingFunction(self, self.OnConfirmDialog),
                    control = self.confirmButton,
                    keybind = "DIALOG_PRIMARY",
                    text = SI_DIALOG_CONFIRM,
                },
                {
                    callback = ZO_GetCallbackForwardingFunction(self, self.OnCancelDialog),
                    control = self.cancelButton,
                    keybind = "DIALOG_NEGATIVE",
                    text = SI_DIALOG_EXIT,
                },
            },
            canQueue = true,
            customControl = self.control,
            finishedCallback = ZO_GetCallbackForwardingFunction(self, self.OnFinishDialog),
            noChoiceCallback = ZO_GetCallbackForwardingFunction(self, self.OnCancelDialog),
            setup = ZO_GetCallbackForwardingFunction(self, self.OnSetupDialog),
        }

        ZO_Dialogs_RegisterCustomDialog(self.dialogName, self.dialog)
    end

    -- Automatically close this dialog when the player leaves the current house.
    HOUSING_EDITOR_STATE:RegisterCallback("HouseChanged", function()
        ZO_Dialogs_ReleaseDialog(self.dialogName)
    end)
end

-- Properties

function ZO_HouseTours_Dialog_Shared:GetControl()
    return self.control
end

function ZO_HouseTours_Dialog_Shared:GetDialog()
    return self.dialog
end

function ZO_HouseTours_Dialog_Shared:GetDialogData()
    return self.dialogData
end

function ZO_HouseTours_Dialog_Shared:GetDialogName()
    return self.dialogName
end

function ZO_HouseTours_Dialog_Shared:GetDialogParams()
    return self.dialogParams
end

function ZO_HouseTours_Dialog_Shared:SetCancelButtonKeybind(keybind)
    self.dialog.buttons[2].keybind = keybind
end

function ZO_HouseTours_Dialog_Shared:SetCancelButtonText(text)
    self.dialog.buttons[2].text = text
end

function ZO_HouseTours_Dialog_Shared:SetCanQueue(canQueue)
    self.dialog.canQueue = canQueue
end

function ZO_HouseTours_Dialog_Shared:SetConfirmButtonKeybind(keybind)
    self.dialog.buttons[1].keybind = keybind
end

function ZO_HouseTours_Dialog_Shared:SetConfirmButtonText(text)
    self.dialog.buttons[1].text = text
end

function ZO_HouseTours_Dialog_Shared:SetDialogData(dialogData)
    self.dialogData = dialogData
end

function ZO_HouseTours_Dialog_Shared:SetDialogParams(dialogParams)
    self.dialogParams = dialogParams
end

function ZO_HouseTours_Dialog_Shared:SetMainText(text)
    local mainText = self.dialog.mainText
    if not mainText then
        mainText = {}
        self.dialog.mainText = mainText
    end
    mainText.text = text
end

function ZO_HouseTours_Dialog_Shared:SetTitleText(text)
    local title = self.dialog.title
    if not title then
        title = {}
        self.dialog.title = title
    end
    title.text = text
end

-- Callbacks

function ZO_HouseTours_Dialog_Shared:FireDialogCallbacks(callbackName, ...)
    local dialogData = self:GetDialogData()
    local dialogParams = self:GetDialogParams()
    return self:FireCallbacks(callbackName, dialogData, dialogParams, ...)
end

function ZO_HouseTours_Dialog_Shared:OnCancelDialog()
    return self:FireDialogCallbacks("OnCancelDialog")
end

function ZO_HouseTours_Dialog_Shared:OnConfirmDialog()
    return self:FireDialogCallbacks("OnConfirmDialog")
end

function ZO_HouseTours_Dialog_Shared:OnFinishDialog()
    return self:FireDialogCallbacks("OnFinishDialog")
end

function ZO_HouseTours_Dialog_Shared:OnSetupDialog(dialog, data)
    local returnValue = self:FireDialogCallbacks("OnSetupDialog")
    if dialog.setupFunc then
        dialog:setupFunc()
    end
    return returnValue
end

function ZO_HouseTours_Dialog_Shared:OnShowDialog()
    self:SetupDialog()
    return self:FireDialogCallbacks("OnShowDialog")
end

-- Methods

function ZO_HouseTours_Dialog_Shared:Hide()
    if not self:IsHidden() then
        ZO_Dialogs_ReleaseDialog(self.dialogName)
    end
end

function ZO_HouseTours_Dialog_Shared:IsHidden()
    return not ZO_Dialogs_IsShowing(self.dialogName)
end

function ZO_HouseTours_Dialog_Shared:Show(dialogData, dialogParams)
    -- Hide any tooltip that might occlude this dialog.
    ClearTooltip(InformationTooltip)

    self:SetDialogData(dialogData)
    self:SetDialogParams(dialogParams)
    self:OnShowDialog()

    ZO_Dialogs_ShowPlatformDialog(self.dialogName, dialogData, dialogParams)
end

-- Abstract Methods

ZO_HouseTours_Dialog_Shared.SetupDialog = ZO_HouseTours_Dialog_Shared:MUST_IMPLEMENT()

---- Favorite / Recommend Dialog

ZO_HouseTours_FavoriteRecommendHouseDialog_Shared = ZO_HouseTours_Dialog_Shared:Subclass()
ZO_HouseTours_FavoriteRecommendHouseDialog_Shared:IGNORE_UNIMPLEMENTED()

function ZO_HouseTours_FavoriteRecommendHouseDialog_Shared:SetupDialog()
    self.isHouseListedByAnotherPlayer = self:IsCurrentHouseListedByAnotherPlayer()
    self.isFavoriteChecked = IsCurrentHouseFavorite()
    self.isRecommendChecked = IsCurrentHouseRecommended()

    if self.isHouseListedByAnotherPlayer then
        -- The house can be recommended and/or favorited.
        self:SetTitleText(GetString(SI_HOUSE_TOURS_VISITOR_DIALOG_TITLE))
    else
        -- The house can only be favorited.
        self:SetTitleText(GetString(SI_HOUSE_TOURS_VISITOR_DIALOG_FAVORITE_OPTION_TEXT))
    end

    local numFavoritesUsed = GetNumHouseToursUnfilteredListings(HOUSE_TOURS_LISTING_TYPE_FAVORITE)
    self.numFavoritesUsedInclusive = numFavoritesUsed + (self.isFavoriteChecked and 0 or 1)
    self.numFavoritesUsedExclusive = numFavoritesUsed + (self.isFavoriteChecked and -1 or 0)
    self.maxFavorites = MAX_HOUSE_TOURS_LISTING_FAVORITES
    self.enableFavoriteCheckbox = self.isFavoriteChecked or numFavoritesUsed < MAX_HOUSE_TOURS_LISTING_FAVORITES

    local numRecommendationsUsed = GetNumHousesRecommendedByLocalPlayer()
    self.numRecommendationsUsed = numRecommendationsUsed
    self.maxRecommendations = MAX_HOUSE_TOURS_WEEKLY_RECOMMENDATIONS
    self.enableRecommendCheckbox = self.isHouseListedByAnotherPlayer and not self.isRecommendChecked and numRecommendationsUsed < MAX_HOUSE_TOURS_WEEKLY_RECOMMENDATIONS
end

function ZO_HouseTours_FavoriteRecommendHouseDialog_Shared:GetFavoritesText()
    local text = {}
    local isFavorite = self.isFavoriteChecked
    local wasFavorite = IsCurrentHouseFavorite()

    -- This text must be based on whether this house is -currently- a favorite
    -- rather than the uncommitted state of the checkbox.
    if wasFavorite then
        table.insert(text, GetString(SI_HOUSE_TOURS_VISITOR_DIALOG_UNFAVORITE_HELP_TEXT))
    else
        table.insert(text, GetString(SI_HOUSE_TOURS_VISITOR_DIALOG_FAVORITE_HELP_TEXT))
    end

    local maxFavorites = self.maxFavorites
    local numFavoritesUsed = isFavorite and self.numFavoritesUsedInclusive or self.numFavoritesUsedExclusive
    local numFavoritesRemaining = maxFavorites - numFavoritesUsed
    local numFavoritesColor = isFavorite == wasFavorite and ZO_WHITE or UNLOCKED_COLOR
    table.insert(text, zo_strformat(SI_HOUSE_TOURS_VISITOR_DIALOG_NUM_FAVORITES_TEXT, numFavoritesColor:Colorize(numFavoritesRemaining), ZO_WHITE:Colorize(maxFavorites)))

    return ZO_GenerateNewlineSeparatedList(text)
end

function ZO_HouseTours_FavoriteRecommendHouseDialog_Shared:GetRecommendationsText()
    if not self:IsCurrentHouseListedByAnotherPlayer() then
        return ""
    end

    local wasRecommended = IsCurrentHouseRecommended()
    if wasRecommended then
        return GetString(SI_HOUSE_TOURS_VISITOR_DIALOG_RECOMMENDED_HELP_TEXT)
    end

    local text = {}
    local maxRecommendations = self.maxRecommendations
    table.insert(text, zo_strformat(SI_HOUSE_TOURS_VISITOR_DIALOG_MAX_RECOMMENDATIONS_HELP_TEXT, ZO_WHITE:Colorize(maxRecommendations)))

    -- This text must be based on whether this house is -currently- a favorite
    -- rather than the uncommitted state of the checkbox.
    local isRecommended = self.isRecommendChecked
    local numRecommendationsUsed = self.numRecommendationsUsed
    if isRecommended then
        numRecommendationsUsed = numRecommendationsUsed + 1
    end
    local numRecommendationsRemaining = maxRecommendations - numRecommendationsUsed
    local numRecommendationsColor = isRecommended == wasRecommended and ZO_WHITE or UNLOCKED_COLOR
    table.insert(text, zo_strformat(SI_HOUSE_TOURS_VISITOR_DIALOG_NUM_RECOMMENDATIONS_TEXT, numRecommendationsColor:Colorize(numRecommendationsRemaining), ZO_WHITE:Colorize(maxRecommendations)))

    local recommendationsResetTimeRemainingMS = GetHouseToursRecommendationsTimeRemainingS()
    local recommendationsResetTimeRemainingString = ZO_FormatTimeLongDurationExpiration(recommendationsResetTimeRemainingMS)
    table.insert(text, zo_strformat(SI_HOUSE_TOURS_VISITOR_DIALOG_RECOMMENDATIONS_REFRESH_TEXT, ZO_WHITE:Colorize(recommendationsResetTimeRemainingString)))

    return ZO_GenerateNewlineSeparatedList(text)
end

function ZO_HouseTours_FavoriteRecommendHouseDialog_Shared:IsCurrentHouseListedByAnotherPlayer()
    return IsCurrentHouseListed() and not HOUSING_EDITOR_STATE:IsLocalPlayerHouseOwner()
end

function ZO_HouseTours_FavoriteRecommendHouseDialog_Shared:IsFavoriteOptionSelected()
    return self.isFavoriteChecked
end

function ZO_HouseTours_FavoriteRecommendHouseDialog_Shared:IsFavoriteOptionEnabled()
    return self.enableFavoriteCheckbox
end

function ZO_HouseTours_FavoriteRecommendHouseDialog_Shared:IsRecommendOptionSelected()
    return self.isRecommendChecked
end

function ZO_HouseTours_FavoriteRecommendHouseDialog_Shared:IsRecommendOptionVisible()
    return self.isHouseListedByAnotherPlayer
end

function ZO_HouseTours_FavoriteRecommendHouseDialog_Shared:IsRecommendOptionEnabled()
    return self.enableRecommendCheckbox
end

function ZO_HouseTours_FavoriteRecommendHouseDialog_Shared:SetFavoriteOptionSelected(selected)
    self.isFavoriteChecked = selected
end

function ZO_HouseTours_FavoriteRecommendHouseDialog_Shared:SetRecommendOptionSelected(selected)
    self.isRecommendChecked = selected
end

function ZO_HouseTours_FavoriteRecommendHouseDialog_Shared:OnConfirmDialog(...)
    ZO_HouseTours_Dialog_Shared.OnConfirmDialog(self, ...)

    -- Order matters:
    local isFavoriteChecked = self:IsFavoriteOptionSelected()
    local isRecommendChecked = self:IsRecommendOptionSelected()
    if isFavoriteChecked ~= IsCurrentHouseFavorite() then
        local operationType = isFavoriteChecked and HOUSE_TOURS_FAVORITE_OPERATION_TYPE_CREATE or HOUSE_TOURS_FAVORITE_OPERATION_TYPE_DELETE
        RequestUpdateCurrentHouseFavoriteStatus(operationType)
    end

    if isRecommendChecked and self:IsRecommendOptionEnabled() then
        RequestRecommendCurrentHouse()
    end
end