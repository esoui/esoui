local HELP_ASK_FOR_HELP_CATEGORY_INFO =
{
	[CUSTOMER_SERVICE_ASK_FOR_HELP_CATEGORY_CHARACTER_ISSUE] =
	{
		ticketCategory = TICKET_CATEGORY_CHARACTER_ISSUE,
	},
	[CUSTOMER_SERVICE_ASK_FOR_HELP_CATEGORY_REPORT_PLAYER] =
	{
		detailsTitle = GetString(SI_CUSTOMER_SERVICE_ASK_FOR_HELP_PLAYER_NAME),
		detailsRegistrationFunction = SetCustomerServiceTicketPlayerTarget,
		detailsFormatText = ZO_FormatManualNameEntry,
		subcategoryStringName = "SI_CUSTOMERSERVICEASKFORHELPREPORTPLAYERSUBCATEGORY",
		subcategories = 
		{
			{
				value = CUSTOMER_SERVICE_ASK_FOR_HELP_REPORT_PLAYER_SUBCATEGORY_NONE,
			},
			{
				value = CUSTOMER_SERVICE_ASK_FOR_HELP_REPORT_PLAYER_SUBCATEGORY_INAPPROPRIATE_NAME,
				ticketCategory = TICKET_CATEGORY_REPORT_BAD_NAME,
			},
			{
				value = CUSTOMER_SERVICE_ASK_FOR_HELP_REPORT_PLAYER_SUBCATEGORY_HARASSMENT,
				ticketCategory = TICKET_CATEGORY_REPORT_HARASSMENT,
			},
			{
				value = CUSTOMER_SERVICE_ASK_FOR_HELP_REPORT_PLAYER_SUBCATEGORY_CHEATING,
				ticketCategory = TICKET_CATEGORY_REPORT_CHEATING,
			},
			{
				value = CUSTOMER_SERVICE_ASK_FOR_HELP_REPORT_PLAYER_SUBCATEGORY_OTHER,
				ticketCategory = TICKET_CATEGORY_REPORT_OTHER,
			},
		},		
	},
}

local ESO_FORUMS_URL_TYPE = {urlType = APPROVED_URL_ESO_FORUMS}
local ESO_FORUMS_FRONT_FACING_ADDRESS = {mainTextParams = {GetString(SI_CUSTOMER_SERVICE_ESO_FORUMS_LINK_TEXT), GetString(SI_URL_APPLICATION_WEB)}}

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

	self.helpSubcategoryContainer = control:GetNamedChild("SubcategoryContainer")
	self.helpDetailsContainer = control:GetNamedChild("DetailsContainer")

	self.helpCategoryComboBoxControl = control:GetNamedChild("CategoryComboBox")
	self.helpSubcategoryComboBoxControl = control:GetNamedChild("SubcategoryComboBox")

	self.helpSubmitButton = control:GetNamedChild("SubmitButton")

	control:RegisterForEvent(EVENT_CUSTOMER_SERVICE_TICKET_SUBMITTED, function (...)
																		if HELP_CUSTOMER_SERVICE_ASK_FOR_HELP_KEYBOARD_FRAGMENT:IsShowing() then
																			self:OnCustomerServiceTicketSubmitted(...)
																		end
																	end)

	self:InitializeTextBoxes()
	self:InitializeComboBoxes()	
	self:InitializeDialogs()
end

function HelpAskForHelp_Keyboard:InitializeComboBoxes()

	local function CreateComboBox(childName)
		local combo = ZO_ComboBox_ObjectFromContainer(self.control:GetNamedChild(childName))
		combo:SetSortsItems(false)
		combo:SetFont("ZoFontWinT1")
		combo:SetSpacing(4)
		return combo
	end

	self.helpCategoryComboBox = CreateComboBox("CategoryComboBox")
	self.helpSubcategoryComboBox = CreateComboBox("SubcategoryComboBox")

	local function OnCategoryChanged(comboBox, entryText, entry)
		self:UpdateSubcategories()
		self:UpdateDetailsComponents()
		self:UpdateSubmitButton()
	end

	for i = CUSTOMER_SERVICE_ASK_FOR_HELP_CATEGORY_MIN_VALUE, CUSTOMER_SERVICE_ASK_FOR_HELP_CATEGORY_MAX_VALUE do
		local name = GetString("SI_CUSTOMERSERVICEASKFORHELPCATEGORIES", i)
		if name ~= nil then
			local entry = ZO_ComboBox:CreateItemEntry(name, OnCategoryChanged)
			entry.index = i
			self.helpCategoryComboBox:AddItem(entry, ZO_COMBOBOX_SUPRESS_UPDATE)
		end
	end

	self.helpCategoryComboBox:SelectItemByIndex(1)
