local HELP_CUSTOMER_SERVICE_INCOMPLETED_FIELDS_DIALOG = "HELP_CUSTOMER_SERVICE_INCOMPLETED_FIELDS_DIALOG"
local lastSubmitTime = 0

local HelpSubmitFeedback_Keyboard = ZO_HelpScreenTemplate_Keyboard:Subclass()

function HelpSubmitFeedback_Keyboard:New(...)
    return ZO_HelpScreenTemplate_Keyboard.New(self, ...)
end

function HelpSubmitFeedback_Keyboard:Initialize(control)
    HELP_CUSTOMER_SERVICE_SUBMIT_FEEDBACK_KEYBOARD_FRAGMENT = ZO_FadeSceneFragment:New(control)
    
    local iconData =
    {
        name = GetString(SI_CUSTOMER_SERVICE_SUBMIT_FEEDBACK),
        categoryFragment = HELP_CUSTOMER_SERVICE_SUBMIT_FEEDBACK_KEYBOARD_FRAGMENT,
        up = "EsoUI/Art/Help/help_tabIcon_feedback_up.dds",
        down = "EsoUI/Art/Help/help_tabIcon_feedback_down.dds",
        over = "EsoUI/Art/Help/help_tabIcon_feedback_over.dds",
    }
    ZO_HelpScreenTemplate_Keyboard.Initialize(self, control, iconData)

    self.helpScrollChild = control:GetNamedChild("ScrollContainerScrollChild")
    self.helpImpactTitle = self.helpScrollChild:GetNamedChild("ImpactTitle")
    self.helpCategoryTitle = self.helpScrollChild:GetNamedChild("CategoryTitle")
    self.helpSubcategoryTitle = self.helpScrollChild:GetNamedChild("SubcategoryTitle")
    self.helpDetailsTitle = self.helpScrollChild:GetNamedChild("DetailsTitle")
    self.helpDescriptionTitle = self.helpScrollChild:GetNamedChild("DescriptionTitle")
    self.helpSubmitButton = self.helpScrollChild:GetNamedChild("SubmitButton")
    self.helpDetailsTextControl = self.helpScrollChild:GetNamedChild("DetailsTextLine")

    self.helpSubcategoryContainer = self.helpScrollChild:GetNamedChild("SubcategoryContainer")
    self.helpDetailsContainer = self.helpScrollChild:GetNamedChild("DetailsContainer")

    self.helpCategoryComboBoxControl = self.helpScrollChild:GetNamedChild("CategoryComboBox")
    self.helpSubcategoryComboBoxControl = self.helpScrollChild:GetNamedChild("SubcategoryComboBox")

    ZO_HELP_GENERIC_TICKET_SUBMISSION_MANAGER:RegisterCallback("CustomerServiceFeedbackSubmitted", function (...) self:OnCustomerServiceFeedbackSubmitted(...) end)

    self:InitializeTextBox()
    self:InitializeComboBoxes()
    self:InitializeCheckButton()
end

function HelpSubmitFeedback_Keyboard:InitializeComboBoxes()

    local function CreateComboBox(childName)
        local combo = ZO_ComboBox_ObjectFromContainer(self.helpScrollChild:GetNamedChild(childName))
        combo:SetSortsItems(false)
        combo:SetFont("ZoFontWinT1")
        combo:SetSpacing(4)
        return combo
    end

    self.helpImpactComboBox = CreateComboBox("ImpactComboBox")
    self.helpCategoryComboBox = CreateComboBox("CategoryComboBox")
    self.helpSubcategoryComboBox = CreateComboBox("SubcategoryComboBox")

    local function SetupComboBox(comboBox, fieldData, callback)
        if fieldData.universallyAddEnum then
            local entry = ZO_ComboBox:CreateItemEntry(GetString(fieldData.enumStringPrefix, fieldData.universallyAddEnum), callback)
            entry.index = fieldData.universallyAddEnum
            comboBox:AddItem(entry, ZO_COMBOBOX_SUPRESS_UPDATE)
        end

        local iterationEntries = {}
        for i = fieldData.iterationBegin, fieldData.iterationEnd do
            local entry = ZO_ComboBox:CreateItemEntry(GetString(fieldData.enumStringPrefix, i), callback)
            entry.index = i
            table.insert(iterationEntries, entry)
        end

        if fieldData.sortFunction then
            table.sort(iterationEntries, fieldData.sortFunction)
        end

        for _, entry in ipairs(iterationEntries) do
            comboBox:AddItem(entry, ZO_COMBOBOX_SUPRESS_UPDATE)
        end

        comboBox:SelectItemByIndex(1)
    end

    local function OnCategoryChanged()
        self:UpdateSubcategories()
        self:UpdateDetailsComponents()
        self:UpdateSubmitButton()
    end

    SetupComboBox(self.helpImpactComboBox, ZO_HELP_SUBMIT_FEEDBACK_FIELD_DATA[ZO_HELP_TICKET_FIELD_TYPE.IMPACT], function() self:UpdateSubmitButton() end)
    SetupComboBox(self.helpCategoryComboBox, ZO_HELP_SUBMIT_FEEDBACK_FIELD_DATA[ZO_HELP_TICKET_FIELD_TYPE.CATEGORY], OnCategoryChanged)
