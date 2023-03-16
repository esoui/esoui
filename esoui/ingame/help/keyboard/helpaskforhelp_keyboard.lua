local GetListEntryName = ZO_GetAskForHelpListEntryName

local HelpAskForHelp_Keyboard = ZO_HelpScreenTemplate_Keyboard:Subclass()

function HelpAskForHelp_Keyboard:New(...)
    return ZO_HelpScreenTemplate_Keyboard.New(self, ...)
end

function HelpAskForHelp_Keyboard:Initialize(control)
    HELP_CUSTOMER_SERVICE_ASK_FOR_HELP_KEYBOARD_FRAGMENT = ZO_FadeSceneFragment:New(control)

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
    self.helpDetailsTextControl = control:GetNamedChild("DetailsTextLine")

    self.helpCategoryContainer = control:GetNamedChild("CategoryContainer")
    self.helpSubcategoryContainer = control:GetNamedChild("SubcategoryContainer")
    self.helpDetailsContainer = control:GetNamedChild("DetailsContainer")

    self.helpImpactComboBoxControl = control:GetNamedChild("ImpactComboBox")
    self.helpCategoryComboBoxControl = control:GetNamedChild("CategoryComboBox")
    self.helpSubcategoryComboBoxControl = control:GetNamedChild("SubcategoryComboBox")

    self.helpSubmitButton = control:GetNamedChild("SubmitButton")

    ZO_HELP_GENERIC_TICKET_SUBMISSION_MANAGER:RegisterCallback("CustomerServiceTicketSubmitted", function (...)
        if HELP_CUSTOMER_SERVICE_ASK_FOR_HELP_KEYBOARD_FRAGMENT:IsShowing() then
            self:OnCustomerServiceTicketSubmitted(...)
        end
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
        self:UpdateCategories()
        self:UpdateDetailsComponents()
        self:UpdateSubmitButton()
        ZO_HELP_GENERIC_TICKET_SUBMISSION_MANAGER:SetReportPlayerTicketSubmittedCallback(nil)
    end

    local impactStringName = ZO_HELP_ASK_FOR_HELP_CATEGORY_INFO.impactStringName
    local impacts = ZO_HELP_ASK_FOR_HELP_CATEGORY_INFO.impacts
    for _, impactData in ipairs(impacts) do
        local entry = ZO_ComboBox:CreateItemEntry(GetListEntryName(impactStringName, impactData), OnImpactChanged)
        entry.data = impactData
        self.helpImpactComboBox:AddItem(entry, ZO_COMBOBOX_SUPPRESS_UPDATE)
    end

    self.helpImpactComboBox:SelectItemByIndex(1)
end

function HelpAskForHelp_Keyboard:InitializeTextBoxes()
    self.details = self.control:GetNamedChild("DetailsTextLineField")
    self.details:SetMaxInputChars(MAX_HELP_DETAILS_TEXT)
    self.details:SetDefaultText(GetString(SI_CUSTOMER_SERVICE_ENTER_NAME))

    --Storing the text field and adding handlers to the visibility events so the Submit Button can be enabled/disabled when the player has typed something in
    --The Submit Button is disabled when the details text is empty (and the details text is visible)
    self.details:SetHandler("OnTextChanged",function() self:UpdateSubmitButton() end)

    self.description = self.control:GetNamedChild("DescriptionBodyField")
    self.description:SetMaxInputChars(MAX_HELP_DESCRIPTION_BODY)
    self.description:SetDefaultText(GetString(SI_CUSTOMER_SERVICE_DEFAULT_DESCRIPTION_TEXT_GENERIC))

    --The Submit Button is disabled if the description text is empty
    self.description:SetHandler("OnTextChanged",function() self:UpdateSubmitButton() end)

    self.description:SetText("")
    self.details:SetText("")
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

function HelpAskForHelp_Keyboard:UpdateCategories()
    self.helpCategoryComboBox:ClearItems()

    local selectedItemData = self.helpImpactComboBox:GetSelectedItemData()
    local impactData = selectedItemData and selectedItemData.data or nil
    local categories = impactData and impactData.categories or nil

    if categories then
        local function OnCategoryChanged()
            self:UpdateSubcategories()
            self:UpdateSubmitButton()
        end

        self:SetCategoryContentHidden(false)
        local categoryStringName = impactData.categoryStringName
        local categoryDescriptionStringName = impactData.categoryDescriptionStringName
        for _, categoryData in ipairs(categories) do
            local entry = ZO_ComboBox:CreateItemEntry(GetListEntryName(categoryStringName, categoryData), OnCategoryChanged)
            entry.data = categoryData
            entry.descriptionStringName = categoryDescriptionStringName
            self.helpCategoryComboBox:AddItem(entry, ZO_COMBOBOX_UPDATE_NOW)
        end

        self.helpCategoryComboBox:SelectItemByIndex(1)
    else
        self:SetCategoryContentHidden(true)
    end
    
    self:UpdateSubcategories()
end

function HelpAskForHelp_Keyboard:UpdateSubcategories()
    self.helpSubcategoryComboBox:ClearItems()

    local selectedItemData = self.helpCategoryComboBox:GetSelectedItemData()
    local categoryData = selectedItemData and selectedItemData.data or nil
    local subcategories = categoryData and categoryData.subcategories or nil

    if subcategories then
        local function OnCategoryChanged()
            self:UpdateSubmitButton()
        end

        self:SetSubcategoryContentHidden(false)
        local subcategoryStringName = categoryData.subcategoryStringName
        local subcategoryDescriptionStringName = categoryData.subcategoryDescriptionStringName
        for _, subcategoryData in ipairs(subcategories) do
            local entry = ZO_ComboBox:CreateItemEntry(GetListEntryName(subcategoryStringName, subcategoryData), OnCategoryChanged)
            entry.data = subcategoryData
            entry.descriptionStringName = subcategoryDescriptionStringName
            self.helpSubcategoryComboBox:AddItem(entry, ZO_COMBOBOX_UPDATE_NOW)
        end

        self.helpSubcategoryComboBox:SelectItemByIndex(1)
    else
        self:SetSubcategoryContentHidden(true)
    end
end

function HelpAskForHelp_Keyboard:UpdateDetailsComponents()
    self.details:SetText("")

    local selectedItemData = self.helpImpactComboBox:GetSelectedItemData()
    local impactData = selectedItemData and selectedItemData.data or nil
    local detailsTitle = impactData and impactData.detailsTitle or nil
        
    if detailsTitle then
        self:SetDetailsContentHidden(false)
        self.helpDetailsTitle:SetText(detailsTitle)
    else
        self:SetDetailsContentHidden(true)
    end
end

function HelpAskForHelp_Keyboard:SetCategoryContentHidden(shouldHide)
    self.helpCategoryComboBoxControl:SetHidden(shouldHide)
    self.helpCategoryTitle:SetHidden(shouldHide)

    local offsetY = 0
    if not shouldHide then
        offsetY = 20
    end
    self.helpCategoryContainer:SetAnchor(TOPLEFT, self.helpImpactComboBoxControl, BOTTOMLEFT, 0, offsetY)
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
    ZO_DefaultEdit_SetEnabled(self.details, not shouldHide)

    local offsetY = 0
    if not shouldHide then
        offsetY = 20
    end
    self.helpDetailsContainer:SetAnchor(TOPLEFT, self.helpSubcategoryContainer, BOTTOMLEFT, 0, offsetY)
end

function HelpAskForHelp_Keyboard:UpdateSubmitButton()
    local enableSubmitButton = true

    if self.description:GetText() == ""  then
        enableSubmitButton = false
    elseif not self.helpDetailsTextControl:IsHidden() and self.details:GetText() == "" then
        enableSubmitButton = false
    elseif not self:GetSelectedTicketCategory() then
        enableSubmitButton = false
    end

    self.helpSubmitButton:SetEnabled(enableSubmitButton)
end

function HelpAskForHelp_Keyboard:ClearFields()
    self.helpImpactComboBox:SelectItemByIndex(1)
    self.description:SetText("")
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

function HelpAskForHelp_Keyboard:OpenAskForHelp(impactId, categoryId, subcategoryId, details)
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

    if details then
        self:SetDetailsText(details)
        ZO_DefaultEdit_SetEnabled(self.details, false)
    end
end

function HelpAskForHelp_Keyboard:GetSelectedTicketCategory()
    local selectedItemData = self.helpImpactComboBox:GetSelectedItemData()
    local impactData = selectedItemData and selectedItemData.data
    if impactData then
        if impactData.ticketCategory then
            return impactData.ticketCategory
        else
            selectedItemData = self.helpCategoryComboBox:GetSelectedItemData()
            local categoryData = selectedItemData and selectedItemData.data
            if categoryData then
                if categoryData.ticketCategory then
                    return categoryData.ticketCategory
                else
                    selectedItemData = self.helpSubcategoryComboBox:GetSelectedItemData()
                    local subcategoryData = selectedItemData and selectedItemData.data
                    if subcategoryData then
                        return subcategoryData.ticketCategory
                    end
                end
            end
        end
    end
    return nil
end

function HelpAskForHelp_Keyboard:AttemptToSendTicket()
    ResetCustomerServiceTicket()

    --Populate the ticket fields.  Impact data must be selected in order to get here.
    SetCustomerServiceTicketCategory(self:GetSelectedTicketCategory())

    local impactData = self.helpImpactComboBox:GetSelectedItemData().data
    local detailsText = self.details:GetText()
    if impactData.detailsRegistrationFunction then
        local text = detailsText
        if impactData.detailsFormatText then
            text = impactData.detailsFormatText(text)
        end
        impactData.detailsRegistrationFunction(text)
    end

    SetCustomerServiceTicketBody(self.description:GetText())

    ZO_Dialogs_ShowDialog("HELP_CUSTOMER_SERVICE_SUBMITTING_TICKET_DIALOG")

    if impactData.id == CUSTOMER_SERVICE_ASK_FOR_HELP_IMPACT_REPORT_PLAYER then
        ZO_HELP_GENERIC_TICKET_SUBMISSION_MANAGER:MarkAttemptingToSubmitReportPlayerTicket(detailsText)
    end

    ZO_DefaultEdit_SetEnabled(self.details, true)

    SubmitCustomerServiceTicket()
end

function HelpAskForHelp_Keyboard:OnCustomerServiceTicketSubmitted(response, success)
    if success then
        self:ClearFields()
    end
end

--Global XML

function ZO_HelpAskForHelp_Keyboard_OnInitialized(self)
    HELP_CUSTOMER_SERVICE_ASK_FOR_HELP_KEYBOARD = HelpAskForHelp_Keyboard:New(self)
end

function ZO_HelpAskForHelp_Keyboard_AttemptToSendTicket()
    HELP_CUSTOMER_SERVICE_ASK_FOR_HELP_KEYBOARD:AttemptToSendTicket()
end

function ZO_HelpAskForHelp_OnForumLinkClicked()
    ZO_PlatformOpenApprovedURL(APPROVED_URL_ESO_FORUMS, GetString(SI_CUSTOMER_SERVICE_ESO_FORUMS_LINK_TEXT), GetString(SI_URL_APPLICATION_WEB))
end