local SCROLL_TYPE_PEGI = 1

--[[
---- Lifecycle
--]]

ZO_PEGIAgreement = ZO_Object:Subclass()

function ZO_PEGIAgreement:New(...)
    local object = ZO_Object.New(self)
    object:Initialize(...)
    return object
end

function ZO_PEGIAgreement:Initialize()
    self.countryToRatingsBoard = {}
    self.countriesPopulated = false
    self.selectedControl = nil

    local function OnLinkClicked(link, button, text, color, linkType, ...)
        if ZO_PEGI_IsDeclineNotificationShowing() and linkType == URL_LINK_TYPE then
            ConfirmOpenURL(zo_strjoin(':', ...))
            return true
        end
    end

    CALLBACK_MANAGER:RegisterCallback("PregameFullyLoaded", function() self:PopulateCountries() end)
    LINK_HANDLER:RegisterCallback(LINK_HANDLER.LINK_CLICKED_EVENT, OnLinkClicked)
end

function ZO_PEGIAgreement:OnCountrySelected(control)
    if self.selectedControl then
        -- Unselect previously selected control
        self.selectedControl.name:SetColor(GetInterfaceColor(INTERFACE_COLOR_TYPE_TEXT_COLORS, INTERFACE_TEXT_COLOR_NORMAL))
    end

    if control then
        -- Select newly selected control
        control.name:SetColor(GetInterfaceColor(INTERFACE_COLOR_TYPE_TEXT_COLORS, INTERFACE_TEXT_COLOR_SELECTED))
    end

    self.selectedControl = control
    self.countrySelectConfirmButton:SetEnabled(true)
end

