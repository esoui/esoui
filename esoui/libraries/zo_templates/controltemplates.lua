local g_mouseTooltipMethods =
{
    GetTooltipString = function(control)
        local tooltipStringOrFunction = control.tooltipString
        if type(tooltipStringOrFunction) == "function" then
            return tooltipStringOrFunction(control)
        end
        return tooltipStringOrFunction
    end,

    SetTooltipString = function(control, stringOrStringIdOrFunction)
        local stringValue = stringOrStringIdOrFunction
        if type(stringOrStringIdOrFunction) == "number" then
            stringValue = GetString(stringValue)
        end
        control.tooltipString = stringValue
    end,
}

function ZO_MouseTooltipBehavior_OnInitialized(control)
    zo_mixin(control, g_mouseTooltipMethods)
end

function ZO_MouseTooltipBehavior_OnMouseEnter(control)
    local tooltipString = control:GetTooltipString()
    if not tooltipString or tooltipString == "" then
        return
    end

    local tooltipControl = InformationTooltip
    control.activeMouseTooltipControl = tooltipControl

    InitializeTooltip(tooltipControl)
    ZO_Tooltips_SetupDynamicTooltipAnchors(tooltipControl, control)
    SetTooltipText(tooltipControl, tooltipString)
end

function ZO_MouseTooltipBehavior_OnMouseExit(control)
    if control.activeMouseTooltipControl then
        ClearTooltip(control.activeMouseTooltipControl)
        control.activeMouseTooltipControl = nil
    end
end