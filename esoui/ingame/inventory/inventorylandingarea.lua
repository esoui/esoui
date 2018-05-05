local function PlaceCursorInInventory(bagId, cursorType)
    -- If the cursor contains a store item, just let that system handle it...
    if cursorType == MOUSE_CONTENT_STORE_ITEM then
        PlaceInInventory(bagId, 0)
        return
    end

    if cursorType == MOUSE_CONTENT_QUEST_ITEM then
        if bagId == BAG_BANK then
            ZO_Alert(UI_ALERT_CATEGORY_ERROR, SOUNDS.NEGATIVE_CLICK, GetString(SI_INVENTORY_ERROR_NO_QUEST_ITEMS_IN_BANK))
        end

        -- can't really move quest items anywhere, so return no matter what
        return
    end

    -- If we are moving from the Craft Bag we need to prompt the transfer dialog
    local sourceBag = GetCursorBagId()
    if sourceBag == BAG_VIRTUAL then
        if bagId == BAG_BACKPACK then
            local sourceSlotIndex = GetCursorSlotIndex()
            ZO_TryMoveToInventoryFromBagAndSlot(sourceBag, sourceSlotIndex)
        end
        -- no support for going from Craft bag directly to a bag other than backpack
        return
    end

    -- Should not auto-stack, that's what right click is for as of now.
    -- This is only called after all cursor data has been checked.
    TryPlaceInventoryItemInEmptySlot(bagId)
end

local dropHandlers =
{
    ["inventory"] = function(landingArea, cursorType)
                        PlaceCursorInInventory(landingArea.bagId, cursorType)
                    end,

    ["store"] =     function(landingArea, cursorType)
                        PlaceInStoreWindow()
                    end,
}

-- Allow calling from external systems (the inventory system will once again begin using this
-- to auto-drop into inventory (bank/bag) when the split stack menu item is chosen.
function ZO_InventoryLandingArea_DropCursor(landingArea)
    local cursorType = GetCursorContentType()
    local handler = dropHandlers[landingArea.descriptor]
    if handler and (cursorType ~= MOUSE_CONTENT_EMPTY) then
        handler(landingArea, cursorType)
    end
end

function ZO_InventoryLandingArea_DropCursorInBag(bagId)
    PlaceCursorInInventory(bagId, GetCursorContentType())
end

function ZO_InventoryLandingArea_SetHidden(landingArea, hidden, hintTextStringId)
    landingArea:SetHidden(hidden)
    if not hidden then
        -- It's assumed that landing areas are children of a ZO_ScrollListContents control that hold ZO_ListInventorySlots
        -- which is how the offsets are determined when there are icons present in the list.
        -- The right offset is determined from the scrollbar.
        local scrollList = landingArea:GetParent():GetParent()
        landingArea:ClearAnchors()
        local iconOffset = 0

        if ZO_ScrollList_HasVisibleData(scrollList) then
            -- Don't adjust for icon offset for now, just allow the landing area to take up the full area of the window
            -- iconOffset = landingArea.iconOffset
        end

        landingArea:SetAnchor(TOPLEFT, scrollList, TOPLEFT, iconOffset, 0)
        landingArea:SetAnchor(BOTTOMRIGHT, scrollList, BOTTOMRIGHT, 0, 0)

        landingArea.hintTextStringId = hintTextStringId
    end
end

function ZO_InventoryLandingArea_Initialize(landingArea, descriptor, bagId, customOffset)
    local newParent = landingArea:GetParent():GetNamedChild("Contents")
    landingArea:SetParent(newParent)

    landingArea.bagId = bagId
    landingArea.descriptor = descriptor
    landingArea.iconOffset = customOffset or 50
end
