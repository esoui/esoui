ZO_DIRECTION_UP = 1
ZO_DIRECTION_DOWN = 2
ZO_DIRECTION_LEFT = 3
ZO_DIRECTION_RIGHT = 4

ZO_OPPOSITE_DIRECTIONS =
{
    [ZO_DIRECTION_UP] = ZO_DIRECTION_DOWN,
    [ZO_DIRECTION_DOWN] = ZO_DIRECTION_UP,
    [ZO_DIRECTION_LEFT] = ZO_DIRECTION_RIGHT,
    [ZO_DIRECTION_RIGHT] = ZO_DIRECTION_LEFT,
}

--Client Input
----------------------------

local ClientInput = ZO_Object:Subclass()

function ClientInput:New()
    local object = ZO_Object.New(self)
    object:Initialize()
    return object
end

function ClientInput:Initialize()
    DIRECTIONAL_INPUT:Activate(self, GuiRoot)
end

function ClientInput:UpdateDirectionalInput()
    SetGamepadLeftStickConsumedByUI(not DIRECTIONAL_INPUT:IsAvailable(ZO_DI_LEFT_STICK))
    SetGamepadRightStickConsumedByUI(not DIRECTIONAL_INPUT:IsAvailable(ZO_DI_RIGHT_STICK))
end


--Directional Input
----------------------------

ZO_DI_LEFT_STICK = 1
ZO_DI_RIGHT_STICK = 2
ZO_DI_DPAD = 3

local NUM_INPUT_DEVICES = 3

local DirectionalInput = ZO_Object:Subclass()

function DirectionalInput:New(...)
    local obj = ZO_Object.New(self)
    obj:Initialize(...)
    return obj
end

function DirectionalInput:Initialize()
    self.inputObjects = {}
    self.inputControls = {}
    self.inputDeviceConsumed = {}
    self.allInputDevices = { ZO_DI_LEFT_STICK, ZO_DI_RIGHT_STICK, ZO_DI_DPAD }
    EVENT_MANAGER:RegisterForUpdate("DirectionalInput", 0, function() self:OnUpdate() end)

    self.updating = false
    self.queuedActivationOperations = {}
end

function DirectionalInput:Activate(object, control)
    assert(control and control.IsControlHidden ~= nil)

    if self.updating then
        self:QueueActivation(object, control)
        return
    end

    -- We use an insertion sort because table.sort is unstable
    -- All the controls take priority over the non-controls
    for index = #self.inputObjects, 1, -1 do
        local currentControl = self.inputControls[index]
        if WINDOW_MANAGER:CompareControlVisualOrder(control, currentControl) >= 0 then
            table.insert(self.inputObjects, index + 1, object)
            table.insert(self.inputControls, index + 1, control)
            return
        end
    end

    table.insert(self.inputObjects, 1, object)
    table.insert(self.inputControls, 1, control)
end

function DirectionalInput:Deactivate(object)
    if self.updating then
        self:QueueDeactivation(object)
        return
    end    
    for i, curObject in ipairs(self.inputObjects) do
        if(curObject == object) then
            table.remove(self.inputObjects, i)
            table.remove(self.inputControls, i)
            break
        end
    end
end

function DirectionalInput:QueueActivation(object, control)
    local op = 
    {
        activate = true,
        object = object,
        control = control,
    }
    table.insert(self.queuedActivationOperations, op)
end


function DirectionalInput:QueueDeactivation(object)
    local op = 
    {
        activate = false,
        object = object,
    }
    table.insert(self.queuedActivationOperations, op)
end

function DirectionalInput:PerformQueuedActivationOperation(op)
    if op.activate then
        self:Activate(op.object, op.control)
    else
        self:Deactivate(op.object)
    end
end

--... = input devices
function DirectionalInput:Consume(...)
    for i = 1, select("#", ...) do
        self.inputDeviceConsumed[select(i, ...)] = true
    end
end

function DirectionalInput:ConsumeAll()
    self:Consume(unpack(self.allInputDevices))
end

function DirectionalInput:AreAllInputDevicesConsumed()
    for i = 1, NUM_INPUT_DEVICES do
        if(self.inputDeviceConsumed[i] == false) then
            return false
        end
    end
    return true
end

-- Continuous updates, this loop will stop once it encounters something that only handles digital inputs
-- The order that objects are activated affects how this works
function DirectionalInput:OnUpdate()

    self.updating = true
    for i = 1, NUM_INPUT_DEVICES do
        self.inputDeviceConsumed[i] = false
    end

    local deltaS = 0
    local nowS = GetFrameTimeSeconds()
    if self.lastUpdateS then
        deltaS = nowS - self.lastUpdateS
    end
    self.lastUpdateS = nowS

    for index = #self.inputObjects, 1, -1 do
        local inputObject = self.inputObjects[index]
        inputObject:UpdateDirectionalInput(deltaS)
    end
    self.updating = false

    for i,op in ipairs(self.queuedActivationOperations) do
        self:PerformQueuedActivationOperation(op)
    end
    ZO_ClearNumericallyIndexedTable(self.queuedActivationOperations)
