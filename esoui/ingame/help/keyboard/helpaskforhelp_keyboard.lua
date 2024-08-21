local GetListEntryName = ZO_GetAskForHelpListEntryName

local HelpAskForHelp_Keyboard = ZO_HelpScreenTemplate_Keyboard:Subclass()

function HelpAskForHelp_Keyboard:New(...)
    return ZO_HelpScreenTemplate_Keyboard.New(self, ...)
end

function HelpAskForHelp_Keyboard:Initialize(control)
    local sceneFragment = ZO_FadeSceneFragment:New(control)
    self.sceneFragment = sceneFragment
    HELP_CUSTOMER_SERVICE_ASK_FOR_HELP_KEYBOARD_FRAGMENT = sceneFragment

    local iconData =
    {
        name = GetString(SI_CUSTOMER_SERVICE_ASK_FOR_HELP),
        categoryFragment = HELP_CUSTOMER_SERVICE_ASK_FOR_HELP_KEYBOARD_FRAGMENT,
        up = "EsoUI/Art/Help/help_tabIcon_CS_up.dds",
        down = "EsoUI/Art/Help/help_tabIcon_CS_down.dds",
        over = "EsoUI/Art/Help/help_tabIcon_CS_over.dds",
    }
    ZO_HelpScreenTemplate_Keyboard.Initialize(self, control, iconData)

    self.helpCategoryTitle = control:GetNamedChild("CategoryTitle")
    self.helpSubcategoryTitle = control:GetNamedChild("SubcategoryTitle")
    self.helpDetailsTitle = control:GetNamedChild("DetailsTitle")
    self.helpDescriptionTitle = control:GetNamedChild("DescriptionTitle")
    self.helpDescriptionBody = self.control:GetNamedChild("DescriptionBody")
    self.helpDetailsTextControl = control:GetNamedChild("DetailsTextLine")

    self.helpCategoryContainer = control:GetNamedChild("CategoryContainer")
    self.helpSubcategoryContainer = control:GetNamedChild("SubcategoryContainer")
    self.helpDetailsContainer = control:GetNamedChild("DetailsContainer")

    self.helpImpactComboBoxControl = control:GetNamedChild("ImpactComboBox")
    self.helpCategoryComboBoxControl = control:GetNamedChild("CategoryComboBox")
    self.helpSubcategoryComboBoxControl = control:GetNamedChild("SubcategoryComboBox")

    self.externalInfoContainer = control:GetNamedChild("ExternalInfo")
    self.externalInfoTitle = self.externalInfoContainer:GetNamedChild("Title")
    self.instructionsText = control:GetNamedChild("Instructions")
    self.helpSubmitButton = control:GetNamedChild("SubmitButton")
    self.additionalInstructionsText = control:GetNamedChild("AdditionalInstructions")

    ZO_HELP_GENERIC_TICKET_SUBMISSION_MANAGER:RegisterCallback("CustomerServiceTicketSubmitted", function (...)
        self:OnCustomerServiceTicketSubmitted(...)
    end)

    self:InitializeTextBoxes()
    self:InitializeComboBoxes()
    self:InitializeDialogs()
end

local function OnComboBoxEntryMouseEnter(comboBox, entry)
    local description = ZO_GetAskForHelpListEntryDescription(entry.m_data.descriptionStringName, entry.m_data.data)
    if description then
        InitializeTooltip(InformationTooltip, comboBox.m_container, RIGHT, -10)
        InformationTooltip:AddLine(description, "", ZO_NORMAL_TEXT:UnpackRGBA())
    end
end

local function OnComboBoxEntryMouseExit(comboBox, entry)
    ClearTooltip(InformationTooltip)
end

