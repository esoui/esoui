local HelpCustomerService_Keyboard = ZO_Object:Subclass()

function HelpCustomerService_Keyboard:New(...)
    local help = ZO_Object.New(self)
    help:Initialize(...)
    return help
end

function HelpCustomerService_Keyboard:Initialize(control)
	self.control = control
    control.owner = self

	HELP_CUSTOMER_SUPPORT_SCENE = ZO_Scene:New("helpCustomerSupport", SCENE_MANAGER)
	local helpCustomerServiceFragment = ZO_FadeSceneFragment:New(control)
    HELP_CUSTOMER_SUPPORT_SCENE:AddFragment(helpCustomerServiceFragment)

	self:InitializeTree()
	self:InitializeHelpDialogs()
end

function HelpCustomerService_Keyboard:InitializeTree()
	self.tree = ZO_Tree:New(GetControl(self.control, "Categories"), 60, -10, 280)
	self.categoryFragmentToNodeLookup = {}

	local function CategorySetup(node, control, data, down)
        control.text:SetModifyTextType(MODIFY_TEXT_TYPE_UPPERCASE)
        control.text:SetText(data.name)

        control.icon:SetTexture(down and data.down or data.up)
        control.iconHighlight:SetTexture(data.over)

        ZO_IconHeader_Setup(control, down)
    end
    local function CategorySelected(control, data, selected, reselectingDuringRebuild)
        if selected then
			self:ShowCategory(data)
        end
        CategorySetup(nil, control, data, selected)
    end
	self.tree:AddTemplate("ZO_HelpCustomerService_Type", CategorySetup, CategorySelected, nil)
    self.tree:SetExclusive(true)
end

function HelpCustomerService_Keyboard:InitializeHelpDialogs()
	local ESO_HELP_URL_TYPE = {urlType = APPROVED_URL_ESO_HELP}
	local ESO_HELP_FRONT_FACING_ADDRESS = {mainTextParams = {GetString(SI_CUSTOMER_SERVICE_ESO_HELP_LINK_TEXT), GetString(SI_URL_APPLICATION_WEB)}}

	ZO_Dialogs_RegisterCustomDialog("HELP_CUSTOMER_SERVICE_SUBMITTING_TICKET_DIALOG",
	{
		showLoadingIcon = true,
		modal = false,
		title =
		{
			text = GetString(SI_CUSTOMER_SERVICE_SUBMITTING_TICKET),
		},
        mainText =
        {
           text = GetString(SI_CUSTOMER_SERVICE_SUBMITTING),
		   align = TEXT_ALIGN_CENTER,
        },
	})

	ZO_Dialogs_RegisterCustomDialog("HELP_CUSTOMER_SERVICE_SUBMIT_TICKET_ERROR_DIALOG",
	{
		canQueue = true,
        mustChoose = true,
		title =
		{
			text = GetString(SI_CUSTOMER_SERVICE_SUBMIT_FAILED),
		},
        mainText =
        {
			text = zo_strformat(SI_CUSTOMER_SERVICE_SUBMIT_FAILED_BODY, GetURLTextByType(APPROVED_URL_ESO_HELP))
        },
       
        buttons =
        {
			{
				keybind = "DIALOG_PRIMARY",
				text = SI_CUSTOMER_SERVICE_OPEN_WEB_BROWSER,
				callback = function(...)
					ZO_Dialogs_ShowDialog("CONFIRM_OPEN_URL_BY_TYPE", ESO_HELP_URL_TYPE, ESO_HELP_FRONT_FACING_ADDRESS)
				end,
			},
			{
				keybind = "DIALOG_NEGATIVE",
				text = SI_DIALOG_EXIT,
			},
        },		
	})
end

function HelpCustomerService_Keyboard:AddCategory(data)
	local node = self.tree:AddNode("ZO_HelpCustomerService_Type", data, nil, SOUNDS.HELP_BLADE_SELECTED)
	self.categoryFragmentToNodeLookup[data.categoryFragment] = node
	self.tree:Commit()
end

function HelpCustomerService_Keyboard:ShowCategory(data)
	if self.currentFragment then
		HELP_CUSTOMER_SUPPORT_SCENE:RemoveFragment(self.currentFragment)
	end

	self.currentFragment = data.categoryFragment
	HELP_CUSTOMER_SUPPORT_SCENE:AddFragment(self.currentFragment)
end

function HelpCustomerService_Keyboard:OpenScreen(fragment)
	if not SCENE_MANAGER:IsShowing("helpCustomerSupport") then
		MAIN_MENU_KEYBOARD:ShowScene("helpCustomerSupport")
	end

	self.tree:SelectNode(self.categoryFragmentToNodeLookup[fragment])
end

-- Global XML --

function ZO_HelpCustomerService_Keyboard_Initialize(control)
    HELP_CUSTOMER_SUPPORT_KEYBOARD = HelpCustomerService_Keyboard:New(control)
end
