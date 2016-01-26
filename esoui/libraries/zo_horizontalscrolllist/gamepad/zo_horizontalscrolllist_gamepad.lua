ZO_HorizontalScrollList_Gamepad = ZO_HorizontalScrollList:Subclass()

--[[ Public  API ]]--
function ZO_HorizontalScrollList_Gamepad:New(...)
    return ZO_HorizontalScrollList.New(self, ...)
end

-- for best results numVisibleEntries should be odd
function ZO_HorizontalScrollList_Gamepad:Initialize(control, templateName, numVisibleEntries, setupFunction, equalityFunction, onCommitWithItemsFunction, onClearedFunction)
    ZO_HorizontalScrollList.Initialize(self, control, templateName, numVisibleEntries, setupFunction, equalityFunction, onCommitWithItemsFunction, onClearedFunction)
    self:SetActive(false)
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
    if (self.active ~= active) or self.dirty then
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
    local hideArrows = not self.active

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
end

function ZO_HorizontalScrollList_Gamepad:Deactivate()
    self:SetActive(false)
end

function ZO_HorizontalScrollList_Gamepad:UpdateDirectionalInput()
	self.hasReleasedStick = self.result == 0
    self.result = DIRECTIONAL_INPUT:GetX(ZO_DI_LEFT_STICK, ZO_DI_DPAD) 
    if self.hasReleasedStick then
        if self.result > 0 then
            self:MoveLeft()
			self.hasReleasedStick = false
        elseif self.result < 0 then
            self:MoveRight()
			self.hasReleasedStick = false
        end
    end
end
