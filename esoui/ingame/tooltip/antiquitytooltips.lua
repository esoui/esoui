function ZO_Tooltip:LayoutAntiquityLead(antiquityId)
    local antiquityData = ANTIQUITY_DATA_MANAGER:GetAntiquityData(antiquityId)
    if antiquityData then
        local topSection = self:AcquireSection(self:GetStyle("topSection"))
        topSection:AddLine(GetString(SI_ANTIQUITY_LEAD_TOOLTIP_TAG))
        self:AddSection(topSection)

        local quality = antiquityData:GetQuality()
        local qualityStyle = ZO_TooltipStyles_GetAntiquityQualityStyle(quality)
        local formattedName = zo_strformat(SI_ANTIQUITY_LEAD_NAME_FORMATTER, antiquityData:GetName())
        self:AddLine(formattedName, qualityStyle, self:GetStyle("title"))

        local bodySection = self:AcquireSection(self:GetStyle("antiquityInfoSection"))
        local descriptionStyle = self:GetStyle("bodyDescription")
        local formattedDescription = zo_strformat(SI_ANTIQUITY_LEAD_TOOLTIP_DESCRIPTION, antiquityData:GetColorizedName())
        bodySection:AddLine(formattedDescription, descriptionStyle)
        self:AddSection(bodySection)

        local zoneName = GetZoneNameById(antiquityData:GetZoneId())
        if zoneName ~= "" then
            local locationSection = self:AcquireSection(self:GetStyle("bodySection"))
            local formattedLocation = zo_strformat(SI_ANTIQUITY_LEAD_TOOLTIP_ZONE, ZO_SELECTED_TEXT:Colorize(zoneName))
            locationSection:AddLine(formattedLocation, self:GetStyle("bodyDescription"))
            self:AddSection(locationSection)
        end
    end
end

function ZO_Tooltip:LayoutAntiquitySetFragment(antiquityId)
    local antiquityData = ANTIQUITY_DATA_MANAGER:GetAntiquityData(antiquityId)
    if antiquityData then
        local antiquitySetData = antiquityData:GetAntiquitySetData()
        if antiquitySetData then
            local topSection = self:AcquireSection(self:GetStyle("topSection"))
            topSection:AddLine(GetString(SI_ANTIQUITY_SET_FRAGMENT_TOOLTIP_TAG))
            self:AddSection(topSection)

            local meetsLeadRequirements = antiquityData:MeetsLeadRequirements()
            local isHidden = not meetsLeadRequirements and not antiquityData:HasRecovered()
            if isHidden then
                self:AddLine(GetString(SI_ANTIQUITY_NAME_HIDDEN), self:GetStyle("title"))
            else
                local formattedName = antiquityData:GetColorizedFormattedName()
                self:AddLine(formattedName, self:GetStyle("title"))
            end

            local bodySection = self:AcquireSection(self:GetStyle("antiquityInfoSection"))
            local formattedSetDescription = zo_strformat(SI_ANTIQUITY_FRAGMENT_SET_DESCRIPTOR, antiquitySetData:GetNumAntiquities(), antiquitySetData:GetName())
            bodySection:AddLine(formattedSetDescription, self:GetStyle("bodyDescription"))
            self:AddSection(bodySection)

            if meetsLeadRequirements then
                local zoneName = GetZoneNameById(antiquityData:GetZoneId())
                if zoneName ~= "" then
                    local locationSection = self:AcquireSection(self:GetStyle("bodySection"))
                    local formattedLocation = zo_strformat(SI_ANTIQUITY_LEAD_TOOLTIP_ZONE, ZO_SELECTED_TEXT:Colorize(zoneName))
                    locationSection:AddLine(formattedLocation, self:GetStyle("bodyDescription"))
                    self:AddSection(locationSection)
                end
            else
                local missingLeadSection = self:AcquireSection(self:GetStyle("bodySection"))
                missingLeadSection:AddLine(GetString(SI_ANTIQUITY_REQUIRES_LEAD), self:GetStyle("bodyDescription"))
                self:AddSection(missingLeadSection)
            end
        end
    end
end
