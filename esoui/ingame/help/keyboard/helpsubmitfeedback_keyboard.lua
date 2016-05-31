local HELP_CUSTOMER_SERVICE_INCOMPLETED_FIELDS_DIALOG = "HELP_CUSTOMER_SERVICE_INCOMPLETED_FIELDS_DIALOG"
local lastSubmitTime = 0

local HELP_SUBMIT_FEEDBACK_SUBCATEGORY =
{
	--Will Replace Subcategories With Enums--
	[CUSTOMER_SERVICE_SUBMIT_FEEDBACK_CATEGORY_ALLIANCE_WAR] =
	{
		minValue = CUSTOMER_SERVICE_SUBMIT_FEEDBACK_SUBCATEGORY_ALLIANCE_WAR_GRAVEYARD,
		maxValue = CUSTOMER_SERVICE_SUBMIT_FEEDBACK_SUBCATEGORY_ALLIANCE_WAR_SIEGE,
	},
	[CUSTOMER_SERVICE_SUBMIT_FEEDBACK_CATEGORY_AUDIO] =
	{
		minValue = CUSTOMER_SERVICE_SUBMIT_FEEDBACK_SUBCATEGORY_AUDIO_MUSIC,
		maxValue = CUSTOMER_SERVICE_SUBMIT_FEEDBACK_SUBCATEGORY_AUDIO_OTHER,
	},
	[CUSTOMER_SERVICE_SUBMIT_FEEDBACK_CATEGORY_CHARACTERS] =
	{
		minValue = CUSTOMER_SERVICE_SUBMIT_FEEDBACK_SUBCATEGORY_CHARACTERS_ABILITIES,
		maxValue = CUSTOMER_SERVICE_SUBMIT_FEEDBACK_SUBCATEGORY_CHARACTERS_TARGETING,
	},
	[CUSTOMER_SERVICE_SUBMIT_FEEDBACK_CATEGORY_COMBAT] =
	{
		minValue = CUSTOMER_SERVICE_SUBMIT_FEEDBACK_SUBCATEGORY_COMBAT_ABILITY,
		maxValue = CUSTOMER_SERVICE_SUBMIT_FEEDBACK_SUBCATEGORY_COMBAT_NPC,
	},
	[CUSTOMER_SERVICE_SUBMIT_FEEDBACK_CATEGORY_ITEMS] =
	{
		minValue = CUSTOMER_SERVICE_SUBMIT_FEEDBACK_SUBCATEGORY_ITEMS_ARMOR,
		maxValue = CUSTOMER_SERVICE_SUBMIT_FEEDBACK_SUBCATEGORY_ITEMS_WEAPONS,
		detailsTitle = GetString(SI_CUSTOMER_SERVICE_ITEM_NAME),
	},
	[CUSTOMER_SERVICE_SUBMIT_FEEDBACK_CATEGORY_GAME_SYSTEM] =
	{
		minValue = CUSTOMER_SERVICE_SUBMIT_FEEDBACK_SUBCATEGORY_GAME_SYSTEM_CHAT,
		maxValue = CUSTOMER_SERVICE_SUBMIT_FEEDBACK_SUBCATEGORY_GAME_SYSTEM_VENDOR,
	},
	[CUSTOMER_SERVICE_SUBMIT_FEEDBACK_CATEGORY_GRAPHICS] =
	{
		minValue = CUSTOMER_SERVICE_SUBMIT_FEEDBACK_SUBCATEGORY_GRAPHICS_ART_ANIMATION,
		maxValue = CUSTOMER_SERVICE_SUBMIT_FEEDBACK_SUBCATEGORY_GRAPHICS_WEATHER,
	},
	[CUSTOMER_SERVICE_SUBMIT_FEEDBACK_CATEGORY_QUESTS] =
	{
		minValue = CUSTOMER_SERVICE_SUBMIT_FEEDBACK_SUBCATEGORY_QUESTS_DIALOG_VOICEOVER,
		maxValue = CUSTOMER_SERVICE_SUBMIT_FEEDBACK_SUBCATEGORY_QUESTS_REWARDS,
		detailsTitle = GetString(SI_CUSTOMER_SERVICE_QUEST_NAME),
	},
	[CUSTOMER_SERVICE_SUBMIT_FEEDBACK_CATEGORY_TEXT] =
	{
		minValue = CUSTOMER_SERVICE_SUBMIT_FEEDBACK_SUBCATEGORY_TEXT_DIALOG_VOICEOVER,
		maxValue = CUSTOMER_SERVICE_SUBMIT_FEEDBACK_SUBCATEGORY_TEXT_BOOKS,
	},
}

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

	control:RegisterForEvent(EVENT_CUSTOMER_SERVICE_FEEDBACK_SUBMITTED, function (...) self:OnCustomerServiceFeedbackSubmitted(...) end)

	self:InitializeTextBox()
	self:InitializeComboBoxes()
	self:InitializeCheckButton()
	self:InitializeDialogs()
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

	local function OnCategoryChanged()
		self:UpdateSubcategories()
		self:UpdateDetailsComponents()
		self:UpdateSubmitButton()
	end

	for i = CUSTOMER_SERVICE_SUBMIT_FEEDBACK_IMPACT_MIN_VALUE, CUSTOMER_SERVICE_SUBMIT_FEEDBACK_IMPACT_MAX_VALUE do
		local name = GetString("SI_CUSTOMERSERVICESUBMITFEEDBACKIMPACTS", i)
		if name ~= nil then
			local entry = ZO_ComboBox:CreateItemEntry(name, function() self:UpdateSubmitButton() end)
			entry.index = i
			self.helpImpactComboBox:AddItem(entry, ZO_COMBOBOX_SUPRESS_UPDATE)
		end
	end

	self.helpImpactComboBox:SelectItemByIndex(1)

	for i = CUSTOMER_SERVICE_SUBMIT_FEEDBACK_CATEGORY_MIN_VALUE, CUSTOMER_SERVICE_SUBMIT_FEEDBACK_CATEGORY_MAX_VALUE do
		local name = GetString("SI_CUSTOMERSERVICESUBMITFEEDBACKCATEGORIES", i)
		if name ~= nil then
			local entry = ZO_ComboBox:CreateItemEntry(name, OnCategoryChanged)
			entry.index = i
			self.helpCategoryComboBox:AddItem(entry, ZO_COMBOBOX_SUPRESS_UPDATE)
		end
	end

	self.helpCategoryComboBox:SelectItemByIndex(1)
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

