-------------------------------------
-- Globals
--
-- Global functions specific to ESO
-------------------------------------

function ZO_ReanchorControlForLeftSidePanel(control)
    local function DoLayout()
        -- Since the control could have been resized by it's anchors clear the anchors before getting it's hieght
        control:ClearAnchors()

        local screenHeight = GuiRoot:GetHeight()
        local controlHeight = control:GetHeight()
        local offsetY = (screenHeight - controlHeight) / 2
        control:SetAnchor(TOPLEFT, GuiRoot, TOPLEFT, 245, offsetY)
    end

    control:RegisterForEvent(EVENT_SCREEN_RESIZED, DoLayout)
    DoLayout()
end

function ZO_ReanchorControlTopHorizontalMenu(control)
    local function DoLayout()
        local screenHeight = GuiRoot:GetHeight()
        local controlHeight = control:GetHeight()
        control:ClearAnchors()
        control:SetAnchor(TOPLEFT, GuiRoot, TOPLEFT, -20, 20)
        control:SetAnchor(BOTTOMLEFT, GuiRoot, BOTTOMLEFT, -20, 20)
    end

    control:RegisterForEvent(EVENT_SCREEN_RESIZED, DoLayout)
    DoLayout()
end