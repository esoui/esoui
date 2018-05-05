ZO_HelpMechanicAssistanceTemplate_Keyboard = ZO_HelpScreenTemplate_Keyboard:Subclass()

function ZO_HelpMechanicAssistanceTemplate_Keyboard:New(...)
    return ZO_HelpScreenTemplate_Keyboard.New(self, ...)
end

function ZO_HelpMechanicAssistanceTemplate_Keyboard:Initialize(control, customerServiceCategoryData, mechanicCategoriesData)
    local fragment = ZO_FadeSceneFragment:New(control)
    customerServiceCategoryData.categoryFragment = fragment
    ZO_HelpScreenTemplate_Keyboard.Initialize(self, control, customerServiceCategoryData)

    self.mechanicCategoriesData = mechanicCategoriesData
    self.helpCategoryTitle = control:GetNamedChild("CategoryTitle")
    self.helpDetailsTitle = control:GetNamedChild("DetailsTitle")
    self.helpExtraInfoTitle = control:GetNamedChild("ExtraInfoTitle")
    self.helpDescriptionTitle = control:GetNamedChild("DescriptionTitle")
    self.helpDetailsTextControl = control:GetNamedChild("DetailsTextLine")

    self.helpDetailsContainer = control:GetNamedChild("DetailsContainer")
    self.helpExtraInfoContainer = control:GetNamedChild("ExtraInfoContainer")

    self.helpCategoryComboBoxControl = control:GetNamedChild("CategoryComboBox")

    self.helpSubmitButton = control:GetNamedChild("SubmitButton")

    self.helpExtraInfoTitle:SetText(self:GetExtraInfoText())
    
    ZO_HELP_GENERIC_TICKET_SUBMISSION_MANAGER:RegisterCallback("CustomerServiceTicketSubmitted", function (...)
                                                                        if fragment:IsShowing() then
                                                                            self:OnCustomerServiceTicketSubmitted(...)
                                                                        end
                                                                    end)

    fragment:RegisterCallback("StateChange",  function(oldState, newState)
        if newState == SCENE_FRAGMENT_HIDDEN then
            self:ClearFields()
        end
    end)

    self.fragment = fragment
    self:InitializeTextBoxes()
    self:InitializeComboBox()
end

function ZO_HelpMechanicAssistanceTemplate_Keyboard:InitializeComboBox()
    local combo = ZO_ComboBox_ObjectFromContainer(self.control:GetNamedChild("CategoryComboBox"))
    combo:SetSortsItems(false)
    combo:SetFont("ZoFontWinT1")
    combo:SetSpacing(4)
    self.helpCategoryComboBox = combo
    local mechanicCategoriesData = self.mechanicCategoriesData
    for _, enumValue in ipairs(mechanicCategoriesData.categoryEnumOrderedValues) do
        local name = GetString(mechanicCategoriesData.categoryEnumStringPrefix, enumValue)
        if name ~= nil then
            local entry = ZO_ComboBox:CreateItemEntry(name, function() self:UpdateSubmitButton() end)
            entry.categoryEnumValue = enumValue
            self.helpCategoryComboBox:AddItem(entry, ZO_COMBOBOX_SUPRESS_UPDATE)
        end
    end

    self.helpCategoryComboBox:SelectItemByIndex(1)
end

function ZO_HelpMechanicAssistanceTemplate_Keyboard:InitializeTextBoxes()
    self.details = self.control:GetNamedChild("DetailsTextLine")
    local function SetTextOverride(label, text)
        if text ~= "" then
            ZO_LABEL_TEMPLATE_DUMMY_LABEL.SetText(label, text)
            label.hasValue = true
        else
            ZO_LABEL_TEMPLATE_DUMMY_LABEL.SetText(label, self:GetDetailsInstructions())
            label.hasValue = false
        end
    end
    self.details.SetText = SetTextOverride

    self.description = self.control:GetNamedChild("DescriptionBodyField")
    self.description:SetMaxInputChars(MAX_HELP_DESCRIPTION_BODY)
    ZO_EditDefaultText_Initialize(self.description, GetString(SI_CUSTOMER_SERVICE_DEFAULT_DESCRIPTION_TEXT_GENERIC))

    --Storing the text field and adding handlers to the visibility events so the Submit Button can be enabled/disabled when the player has typed something in
    --The Submit Button is disabled if the description text is empty
    self.descriptionDefaultTextField = self.description:GetNamedChild("Text")
    
    local function UpdateSubmitButton()
        self:UpdateSubmitButton()
    end
    self.descriptionDefaultTextField:SetHandler("OnEffectivelyShown", UpdateSubmitButton)
    self.descriptionDefaultTextField:SetHandler("OnEffectivelyHidden", UpdateSubmitButton)

    self.description:SetText("")