function HelpAskForHelp_Keyboard:InitializeComboBoxes()
    local function CreateComboBox(childName)
        local combo = ZO_ComboBox_ObjectFromContainer(self.control:GetNamedChild(childName))
        combo:SetSortsItems(false)
        combo:SetFont("ZoFontWinT1")
        combo:SetSpacing(4)
        return combo
    end

    self.helpImpactComboBox = CreateComboBox("ImpactComboBox")
    self.helpCategoryComboBox = CreateComboBox("CategoryComboBox")
    self.helpSubcategoryComboBox = CreateComboBox("SubcategoryComboBox")

    self.helpCategoryComboBox:SetEntryMouseOverCallbacks(OnComboBoxEntryMouseEnter, OnComboBoxEntryMouseExit)
    self.helpSubcategoryComboBox:SetEntryMouseOverCallbacks(OnComboBoxEntryMouseEnter, OnComboBoxEntryMouseExit)

    local function OnImpactChanged()
        self:SetExternalInfo(nil)
        self:UpdateSubmitButton()
        ZO_HELP_GENERIC_TICKET_SUBMISSION_MANAGER:SetReportPlayerTicketSubmittedCallback(nil)
    end

    local impactStringName = ZO_HELP_ASK_FOR_HELP_CATEGORY_INFO.impactStringName
    local impacts = ZO_HELP_ASK_FOR_HELP_CATEGORY_INFO.impacts
    for _, impactData in ipairs(impacts) do
        local entry = self.helpImpactComboBox:CreateItemEntry(GetListEntryName(impactStringName, impactData), OnImpactChanged)
        entry.data = impactData
        self.helpImpactComboBox:AddItem(entry, ZO_COMBOBOX_SUPPRESS_UPDATE)
    end

    self.helpImpactComboBox:SelectItemByIndex(1)
    self:OnSelectedCategoriesChanged()
end

function HelpAskForHelp_Keyboard:InitializeTextBoxes()
    self.detailsEditBox = self.control:GetNamedChild("DetailsTextLineField")
    self.detailsEditBox:SetMaxInputChars(MAX_HELP_DETAILS_TEXT)
    self.detailsEditBox:SetDefaultText(GetString(SI_CUSTOMER_SERVICE_ENTER_NAME))

    --Storing the text field and adding handlers to the visibility events so the Submit Button can be enabled/disabled when the player has typed something in
    --The Submit Button is disabled when the details text is empty (and the details text is visible)
    self.detailsEditBox:SetHandler("OnTextChanged",function() self:UpdateSubmitButton() end)

    self.description = self.helpDescriptionBody:GetNamedChild("Field")
    self.description:SetMaxInputChars(MAX_HELP_DESCRIPTION_BODY)
    self.description:SetDefaultText(GetString(SI_CUSTOMER_SERVICE_DEFAULT_DESCRIPTION_TEXT_GENERIC))

    --The Submit Button is disabled if the description text is empty
    self.description:SetHandler("OnTextChanged",function() self:UpdateSubmitButton() end)

    self.description:SetText("")
    self.detailsEditBox:SetText("")
end

function HelpAskForHelp_Keyboard:InitializeDialogs()
    ZO_Dialogs_RegisterCustomDialog("HELP_ASK_FOR_HELP_SUBMIT_TICKET_SUCCESSFUL_DIALOG",
    {
        canQueue = true,
        mustChoose = true,
        title =
        {
            text = GetString(SI_CUSTOMER_SERVICE_SUBMIT_CONFIRMATION),
        },
        mainText =
        {
            text = GetString(SI_CUSTOMER_SERVICE_ASK_FOR_HELP_SUBMIT_TICKET_CONFIRMATION),
        },
       
        buttons =
        {
            {
                keybind = "DIALOG_NEGATIVE",
                text = SI_DIALOG_EXIT,
            },
        },
    })
end

function HelpAskForHelp_Keyboard:GetImpactData()
    local selectedItemData = self.helpImpactComboBox:GetSelectedItemData()
    return selectedItemData and selectedItemData.data
end

function HelpAskForHelp_Keyboard:GetCategoryData()
    local selectedItemData = self.helpCategoryComboBox:GetSelectedItemData()
    return selectedItemData and selectedItemData.data
end

