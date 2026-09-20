-- Focused integration regression for the controller setup path.
-- Unlike the narrower harnesses, this loads the real Core, Bindings and Menu
-- modules together and drives the same frame callbacks used by the game UI.

local function RunScript(region, script, value)
  local handler = region.scripts and region.scripts[script]
  if not handler then return end
  local oldThis, oldArg1 = this, arg1
  this, arg1 = region, value
  handler()
  this, arg1 = oldThis, oldArg1
end

local function NewRegion(parent)
  local region = {
    visible = true,
    text = "",
    scripts = {},
    parent = parent,
    registeredEvents = {},
  }
  local noops = {
    "SetFrameStrata", "SetFrameLevel", "RegisterForClicks", "SetBackdrop",
    "SetJustifyH", "SetJustifyV", "EnableKeyboard", "SetClampedToScreen",
    "SetMovable", "RegisterForDrag", "SetAllPoints", "SetScale", "SetAlpha",
    "SetVertexColor", "StartMoving", "StopMovingOrSizing",
  }
  for index = 1, table.getn(noops) do
    region[noops[index]] = function() end
  end
  function region:SetText(value) self.text = value or "" end
  function region:GetText() return self.text end
  function region:SetWidth(value) self.width = value end
  function region:SetHeight(value) self.height = value end
  function region:GetWidth() return self.width or 1024 end
  function region:GetHeight() return self.height or 768 end
  function region:GetCenter() return 512, 384 end
  function region:SetPoint(...) self.point = { ... } end
  function region:ClearAllPoints() self.point = nil end
  function region:SetTexture(value) self.texture = value end
  function region:SetTextColor(...) self.textColor = { ... } end
  function region:SetBackdropColor(...) self.backdropColor = { ... } end
  function region:SetBackdropBorderColor(...) self.borderColor = { ... } end
  function region:RegisterEvent(name) self.registeredEvents[name] = true end
  function region:EnableMouse(value) self.mouseEnabled = value and true or false end
  function region:SetScript(name, handler) self.scripts[name] = handler end
  function region:Show()
    if self.visible then return end
    self.visible = true
    RunScript(self, "OnShow")
  end
  function region:Hide()
    if not self.visible then return end
    self.visible = false
    RunScript(self, "OnHide")
  end
  function region:IsVisible()
    if not self.visible then return false end
    if self.parent and self.parent.IsVisible then return self.parent:IsVisible() end
    return true
  end
  function region:GetFrameLevel() return 1 end
  function region:CreateFontString() return NewRegion(self) end
  function region:CreateTexture() return NewRegion(self) end
  function region:LockHighlight() self.highlighted = true end
  function region:UnlockHighlight() self.highlighted = false end
  function region:Click(button) RunScript(self, "OnClick", button or "LeftButton") end
  return region
end

function CreateFrame(_, name, parent)
  local frame = NewRegion(parent)
  if name then _G[name] = frame end
  return frame
end

UIParent = NewRegion()
SlashCmdList = {}
DEFAULT_CHAT_FRAME = { AddMessage = function() end }
function GetCursorPosition() return 100, 100 end
function GetTime() return 1 end
function IsShiftKeyDown() return false end
function IsControlKeyDown() return false end
function IsAltKeyDown() return false end
function InCombatLockdown() return false end
function UnitAffectingCombat() return false end

local bindings = {
  ["1"] = "OPENCHAT",
  ["2"] = "TOGGLEGAMEMENU",
  ["3"] = "TOGGLECHARACTER0",
  ["4"] = "TOGGLESPELLBOOK",
  W = "OPENCHATSLASH",
  S = "SITORSTAND",
  A = "TURNLEFT",
  D = "TURNRIGHT",
  UP = "PREVIOUSACTIONPAGE",
  DOWN = "NEXTACTIONPAGE",
  LEFT = "CAMERAZOOMIN",
  RIGHT = "CAMERAZOOMOUT",
  F9 = "REPLY",
  F13 = "ACTIONBUTTON1",
  F14 = "ACTIONBUTTON1",
  ["SHIFT-W"] = "CUSTOMSHIFTW",
  ["CTRL-W"] = "CUSTOMCTRLW",
  ["SHIFT-UP"] = "CUSTOMSHIFTUP",
  ["CTRL-UP"] = "CUSTOMCTRLUP",
}
local saveCount = 0

function GetBindingAction(key) return bindings[key] or "" end
function GetBindingKey(command)
  local keys = {}
  for key, action in pairs(bindings) do
    if action == command then table.insert(keys, key) end
  end
  table.sort(keys)
  return keys[1], keys[2]
