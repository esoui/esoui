-- Valid Text Instructions Base Class --

ZO_ValidTextInstructions = ZO_InitializingObject:Subclass()

function ZO_ValidTextInstructions:Initialize(control, template, instructions)
    self.m_control = control
    self.m_ruleToControl = { }
    self.m_template = template or "ZO_TextInstructionLine"
    self.m_instructionPool = ZO_ControlPool:New(self.m_template, control, "TextInstruction")

    self:AddInstructions(instructions)
end

function ZO_ValidTextInstructions:GetControl()
    return self.m_control
end

function ZO_ValidTextInstructions:HasRules()
    return next(self.m_ruleToControl) ~= nil
end

ZO_ValidTextInstructions.GetViolationPrefix = ZO_ValidTextInstructions:MUST_IMPLEMENT()

function ZO_ValidTextInstructions:AddInstructions(instructions)
    --[[Because different contexts may use different rules,
    and because we don't want to display rules that are irrelevant
    to the current context, which instructions we're adding is
    handled elsewhere depending on context. The new locations are
    as follows:
    Outfit and Collectible renaming: InGameDialogs.lua
    Guild naming: SocialDialogs_Keyboard.lua
    Character naming: ZO_CharacterCreate_Keyboad.lua
    Character REnaming: ZO_CharacterSelect_Keyboard.lua

    If a design decision is made to change which rules any context should follow,
    then in addition to the above, a corresponding change will also have to be made
    in NameValidation.cpp. ]]

    if instructions then
        for _, instruction in ipairs(instructions) do
            self:AddInstruction(instruction)
        end
    end
end

function ZO_ValidTextInstructions:ClearInstructions()
    self.m_anchorTo = nil
    ZO_ClearTable(self.m_ruleToControl)
    self.m_instructionPool:ReleaseAllObjects()
end

function ZO_ValidTextInstructions:AddInstruction(instructionEnum)
    if self.m_ruleToControl[instructionEnum] then
        return
    end
    
    local instruction = self.m_instructionPool:AcquireObject()
    instruction:SetText(GetString(self:GetViolationPrefix(), instructionEnum))
    instruction.m_rule = instructionEnum

    if(self.m_anchorTo) then
        instruction:SetAnchor(TOPLEFT, self.m_anchorTo, BOTTOMLEFT, 0, 15)
    else
        instruction:SetAnchor(TOP, self.m_control, TOP, 0, 10)
    end

    self.m_anchorTo = instruction
    self.m_ruleToControl[instructionEnum] = instruction
end

local function HasViolatedRule(rule, ruleViolations)
    if ruleViolations then
        return ZO_IsElementInNumericallyIndexedTable(ruleViolations, rule)
    end

    return false
end

function ZO_ValidTextInstructions:UpdateViolations(ruleViolations)
    for rule, instructionLine in pairs(self.m_ruleToControl) do
        if(HasViolatedRule(rule, ruleViolations)) then
            instructionLine:SetColor(GetInterfaceColor(INTERFACE_COLOR_TYPE_TEXT_COLORS, INTERFACE_TEXT_COLOR_FAILED))
        else
            instructionLine:SetColor(GetInterfaceColor(INTERFACE_COLOR_TYPE_TEXT_COLORS, INTERFACE_TEXT_COLOR_NORMAL))
        end
    end
end

function ZO_ValidTextInstructions:SetPreferredAnchor(point, relativeTo, relativePoint, offsetX, offsetY)
    self.m_preferredAnchor = ZO_Anchor:New(point, relativeTo, relativePoint, offsetX, offsetY)
end

function ZO_ValidTextInstructions:Show(editControl, ruleViolations)
    if(self.m_preferredAnchor) then
        self.m_preferredAnchor:Set(self.m_control)
    elseif editControl then
        self.m_control:ClearAnchors()
        self.m_control:SetAnchor(TOPRIGHT, editControl, TOPLEFT, -50, 0)
    end

    if self:HasRules() then
        self.m_control:SetHidden(false)
        self:UpdateViolations(ruleViolations)
    end
end

function ZO_ValidTextInstructions:Hide()
    self.m_control:SetHidden(true)
end

-- Valid Name Instructions --

ZO_ValidNameInstructions = ZO_ValidTextInstructions:Subclass()

function ZO_ValidNameInstructions:GetViolationPrefix()
    return "SI_NAMINGERROR"
end

local NAME_RULES_TABLE = nil

function ZO_ValidNameInstructions_GetViolationString(name, ruleViolations, hideUnviolatedRules, format)
    format = format or SI_INVALID_NAME_DIALOG_INSTRUCTION_FORMAT

    if(NAME_RULES_TABLE == nil) then
        NAME_RULES_TABLE = {}

        table.insert(NAME_RULES_TABLE, NAME_RULE_TOO_SHORT)
        table.insert(NAME_RULES_TABLE, NAME_RULE_CANNOT_START_WITH_SPACE)
        table.insert(NAME_RULES_TABLE, NAME_RULE_MUST_END_WITH_LETTER)
        table.insert(NAME_RULES_TABLE, NAME_RULE_TOO_MANY_IDENTICAL_ADJACENT_CHARACTERS)
        table.insert(NAME_RULES_TABLE, NAME_RULE_NO_NUMBERS)
        table.insert(NAME_RULES_TABLE, NAME_RULE_NO_ADJACENT_PUNCTUATION_CHARACTERS)
        table.insert(NAME_RULES_TABLE, NAME_RULE_TOO_MANY_PUNCTUATION_CHARACTERS)
        table.insert(NAME_RULES_TABLE, NAME_RULE_INVALID_CHARACTERS)
    end

    local invalidNameString = ""

    for i, instructionEnum in ipairs(NAME_RULES_TABLE) do
        local violatedRule = HasViolatedRule(instructionEnum, ruleViolations)
        if(violatedRule or hideUnviolatedRules ~= true) then
            local color = ZO_ColorDef:New(GetInterfaceColor(INTERFACE_COLOR_TYPE_TEXT_COLORS, INTERFACE_TEXT_COLOR_NORMAL))
            if(violatedRule) then
                color = ZO_ColorDef:New(GetInterfaceColor(INTERFACE_COLOR_TYPE_TEXT_COLORS, INTERFACE_TEXT_COLOR_FAILED))
            end

            local text = GetString("SI_NAMINGERROR", instructionEnum)
            local coloredText = color:Colorize(text)

            invalidNameString = invalidNameString .. zo_strformat(format, coloredText)
        end
    end

    return invalidNameString
end

-- Valid AccoutName Instructions --

ZO_ValidAccountNameInstructions = ZO_ValidTextInstructions:Subclass()

function ZO_ValidAccountNameInstructions:GetViolationPrefix()
    return "SI_ACCOUNTNAMINGERROR"
end


function ZO_ValidAccountNameInstructions:AddInstructions(instructions)
    local shownInstructions = instructions or
    {
        ACCOUNT_NAME_RULE_INCORRECT_LENGTH,
        ACCOUNT_NAME_RULE_TOO_MANY_IDENTICAL_ADJACENT_CHARACTERS,
        ACCOUNT_NAME_RULE_TOO_MANY_PUNCTUATION_CHARACTERS,
        ACCOUNT_NAME_RULE_MUST_START_WITH_LETTER,
        ACCOUNT_NAME_RULE_MUST_END_WITH_NUMBER_OR_LETTER,
        ACCOUNT_NAME_RULE_NO_SPACES,
        ACCOUNT_NAME_RULE_INVALID_CHARACTERS
    }
    
    ZO_ValidTextInstructions.AddInstructions(self, shownInstructions)
end