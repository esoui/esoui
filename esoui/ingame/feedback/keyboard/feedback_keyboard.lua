ZO_FEEDBACK = nil
local ZO_Feedback = ZO_Object:Subclass()

local BUG_REPORT_FRAMES_TO_WAIT = 3
local FEEDBACK_FRAMES_TO_WAIT = 3
local MINIMUM_FEEDBACK_TIME = 0

function ZO_Feedback:New(...)
    local feedback = ZO_Object.New(self)
    feedback:Initialize(...)

    return feedback
end

function ZO_Feedback:Initialize(control)
    self.queuedQuestFeedback = {}
    self.interactWindowShown = false

    self.control = control
    control.owner = self
    self.browser = control:GetNamedChild("Browser")
    self.browserAnimation = ANIMATION_MANAGER:CreateTimelineFromVirtual("FeedbackAnimation", self.browser)
    local loadLabel = control:GetNamedChild("LoadingLabel")
    self.loadLabelAnimation = ANIMATION_MANAGER:CreateTimelineFromVirtual("FeedbackAnimation", loadLabel)
    self.nextFeedbackTime = 0
    self.logoutOnClose = false
    self.quitOnClose = false

    HELP_CUSTOMER_SUPPORT_SCENE = ZO_Scene:New("helpCustomerSupport", SCENE_MANAGER)
    HELP_CUSTOMER_SUPPORT_SCENE:RegisterCallback("StateChange", function(oldState, newState)
        if(newState == SCENE_SHOWING) then
            if(not self.pageOpened) then
                self:OpenBrowserByType(BROWSER_TYPE_USER_HELP)
            end
        elseif(newState == SCENE_HIDDEN) then
            self.openingFramesToWait = nil
        end
    end)

    INTERACT_WINDOW:RegisterCallback("Hidden", function() self:OnInteractWindowHidden() end)
    INTERACT_WINDOW:RegisterCallback("Shown", function() self:OnInteractWindowShown() end)

    EVENT_MANAGER:RegisterForUpdate("ZO_Feedback", 0, function() self:OnUpdate() end)

    control:RegisterForEvent(EVENT_FEEDBACK_REQUESTED, function(eventCode, ...) self:OnFeedbackRequested(...) end)
    control:RegisterForEvent(EVENT_FEEDBACK_TOO_FREQUENT_SCREENSHOT, function(eventCode, ...) self:OnFeedbackTooFrequentScreenshot(...) end)
    control:RegisterForEvent(EVENT_AGENT_CHAT_FORCED, function() self:OpenBrowserByType(BROWSER_TYPE_AGENT_CHAT) end)
    control:RegisterForEvent(EVENT_AGENT_CHAT_ACCEPTED, function() self:OpenBrowserByType(BROWSER_TYPE_AGENT_CHAT) end)

    for i=1, GetNumPendingFeedback() do
        local feedbackId = GetFeedbackIdByIndex(i)
        self:OnFeedbackRequested(feedbackId)
    end
end

-- Helper to fill out optional arguments and marshal them correctly to BrowserControl:Open
local browserOpenTypes = 
{ 
    ["number"] = 1, 
    ["string"] = 2
}

local browserOpenArguments = { 0, "" }

local function GetBrowserArguments(...)
    for argType, argIndex in pairs(browserOpenTypes) do
        browserOpenArguments[argIndex] = nil
    end

    for i = 1, select("#", ...) do
        local argument = select(i, ...)
        local argumentIndex = browserOpenTypes[type(argument)]
        if(argumentIndex ~= nil) then
            browserOpenArguments[argumentIndex] = argument
        end
    end

    return unpack(browserOpenArguments)
end

function ZO_Feedback:OpenBrowserPage(...)
    self.browser:Open(...)
    self.pageOpened = true
end

function ZO_Feedback:Toggle()
    MAIN_MENU_KEYBOARD:ToggleScene("helpCustomerSupport")
end

