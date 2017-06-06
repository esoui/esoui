
-- TODO: Window and Animation managers could arguably be exposed as global functions
WINDOW_MANAGER = GetWindowManager()     
ANIMATION_MANAGER = GetAnimationManager()
EVENT_MANAGER = GetEventManager()

ESO_Dialogs = {}

function CreateTopLevelWindow(name)
    return WINDOW_MANAGER:CreateTopLevelWindow(name)
end

function CreateControl(name, parent, controlType)
    return WINDOW_MANAGER:CreateControl(name, parent, controlType)
end

function CreateControlFromVirtual(name, parent, templateName, optionalNameSuffix)
    return WINDOW_MANAGER:CreateControlFromVirtual(name, parent, templateName, optionalNameSuffix)
end

function ApplyTemplateToControl(control, templateName)
    WINDOW_MANAGER:ApplyTemplateToControl(control, templateName)
end

function CreateControlRangeFromVirtual(name, parent, templateName, rangeMinSuffix, rangeMaxSuffix)
    for i = rangeMinSuffix, rangeMaxSuffix do
        CreateControlFromVirtual(name, parent, templateName, i)
    end
end

-- 
-- GetControl now calls into C++ to avoid memory allocations resulting from string concatenation.
-- Previously this would do a lookup like: _G[controlName..suffix].  The problem is this function is
-- called a LOT of times, so that would end up doing tons of very small allocations.  
-- To get around this problem we just pay the price of a Lua -> C++ call where we can sprintf to a temp
-- symbol and find the control without allocating memory.
--
function GetControl(name, suffix)    
    if(type(name) == "string") then
        if(suffix) then
            return WINDOW_MANAGER:GetControlByName(name, tostring(suffix))
        end
        
        return _G[name]
    -- "name" must be an actual Control object and "suffix" is a string. Otherwise this function wouldn't need to be called
    elseif(suffix) then
        return name:GetNamedChild(suffix)
    end
end

-- Function that simplifies the creation of a timeline that is required for all animations
function CreateSimpleAnimation(animationType, controlToAnimate, delay)
    local timeline = ANIMATION_MANAGER:CreateTimeline()
    local animation = timeline:InsertAnimation(animationType, controlToAnimate, delay)
    return animation, timeline
end