function HelpSubmitFeedback_Keyboard:InitializeDialogs()
	ZO_Dialogs_RegisterCustomDialog("HELP_SUBMIT_FEEDBACK_SUBMIT_TICKET_SUCCESSFUL_DIALOG",
	{
		canQueue = true,
        mustChoose = true,
		title =
		{
			text = GetString(SI_CUSTOMER_SERVICE_SUBMIT_CONFIRMATION),
		},
        mainText =
        {
			text = GetString(SI_CUSTOMER_SERVICE_SUBMIT_FEEDBACK_SUBMIT_CONFIRMATION), 
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

function HelpSubmitFeedback_Keyboard:UpdateSubcategories()
	local categoryIndex = self.helpCategoryComboBox:GetSelectedItemData().index

	self.helpSubcategoryComboBox:ClearItems()

	self.subcategoryIndex = HELP_SUBMIT_FEEDBACK_SUBCATEGORY[categoryIndex]

	if self.subcategoryIndex == nil then
		self:SetSubcategoryContentHidden(true)
	else
		self:SetSubcategoryContentHidden(false)

		--Add Select Subcategory Entry in the Subcategory Combo Box
		local defaultEntry = ZO_ComboBox:CreateItemEntry(GetString("SI_CUSTOMERSERVICESUBMITFEEDBACKSUBCATEGORIES",CUSTOMER_SERVICE_SUBMIT_FEEDBACK_SUBCATEGORY_NONE), OnImpactChanged)
		defaultEntry.index = CUSTOMER_SERVICE_SUBMIT_FEEDBACK_SUBCATEGORY_NONE
		self.helpSubcategoryComboBox:AddItem(defaultEntry, ZO_COMBOBOX_UPDATE_NOW)

		for i = self.subcategoryIndex.minValue, self.subcategoryIndex.maxValue do
			local entry = ZO_ComboBox:CreateItemEntry(GetString("SI_CUSTOMERSERVICESUBMITFEEDBACKSUBCATEGORIES",i), function() self:UpdateSubmitButton() end)
			entry.index = i
			self.helpSubcategoryComboBox:AddItem(entry, ZO_COMBOBOX_UPDATE_NOW)
		end

		local PERFORM_CALLBACK = false
		self.helpSubcategoryComboBox:SelectItemByIndex(1,PERFORM_CALLBACK)		
	end
end

function HelpSubmitFeedback_Keyboard:UpdateDetailsComponents()
	self.details:SetText("")

	if self.subcategoryIndex then
		if self.subcategoryIndex.detailsTitle then
			self:SetDetailsContentHidden(false)
			self.helpDetailsTitle:SetText(self.subcategoryIndex.detailsTitle)
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
	elseif self.helpImpactComboBox:GetSelectedItemData().index <= CUSTOMER_SERVICE_SUBMIT_FEEDBACK_IMPACT_MIN_VALUE then
		enableSubmitButton = false
	elseif self.helpCategoryComboBox:GetSelectedItemData().index <= CUSTOMER_SERVICE_SUBMIT_FEEDBACK_CATEGORY_MIN_VALUE then
		enableSubmitButton = false
	elseif not self.helpSubcategoryComboBoxControl:IsHidden() and self.helpSubcategoryComboBox:GetSelectedItemData().index <= 0 then
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

    if attachScreenshot and (lastSubmitTime + 30000) > GetFrameTimeMilliseconds() then
        ZO_Dialogs_ShowDialog("TOO_FREQUENT_BUG_SCREENSHOT")
    else
        ZO_Dialogs_ShowDialog("HELP_CUSTOMER_SERVICE_SUBMITTING_TICKET_DIALOG")
        ReportFeedback(impactId, categoryId, subcategoryId, detailsText, descriptionText, attachScreenshot)
        SCENE_MANAGER:ShowBaseScene()
        lastSubmitTime = GetFrameTimeMilliseconds()
    end
end

function HelpSubmitFeedback_Keyboard:OnCustomerServiceFeedbackSubmitted(eventCode, response, success)
	ZO_Dialogs_ReleaseDialog("HELP_CUSTOMER_SERVICE_SUBMITTING_TICKET_DIALOG")

	if success then
		ZO_Dialogs_ShowDialog("HELP_SUBMIT_FEEDBACK_SUBMIT_TICKET_SUCCESSFUL_DIALOG", nil, {mainTextParams = {response}})
	else
		ZO_Dialogs_ShowDialog("HELP_CUSTOMER_SERVICE_SUBMIT_TICKET_ERROR_DIALOG", nil, {mainTextParams = {response}})
	end
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