end
function SetBinding(key, command)
  if command and bindings[key] ~= command then
    local key1, key2 = GetBindingKey(command)
    -- Vanilla commands keep at most two keys. Exercise the addon's full
    -- command snapshot by evicting the second key when a third is installed.
    if key1 and key2 and key ~= key1 and key ~= key2 then bindings[key2] = nil end
  end
  bindings[key] = command
  return 1
end
function SaveBindings() saveCount = saveCount + 1 end
function GetCurrentBindingSet() return 2 end
function TargetNearestFriend() error("settings navigation leaked into world targeting") end
function TargetNearestEnemy() error("settings navigation leaked into world targeting") end

local function CopyMap(source)
  local copy = {}
  for key, value in pairs(source) do copy[key] = value end
  return copy
end

local function AssertMap(expected, message)
  for key, command in pairs(expected) do
    assert(bindings[key] == command, message .. ": lost " .. key .. " -> " .. command)
  end
  for key, command in pairs(bindings) do
    assert(expected[key] == command, message .. ": leaked " .. key .. " -> " .. command)
  end
end

local function FindRow(id)
  for index = 1, table.getn(OctoPort.bindingDefinitions) do
    if OctoPort.bindingDefinitions[index].id == id then return OctoPort.bindingRows[index] end
  end
end

local function Capture(raw)
  RunScript(OctoPort.captureFrame, "OnKeyDown", raw)
  RunScript(OctoPort.captureFrame, "OnKeyUp", raw)
end

OctoPort = nil
OctoPortConfig = nil
dofile("Core.lua")
dofile("Bindings.lua")
dofile("Menu.lua")
OctoPort:InitializeConfig()

assert(OctoPort.InitializeConfig and OctoPort.ActivateSessionBindings and OctoPort.CreateConfigMenu,
  "real Core/Bindings/Menu modules were not loaded together")
local originalBindings = CopyMap(bindings)

-- The public settings entry creates a usable UI and installs only its nested
-- controller-navigation layer while gameplay remains disabled.
OctoPort:HandleSlash("")
assert(OctoPort.configFrame and OctoPort.configFrame:IsVisible(), "settings UI was not created/opened")
assert(OctoPort.configNavigationBindingsActive, "open settings did not install controller navigation")
assert(bindings["1"] == "OCTOPORT_ACTION_A" and bindings.UP == "OCTOPORT_TARGET_UP",
  "settings did not receive ABXY/D-pad input")

-- A real manual-mapping row must capture its own definition, stage the signal
-- on key-down, and commit only after the same physical input is released.
OctoPort:ShowConfigTab(2, true)
local aRow = assert(FindRow("A"), "manual A row was not built")
local oldA = OctoPort.config.controllerKeys.A
aRow.keyButton:Click()
assert(OctoPort.bindingCaptureActive and OctoPort.captureDefinition.id == "A",
  "manual A row opened the wrong capture")
assert(OctoPort.captureFrame:IsVisible() and not OctoPort.configFrame:IsVisible(),
  "manual capture overlay did not replace settings")
RunScript(OctoPort.captureFrame, "OnKeyDown", "F9")
assert(OctoPort.config.controllerKeys.A == oldA, "manual mapping committed before key release")
RunScript(OctoPort.captureFrame, "OnKeyUp", "F9")
assert(not OctoPort.bindingCaptureActive and OctoPort.config.controllerKeys.A == "F9",
  "manual mapping did not commit on release")
assert(OctoPort.configFrame:IsVisible() and bindings.F9 == "OCTOPORT_ACTION_A",
  "settings did not resume with the newly captured A input")
OctoPort.configFrame:Hide()
AssertMap(originalBindings, "manual-mapping close did not restore exact bindings")

-- Direction setup is one atomic live transaction. Use deliberately different
-- old values so this proves all eight physical stick/D-pad signals commit.
local oldDirections = {
  LSUP = "I", LSDOWN = "K", LSLEFT = "J", LSRIGHT = "L",
  DUP = "T", DDOWN = "G", DLEFT = "F", DRIGHT = "H",
}
for id, key in pairs(oldDirections) do OctoPort.config.controllerKeys[id] = key end
OctoPort.config.directionVerifiedKeys = {}
OctoPort:RefreshSetupState()
OctoPort:ShowConfigTab(1, true)
assert(OctoPort:StartDirectionalBindingWizard(), "eight-direction calibration did not start")
RunScript(OctoPort.captureFrame, "OnKeyDown", "W")
assert(OctoPort.config.controllerKeys.LSUP == "I", "direction calibration committed before release")
RunScript(OctoPort.captureFrame, "OnKeyUp", "W")
local remainingDirections = { "S", "A", "D", "UP", "DOWN", "LEFT", "RIGHT" }
for index = 1, table.getn(remainingDirections) do Capture(remainingDirections[index]) end

