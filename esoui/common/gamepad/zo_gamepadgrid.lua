--[[ Grid Selector Code ]]--
-- The user should call DIRECTIONAL_INPUT:Activate(self) and DIRECTIONAL_INPUT:Deactivate(self) as appropriate
ZO_GamepadGrid = ZO_Object:Subclass()

function ZO_GamepadGrid:New(...)
    local gridObject = ZO_Object.New(self)
    gridObject:Initialize(...)
    return gridObject
end

-- rowMajor = true specifies that you have a grid of rows with a potentially variable number of columns in each row
-- rowMajor = false specifies that you have a grid of columns with a potentially variable number of rows in each column
function ZO_GamepadGrid:Initialize(control, rowMajor)
    self.control = control
    self.focusX = 1
    self.focusY = 1
    self.rowMajor = rowMajor

    self.verticalMovementController = ZO_MovementController:New(MOVEMENT_CONTROLLER_DIRECTION_VERTICAL)
    self.horizontalMovementController = ZO_MovementController:New(MOVEMENT_CONTROLLER_DIRECTION_HORIZONTAL)
    self.directionalMovementSound = SOUNDS.HOR_LIST_ITEM_SELECTED
end

function ZO_GamepadGrid:GetIsRowMajor()
    return self.rowMajor
end

function ZO_GamepadGrid:GetGridItems()
    -- This should be overridden to return an list of lists of grid controls
end

function ZO_GamepadGrid:RefreshGridHighlight()
    -- This should be overridden to refresh the grid highlight (when focus changes)
end

