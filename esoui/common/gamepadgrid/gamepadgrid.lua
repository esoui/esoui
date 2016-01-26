GAMEPAD_GRID_NAV1 = 1
GAMEPAD_GRID_NAV2 = 2
GAMEPAD_GRID_NAV3 = 3
GAMEPAD_GRID_NAV4 = 4
GAMEPAD_GRID_NAV8 = 8

local NAV_ANCHORS =
{
    [GAMEPAD_GRID_NAV1] = { ZO_Anchor:New(TOPLEFT, GuiRoot, TOPLEFT, 96, 30), ZO_Anchor:New(BOTTOMLEFT, GuiRoot, BOTTOMLEFT, 96, -30) },
    [GAMEPAD_GRID_NAV2] = { ZO_Anchor:New(TOPLEFT, GuiRoot, TOPLEFT, 96, 30), ZO_Anchor:New(BOTTOMLEFT, GuiRoot, BOTTOMLEFT, 96, -30) },
    [GAMEPAD_GRID_NAV3] = { ZO_Anchor:New(TOPLEFT, GuiRoot, TOPLEFT, 578, 92), ZO_Anchor:New(BOTTOMLEFT, GuiRoot, BOTTOMLEFT, 578, -92) },
    [GAMEPAD_GRID_NAV4] = { ZO_Anchor:New(TOPRIGHT, GuiRoot, TOPRIGHT, -96, 92), ZO_Anchor:New(BOTTOMRIGHT, GuiRoot, BOTTOMRIGHT, -96, -92) },
    [GAMEPAD_GRID_NAV8] = { ZO_Anchor:New(TOPLEFT, GuiRoot, TOPLEFT, 96, 30), ZO_Anchor:New(BOTTOMLEFT, GuiRoot, BOTTOMLEFT, 96, -30) },
}

local NAV_CONTAINER_ANCHORS =
{
    [GAMEPAD_GRID_NAV1] = { ZO_Anchor:New(TOPLEFT, nil, TOPLEFT, 20, 0), ZO_Anchor:New(BOTTOMLEFT, nil, BOTTOMLEFT, 20, 0) },
    [GAMEPAD_GRID_NAV2] = { ZO_Anchor:New(TOPLEFT, nil, TOPLEFT, 20, 0), ZO_Anchor:New(BOTTOMLEFT, nil, BOTTOMLEFT, 20, 0) },
    [GAMEPAD_GRID_NAV3] = { ZO_Anchor:New(TOPLEFT, nil, TOPLEFT, 20, 0), ZO_Anchor:New(BOTTOMLEFT, nil, BOTTOMLEFT, 20, 0) },
    [GAMEPAD_GRID_NAV4] = { ZO_Anchor:New(TOPLEFT, nil, TOPLEFT, 20, 0), ZO_Anchor:New(BOTTOMLEFT, nil, BOTTOMLEFT, 20, 0) },
    [GAMEPAD_GRID_NAV8] = { ZO_Anchor:New(TOPLEFT, nil, TOPLEFT, 0, 0), ZO_Anchor:New(BOTTOMLEFT, nil, BOTTOMLEFT, 0, 0) },
}

function ZO_GamepadGrid_AnchorToNav(control, navLocation)
    local anchors = NAV_ANCHORS[navLocation]

    control:ClearAnchors()
    for i, anchor in ipairs(anchors) do
        anchor:AddToControl(control)
    end
end

function ZO_GamepadGrid_GetNavAnchor(navLocation, anchorIndex)
    return NAV_ANCHORS[navLocation][anchorIndex or 1]
end

function ZO_GamepadGrid_GetNavContainerAnchor(navLocation, anchorIndex)
    return NAV_CONTAINER_ANCHORS[navLocation][anchorIndex or 1]
end