end

function HelpAskForHelp_Keyboard:InitializeTextBoxes()
	self.details = self.control:GetNamedChild("DetailsTextLineField")
    self.details:SetMaxInputChars(MAX_HELP_DETAILS_TEXT)
	ZO_EditDefaultText_Initialize(self.details, GetString(SI_CUSTOMER_SERVICE_ENTER_NAME))

	--Storing the text field and adding handlers to the visibility events so the Submit Button can be enabled/disabled when the player has typed something in
	--The Submit Button is disabled when the details text is empty (and the details text is visible)
	self.detailsDefaultTextField = self.details:GetNamedChild("Text")
	self.detailsDefaultTextField:SetHandler("OnEffectivelyShown",function() self:UpdateSubmitButton() end)
	self.detailsDefaultTextField:SetHandler("OnEffectivelyHidden",function() self:UpdateSubmitButton() end)

	self.description = self.control:GetNamedChild("DescriptionBodyField")
    self.description:SetMaxInputChars(MAX_HELP_DESCRIPTION_BODY)
    ZO_EditDefaultText_Initialize(self.description, GetString(SI_CUSTOMER_SERVICE_DEFAULT_DESCRIPTION_TEXT_ASK_FOR_HELP))

	--The Submit Button is disabled if the description text is empty
	self.descriptionDefaultTextField = self.description:GetNamedChild("Text")
	self.descriptionDefaultTextField:SetHandler("OnEffectivelyShown",function() self:UpdateSubmitButton() end)
	self.descriptionDefaultTextField:SetHandler("OnEffectivelyHidden",function() self:UpdateSubmitButton() end)

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

function HelpAskForHelp_Keyboard:UpdateSubcategories()
	self.helpSubcategoryComboBox:ClearItems()

	local categoryIndex = self.helpCategoryComboBox:GetSelectedItemData().index

	local mainArray = HELP_ASK_FOR_HELP_CATEGORY_INFO[categoryIndex]
		
	if mainArray == nil then
		self:SetSubcategoryContentHidden(true)
	else
		self.subcategoryArray = mainArray.subcategories

		if self.subcategoryArray == nil then
			self:SetSubcategoryContentHidden(true)
		else
			self:SetSubcategoryContentHidden(false)

			for i, subcategoryId in ipairs(self.subcategoryArray) do
				local entry = ZO_ComboBox:CreateItemEntry(GetString(mainArray.subcategoryStringName, subcategoryId.value), function() self:UpdateSubmitButton() end)
				entry.index = i
				self.helpSubcategoryComboBox:AddItem(entry, ZO_COMBOBOX_UPDATE_NOW)
			end

			self.helpSubcategoryComboBox:SelectItemByIndex(1)		
		end
	end
end

function HelpAskForHelp_Keyboard:UpdateDetailsComponents()
	self.details:SetText("")

	local categoryIndex = self.helpCategoryComboBox:GetSelectedItemData().index

	local mainArray = HELP_ASK_FOR_HELP_CATEGORY_INFO[categoryIndex]
		
	if mainArray == nil then
		self:SetDetailsContentHidden(true)
	else
		local title = mainArray.detailsTitle
		if title == nil then
			self:SetDetailsContentHidden(true)
		else
			self:SetDetailsContentHidden(false)
			self.helpDetailsTitle:SetText(title)
		end
	end
end

function HelpAskForHelp_Keyboard:SetSubcategoryContentHidden(shouldHide)
	self.helpSubcategoryComboBoxControl:SetHidden(shouldHide)
	self.helpSubcategoryTitle:SetHidden(shouldHide)

	local offsetY = 0
	if not shouldHide then
		offsetY = 20
	end
	self.helpSubcategoryContainer:SetAnchor(TOPLEFT, self.helpCategoryComboBoxControl, BOTTOMLEFT, 0, offsetY)
end

function HelpAskForHelp_Keyboard:SetDetailsContentHidden(shouldHide)
	self.helpDetailsTextControl:SetHidden(shouldHide)
	self.helpDetailsTitle:SetHidden(shouldHide)

	local offsetY = 0
	if not shouldHide then
		offsetY = 20
	end
	self.helpDetailsContainer:SetAnchor(TOPLEFT, self.helpSubcategoryContainer, BOTTOMLEFT, 0, offsetY)
end

