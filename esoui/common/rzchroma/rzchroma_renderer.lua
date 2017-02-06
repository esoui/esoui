ZO_ChromaCustomRenderer = ZO_Object:Subclass()

function ZO_ChromaCustomRenderer:New(...)
    local object = ZO_Object.New(self)
    object:Initialize(...)
    return object
end

function ZO_ChromaCustomRenderer:Initialize()

end

function ZO_ChromaCustomRenderer:RenderEffect(effect)
    if effect:IsCStyle() then
        ChromaApplyCustomEffectId(effect:GetEffectId())
    else
        local deviceType = effect:GetDeviceType()
        local blendMode = effect:GetBlendMode()
        local numRows, numColumns = ChromaGetCustomEffectDimensions(deviceType)
        local valid, r, g, b, a = effect:GetColorRGB()
        if effect:IsFullGrid() then
            ChromaApplyCustomEffectFullColor(deviceType, r, g, b, a, blendMode)
        else
            for row = 1, numRows do
                for column = 1, numColumns do
                    if effect:GetCellValid(row, column) then
                        ChromaApplyCustomEffectCellColor(deviceType, row, column, r, g, b, a, blendMode)
                    end
                end
            end
        end
    end
end

if IsChromaSystemAvailable() then
    ZO_CHROMA_RENDERER = ZO_ChromaCustomRenderer:New()
end