end

function DirectionalInput:IsAvailable(inputDevice)
    return not self.inputDeviceConsumed[inputDevice]
end

--... = input devices
function DirectionalInput:GetX(...)
    local numArgs = select("#", ...)
    if(numArgs == 0) then
        return self:GetX(unpack(self.allInputDevices))
    end

    local resultX = 0
    for i = 1, numArgs do
        local inputDevice = select(i, ...)
        if(self:IsAvailable(inputDevice)) then
            local x = self:GetXFromInputDevice(inputDevice)
            local y = self:GetYFromInputDevice(inputDevice)
            if(zo_abs(x) > zo_abs(y)) then
                resultX = x
                break
            end
        end
    end

    if(resultX ~= 0) then
        self:Consume(...)
    end

    return resultX
end

--... = input devices
function DirectionalInput:GetY(...)
    local numArgs = select("#", ...)
    if(numArgs == 0) then
        return self:GetY(unpack(self.allInputDevices))
    end

    local resultY = 0
    for i = 1, numArgs do
        local inputDevice = select(i, ...)
        if(self:IsAvailable(inputDevice)) then
            local x = self:GetXFromInputDevice(inputDevice)
            local y = self:GetYFromInputDevice(inputDevice)
            if(zo_abs(y) > zo_abs(x)) then
                resultY = y
                break
            end
        end
    end

    if(resultY ~= 0) then
        self:Consume(...)
    end

    return resultY
end

--... = input devices
function DirectionalInput:GetXY(...)
    local numArgs = select("#", ...)
    if(numArgs == 0) then
        return self:GetXY(unpack(self.allInputDevices))
    end
    
    for i = 1, numArgs do
        local inputDevice = select(i, ...)
        if(self:IsAvailable(inputDevice)) then
            local x = self:GetXFromInputDevice(inputDevice)
            local y = self:GetYFromInputDevice(inputDevice)
            if(x ~= 0 or y ~= 0) then
                self:Consume(...)
                return x, y
            end
        end
    end

    --even if there's no input on X,Y we might as well consume the devices since they have no input and won't be used
    self:Consume(...)
    return 0, 0
end

local DIGITAL_BUTTON_MAGNITUDE = 1.0

local INPUT_DEVICE_QUERY_X =
{
    [ZO_DI_LEFT_STICK] = function(self)
        return GetGamepadLeftStickX(GAMEPAD_INCLUDE_DEADZONE)
    end,
    [ZO_DI_RIGHT_STICK] = function(self)
        return GetGamepadRightStickX(GAMEPAD_INCLUDE_DEADZONE)
    end,
    [ZO_DI_DPAD] = function(self)
        return (IsKeyDown(KEY_GAMEPAD_DPAD_LEFT) and -DIGITAL_BUTTON_MAGNITUDE or 0) + (IsKeyDown(KEY_GAMEPAD_DPAD_RIGHT) and DIGITAL_BUTTON_MAGNITUDE or 0)
    end,
}

function DirectionalInput:GetXFromInputDevice(inputDevice)
    return INPUT_DEVICE_QUERY_X[inputDevice](self)
end

local INPUT_DEVICE_QUERY_Y =
{
    [ZO_DI_LEFT_STICK] = function(self)
        return GetGamepadLeftStickY(GAMEPAD_INCLUDE_DEADZONE)
    end,
    [ZO_DI_RIGHT_STICK] = function(self)
        return GetGamepadRightStickY(GAMEPAD_INCLUDE_DEADZONE)
    end,
    [ZO_DI_DPAD] = function(self)
        return (IsKeyDown(KEY_GAMEPAD_DPAD_UP) and DIGITAL_BUTTON_MAGNITUDE or 0) + (IsKeyDown(KEY_GAMEPAD_DPAD_DOWN) and -DIGITAL_BUTTON_MAGNITUDE or 0)
    end,
}

function DirectionalInput:GetYFromInputDevice(inputDevice)
    return INPUT_DEVICE_QUERY_Y[inputDevice](self)
end

function DirectionalInput:IsListening(object)
    for i, inputObject in ipairs(self.inputObjects) do
        if inputObject == object then
            return true
        end
    end
    return false
end

DIRECTIONAL_INPUT = DirectionalInput:New()
CLIENT_INPUT = ClientInput:New()