end

function ZO_HelpMechanicAssistanceTemplate_Keyboard:GetExtraInfoText()
    return "" -- To be overriden
end

function ZO_HelpMechanicAssistanceTemplate_Keyboard:GetDetailsInstructions()
    assert(false) -- Must be override
end

function ZO_HelpMechanicAssistanceTemplate_Keyboard:GetFragment()
    return self.fragment
end

function ZO_HelpMechanicAssistanceTemplate_Keyboard:DetailsRequired()
    return false
end

function ZO_HelpMechanicAssistanceTemplate_Keyboard:UpdateSubmitButton()
    local enableSubmitButton = true

    if self.helpCategoryComboBox:GetSelectedItemData().categoryEnumValue == self.mechanicCategoriesData.invalidCategory then
        enableSubmitButton = false
    elseif not self.details.hasValue and self:DetailsRequired() then
        enableSubmitButton = false
    elseif not self.description:IsHidden() and not self.descriptionDefaultTextField:IsHidden() then
        enableSubmitButton = false
    end
    
    self.helpSubmitButton:SetEnabled(enableSubmitButton)
end

function ZO_HelpMechanicAssistanceTemplate_Keyboard:ClearFields()
    self.helpCategoryComboBox:SelectItemByIndex(1)
    self.details:SetText("")
    self.description:SetText("")

    ResetCustomerServiceTicket()
end

function ZO_HelpMechanicAssistanceTemplate_Keyboard:SelectCategory(category)
    local categories = self.helpCategoryComboBox:GetItems()

    for i, categoryId in ipairs(categories) do
        if categoryId.categoryEnumValue == category then
            local PERFORM_CALLBACK = false
            self.helpCategoryComboBox:SelectItemByIndex(i, PERFORM_CALLBACK)
            break
        end
    end
end

function ZO_HelpMechanicAssistanceTemplate_Keyboard:SetDetailsText(text)
    self:ClearFields()
    self.details:SetText(text)
end

function ZO_HelpMechanicAssistanceTemplate_Keyboard:GetDetailsText()
    return self.details:GetText()
end

function ZO_HelpMechanicAssistanceTemplate_Keyboard:RegisterDetails()
    assert(false) -- Must be overriden
end

function ZO_HelpMechanicAssistanceTemplate_Keyboard:Open(category)
    HELP_CUSTOMER_SUPPORT_KEYBOARD:OpenScreen(self.fragment)
    self:ClearFields()

    if category then
        self:SelectCategory(category)
    end
end

function ZO_HelpMechanicAssistanceTemplate_Keyboard:AttemptToSendTicket()
    ResetCustomerServiceTicket()

    --Populate the ticket fields
    SetCustomerServiceTicketContactEmail(GetActiveUserEmailAddress())
    
    --Category value must be valid as it enables the submit button to be clicked on
    local categoryEnumValue = self.helpCategoryComboBox:GetSelectedItemData().categoryEnumValue
    local infoMap = self.mechanicCategoriesData.ticketCategoryMap[categoryEnumValue]
    SetCustomerServiceTicketCategory(infoMap.ticketCategory)
    if self.details.hasValue then
        self:RegisterDetails()
    end
    SetCustomerServiceTicketBody(self.description:GetText())

    ZO_Dialogs_ShowDialog("HELP_CUSTOMER_SERVICE_SUBMITTING_TICKET_DIALOG")

    SubmitCustomerServiceTicket()
end

function ZO_HelpMechanicAssistanceTemplate_Keyboard:OnCustomerServiceTicketSubmitted(response, success)
    if success then
        self:ClearFields()
    end
end