function HelpAskForHelp_Keyboard:GetSubcategoryData()
    local selectedItemData = self.helpSubcategoryComboBox:GetSelectedItemData()
    return selectedItemData and selectedItemData.data
end

function HelpAskForHelp_Keyboard:UpdateCategories()
    self.helpCategoryComboBox:ClearItems()

    local impactData = self:GetImpactData()
    local meetsExternalInfoRequirements = self:MeetsExternalInfoRequirements()
    local categories = meetsExternalInfoRequirements and impactData and impactData.categories or nil

    if categories then
        local function OnCategoryChanged()
            self:UpdateSubcategories()
            self:UpdateSubmitButton()
            self:OnSelectedCategoriesChanged()
        end

        self:SetCategoryContentHidden(false)
        local categoryStringName = impactData.categoryStringName
        local categoryDescriptionStringName = impactData.categoryDescriptionStringName
        for _, categoryData in ipairs(categories) do
            local entry = self.helpCategoryComboBox:CreateItemEntry(GetListEntryName(categoryStringName, categoryData), OnCategoryChanged)
            entry.data = categoryData
            entry.descriptionStringName = categoryDescriptionStringName
            self.helpCategoryComboBox:AddItem(entry, ZO_COMBOBOX_UPDATE_NOW)
        end

        self.helpCategoryComboBox:SelectItemByIndex(1)
    else
        self:SetCategoryContentHidden(true)
    end

    self:UpdateSubcategories()
    self:OnSelectedCategoriesChanged()
end

function HelpAskForHelp_Keyboard:UpdateSubcategories()
    self.helpSubcategoryComboBox:ClearItems()

    local categoryData = self:GetCategoryData()
    local subcategories = categoryData and categoryData.subcategories or nil

    if subcategories then
        local function OnCategoryChanged()
            self:UpdateSubmitButton()
            self:OnSelectedCategoriesChanged()
        end

        self:SetSubcategoryContentHidden(false)
        local subcategoryStringName = categoryData.subcategoryStringName
        local subcategoryDescriptionStringName = categoryData.subcategoryDescriptionStringName
        for _, subcategoryData in ipairs(subcategories) do
            local entry = self.helpSubcategoryComboBox:CreateItemEntry(GetListEntryName(subcategoryStringName, subcategoryData), OnCategoryChanged)
            entry.data = subcategoryData
            entry.descriptionStringName = subcategoryDescriptionStringName
            self.helpSubcategoryComboBox:AddItem(entry, ZO_COMBOBOX_UPDATE_NOW)
        end

        self.helpSubcategoryComboBox:SelectItemByIndex(1)
    else
        self:SetSubcategoryContentHidden(true)
    end
end

function HelpAskForHelp_Keyboard:MeetsExternalInfoRequirements()
    local impactData = self:GetImpactData()
    local requiresExternalInfo = impactData and (impactData.externalInfoTitle ~= nil) or false
    if requiresExternalInfo then
        return self.externalInfo ~= nil
    end
    return true
end

function HelpAskForHelp_Keyboard:SetExternalInfo(externalInfo)
    self.externalInfo = externalInfo
    self.detailsEditBox:SetText("")
    local impactData = self:GetImpactData()
    local meetsExternalInfoRequirements = self:MeetsExternalInfoRequirements()
    local failsExternalInfoRequirements = not meetsExternalInfoRequirements

    -- Instructions
    local instructions = failsExternalInfoRequirements and impactData.externalInfoInstructions
    if instructions then
        self.instructionsText:SetHidden(false)
        self.instructionsText:SetText(instructions)
    else
        self.instructionsText:SetHidden(true)
    end

    -- Details
    local detailsTitle = meetsExternalInfoRequirements and impactData.detailsTitle or nil
    if detailsTitle then
        self:SetDetailsContentHidden(false)
        self.helpDetailsTitle:SetText(detailsTitle)
    else
        self:SetDetailsContentHidden(true)
    end

    -- Description
    self.helpDescriptionTitle:SetHidden(failsExternalInfoRequirements)
    self.helpDescriptionBody:SetHidden(failsExternalInfoRequirements)

    -- External Info
    if impactData and impactData.externalInfoTitle then
        self.externalInfoContainer:SetHidden(failsExternalInfoRequirements)
        self.externalInfoTitle:SetText(impactData.externalInfoTitle)
    else
        self.externalInfoContainer:SetHidden(true)
    end
    
    self:UpdateCategories()