function HelpAskForHelp_Keyboard:UpdateSubmitButton()
	local enableSubmitButton = true

	if self.helpCategoryComboBox == nil or self.helpSubcategoryComboBox == nil or self.descriptionDefaultTextField == nil or self.details == nil then
		enableSubmitButton = false
	elseif self.helpCategoryComboBox:GetSelectedItemData().index <= CUSTOMER_SERVICE_ASK_FOR_HELP_CATEGORY_MIN_VALUE then
		enableSubmitButton = false
	elseif not self.helpSubcategoryComboBoxControl:IsHidden() and self.helpSubcategoryComboBox:GetSelectedItemData().index <= 0 then
		enableSubmitButton = false
	elseif not self.helpDetailsTextControl:IsHidden() and not self.detailsDefaultTextField:IsHidden() then
		enableSubmitButton = false
	elseif not self.descriptionDefaultTextField:IsHidden() then
		enableSubmitButton = false
	end
	
	self.helpSubmitButton:SetEnabled(enableSubmitButton)
end

function HelpAskForHelp_Keyboard:ClearFields()

	self.helpCategoryComboBox:SelectItemByIndex(1)
	self.description:SetText("")

	ResetCustomerServiceTicket()
end

function HelpAskForHelp_Keyboard:SelectCategory(category)
	local categories = self.helpCategoryComboBox:GetItems()

	for i, categoryId in ipairs(categories) do
		if categoryId.index == category then
			local PERFORM_CALLBACK = false
			self.helpCategoryComboBox:SelectItemByIndex(i, PERFORM_CALLBACK)
			break
		end
	end
end

function HelpAskForHelp_Keyboard:SelectSubcategory(subcategory)
	local categoryIndex = self.helpCategoryComboBox:GetSelectedItemData().index

	local mainArray = HELP_ASK_FOR_HELP_CATEGORY_INFO[categoryIndex]
	if mainArray and mainArray.subcategories then			
		for i, subcategoryId in ipairs(mainArray.subcategories) do
			if subcategoryId.value == subcategory then
				local PERFORM_CALLBACK = false
				self.helpSubcategoryComboBox:SelectItemByIndex(i, PERFORM_CALLBACK)
				break
			end
		end
	end
end

function HelpAskForHelp_Keyboard:SetDetailsText(text)
	self.details:SetText(text)
end

function HelpAskForHelp_Keyboard:OpenAskForHelp(category, subcategory, playerName)
	HELP_CUSTOMER_SUPPORT_KEYBOARD:OpenScreen(HELP_CUSTOMER_SERVICE_ASK_FOR_HELP_KEYBOARD_FRAGMENT)
	self:ClearFields()

	if category then
		self:SelectCategory(category)

		if subcategory then
			self:SelectSubcategory(subcategory)
		end
	end

    if playerName then
        self:SetDetailsText(playerName)
    end
end

function HelpAskForHelp_Keyboard:AttemptToSendTicket()
	ResetCustomerServiceTicket()

	--Populate the ticket fields
	SetCustomerServiceTicketContactEmail(GetActiveUserEmailAddress())
	
	--Category and subcategory values must be valid as they enable the submit button to be clicked On
	local categoryIndex = self.helpCategoryComboBox:GetSelectedItemData().index
	local mainArray = HELP_ASK_FOR_HELP_CATEGORY_INFO[categoryIndex]
	local ticketCategory = TICKET_CATEGORY_OTHER

	if mainArray.subcategories then
		local subcategory = self.helpSubcategoryComboBox:GetSelectedItemData().index
		ticketCategory = mainArray.subcategories[subcategory].ticketCategory
	else
		ticketCategory = mainArray.ticketCategory
	end

	SetCustomerServiceTicketCategory(ticketCategory)
		
	if mainArray.detailsRegistrationFunction then
		local text = self.details:GetText()
		if mainArray.detailsFormatText then
			text = mainArray.detailsFormatText(text)
		end
		mainArray.detailsRegistrationFunction(text)
	end

	SetCustomerServiceTicketBody(self.description:GetText())

	ZO_Dialogs_ShowDialog("HELP_CUSTOMER_SERVICE_SUBMITTING_TICKET_DIALOG")

	SubmitCustomerServiceTicket()
end

function HelpAskForHelp_Keyboard:OnCustomerServiceTicketSubmitted(eventCode, response, success)
	ZO_Dialogs_ReleaseDialog("HELP_CUSTOMER_SERVICE_SUBMITTING_TICKET_DIALOG")

	if success then
		ZO_Dialogs_ShowDialog("HELP_ASK_FOR_HELP_SUBMIT_TICKET_SUCCESSFUL_DIALOG", nil, {mainTextParams = {response}})

		self:ClearFields()
	else
		ZO_Dialogs_ShowDialog("HELP_CUSTOMER_SERVICE_SUBMIT_TICKET_ERROR_DIALOG", nil, {mainTextParams = {response}})
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
	ZO_Dialogs_ShowDialog("CONFIRM_OPEN_URL_BY_TYPE", ESO_FORUMS_URL_TYPE, ESO_FORUMS_FRONT_FACING_ADDRESS)
end