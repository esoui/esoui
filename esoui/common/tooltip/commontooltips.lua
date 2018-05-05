-- These are tooltips that are generic enough to be used by multiple UIs for various purposes
-- do not add layout functions that are specific to one UI

--If there are three or more functions for one system move it to its own file

function ZO_Tooltip:LayoutTextBlockTooltip(text)
    local section = self:AcquireSection(self:GetStyle("bodySection"))
    section:AddLine(text, self:GetStyle("bodyDescription"))
    self:AddSection(section)
end

function ZO_Tooltip:LayoutCurrency(currencyType, amount)
    if currencyType ~= CURT_NONE then
        --things added to the topSection stack upwards
        local topSection = self:AcquireSection(self:GetStyle("topSection"))
        local heldAmount = GetCurrencyAmount(currencyType, GetCurrencyPlayerStoredLocation(currencyType))
        if heldAmount > 0 then
            local topSubsection = topSection:AcquireSection(self:GetStyle("topSubsectionItemDetails"))
            local currencyGamepadIcon = GetCurrencyGamepadIcon(currencyType)
            topSubsection:AddLine(zo_iconTextFormat(currencyGamepadIcon, 24, 24, heldAmount))
            topSection:AddSection(topSubsection)
        end

        self:AddSection(topSection)

        -- Name
        local IS_UPPER = false
        local displayName
        if amount and amount > 1 then
            local IS_PLURAL = false
            local currencyName = GetCurrencyName(currencyType, IS_PLURAL, IS_UPPER)
            displayName = zo_strformat(SI_TOOLTIP_ITEM_NAME_WITH_QUANTITY, currencyName, amount)
        else
            local IS_SINGULAR = true
            local currencyName = GetCurrencyName(currencyType, IS_SINGULAR, IS_UPPER)
            displayName = zo_strformat(SI_TOOLTIP_ITEM_NAME, currencyName)
        end
        self:AddLine(displayName, self:GetStyle("title"))

        -- Description
        local bodySection = self:AcquireSection(self:GetStyle("collectionsInfoSection"))
        local description = GetCurrencyDescription(currencyType)
        bodySection:AddLine(description, self:GetStyle("bodyDescription"))
        self:AddSection(bodySection)
    end
end