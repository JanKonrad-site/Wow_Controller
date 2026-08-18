-- Optional quest acceptance. This only accepts a quest whose detail panel is
-- already open; it does not navigate NPC gossip or automate quest rewards.

local questAutomation = CreateFrame("Frame", "OctoPortQuestAutomation", UIParent)
questAutomation.pendingAccept = nil
questAutomation.waited = 0

questAutomation:RegisterEvent("QUEST_DETAIL")
questAutomation:RegisterEvent("QUEST_FINISHED")

questAutomation:SetScript("OnEvent", function()
  if event == "QUEST_DETAIL" then
    if OctoPort.config and OctoPort.config.autoAcceptQuests then
      -- Holding LB/Shift is the temporary manual-review override.
      if IsShiftKeyDown and IsShiftKeyDown() then
        this.pendingAccept = nil
        return
      end
      this.pendingAccept = true
      this.waited = 0
    end
  elseif event == "QUEST_FINISHED" then
    this.pendingAccept = nil
  end
end)

questAutomation:SetScript("OnUpdate", function()
  if not this.pendingAccept then return end
  this.waited = this.waited + arg1

  if IsShiftKeyDown and IsShiftKeyDown() then
    this.pendingAccept = nil
    return
  end

  -- The default quest frame enables its accept button after the description
  -- fade. Waiting for that state keeps the behavior compatible with 1.12 UI.
  local enabled = QuestFrameAcceptButton and QuestFrameAcceptButton:IsEnabled()
  if enabled and enabled ~= 0 then
    this.pendingAccept = nil
    AcceptQuest()
    return
  end

  if this.waited > 5 then
    this.pendingAccept = nil
  end
end)