function ZO_Feedback:OpenBrowserByType(type, ...)
    if type == BROWSER_TYPE_USER_FEEDBACK and (self.feedbackId or #self.queuedQuestFeedback > 0) then
        self:ShowQueuedFeedback()
    else
        self:OpenBrowserPage(BROWSER_OPEN_TYPE_BUG, type, GetBrowserArguments(...))
        self.openingFramesToWait = BUG_REPORT_FRAMES_TO_WAIT
    end
    self.logoutOnClose =  false
    self.quitOnClose = false
end

function ZO_Feedback:ReportPlayer(entityName, reasonForReporting, optionalId)
    if(type(optionalId) == "number") then
        entityName = string.format("%s:%u", entityName, optionalId)
    end
    self:OpenBrowserByType(BROWSER_TYPE_USER_REPORT, entityName, reasonForReporting)
end

function ZO_Feedback:QuickReportForSpam(entityName, reasonForReporting, rawName)
    -- TODO: Needs to get wired up to something, for now, we definitely want to ignore this user for the rest of the session
    SubmitSpamReport(rawName or entityName, reasonForReporting)
end

function ZO_Feedback:OnUpdate()
    if self.openingFramesToWait and IsPlayerActivated() then
        self.openingFramesToWait = self.openingFramesToWait - 1
        if self.openingFramesToWait == 0 then
            self.openingFramesToWait = nil
            MAIN_MENU_KEYBOARD:ShowScene("helpCustomerSupport")
        end
    end
end

function ZO_Feedback:Quit()
    local QUIT = true
    self:ExitIngame(QUIT)
end

function ZO_Feedback:Logout()
    local LOGOUT = false
    self:ExitIngame(LOGOUT)
end

function ZO_Feedback:ExitIngame(quit)
    if (self.logoutOnClose or self.quitOnClose) and not self.control:IsHidden() then
        if quit then
            Quit()
        else
            Logout()
        end
        self.logoutOnClose = false
        self.quitOnClose = false
    elseif not self.openingFramesToWait then
        self:OpenBrowserPage(BROWSER_OPEN_TYPE_LOGOUT)
        self.logoutOnClose = not quit
        self.quitOnClose = quit

        self.openingFramesToWait = BUG_REPORT_FRAMES_TO_WAIT
    end
end

function ZO_Feedback:OnFeedbackRequested(feedbackId)
    if GetFeedbackType(feedbackId) == FEEDBACK_TYPE_QUEST then
        self:QueueQuestFeedback(feedbackId)
    end
end

function ZO_Feedback:OnFeedbackTooFrequentScreenshot()
    ZO_Dialogs_ShowDialog("TOO_FREQUENT_BUG_SCREENSHOT")
end

function ZO_Feedback:OnLoadStart()
    self.browser:SetAlpha(0)
    self.loadLabelAnimation:PlayForward()
end

function ZO_Feedback:OnLoadFinished()
    self.browserAnimation:PlayFromStart()
    self.loadLabelAnimation:PlayBackward()
end

function ZO_Feedback:QueueQuestFeedback(feedbackId)
    if self.interactWindowShown or (self.feedbackId and not self.control:IsHidden()) then
        self.queuedQuestFeedback[#self.queuedQuestFeedback + 1] = feedbackId
    else
        self:ShowFeedback(feedbackId)
    end
end

function ZO_Feedback:OnInteractWindowHidden()
    if self.interactWindowShown then
        self.interactWindowShown = false
        self:ShowQueuedFeedback()
    end
end

function ZO_Feedback:OnInteractWindowShown()
    if not self.interactWindowShown then
        self.interactWindowShown = true
    end
end

function ZO_Feedback:Close()
    if self.logoutOnClose then
        Logout()
    elseif self.quitOnClose then
        Quit()
    elseif self.feedbackId then
        RemovePendingFeedback(self.feedbackId)
        self.feedbackId = nil
        self.nextFeedbackTime = GetFrameTimeMilliseconds() + MINIMUM_FEEDBACK_TIME
    end

    self.logoutOnClose = false
    self.quitOnClose = false
end

function ZO_Feedback:ShowQueuedFeedback()
    if self.feedbackId and self.control:IsHidden() then
        --We already have feedback open, that was forced closed, reshow it
        self:ShowFeedback(self.feedbackId)
    elseif #self.queuedQuestFeedback > 0 then
        local feedbackId = table.remove(self.queuedQuestFeedback, 1)
        self:ShowFeedback(feedbackId)
    end
end

function ZO_Feedback:ShowFeedback(feedbackId)
    if GetFrameTimeMilliseconds() > self.nextFeedbackTime then
        self.feedbackId = feedbackId
        self:OpenBrowserPage(BROWSER_OPEN_TYPE_FEEDBACK, feedbackId)

        self.openingFramesToWait = FEEDBACK_FRAMES_TO_WAIT
        self.logoutOnClose = false
        self.quitOnClose = false

    elseif feedbackId then
        RemovePendingFeedback(feedbackId)
    end
end

function ZO_Feedback_Initialize(control)
    ZO_FEEDBACK = ZO_Feedback:New(control)
end

function ZO_Feedback_OnLoadStart(control)
    control.owner:OnLoadStart()
end

function ZO_Feedback_OnLoadFinished(control)
    control.owner:OnLoadFinished()
end

function ZO_Feedback_OnRequestClose(control)
    control.owner:Close()
end
