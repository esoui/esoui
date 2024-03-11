-- ColorDef implementation

ZO_ColorDef = ZO_Object:Subclass()

function ZO_ColorDef:New(r, g, b, a)
    local c = ZO_Object.New(self)

    if type(r) == "string" then
        c.r, c.g, c.b, c.a = self.HexToFloats(r)
    elseif type(r) == "table" then
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

-- Returns the RGB linearly interpolated from this color to the specified color.
function ZO_ColorDef:GetLerpRGB(colorToLerpTo, normalizedPercent)
    return self.LerpRGB(self, colorToLerpTo, normalizedPercent)
end

-- Returns the RGBA linearly interpolated from this color to the specified color.
function ZO_ColorDef:GetLerpRGBA(colorToLerpTo, normalizedPercent)
    return self.LerpRGBA(self, colorToLerpTo, normalizedPercent)
end

-- Sets the RGB for this color to the linear interpolation between the two specified colors.
function ZO_ColorDef:SetLerpRGB(colorToLerpFrom, colorToLerpTo, normalizedPercent)
    self.r, self.g, self.b = self.LerpRGB(colorToLerpFrom, colorToLerpTo, normalizedPercent)
end

-- Sets the RGBA for this color to the linear interpolation between the two specified colors.
function ZO_ColorDef:SetLerpRGBA(colorToLerpFrom, colorToLerpTo, normalizedPercent)
    self.r, self.g, self.b, self.a = self.LerpRGBA(colorToLerpFrom, colorToLerpTo, normalizedPercent)
end

-- Returns a new color that is the linear interpolation between this color and the specified color.
function ZO_ColorDef:Lerp(colorToLerpTorwards, amount)
	return ZO_ColorDef:New(
        zo_lerp(self.r, colorToLerpTorwards.r, amount),
        zo_lerp(self.g, colorToLerpTorwards.g, amount),
        zo_lerp(self.b, colorToLerpTorwards.b, amount),
        zo_lerp(self.a, colorToLerpTorwards.a, amount)
    )
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
    return self.FloatsToHex(self.r, self.g, self.b, 1)
end

function ZO_ColorDef:ToARGBHex()
    return self.FloatsToHex(self.r, self.g, self.b, self.a)
end

function ZO_ColorDef:Colorize(text)
	local combineTable = { "|c", self:ToHex(), tostring(text), "|r" }
	return table.concat(combineTable)
end

function ZO_ColorDef:ToHSL()
    return ConvertRGBToHSL(self.r, self.g, self.b)
end

function ZO_ColorDef:ToHSV()
    return ConvertRGBToHSV(self.r, self.g, self.b)
end

do
    local REDUCE_AMOUNT = 0.25
    function ZO_ColorDef:GetDim()
        if not self.dimColor then
            local r, g, b, a = self:UnpackRGBA()
            r, g, b = zo_saturate(r - REDUCE_AMOUNT), zo_saturate(g - REDUCE_AMOUNT), zo_saturate(b - REDUCE_AMOUNT)
            self.dimColor = ZO_ColorDef:New(r, g, b, a)
        end

        return self.dimColor
    end
end

do
    local INCREASE_AMOUNT = 0.15
    function ZO_ColorDef:GetBright()
        if not self.brightColor then
            local r, g, b, a = self:UnpackRGBA()
            r, g, b = zo_saturate(r + INCREASE_AMOUNT), zo_saturate(g + INCREASE_AMOUNT), zo_saturate(b + INCREASE_AMOUNT)
            self.brightColor = ZO_ColorDef:New(r, g, b, a)
        end

        return self.brightColor
    end
end

-- Utility functions for ColorDef...
-- Some of these functions are not fast, they were copied from an internal dev utility.
-- RGBA values are values from 0 - 255
-- Float values are values from 0 - 1
-- Hex values are either 6 (RRGGBB) or 8 (AARRGGBB) character hexideciaml strings (e.g.: 0fc355, bb0fc355)

local g_colorDef = ZO_ColorDef

function ZO_ColorDef.RGBAToFloats(r, g, b, a)
    return r / 255, g / 255, b / 255, a / 255
end

function ZO_ColorDef.FloatsToRGBA(r, g, b, a)
    return zo_round(r * 255), zo_round(g * 255), zo_round(b * 255), zo_round(a * 255)
end

function ZO_ColorDef.RGBAToStrings(r, g, b, a)
    return string.format("%d", r), string.format("%d", g), string.format("%d", b), string.format("%d", a)
end

function ZO_ColorDef.FloatsToStrings(r, g, b, a)
    return string.format("%.3f", r), string.format("%.3f", g), string.format("%.3f", b), string.format("%.3f", a)
end

function ZO_ColorDef.RGBAToHex(r, g, b, a)
    if a == 255 then
        return string.format("%02x%02x%02x", r, g, b)
    else
        return string.format("%02x%02x%02x%02x", a, r, g, b)
    end
end

function ZO_ColorDef.FloatsToHex(r, g, b, a)
    r, g, b, a = g_colorDef.FloatsToRGBA(r, g, b, a)
    return g_colorDef.RGBAToHex(r, g, b, a)
end

do
    local function ConsumeRightmostChannel(value)
        local channel = value % 256
        value = zo_floor(value / 256)
        return channel, value
    end

    function ZO_ColorDef.HexToRGBA(hexColor)
        local hexColorLen = #hexColor
        if hexColorLen >= 6 then
            local value = tonumber(hexColor, 16)
            if value then
                local r, g, b, a
                b, value = ConsumeRightmostChannel(value)
                g, value = ConsumeRightmostChannel(value)
                r, value = ConsumeRightmostChannel(value)
                if hexColorLen >= 8 then
                    a = ConsumeRightmostChannel(value)
                else
                    a = 255
                end

                return r, g, b, a
            end
        end
    end

    function ZO_ColorDef.HexToFloats(hexColor)
        local r, g, b, a = g_colorDef.HexToRGBA(hexColor)
        if r then
            return g_colorDef.RGBAToFloats(r, g, b, a)
        end
    end
end

-- Returns the linearly interpolated RGB between the two specified colors.
function ZO_ColorDef.LerpRGB(colorToLerpFrom, colorToLerpTo, normalizedPercent)
    local r = zo_lerp(colorToLerpFrom.r, colorToLerpTo.r, normalizedPercent)
    local g = zo_lerp(colorToLerpFrom.g, colorToLerpTo.g, normalizedPercent)
    local b = zo_lerp(colorToLerpFrom.b, colorToLerpTo.b, normalizedPercent)
    return r, g, b
end

-- Returns the linearly interpolated RGBA between the two specified colors.
function ZO_ColorDef.LerpRGBA(colorToLerpFrom, colorToLerpTo, normalizedPercent)
    local r = zo_lerp(colorToLerpFrom.r, colorToLerpTo.r, normalizedPercent)
    local g = zo_lerp(colorToLerpFrom.g, colorToLerpTo.g, normalizedPercent)
    local b = zo_lerp(colorToLerpFrom.b, colorToLerpTo.b, normalizedPercent)
    local a = zo_lerp(colorToLerpFrom.a, colorToLerpTo.a, normalizedPercent)
    return r, g, b, a
end