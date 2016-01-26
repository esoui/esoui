ZO_RadioButtonGroup = ZO_Object:Subclass()

function ZO_RadioButtonGroup:New()
    local group = ZO_Object.New(self)
    
    group.m_buttons = {}
    group.m_enabled = true
    
    return group    
end

local function SetButtonState(button, clickedButton, enabled)
    if(enabled) then
        if(button == clickedButton) then
            button:SetState(BSTATE_PRESSED, true)
        else
            button:SetState(BSTATE_NORMAL, false)
        end
    else
        if(button == clickedButton) then
            button:SetState(BSTATE_DISABLED_PRESSED, true)
        else
            button:SetState(BSTATE_DISABLED, true)
        end
    end
end

function ZO_RadioButtonGroup:HandleClick(button, buttonId)
    if not self.m_enabled then
        return
    end

    -- For now only the LMB will be allowed to click radio buttons.    
    if(buttonId == 1)
    then
        -- Set all buttons in the group to unpressed, and unlocked.
        -- If the button is disabled externally (maybe it isn't a valid option at this time)
        -- then set it to unpressed, but disabled.
        for k, v in pairs(self.m_buttons)
        do
            SetButtonState(k, nil, v.isValidOption)
        end

        -- Set the clicked button to pressed and lock it down (so that it stays pressed.)
        button:SetState(BSTATE_PRESSED, true)
        self.m_clickedButton = button
    end
end

function ZO_RadioButtonGroup:Add(button)
    if(button)
    then
        if(self.m_buttons[button] == nil)
        then
            -- Remember the original handler so that its call can be forced.
            local originalHandler = button:GetHandler("OnClicked")
            self.m_buttons[button] = { originalHandler = originalHandler, isValidOption = true } -- newly added buttons always start as valid options for now.
            
            -- This throws away return values from the original function, which is most likely ok in the case of a click handler.
            local newHandler =  function(b, id) 
                                    self:HandleClick(b, id)

                                    if(originalHandler)
                                    then
                                        originalHandler(b, id)
                                    end
                                end
                                
            button:SetHandler("OnClicked", newHandler)
        end
    end
end

-- This changes the enabled state of the entire radio group, but must still take into account 
-- whether each button is a valid option...for example, enabling a radio group that has certain
-- invalid options must remember to keep those options disabled.
function ZO_RadioButtonGroup:SetEnabled(enabled)
    if(enabled ~= self.m_enabled) then
        self.m_enabled = enabled
        local clickedButton = self:GetClickedButton()

        for k, v in pairs(self.m_buttons)
        do
            local buttonEnabled = enabled and v.isValidOption
            SetButtonState(k, clickedButton, buttonEnabled)
        end
    end
end

-- Allow external control over whether individual buttons are valid options
-- within the group.  Invalid options will force those buttons to appear disabled.
function ZO_RadioButtonGroup:SetButtonIsValidOption(button, isValidOption)
    local buttonData = self.m_buttons[button]
    if(buttonData and (isValidOption ~= buttonData.isValidOption)) then
        buttonData.isValidOption = isValidOption
        
        -- NOTE: This doesn't update the state of the clicked button, because that could
        -- potentially call a click handler that shouldn't be called at this time, or cause
        -- more data to need to be updated externally...it's a best practice to first figure
        -- out which buttons need to be validOptions, and then allow the clicked button to change.
        SetButtonState(button, self:GetClickedButton(), self.m_enabled and isValidOption)
    end
end

function ZO_RadioButtonGroup:Clear()
    for k, v in pairs(self.m_buttons)
    do
        -- Restore the button to its correct state, as if it hadn't been added to the radio group
        -- Since "valid option" is set externally, just use that to figure out the current enabled state.
        SetButtonState(k, nil, v.isValidOption)
        
        -- Reset handler, it's ok if this is nil, it means there was no original handler
        -- so there shouldn't be one now...
        k:SetHandler("OnClicked", v.originalHandler)
    end
    
    self.m_buttons = {}
    self.m_clickedButton = nil
end

function ZO_RadioButtonGroup:SetClickedButton(button)
    local buttonData = self.m_buttons[button]
    if(buttonData and buttonData.isValidOption)
    then
       button:GetHandler("OnClicked")(button, 1)
    end
end

function ZO_RadioButtonGroup:GetClickedButton()
    return self.m_clickedButton
end

-- Just change the state of the button group to reflect the current state of the data;
-- this shouldn't actually call any click handlers.
function ZO_RadioButtonGroup:UpdateFromData(isPressedQueryFn)
    -- Find the button that's actually the clicked button from backing data
    self.m_clickedButton = nil
    for button, buttonData in pairs(self.m_buttons)
    do
        if(isPressedQueryFn(button)) then
            self.m_clickedButton = button
            break
        end
    end

    -- Update the state of all the buttons and reassign the currently clicked button
    local clickedButton = self.m_clickedButton
    local enabled = self.m_enabled
    for button, buttonData in pairs(self.m_buttons)
    do
        local buttonEnabled = enabled and buttonData.isValidOption
        SetButtonState(button, clickedButton, buttonEnabled)
    end
end