local expectedDirections = {
  LSUP = "W", LSDOWN = "S", LSLEFT = "A", LSRIGHT = "D",
  DUP = "UP", DDOWN = "DOWN", DLEFT = "LEFT", DRIGHT = "RIGHT",
}
for id, key in pairs(expectedDirections) do
  assert(OctoPort.config.controllerKeys[id] == key, "calibration did not commit " .. id)
  assert(OctoPort.config.directionVerifiedKeys[id] == key, "calibration did not live-verify " .. id)
end
assert(OctoPort:ValidateDirectionalInputs(), "live-calibrated directions were rejected")
assert(OctoPort.config.setupComplete, "complete real-module profile stayed incomplete")
OctoPort.configFrame:Hide()
AssertMap(originalBindings, "direction-calibration close did not restore exact bindings")

-- Gameplay installs both independent groups at once: stick movement remains
-- native while the D-pad owns Blizzard's native target commands.
assert(OctoPort:SetEnabled(true), "live-calibrated controller did not enable")
assert(OctoPort.sessionBindingsActive, "gameplay session did not become active")
assert(bindings.W == "MOVEFORWARD" and bindings.S == "MOVEBACKWARD" and
  bindings.A == "STRAFELEFT" and bindings.D == "STRAFERIGHT",
  "left stick did not own native movement: " .. tostring(bindings.W) .. "/" ..
    tostring(bindings.S) .. "/" .. tostring(bindings.A) .. "/" .. tostring(bindings.D))
assert(bindings.UP == "TARGETPREVIOUSFRIEND" and bindings.DOWN == "TARGETNEARESTFRIEND" and
  bindings.LEFT == "TARGETPREVIOUSENEMY" and bindings.RIGHT == "TARGETNEARESTENEMY",
  "D-pad did not own native target selection beside movement")
assert(bindings.F9 == "ACTIONBUTTON1", "captured physical A did not own native action slot 1")
assert(bindings["SHIFT-F9"] == "MULTIACTIONBAR1BUTTON1" and
  bindings["CTRL-F9"] == "MULTIACTIONBAR2BUTTON1",
  "captured A did not participate in both action layers")
assert(bindings["SHIFT-W"] == nil and bindings["CTRL-W"] == nil,
  "modified movement chords were not cleared to fall through to base W")
assert(OctoPort:SetEnabled(false), "controller did not disable cleanly")
AssertMap(originalBindings, "gameplay disable did not restore exact bindings")
assert(bindings["SHIFT-W"] == "CUSTOMSHIFTW" and bindings["CTRL-W"] == "CUSTOMCTRLW",
  "disable did not restore the player's original modified movement chords")
assert(bindings.F13 == "ACTIONBUTTON1" and bindings.F14 == "ACTIONBUTTON1",
  "full command restore lost the evicted second action key")

-- Settings remains a recovery surface with gameplay OFF and an invalid stick
-- profile. D-pad changes focus, A activates it, and B closes the window while
-- restoring the exact pre-addon binding map.
OctoPort.config.controllerKeys.LSDOWN = OctoPort.config.controllerKeys.LSUP
OctoPort.config.directionVerifiedKeys.LSDOWN = OctoPort.config.controllerKeys.LSDOWN
OctoPort:RefreshSetupState()
assert(not OctoPort.config.setupComplete and not OctoPort.config.enabled,
  "invalid disabled-profile fixture did not take effect")
OctoPort:ShowConfigTab(1, true)
assert(OctoPort.configNavigationBindingsActive and bindings.UP == "OCTOPORT_TARGET_UP",
  "invalid disabled profile could not navigate settings")
local previousFocus = OctoPort.configFocusIndex
OctoPort_Target("down", "down")
assert(OctoPort.configFocusIndex == previousFocus + 1, "D-pad did not change settings focus")
OctoPort_ActionKey(1, "up")
assert(OctoPort.config.selectedConfigTab == 2, "A did not activate the focused settings control")
OctoPort_ActionKey(2, "up")
assert(not OctoPort.configFrame:IsVisible(), "B did not close settings")
AssertMap(originalBindings, "disabled/invalid settings close did not restore exact bindings")
assert(not OctoPort.config.bindingRecoverySnapshot, "successful integration flow left a recovery snapshot")
assert(saveCount == 0, "normal integration flow persisted WoW bindings")

print("core/bindings/menu integration harness: OK")
