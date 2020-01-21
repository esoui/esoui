ZO_HorizontalScrollList_Gamepad = ZO_HorizontalScrollList:Subclass()

--[[ Public  API ]]--
function ZO_HorizontalScrollList_Gamepad:New(...)
    return ZO_HorizontalScrollList.New(self, ...)
end

-- for best results numVisibleEntries should be odd
function ZO_HorizontalScrollList_Gamepad:Initialize(control, templateName, numVisibleEntries, setupFunction, equalityFunction, onCommitWithItemsFunction, onClearedFunction)
    ZO_HorizontalScrollList.Initialize(self, control, templateName, numVisibleEntries, setupFunction, equalityFunction, onCommitWithItemsFunction, onClearedFunction)
    self:SetActive(false)
    self.movementController = ZO_MovementController:New(MOVEMENT_CONTROLLER_DIRECTION_HORIZONTAL)
end

function ZO_HorizontalScrollList_Gamepad:SetOnActivatedChangedFunction(onActivatedChangedFunction)
    self.onActivatedChangedFunction = onActivatedChangedFunction
    self.dirty = true
end

function ZO_HorizontalScrollList_Gamepad:Commit()
    ZO_HorizontalScrollList.Commit(self)

    self:UpdateArrows()
end

function ZO_HorizontalScrollList_Gamepad:SetActive(active)
    if self.active ~= active or self.dirty then
        self.active = active
        self.dirty = false

        if self.active then
            DIRECTIONAL_INPUT:Activate(self, self.control)
        else
            DIRECTIONAL_INPUT:Deactivate(self)
        end

        self:UpdateArrows()

        if self.onActivatedChangedFunction then
            self.onActivatedChangedFunction(self, self.active)
        end
    end
end

function ZO_HorizontalScrollList_Gamepad:UpdateArrows()
    local hideArrows = not self.active or not self:CanScroll()

    self.leftArrow:SetHidden(hideArrows)
    self.rightArrow:SetHidden(hideArrows)

    if not hideArrows then
        local numItems = self:GetNumItems()
        local selectedIndex = self:GetSelectedIndex()
        local disableArrows = numItems == 0 or (numItems == 1 and not self.allowWrapping)
        
        if disableArrows then
            self.leftArrow:SetEnabled(not disableArrows)
            self.rightArrow:SetEnabled(not disableArrows)
        elseif not disableArrows and selectedIndex and not self.allowWrapping then
            if selectedIndex == 0 then
                self.leftArrow:SetEnabled(false)
            elseif zo_abs(selectedIndex) == numItems - 1 then
                self.rightArrow:SetEnabled(false)
            end
        end
    end
end

function ZO_HorizontalScrollList_Gamepad:Activate()
    self:SetActive(true)

    self.lastScrollTime = GetFrameTimeSeconds()
    self.lastInteractionAutomatic = true
end

function ZO_HorizontalScrollList_Gamepad:Deactivate()
    self:SetActive(false)
end

function ZO_HorizontalScrollList_Gamepad:UpdateDirectionalInput()
    local result = self.movementController:CheckMovement()

    if self.customDirectionalInputHandler and self.customDirectionalInputHandler(result) then
        return
    end

    if result == MOVEMENT_CONTROLLER_MOVE_NEXT then
        self:MoveLeft()
    elseif result == MOVEMENT_CONTROLLER_MOVE_PREVIOUS then
        self:MoveRight()
    end
end

-- Will fire a callback with the directional input result
-- Optionally you can return true to consume the result before the list processes it
function ZO_HorizontalScrollList_Gamepad:SetCustomDirectionInputHandler(handler)
    self.customDirectionalInputHandler = handler
end