---- Favorite / Recommend Dialog

ZO_HouseTours_FavoriteRecommendHouseDialog_Keyboard = ZO_HouseTours_FavoriteRecommendHouseDialog_Shared:Subclass()

function ZO_HouseTours_FavoriteRecommendHouseDialog_Keyboard:Initialize(dialogName, control)
    self.divider = control:GetNamedChild("Divider")
    self.favoriteContainer = control:GetNamedChild("Favorite")
    self.favoriteLabel = self.favoriteContainer:GetNamedChild("Text")
    self.favoriteCheckbox = self.favoriteContainer:GetNamedChild("ContainerCheckbox")
    ZO_CheckButton_SetToggleFunction(self.favoriteCheckbox, ZO_GetCallbackForwardingFunction(self, self.OnFavoriteChecked))
    self.recommendContainer = control:GetNamedChild("Recommend")
    self.recommendLabel = self.recommendContainer:GetNamedChild("Text")
    self.recommendCheckbox = self.recommendContainer:GetNamedChild("ContainerCheckbox")
    ZO_CheckButton_SetToggleFunction(self.recommendCheckbox, ZO_GetCallbackForwardingFunction(self, self.OnRecommendChecked))

    ZO_HouseTours_FavoriteRecommendHouseDialog_Shared.Initialize(self, dialogName, control)
end

function ZO_HouseTours_FavoriteRecommendHouseDialog_Keyboard:SetupDialog()
    ZO_HouseTours_FavoriteRecommendHouseDialog_Shared.SetupDialog(self)

    self:RefreshMainText()
    ZO_CheckButton_SetLabelText(self.favoriteCheckbox, GetString(SI_HOUSE_TOURS_VISITOR_DIALOG_FAVORITE_OPTION_TEXT))
    ZO_CheckButton_SetLabelText(self.recommendCheckbox, GetString(SI_HOUSE_TOURS_VISITOR_DIALOG_RECOMMEND_OPTION_TEXT))
    ZO_CheckButton_SetCheckState(self.favoriteCheckbox, self:IsFavoriteOptionSelected())
    ZO_CheckButton_SetCheckState(self.recommendCheckbox, self:IsRecommendOptionSelected())
    ZO_CheckButton_SetEnableState(self.favoriteCheckbox, self:IsFavoriteOptionEnabled())
    ZO_CheckButton_SetEnableState(self.recommendCheckbox, self:IsRecommendOptionEnabled())

    local showRecommendOption = self:IsRecommendOptionVisible()
    self.recommendContainer:SetHidden(not showRecommendOption)
    self.favoriteContainer:ClearAnchors()
    if showRecommendOption then
        self.favoriteContainer:SetAnchor(TOP, self.recommendContainer, BOTTOM, 0, 10)
    else
        self.favoriteContainer:SetAnchor(TOP, self.divider, BOTTOM, 0, 20)
    end
end

function ZO_HouseTours_FavoriteRecommendHouseDialog_Keyboard:RefreshMainText()
    self.favoriteLabel:SetText(self:GetFavoritesText())
    self.recommendLabel:SetText(self:GetRecommendationsText())
end

function ZO_HouseTours_FavoriteRecommendHouseDialog_Keyboard:Show(...)
    HousingEditorRequestModeChange(HOUSING_EDITOR_MODE_DISABLED)

    return ZO_HouseTours_FavoriteRecommendHouseDialog_Shared.Show(self, ...)
end

function ZO_HouseTours_FavoriteRecommendHouseDialog_Keyboard:OnFavoriteChecked(control, checked)
    self:SetFavoriteOptionSelected(checked)
    self:RefreshMainText()
end

function ZO_HouseTours_FavoriteRecommendHouseDialog_Keyboard:OnRecommendChecked(control, checked)
    self:SetRecommendOptionSelected(checked)
    self:RefreshMainText()
end

function ZO_HouseTours_FavoriteRecommendHouseDialog_Keyboard.OnControlInitialized(control)
    HOUSE_TOURS_FAVORITE_RECOMMEND_HOUSE_DIALOG_KEYBOARD = ZO_HouseTours_FavoriteRecommendHouseDialog_Keyboard:New("HOUSE_TOURS_FAVORITE_RECOMMEND_HOUSE", control)
end