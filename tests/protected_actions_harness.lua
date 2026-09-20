-- Focused harness for calls protected by OctoWoW's backported lockdown.

local lockdown = false
local playerInCombat = false
local autoRunCalls = 0
local castSpellCalls = 0
local useItemCalls = 0
local acceptQuestCalls = 0
local popupClicks = 0
local messages = {}
local frames = {}

UIParent = {}
BOOKTYPE_SPELL = "spell"

function InCombatLockdown()
  return lockdown
end

function UnitAffectingCombat(unit)
  return unit == "player" and playerInCombat
end

function ToggleAutoRun()
  assert(not lockdown and not playerInCombat, "ToggleAutoRun was called in combat")
  autoRunCalls = autoRunCalls + 1
end

function CastSpell()
  assert(not lockdown and not playerInCombat, "CastSpell was called in combat")
  castSpellCalls = castSpellCalls + 1
end

function UseContainerItem()
  assert(not lockdown and not playerInCombat, "UseContainerItem was called in combat")
  useItemCalls = useItemCalls + 1
end

function AcceptQuest()
  assert(not lockdown and not playerInCombat, "AcceptQuest was called in combat")
  acceptQuestCalls = acceptQuestCalls + 1
end

function CreateFrame(_, name)
  local frame = { scripts = {}, name = name }
  function frame:RegisterEvent() end
  function frame:SetScript(script, handler) self.scripts[script] = handler end
  frames[name] = frame
  return frame
end

function GetSpellName(index)
  if index == 1 then return "Brown Horse" end
end

function GetContainerNumSlots(bag)
  if bag == 0 then return 1 end
  return 0
end

function GetContainerItemLink()
  return "|cffffffff|Hitem:1:0:0:0|h[Brown Horse Reins]|h|r"
end

function IsShiftKeyDown() return false end

QuestFrameAcceptButton = {
  IsEnabled = function() return 1 end,
}

OctoPort = {
  config = {
    enabled = true,
    autoAcceptQuests = true,
    mountName = "Brown Horse",
    radialSlots = { "autorun", "mount" },
  },
}

function OctoPort:Print(message)
  table.insert(messages, message)
end

dofile("Radial.lua")
dofile("Quest.lua")

StaticPopup1Button1 = {
  IsVisible = function() return true end,
  IsEnabled = function() return 1 end,
  Click = function() popupClicks = popupClicks + 1 end,
}

local function ActivateRadial(index)
  OctoPort.radialSelection = index
  OctoPort:ActivateRadialSelection()
end

local function OpenAndUpdateQuest()
  local frame = frames.OctoPortQuestAutomation
  event = "QUEST_DETAIL"
  this = frame
  frame.scripts.OnEvent()
  arg1 = 0.1
  frame.scripts.OnUpdate()
end

-- InCombatLockdown alone must block every protected radial/quest call.
lockdown = true
ActivateRadial(1)
ActivateRadial(2)
OpenAndUpdateQuest()
assert(OctoPort:ConfirmVisibleUI(), "visible confirmation was not consumed during lockdown")
assert(autoRunCalls == 0, "lockdown allowed ToggleAutoRun")
assert(castSpellCalls == 0 and useItemCalls == 0, "lockdown allowed a mount action")
assert(acceptQuestCalls == 0, "lockdown allowed AcceptQuest")
assert(popupClicks == 0, "lockdown allowed a synthetic Blizzard button click")

-- Vanilla-compatible UnitAffectingCombat fallback must do the same even when
-- InCombatLockdown exists but returns false.
lockdown = false
playerInCombat = true
ActivateRadial(1)
ActivateRadial(2)
OpenAndUpdateQuest()
assert(OctoPort:ConfirmVisibleUI(), "visible confirmation was not consumed during combat")
assert(autoRunCalls == 0, "combat fallback allowed ToggleAutoRun")
assert(castSpellCalls == 0 and useItemCalls == 0, "combat fallback allowed a mount action")
assert(acceptQuestCalls == 0, "combat fallback allowed AcceptQuest")
assert(popupClicks == 0, "combat fallback allowed a synthetic Blizzard button click")
assert(table.getn(messages) >= 8, "blocked actions did not produce user-visible feedback")

-- Outside combat the same actions remain available.
playerInCombat = false
ActivateRadial(1)
ActivateRadial(2)
OpenAndUpdateQuest()
assert(OctoPort:ConfirmVisibleUI(), "safe visible confirmation was not handled")
assert(autoRunCalls == 1, "safe autorun action did not run")
assert(castSpellCalls == 1, "safe mount spell did not run")
assert(useItemCalls == 0, "spellbook mount unexpectedly fell through to an item")
assert(acceptQuestCalls == 1, "safe quest acceptance did not run")
assert(popupClicks == 1, "safe synthetic Blizzard button click did not run")

-- Exercise the bag-item branch independently.
function GetSpellName() return nil end
OctoPort.config.mountName = "Brown Horse Reins"
ActivateRadial(2)
assert(useItemCalls == 1, "safe mount item did not run")

print("protected action harness: OK")