end

function HelpAskForHelp_Keyboard:SetCategoryContentHidden(shouldHide)
    self.helpCategoryComboBoxControl:SetHidden(shouldHide)
    self.helpCategoryTitle:SetHidden(shouldHide)

    local offsetY = 0
    if not shouldHide then
        offsetY = 20
    end
    self.helpCategoryContainer:SetAnchor(TOPLEFT, self.helpImpactComboBoxControl, BOTTOMLEFT, 0, offsetY)

    self:OnSelectedCategoriesChanged()
end

function HelpAskForHelp_Keyboard:SetSubcategoryContentHidden(shouldHide)
    self.helpSubcategoryComboBoxControl:SetHidden(shouldHide)
    self.helpSubcategoryTitle:SetHidden(shouldHide)

    local offsetY = 0
    if not shouldHide then
        offsetY = 20
    end
    self.helpSubcategoryContainer:SetAnchor(TOPLEFT, self.helpCategoryContainer, BOTTOMLEFT, 0, offsetY)
end

function HelpAskForHelp_Keyboard:SetDetailsContentHidden(shouldHide)
    self.helpDetailsTextControl:SetHidden(shouldHide)
    self.helpDetailsTitle:SetHidden(shouldHide)
    ZO_DefaultEdit_SetEnabled(self.detailsEditBox, not shouldHide)

    local offsetY = 0
    if not shouldHide then
        offsetY = 20
    end
    self.helpDetailsContainer:SetAnchor(TOPLEFT, self.helpSubcategoryContainer, BOTTOMLEFT, 0, offsetY)
end

function HelpAskForHelp_Keyboard:UpdateSubmitButton()
    local enableSubmitButton = true

    if not self.instructionsText:IsHidden() then
        enableSubmitButton = false
    elseif not self.helpDetailsTextControl:IsHidden() and self.detailsEditBox:GetText() == "" then
        enableSubmitButton = false
    elseif not self:GetSelectedTicketCategory() then
        enableSubmitButton = false
    end

    self.helpSubmitButton:SetEnabled(enableSubmitButton)
end

function HelpAskForHelp_Keyboard:ClearFields()
    self.helpImpactComboBox:SelectItemByIndex(1)
    self.description:SetText("")
    self:SetAdditionalInstructions(nil)
    ZO_HELP_GENERIC_TICKET_SUBMISSION_MANAGER:SetReportPlayerTicketSubmittedCallback(nil)

    ResetCustomerServiceTicket()
end

function HelpAskForHelp_Keyboard:SelectImpact(impactId)
    local impacts = self.helpImpactComboBox:GetItems()

    for i, impactItem in ipairs(impacts) do
        if impactItem.data.id == impactId then
            local PERFORM_CALLBACK = false
            self.helpImpactComboBox:SelectItemByIndex(i, PERFORM_CALLBACK)
            break
        end
    end
end

function HelpAskForHelp_Keyboard:SelectCategory(categoryId)
    local categories = self.helpCategoryComboBox:GetItems()

    for i, categoryItem in ipairs(categories) do
        if categoryItem.data.id == categoryId then
            local PERFORM_CALLBACK = false
            self.helpCategoryComboBox:SelectItemByIndex(i, PERFORM_CALLBACK)
            break
        end
    end

    self:OnSelectedCategoriesChanged()
end