function ZO_PEGIAgreement:PopulateCountries()
    if not self.countriesPopulated then
        -- Set up list
        local listTemplate = ZO_PEGI_CountrySelectDialog_ListItem
        self.control = ZO_PEGI_CountrySelectDialog
        self.list = self.control:GetNamedChild("CountryList")
        ZO_ScrollList_SetHeight(self.list, self.list:GetHeight())

        local function OnMouseUp(rowControl, button, upInside)
            if upInside then
                local data = ZO_ScrollList_GetData(rowControl)
                ZO_ScrollList_SelectData(self.list, data, rowControl)
            end
        end

        local function SetupListItem(rowControl, data)
            rowControl.name:SetText(data.countryName)
        end

        ZO_ScrollList_AddDataType(self.list, SCROLL_TYPE_PEGI, "ZO_PEGI_CountrySelectDialog_ListItem", 32, SetupListItem)

        ZO_ScrollList_EnableSelection(self.list, "ZO_ThinListHighlight")
        ZO_ScrollList_EnableHighlight(self.list, "ZO_ThinListHighlight")
        ZO_ScrollList_SetDeselectOnReselect(self.list, false)

        -- Populate list

        local numCountries = GetNumCountries()
        local scrollData = ZO_ScrollList_GetDataList(self.list)

        for i = 1, numCountries do
            local countryName, ratingsBoard = GetCountryDataForIndex(i)
            self.countryToRatingsBoard[countryName] = ratingsBoard
            scrollData[#scrollData + 1] = ZO_ScrollList_CreateDataEntry(SCROLL_TYPE_PEGI, { countryName = countryName or "", countryNameLower = zo_strlower(countryName or "") })
        end	

        -- Sort list
        local function countrySortFunction(countryName1, countryName2)
            -- We assume there will never be two countries with exactly the same name, and that the arguments will both always be strings
            return countryName1.data.countryNameLower < countryName2.data.countryNameLower
        end

        table.sort(scrollData, countrySortFunction)
        
        ZO_ScrollList_Commit(self.list)

        if numCountries > 0 then
            self.countrySelectConfirmButton:SetEnabled(false)
        end

        self.countriesPopulated = true
    end
end

function ZO_PEGIAgreement:OnCountrySelectionConfirmed()
    local selectedData = ZO_ScrollList_GetSelectedData(self.list)
    local selectedCountry = selectedData.countryName

    if self.countryToRatingsBoard[selectedCountry] == RATINGS_BOARD_PEGI then
        ZO_Dialogs_ShowDialog("PEGI_NOTIFICATION")
    else
        AgreeToPEGI()
    end
end

--[[
---- Global XML
--]]

function ZO_PEGI_CountrySelectDialog_OnInitialized(self)
    PEGI_AGREEMENT.countrySelectList = self:GetNamedChild("CountryList")
    PEGI_AGREEMENT.countrySelectConfirmButton = self:GetNamedChild("Confirm")

    ZO_Dialogs_RegisterCustomDialog("PEGI_COUNTRY_SELECT",
    {
        customControl = self,
        mustChoose = true,
        canQueue = true,
        title =
        {
            text = SI_PEGI_COUNTRY_SELECT_TITLE,
        },
        buttons =
        {
            [1] =
            {
                control = self:GetNamedChild("Confirm"),
                text = SI_DIALOG_CONFIRM,
                callback =  function(self)
                                PEGI_AGREEMENT:OnCountrySelectionConfirmed()
                            end,
            },
        }                                   
    })
end

function ZO_PEGI_AgreementDialog_OnInitialized(self)
    ZO_Dialogs_RegisterCustomDialog("PEGI_NOTIFICATION",
    {
        customControl = self,
        mustChoose = true,
        canQueue = true,
        title =
        {
            text = SI_PEGI_AGREEMENT_TITLE,
        },
        buttons =
        {
            [1] =
            {
                control = self:GetNamedChild("Accept"),
                text = SI_DIALOG_ACCEPT,
                callback =  function(self)
                                AgreeToPEGI()
                            end,
            },
            [2] =
            {
                control = self:GetNamedChild("Decline"),
                text = SI_DIALOG_DECLINE,
                callback =  function(self)
                                ZO_Dialogs_ShowDialog("PEGI_NOTIFICATION_DECLINE")
                            end,
            },
        }                                   
    })
end

function ZO_PEGI_AgreementDeclinedDialog_OnInitialized(self)
    local customerSupportLink = ZO_LinkHandler_CreateURLLink(GetURLTextByType(APPROVED_URL_ESO_HELP), GetString(SI_PEGI_AGREEMENT_LINK_TEXT))
    self:GetNamedChild("AgreementText"):SetText(zo_strformat(SI_PEGI_AGREEMENT_DECLINE_TEXT, customerSupportLink))

    ZO_Dialogs_RegisterCustomDialog("PEGI_NOTIFICATION_DECLINE",
    {
        customControl = self,
        mustChoose = true,
        canQueue = true,
        title =
        {
            text = SI_PEGI_AGREEMENT_DECLINE_TITLE,
        },
        buttons =
        {
            [1] =
            {
                control = self:GetNamedChild("Back"),
                text = SI_BACK_UP_ONE_MENU,
                callback =  function(self)
                                ZO_Dialogs_ShowDialog("PEGI_NOTIFICATION")
                            end,
            },
        }                                   
    })
end

function ZO_PEGI_IsDeclineNotificationShowing()
    return ZO_Dialogs_FindDialog("PEGI_NOTIFICATION_DECLINE") ~= nil
end

function ZO_PEGI_CountrySelectDialog_OnMouseEnter(control)
    control.name:SetColor(GetInterfaceColor(INTERFACE_COLOR_TYPE_TEXT_COLORS, INTERFACE_TEXT_COLOR_SELECTED))
    ZO_ScrollList_MouseEnter(PEGI_AGREEMENT.list, control)
end

function ZO_PEGI_CountrySelectDialog_OnMouseExit(control)
    if control ~= PEGI_AGREEMENT.selectedControl then
        control.name:SetColor(GetInterfaceColor(INTERFACE_COLOR_TYPE_TEXT_COLORS, INTERFACE_TEXT_COLOR_NORMAL))
    end

    ZO_ScrollList_MouseExit(PEGI_AGREEMENT.list, control)
end

function ZO_PEGI_CountrySelectDialog_OnMouseUp(control)
    PEGI_AGREEMENT:OnCountrySelected(control)
    ZO_ScrollList_MouseClick(PEGI_AGREEMENT.list, control)
end

function ZO_PEGI_CountrySelectDialog_OnDoubleClick()
    PEGI_AGREEMENT:OnCountrySelectionConfirmed()
    ZO_Dialogs_ReleaseDialog("PEGI_COUNTRY_SELECT")
end

PEGI_AGREEMENT = ZO_PEGIAgreement:New()