end

function HelpSubmitFeedback_Keyboard:InitializeTextBox()
    self.details = self.helpScrollChild:GetNamedChild("DetailsTextLineField")
    self.details:SetMaxInputChars(MAX_HELP_DETAILS_TEXT)
    ZO_EditDefaultText_Initialize(self.details, GetString(SI_CUSTOMER_SERVICE_ENTER_NAME))

    --Storing the text field and adding handlers to the visibility events so the Submit Button can be enabled/disabled when the player has typed something in
    --The Submit Button is disabled when the details text is empty (and the details text is visible)
    self.detailsDefaultTextField = self.details:GetNamedChild("Text")
    self.detailsDefaultTextField:SetHandler("OnEffectivelyShown",function() self:UpdateSubmitButton() end)
    self.detailsDefaultTextField:SetHandler("OnEffectivelyHidden",function() self:UpdateSubmitButton() end)

    self.description = self.helpScrollChild:GetNamedChild("DescriptionBodyField")
    self.description:SetMaxInputChars(MAX_HELP_DESCRIPTION_BODY)
    ZO_EditDefaultText_Initialize(self.description, GetString(SI_CUSTOMER_SERVICE_DEFAULT_DESCRIPTION_TEXT_FEEDBACK))

    --The Submit Button is disabled when the description text is empty
    self.descriptionDefaultTextField = self.description:GetNamedChild("Text")
    self.descriptionDefaultTextField:SetHandler("OnEffectivelyShown",function() self:UpdateSubmitButton() end)
    self.descriptionDefaultTextField:SetHandler("OnEffectivelyHidden",function() self:UpdateSubmitButton() end)

    self.description:SetText("")
end

function HelpSubmitFeedback_Keyboard:InitializeCheckButton()
    self.helpAttachScreenshotCheckButton = self.helpScrollChild:GetNamedChild("AttachScreenshotCheckButton")
    ZO_CheckButton_SetUnchecked(self.helpAttachScreenshotCheckButton)
end

function HelpSubmitFeedback_Keyboard:UpdateSubcategories()
    local categoryIndex = self.helpCategoryComboBox:GetSelectedItemData().index

    self.helpSubcategoryComboBox:ClearItems()

    local subcategoryData = ZO_HELP_SUBMIT_FEEDBACK_FIELD_DATA[ZO_HELP_TICKET_FIELD_TYPE.SUBCATEGORY]
    self.subcategoryContextualData = subcategoryData.categoryContextualData[categoryIndex]

    if self.subcategoryContextualData == nil then
        self:SetSubcategoryContentHidden(true)
    else
        self:SetSubcategoryContentHidden(false)
        local enumStringPrefix = subcategoryData.enumStringPrefix

        local function OnSubcategoryChanged()
            self:UpdateSubmitButton()
        end

        if subcategoryData.universallyAddEnum then
            local defaultEntry = ZO_ComboBox:CreateItemEntry(GetString(enumStringPrefix, subcategoryData.universallyAddEnum), OnSubcategoryChanged)
            defaultEntry.index = subcategoryData.universallyAddEnum
            self.helpSubcategoryComboBox:AddItem(defaultEntry, ZO_COMBOBOX_UPDATE_NOW)
        end

        for i = self.subcategoryContextualData.iterationBegin, self.subcategoryContextualData.iterationEnd do
            local entry = ZO_ComboBox:CreateItemEntry(GetString(enumStringPrefix, i), OnSubcategoryChanged)
            entry.index = i
            self.helpSubcategoryComboBox:AddItem(entry, ZO_COMBOBOX_UPDATE_NOW)
        end

        if subcategoryData.otherEnum then
            local otherEntry = ZO_ComboBox:CreateItemEntry(GetString(enumStringPrefix, subcategoryData.otherEnum), OnSubcategoryChanged)
            otherEntry.index = subcategoryData.otherEnum
            self.helpSubcategoryComboBox:AddItem(otherEntry, ZO_COMBOBOX_UPDATE_NOW)
        end

        local PERFORM_CALLBACK = false
        self.helpSubcategoryComboBox:SelectItemByIndex(1,PERFORM_CALLBACK)
    end
end