function ZO_GamepadGrid:ClampToGrid(x,y)
    local items = self:GetGridItems()

    if #items > 0 then
        if self.rowMajor then
            y = zo_clamp(y, 1, #items)
            x = zo_clamp(x, 1, #items[y])
        else
            x = zo_clamp(x, 1, #items)
            y = zo_clamp(y, 1, #items[x])
        end
    else
        x = 0
        y = 0
    end

    return x,y
end

function ZO_GamepadGrid:GetGridPosition()
    -- Clamp them again to make sure they are valid (just in case the grid changes)
    self.focusX, self.focusY = self:ClampToGrid(self.focusX, self.focusY)
    return self.focusX, self.focusY
end

function ZO_GamepadGrid:ResetGridPosition()
    self.focusX = 1
    self.focusY = 1
    self:RefreshGridHighlight()
end

function ZO_GamepadGrid:UpdateDirectionalInput()
    local x = self.focusX
    local y = self.focusY

    local move = self.verticalMovementController:CheckMovement()

    if move == MOVEMENT_CONTROLLER_MOVE_NEXT then
        y = y + 1
    elseif move == MOVEMENT_CONTROLLER_MOVE_PREVIOUS then
        y = y - 1
    end

    local move = self.horizontalMovementController:CheckMovement()

    if move == MOVEMENT_CONTROLLER_MOVE_NEXT then
        x = x + 1
    elseif move == MOVEMENT_CONTROLLER_MOVE_PREVIOUS then
        x = x - 1
    end

    x, y = self:ClampToGrid(x, y)

    if (self.focusX ~= x or self.focusY ~= y) then
        self.focusX = x
        self.focusY = y

        PlaySound(self.directionalMovementSound)

        self:RefreshGridHighlight()
    end
end

function ZO_GamepadGrid:SetDirectionalMovementSound(sound)
    self.directionalMovementSound = sound
end

--
-- ZO_GamepadPagedGrid
--

ZO_GamepadPagedGrid = ZO_GamepadGrid:Subclass()

function ZO_GamepadPagedGrid:New(...)
    return ZO_GamepadGrid.New(self, ...)
end

function ZO_GamepadPagedGrid:Initialize(control, rowMajor, footerControl)
    ZO_GamepadGrid.Initialize(self, control, rowMajor)

    self:SetDirectionalMovementSound(SOUNDS.GAMEPAD_MENU_UP)

    if footerControl then
        self.footer = {
            control = footerControl,
            previousControl = footerControl:GetNamedChild("PreviousButton"),
            nextControl = footerControl:GetNamedChild("NextButton"),
            pageNumberLabel = footerControl:GetNamedChild("PageNumberText"),
        }
    end

    self.currentPage = 0
    self.numPages = 0

    self:InitializeKeybindStripDescriptors()
end

function ZO_GamepadPagedGrid:SetPageNumberFont(font)
    if self.footer then
        self.footer.pageNumberLabel:SetFont(font)
    end
end

function ZO_GamepadPagedGrid:SetPageInfo(currentPage, numPages)
    self.currentPage = currentPage
    self.numPages = numPages
    if self.currentPage > self.numPages then
        self.currentPage = self.numPages
    end

    self:UpdateForPageChange()
end

function ZO_GamepadPagedGrid:UpdateForPageChange()
    if self.footer then
        local enablePrevious = self.currentPage ~= 1
        local enableNext = self.currentPage ~= self.numPages
        local hideButtons = not (enablePrevious or enableNext)

        local nextControl = self.footer.nextControl
        local prevControl = self.footer.previousControl
        local pageLabel = self.footer.pageNumberLabel
        nextControl:SetHidden(hideButtons)
        prevControl:SetHidden(hideButtons)
        nextControl:SetEnabled(enableNext)
        prevControl:SetEnabled(enablePrevious)

        pageLabel:SetHidden(hideButtons)

        if not hideButtons then
            pageLabel:SetText(zo_strformat(SI_GAMEPAD_PAGED_LIST_PAGE_NUMBER, self.currentPage))
        end
    end

    self:RefreshGrid()

    if self.pageChangedCallback then
        self.pageChangedCallback()
    end

    KEYBIND_STRIP:UpdateKeybindButtonGroup(self.keybindStripDescriptor)
end

function ZO_GamepadPagedGrid:SetPageChangedCallback(callback)
    self.pageChangedCallback = callback
end

function ZO_GamepadPagedGrid:GetCurrentPage()
    return self.currentPage
end

function ZO_GamepadPagedGrid:GetNumPages()
    return self.numPages
end

function ZO_GamepadPagedGrid:NextPage()
    if self.currentPage < self.numPages then
        self.currentPage = self.currentPage + 1
        self:UpdateForPageChange()
        PlaySound(SOUNDS.GAMEPAD_PAGE_FORWARD)
    end
end

function ZO_GamepadPagedGrid:PreviousPage()
    if self.currentPage > 1 then
        self.currentPage = self.currentPage - 1
        self:UpdateForPageChange()
        PlaySound(SOUNDS.GAMEPAD_PAGE_BACK)
    end
end

function ZO_GamepadPagedGrid:InitializeKeybindStripDescriptors()
    self.keybindStripDescriptor = {
        alignment = KEYBIND_STRIP_ALIGN_LEFT,
        {
            name = GetString(SI_GAMEPAD_PAGED_GRID_PREVIOUS_PAGE),
            keybind = "UI_SHORTCUT_LEFT_TRIGGER",
            ethereal = true,
            callback = function()
                self:PreviousPage()
            end,
            enabled = function()
                return self.currentPage > 1
            end,
        },

        {
            name = GetString(SI_GAMEPAD_PAGED_GRID_NEXT_PAGE),
            keybind = "UI_SHORTCUT_RIGHT_TRIGGER",
            ethereal = true,
            callback = function()
                self:NextPage()
            end,
            enabled = function()
                return self.currentPage < self.numPages
            end,
        },
    }

end

function ZO_GamepadPagedGrid:Activate()
    KEYBIND_STRIP:AddKeybindButtonGroup(self.keybindStripDescriptor)
    DIRECTIONAL_INPUT:Activate(self, self.control)
end

function ZO_GamepadPagedGrid:Deactivate()
    DIRECTIONAL_INPUT:Deactivate(self)
    KEYBIND_STRIP:RemoveKeybindButtonGroup(self.keybindStripDescriptor)
end

function ZO_GamepadPagedGrid:RefreshGrid()
    -- This should be overridden and will be called when a page change occurs
end

    
    