function HelpAskForHelp_Keyboard:SelectSubcategory(subcategoryId)
    local subcategories = self.helpSubcategoryComboBox:GetItems()

    for i, subcategoryItem in ipairs(subcategories) do
        if subcategoryItem.data.id == subcategoryId then
            local PERFORM_CALLBACK = false
            self.helpSubcategoryComboBox:SelectItemByIndex(i, PERFORM_CALLBACK)
            break
        end
    end
end

function HelpAskForHelp_Keyboard:SetDetailsText(text)
    self.details:SetText(text)
end

function HelpAskForHelp_Keyboard:SetAdditionalInstructions(additionalInstructions)
    if additionalInstructions ~= nil and additionalInstructions ~= "" then
        self.additionalInstructionsText:SetText(additionalInstructions)
        self.additionalInstructionsText:SetHidden(false)
    else
        self.additionalInstructionsText:SetHidden(true)
    end
end

function HelpAskForHelp_Keyboard:OpenAskForHelp(impactId, categoryId, subcategoryId, externalInfo)
    HELP_CUSTOMER_SUPPORT_KEYBOARD:OpenScreen(HELP_CUSTOMER_SERVICE_ASK_FOR_HELP_KEYBOARD_FRAGMENT)
    self:ClearFields()

    if impactId then
        self:SelectImpact(impactId)

        if categoryId then
            self:SelectCategory(categoryId)

            if subcategoryId then
                self:SelectSubcategory(subcategoryId)
            end
        end
    end

    if externalInfo then
        local impactData = self:GetImpactData()
        if impactData then
            if impactData.externalInfoRegistrationFunction then
                impactData.externalInfoRegistrationFunction(externalInfo)
            end
            if impactData.externalInfoTitle then
                self:SetExternalInfo(externalInfo)
            else
                self.detailsEditBox:SetText(externalInfo)
                ZO_DefaultEdit_SetEnabled(self.detailsEditBox, false)
            end
        end
    end
end

function HelpAskForHelp_Keyboard:GetSelectedTicketCategoryData()
    local impactData = self:GetImpactData()
    if impactData then
        if impactData.ticketCategory then
            return impactData
        else
            local categoryData = self:GetCategoryData()
            if categoryData then
                if categoryData.ticketCategory then
                    return categoryData
                else
                    local subcategoryData = self:GetSubcategoryData()
                    if subcategoryData then
                        return subcategoryData
                    end
                end
            end
        end
    end
    return nil
end

function HelpAskForHelp_Keyboard:GetSelectedTicketCategory()
    local ticketCategoryData = self:GetSelectedTicketCategoryData()
    return ticketCategoryData and ticketCategoryData.ticketCategory or nil
end

function HelpAskForHelp_Keyboard:OnExternalInfoMouseEnter()
    local impactData = self:GetImpactData()
    if impactData.externalInfoKeyboardTooltipFunction then
        impactData.externalInfoKeyboardTooltipFunction()
    end
end

function HelpAskForHelp_Keyboard:OnExternalInfoMouseExit()
    ClearTooltip(InformationTooltip)
end

function HelpAskForHelp_Keyboard:ShowGroupFinderListingTooltip()
    InitializeTooltip(InformationTooltip, self.externalInfoContainer, RIGHT, -5, 0)
    local externalInfo = self.externalInfo
    local owner = ZO_WHITE:Colorize(ZO_GetPrimaryPlayerName(externalInfo.ownerDisplayName, externalInfo.ownerCharacterName))
    local title = ZO_WHITE:Colorize(externalInfo.title)
    local description = ZO_WHITE:Colorize(externalInfo.description)
    local text = zo_strformat(SI_GROUP_FINDER_LISTING_ASK_FOR_HELP_KEYBOARD_TOOLTIP_FORMATTER, owner, title, description)
    SetTooltipText(InformationTooltip, EscapeMarkup(text, ALLOW_MARKUP_TYPE_COLOR_ONLY))
end

