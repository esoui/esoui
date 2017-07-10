-- Utility functions for ColorDef...
local function ConvertHTMLColorToFloatValues(htmlColor) -- This function is not fast, it was copied from an internal dev utility.
    local htmlColorLen = string.len(htmlColor)
    local a, r, g, b
    
    if(htmlColorLen == 8)
    then
        a, r, g, b = tonumber("0x"..string.sub(htmlColor, 1, 2)) / 255, tonumber("0x"..string.sub(htmlColor, 3, 4)) / 255, tonumber("0x"..string.sub(htmlColor, 5, 6)) / 255, tonumber("0x"..string.sub(htmlColor, 7, 8)) / 255
    elseif(htmlColorLen == 6)
    then
        a, r, g, b = 1, tonumber("0x"..string.sub(htmlColor, 1, 2)) / 255, tonumber("0x"..string.sub(htmlColor, 3, 4)) / 255, tonumber("0x"..string.sub(htmlColor, 5, 6)) / 255
    end
    
    if(a)
    then
        return a, r, g, b
    end
end

-- ColorDef implementation

ZO_ColorDef = ZO_Object:Subclass()

function ZO_ColorDef:New(r, g, b, a)
    local c = ZO_Object.New(self)
    
    if(type(r) == "string") then            
        c.a, c.r, c.g, c.b = ConvertHTMLColorToFloatValues(r)
    elseif(type(r) == "table") then
		local otherColorDef = r
		c.r = otherColorDef.r or 1
        c.g = otherColorDef.g or 1
        c.b = otherColorDef.b or 1
        c.a = otherColorDef.a or 1
    else
        c.r = r or 1
        c.g = g or 1
        c.b = b or 1
        c.a = a or 1
    end

    return c
end

function ZO_ColorDef.FromInterfaceColor(colorType, fieldValue)
    return ZO_ColorDef:New(GetInterfaceColor(colorType, fieldValue))
end

do
    local function ConsumeRightmostChannel(value)
        local channel = value % 256
        channel = channel / 255
        value = zo_floor(value / 256)
        return channel, value
    end

    function ZO_ColorDef.FromARGBHexadecimal(ARGBHexadecimal)
        if #ARGBHexadecimal == 8 then
            local value = tonumber(ARGBHexadecimal, 16)
            if value then
                local a, r, g, b
                b, value = ConsumeRightmostChannel(value)
                g, value = ConsumeRightmostChannel(value)
                r, value = ConsumeRightmostChannel(value)
                a, value = ConsumeRightmostChannel(value)
                return ZO_ColorDef:New(r, g, b, a)
            end
        end
    end
end

function ZO_ColorDef:UnpackRGB()
    return self.r, self.g, self.b
end

function ZO_ColorDef:UnpackRGBA()
    return self.r, self.g, self.b, self.a
end

function ZO_ColorDef:SetRGB(r, g, b)
	self.r = r
	self.g = g
	self.b = b
end

function ZO_ColorDef:SetRGBA(r, g, b, a)
	self.r = r
	self.g = g
	self.b = b
	self.a = a
end

function ZO_ColorDef:SetAlpha(a)
    self.a = a
end

function ZO_ColorDef:IsEqual(other)
    return self.r == other.r
       and self.g == other.g
       and self.b == other.b
       and self.a == other.a
end

function ZO_ColorDef:Clone()
	return ZO_ColorDef:New(self:UnpackRGBA())
end

function ZO_ColorDef:ToHex()
	return string.format("%.2x%.2x%.2x", zo_round(self.r * 255), zo_round(self.g * 255), zo_round(self.b * 255))
end

function ZO_ColorDef:ToARGBHexadecimal()
    return ZO_ColorDef.ToARGBHexadecimal(self.r, self.g, self.b, self.a)
end

function ZO_ColorDef.ToARGBHexadecimal(r, g, b, a)
    return string.format("%.2x%.2x%.2x%.2x", zo_round(a * 255), zo_round(r * 255), zo_round(g * 255), zo_round(b * 255))
end

function ZO_ColorDef:Colorize(text)
	local combineTable = { "|c", self:ToHex(), tostring(text), "|r" }
	return table.concat(combineTable)
end

function ZO_ColorDef:Lerp(colorToLerpTorwards, amount)
	return ZO_ColorDef:New(
        zo_lerp(self.r, colorToLerpTorwards.r, amount),
        zo_lerp(self.g, colorToLerpTorwards.g, amount),
        zo_lerp(self.b, colorToLerpTorwards.b, amount),
        zo_lerp(self.a, colorToLerpTorwards.a, amount)
    )
end