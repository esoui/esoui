ZO_HelpScreenTemplate_Keyboard = ZO_InitializingObject:Subclass()

function ZO_HelpScreenTemplate_Keyboard:Initialize(control, data)
	self.control = control
	control.owner = self

	if data then 
		HELP_CUSTOMER_SUPPORT_KEYBOARD:AddCategory(data)
	end
end