function HelpSubmitFeedback_Keyboard:UpdateDetailsComponents()
    self.details:SetText("")

    if self.subcategoryContextualData then
        if self.subcategoryContextualData.detailsTitle then
            self:SetDetailsContentHidden(false)
            self.helpDetailsTitle:SetText(self.subcategoryContextualData.detailsTitle)
        else
            self:SetDetailsContentHidden(true)
        end
    else
        self:SetDetailsContentHidden(true)
    end
end

function HelpSubmitFeedback_Keyboard:SetSubcategoryContentHidden(shouldHide)
    self.helpSubcategoryComboBoxControl:SetHidden(shouldHide)
    self.helpSubcategoryTitle:SetHidden(shouldHide)

    local offsetY = 0
    if not shouldHide then
        offsetY = 20
    end
    self.helpSubcategoryContainer:SetAnchor(TOPLEFT, self.helpCategoryComboBoxControl, BOTTOMLEFT, 0, offsetY)
end

function HelpSubmitFeedback_Keyboard:SetDetailsContentHidden(shouldHide)
    self.helpDetailsTextControl:SetHidden(shouldHide)
    self.helpDetailsTitle:SetHidden(shouldHide)

    local offsetY = 0
    if not shouldHide then
        offsetY = 20
    end
    self.helpDetailsContainer:SetAnchor(TOPLEFT, self.helpSubcategoryContainer, BOTTOMLEFT, 0, offsetY)
end

function HelpSubmitFeedback_Keyboard:UpdateSubmitButton()
    local enableSubmitButton = true

    if self.helpCategoryComboBox == nil or self.helpImpactComboBox == nil or self.helpSubcategoryComboBox == nil or self.descriptionDefaultTextField == nil then
        enableSubmitButton = false
    elseif self.helpImpactComboBox:GetSelectedItemData().index <= ZO_HELP_SUBMIT_FEEDBACK_FIELD_DATA[ZO_HELP_TICKET_FIELD_TYPE.IMPACT].invalidEntry then
        enableSubmitButton = false
    elseif self.helpCategoryComboBox:GetSelectedItemData().index <= ZO_HELP_SUBMIT_FEEDBACK_FIELD_DATA[ZO_HELP_TICKET_FIELD_TYPE.CATEGORY].invalidEntry then
        enableSubmitButton = false
    elseif not self.helpSubcategoryComboBoxControl:IsHidden() and self.helpSubcategoryComboBox:GetSelectedItemData().index <= ZO_HELP_SUBMIT_FEEDBACK_FIELD_DATA[ZO_HELP_TICKET_FIELD_TYPE.SUBCATEGORY].invalidEntry then
        enableSubmitButton = false
    elseif not self.helpDetailsTextControl:IsHidden() and self.details:GetText() == "" then
        enableSubmitButton = false
    elseif not self.descriptionDefaultTextField:IsHidden() then
        enableSubmitButton = false
    end

    self.helpSubmitButton:SetEnabled(enableSubmitButton)
end

function HelpSubmitFeedback_Keyboard:ClearFields()
    self.helpImpactComboBox:SelectItemByIndex(1)
    self.helpCategoryComboBox:SelectItemByIndex(1)
    self.description:SetText("")
    ZO_CheckButton_SetUnchecked(self.helpAttachScreenshotCheckButton)
end

function HelpSubmitFeedback_Keyboard:AttemptToSendFeedback()
    --Create the Request
    local impactId = self.helpImpactComboBox:GetSelectedItemData().index
    local categoryId = self.helpCategoryComboBox:GetSelectedItemData().index
    local detailsText = self.details:GetText()
    local descriptionText = self.description:GetText()
    local attachScreenshot = ZO_CheckButton_IsChecked(self.helpAttachScreenshotCheckButton)

    local subcategoryId
    if not self.helpSubcategoryComboBoxControl:IsHidden() then
        subcategoryId = self.helpSubcategoryComboBox:GetSelectedItemData().index
    end

    ZO_HELP_GENERIC_TICKET_SUBMISSION_MANAGER:AttemptToSendFeedback(impactId, categoryId, subcategoryId, detailsText, descriptionText, attachScreenshot)
end

function HelpSubmitFeedback_Keyboard:OnCustomerServiceFeedbackSubmitted(eventCode, response, success)
    self:ClearFields()
end

--Global XML

function ZO_HelpSubmitFeedback_Keyboard_OnInitialized(self)
    if IsSubmitFeedbackSupported() then
        HELP_CUSTOMER_SERVICE_SUBMIT_FEEDBACK_KEYBOARD = HelpSubmitFeedback_Keyboard:New(self)
    end
end

function ZO_HelpSubmitFeedback_Keyboard_AttemptToSendFeedback()
    HELP_CUSTOMER_SERVICE_SUBMIT_FEEDBACK_KEYBOARD:AttemptToSendFeedback()
end