function HelpAskForHelp_Keyboard:ShowHouseTourListingTooltip()
    InitializeTooltip(InformationTooltip, self.externalInfoContainer, RIGHT, -5, 0)
    local externalInfo = self.externalInfo
    local owner = ZO_WHITE:Colorize(externalInfo.ownerDisplayName)
    local nickname = ZO_WHITE:Colorize(externalInfo.nickname)
    local text = zo_strformat(SI_HOUSE_TOURS_LISTING_ASK_FOR_HELP_KEYBOARD_TOOLTIP_FORMATTER, owner, nickname)
    SetTooltipText(InformationTooltip, EscapeMarkup(text, ALLOW_MARKUP_TYPE_COLOR_ONLY))
end

function HelpAskForHelp_Keyboard:AttemptToSendTicket()
    local ticketCategoryData = self:GetSelectedTicketCategoryData()
    local includeScreenshot = ticketCategoryData and ticketCategoryData.includeScreenshot or false
    if includeScreenshot and not ZO_HELP_GENERIC_TICKET_SUBMISSION_MANAGER:CanSubmitFeedbackWithScreenshot() then
        ZO_Dialogs_ShowDialog("CUSTOMER_SERVICE_TICKET_SCREENSHOT_COOLDOWN")
        return
    end

    --Populate the ticket fields. Impact data must be selected in order to get here.
    local impactData = self:GetImpactData()
    local retainTargetInfo = impactData.externalInfoRegistrationFunction ~= nil
    ResetCustomerServiceTicket(retainTargetInfo)

    SetCustomerServiceTicketCategory(self:GetSelectedTicketCategory())

    local detailsText = self.detailsEditBox:GetText()
    if impactData.detailsRegistrationFunction then
        local formattedDetails = detailsText
        if impactData.detailsRegistrationFormatText then
            formattedDetails = impactData.detailsRegistrationFormatText(formattedDetails)
        end
        impactData.detailsRegistrationFunction(formattedDetails)
    end

    SetCustomerServiceTicketBody(self.description:GetText())
    SetCustomerServiceTicketIncludeScreenshot(includeScreenshot)

    if impactData.id == CUSTOMER_SERVICE_ASK_FOR_HELP_IMPACT_REPORT_PLAYER then
        -- details should always be a string in this case
        ZO_HELP_GENERIC_TICKET_SUBMISSION_MANAGER:MarkAttemptingToSubmitReportPlayerTicket(detailsText)
    elseif impactData.id == CUSTOMER_SERVICE_ASK_FOR_HELP_IMPACT_REPORT_GROUP_FINDER_LISTING then
        ZO_HELP_GENERIC_TICKET_SUBMISSION_MANAGER:MarkAttemptingToSubmitReportPlayerTicket(self.externalInfo.ownerDisplayName)
    end

    ZO_DefaultEdit_SetEnabled(self.detailsEditBox, true)

    ZO_Dialogs_ShowDialog("HELP_CUSTOMER_SERVICE_SUBMITTING_TICKET_DIALOG")
    SubmitCustomerServiceTicket()
end

function HelpAskForHelp_Keyboard:OnCustomerServiceTicketSubmitted(response, success)
    if success then
        self:ClearFields()
    end
end

function HelpAskForHelp_Keyboard:OnSelectedCategoriesChanged()
    local additionalInstructions = ""
    local categoryData = self:GetSelectedTicketCategoryData()
    if categoryData then
        additionalInstructions = categoryData.additionalInstructions or additionalInstructions
    end
    self:SetAdditionalInstructions(additionalInstructions)
end

--Global XML

function ZO_HelpAskForHelp_Keyboard_OnInitialized(self)
    HELP_CUSTOMER_SERVICE_ASK_FOR_HELP_KEYBOARD = HelpAskForHelp_Keyboard:New(self)
end

function ZO_HelpAskForHelp_OnForumLinkClicked()
    ZO_PlatformOpenApprovedURL(APPROVED_URL_ESO_FORUMS, GetString(SI_CUSTOMER_SERVICE_ESO_FORUMS_LINK_TEXT), GetString(SI_URL_APPLICATION_WEB))
end