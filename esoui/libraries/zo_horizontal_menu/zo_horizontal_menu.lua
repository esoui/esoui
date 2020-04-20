------------------------
-- ZO_Horizontal_Menu
------------------------

ZO_HORIZONAL_MENU_ALIGN_LEFT = 1
ZO_HORIZONAL_MENU_ALIGN_CENTER = 2
ZO_HORIZONAL_MENU_ALIGN_RIGHT = 3

local HORIZONTAL_MENU_DEFAULT_SPACING = 30

ZO_Horizontal_Menu = ZO_Object:Subclass()

function ZO_Horizontal_Menu:New(...)
    local object = ZO_Object.New(self)
    object:Initialize(...)
    return object
end

function ZO_Horizontal_Menu:Initialize(control, anchorStyle)
    self.control = control

    self.anchorStyle = anchorStyle or ZO_HORIZONAL_MENU_ALIGN_LEFT

    self.menuControls = {}
end

function ZO_Horizontal_Menu:AddTemplate(templateName, setupFunction, spacing)
    self.template =
    {
        templateName = templateName,
        setupFunction = setupFunction,
        spacing = spacing or HORIZONTAL_MENU_DEFAULT_SPACING
    }
end

function ZO_Horizontal_Menu:AddMenuItem(controlName, name, onSelectedCallback, onUnselectedCallback, onMouseEnterCallback, onMouseExitCallback)
    local menuItemControl = CreateControlFromVirtual("$(parent)" .. controlName, self.control, self.template.templateName)

    menuItemControl.data =
    {
        index = #self.menuControls + 1,
        name = name,
        onSelectedCallback = onSelectedCallback,
        onUnselectedCallback = onUnselectedCallback,
    }

    if self.template.setupFunction then
        self.template.setupFunction(menuItemControl, menuItemControl.data)
    end

    if onMouseEnterCallback then
        menuItemControl:SetHandler("OnMouseEnter", onMouseEnterCallback)
    end

    if onMouseExitCallback then
        menuItemControl:SetHandler("OnMouseExit", onMouseExitCallback)
    end

    -- Anchor new control
    local previousControl = self.menuControls[#self.menuControls]
    if previousControl then
        local isValid, point, target, relPoint, offsetX, offsetY = previousControl:GetAnchor(0)
        if isValid then
            if self.anchorStyle == ZO_HORIZONAL_MENU_ALIGN_LEFT then
                menuItemControl:SetAnchor(TOPLEFT, previousControl, TOPRIGHT, self.template.spacing)
            elseif self.anchorStyle == ZO_HORIZONAL_MENU_ALIGN_CENTER then
                menuItemControl:SetAnchor(TOPLEFT, previousControl, TOPRIGHT, self.template.spacing)
                local firstControlOffsetX = offsetX + (previousControl:GetWidth() + self.template.spacing) / 2
                local firstControl = self.menuControls[1]
                firstControl:ClearAnchors()
                firstControl:SetAnchor(TOP, self.control, TOP, -firstControlOffsetX)
            else -- Align Right
                previousControl:SetAnchor(TOPRIGHT, menuItemControl, TOPLEFT, -self.template.spacing)
                menuItemControl:SetAnchor(point, target, relPoint, offsetX, offsetY)
            end
        else
            menuItemControl:SetAnchor(TOPRIGHT, self.control, TOPRIGHT)
        end
    else
        if self.anchorStyle == ZO_HORIZONAL_MENU_ALIGN_LEFT then
            menuItemControl:SetAnchor(TOPLEFT, self.control, TOPLEFT)
        elseif self.anchorStyle == ZO_HORIZONAL_MENU_ALIGN_CENTER then
            menuItemControl:SetAnchor(TOP, self.control, TOP)
        else -- Anchored Right
            menuItemControl:SetAnchor(TOPRIGHT, self.control, TOPLEFT)
        end
    end

    table.insert(self.menuControls, menuItemControl)

    return menuItemControl
end

function ZO_Horizontal_Menu:SetSelectedByIndex(index)
    if index and index > 0 and index <= #self.menuControls then
        if self.selectedIndex ~= index then
            if self.selectedIndex then
                self.menuControls[self.selectedIndex]:SetSelected(false)
            end
            self.selectedIndex = index
            self.menuControls[self.selectedIndex]:SetSelected(true)
            if self.menuControls[self.selectedIndex].data.onSelectedCallback then
                self.menuControls[self.selectedIndex].data.onSelectedCallback(self.menuControls[self.selectedIndex])
            end
        end
    elseif not index then
        if self.selectedIndex and self.selectedIndex <= #self.menuControls then
            self.menuControls[self.selectedIndex]:SetSelected(false)
            if self.menuControls[self.selectedIndex].data.onUnselectedCallback then
                self.menuControls[self.selectedIndex].data.onUnselectedCallback()
            end
        end
        self.selectedIndex = nil
    else
        assert(false, "ZO_Horizontal_Menu:SetSelectedByIndex out-of-bounds: " .. index)
    end
end

function ZO_Horizontal_Menu:Refresh()
    if self.template.setupFunction then
        for i, control in ipairs(self.menuControls) do
            self.template.setupFunction(control, control.data)
        end
    end
end

function ZO_Horizontal_Menu:Reset()
    self.menuControls = {}
end

--Global XML

function ZO_HorizontalMenu_LabelHeader_MouseUp(control, upInside)
    if upInside and control.data.onSelectedCallback then
       control.data.onSelectedCallback(control)
    end
end