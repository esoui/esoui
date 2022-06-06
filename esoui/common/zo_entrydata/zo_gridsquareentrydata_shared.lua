ZO_GridSquareEntryData_Shared = ZO_EntryData:Subclass()

function ZO_GridSquareEntryData_Shared:New(...)
    return ZO_EntryData.New(self, ...)
end

-- If these are set for one data entry in a list for a given data type, they must be set for all entries in that list for that data type
-- Otherwise they will not be reset when the control gets recycled
function ZO_GridSquareEntryData_Shared:SetIconDesaturation(desaturation)
    self.iconDesaturation = desaturation
end

function ZO_GridSquareEntryData_Shared:SetIconSampleProcessingWeight(type, weight)
    if not self.textureSampleProcessingWeights then
        self.textureSampleProcessingWeights = {}
    end
    self.textureSampleProcessingWeights[type] = weight
end

function ZO_GridSquareEntryData_Shared:SetIconSampleProcessingWeightTable(typeToWeightTable)
    self.textureSampleProcessingWeights = typeToWeightTable
end

function ZO_GridSquareEntryData_Shared:SetIconColor(color)
    self.iconColor = color
end
