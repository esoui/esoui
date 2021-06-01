-- ZO_AbstractSingleTemplateGridScrollList_Keyboard --

ZO_AbstractSingleTemplateGridScrollList_Keyboard = ZO_AbstractGridScrollList_Keyboard:Subclass()

function ZO_AbstractSingleTemplateGridScrollList_Keyboard:New(...)
    return ZO_AbstractGridScrollList_Keyboard.New(self, ...)
end

function ZO_AbstractSingleTemplateGridScrollList_Keyboard:Initialize(control)
    ZO_AbstractGridScrollList_Keyboard.Initialize(self, control)
end

-- ZO_SingleTemplateGridScrollList_Keyboard --

ZO_SingleTemplateGridScrollList_Keyboard = ZO_Object.MultiSubclass(ZO_AbstractSingleTemplateGridScrollList_Keyboard, ZO_AbstractSingleTemplateGridScrollList)

function ZO_SingleTemplateGridScrollList_Keyboard:New(...)
    return ZO_AbstractSingleTemplateGridScrollList.New(self, ...)
end

function ZO_SingleTemplateGridScrollList_Keyboard:Initialize(control, autofillRows)
    ZO_AbstractSingleTemplateGridScrollList.Initialize(self, control, autofillRows)
    ZO_AbstractGridScrollList_Keyboard.Initialize(self, control)
end
