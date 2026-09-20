-- Minimal WoW 1.12 frame mock for the persistent minimap button and raw test.

local function NewRegion()
  local region = { visible = true, text = "", scripts = {} }
  local noops = {
    "SetWidth", "SetHeight", "SetPoint", "SetFrameStrata", "SetFrameLevel",
    "RegisterForClicks", "SetBackdrop", "SetBackdropColor", "SetBackdropBorderColor",
    "SetTextColor", "SetJustifyH", "SetJustifyV", "EnableKeyboard", "EnableMouse",
    "SetClampedToScreen", "SetMovable", "RegisterForDrag", "SetAllPoints", "SetScale",
    "ClearAllPoints", "SetAlpha", "SetTexture", "SetVertexColor", "LockHighlight",
    "UnlockHighlight",
  }
  for index = 1, table.getn(noops) do
    region[noops[index]] = function() end
  end
  function region:SetText(value) self.text = value or "" end
  function region:GetText() return self.text end
  function region:SetScript(name, handler) self.scripts[name] = handler end
  function region:Show() self.visible = true end
  function region:Hide() self.visible = false end
  function region:IsVisible() return self.visible end
  function region:GetFrameLevel() return 1 end
  function region:CreateFontString() return NewRegion() end
  function region:CreateTexture() return NewRegion() end
  return region
end

function CreateFrame(_, name)
  local frame = NewRegion()
  if name then _G[name] = frame end
  return frame
end

UIParent = NewRegion()
Minimap = NewRegion()
GameTooltip = NewRegion()
function GameTooltip:SetOwner() end
function GameTooltip:AddLine() end
function GameTooltip:SetAction() end
function GetCursorPosition() return 100, 100 end
function GetTime() return 1 end
local shiftDown = false
local controlDown = false
function IsShiftKeyDown() return shiftDown end
function IsControlKeyDown() return controlDown end
function IsAltKeyDown() return false end

local pickedAction = nil
function PickupAction(action) pickedAction = action end
function PlaceAction(action) pickedAction = action end

OctoPort = {
  version = "0.9.0",
  config = {
    enabled = false,
    controllerKeys = {
      LSUP = "W", LSDOWN = "S", LSLEFT = "A", LSRIGHT = "D",
      DUP = "UP", DDOWN = "DOWN", DLEFT = "LEFT", DRIGHT = "RIGHT",
      LB = "BUTTON1", RB = "BUTTON2",
    },
    nativeModifiers = { SHIFT = "lt", CTRL = "rt" },
  },
  bindingDefinitions = {
    { id = "LSUP", label = "L-Stick Up", command = "MOVEFORWARD", movement = "forward" },
    { id = "LSDOWN", label = "L-Stick Down", command = "MOVEBACKWARD", movement = "backward" },
    { id = "LSLEFT", label = "L-Stick Left", command = "STRAFELEFT", movement = "left" },
    { id = "LSRIGHT", label = "L-Stick Right", command = "STRAFERIGHT", movement = "right" },
    { id = "A", label = "A / Action 1", command = "OCTOPORT_ACTION_A", required = true, nativeAction = true },
    { id = "B", label = "B / Action 2", command = "OCTOPORT_ACTION_B", required = true, nativeAction = true },
    { id = "X", label = "X / Action 3", command = "OCTOPORT_ACTION_X", required = true, nativeAction = true },
    { id = "Y", label = "Y / Action 4", command = "OCTOPORT_ACTION_Y", required = true, nativeAction = true },
    { id = "DUP", label = "D-Pad Up", command = "OCTOPORT_TARGET_UP", required = true },
    { id = "DDOWN", label = "D-Pad Down", command = "OCTOPORT_TARGET_DOWN", required = true },
    { id = "DLEFT", label = "D-Pad Left", command = "OCTOPORT_TARGET_LEFT", required = true },
    { id = "DRIGHT", label = "D-Pad Right", command = "OCTOPORT_TARGET_RIGHT", required = true },
    { id = "LT", label = "LT / Action layer", command = "OCTOPORT_LAYER_LT", layer = "lt" },
    { id = "RT", label = "RT / Action layer", command = "OCTOPORT_LAYER_RT", layer = "rt" },
    { id = "LB", label = "LB / Mouse Left", passthrough = true },
    { id = "RB", label = "RB / Mouse Right", passthrough = true },
  },
}

function OctoPort:SignalInput(id, state)
  self.lastControllerInput = id
  self.lastControllerInputState = state
end

function OctoPort:Print() end

function OctoPort:SetQuickMenuKey(key)
  self.testMenuKey = key
  return true
end

function OctoPort:GetBindingDefinition(id)
  for index = 1, table.getn(self.bindingDefinitions) do
    if self.bindingDefinitions[index].id == id then return self.bindingDefinitions[index] end
  end
end

function OctoPort:BindControllerKey(definition, key)
  self.config.controllerKeys[definition.id] = key
  return true
end

dofile("Menu.lua")
dofile("UI.lua")

OctoPort:CreateMinimapButton()
assert(OctoPort.minimapButton and OctoPort.minimapButton.visible, "minimap button was not created")
assert(OctoPort.minimapButton.scripts.OnClick, "minimap button is not clickable")
assert(not OctoPort.arrowModeButton, "obsolete shared-arrow mode button was created")

arg1 = "LeftButton"
OctoPort.minimapButton.scripts.OnClick()
assert(OctoPort.rawTestFrame and OctoPort.rawTestFrame.visible, "left-click did not open raw testing")

this = OctoPort.rawTestFrame
arg1 = "W"
OctoPort.rawTestFrame.scripts.OnKeyDown()
assert(string.find(OctoPort.rawTestFrame.last.text, "L%-Stick Up"), "raw keyboard signal was not identified")

arg1 = "LSHIFT"
OctoPort.rawTestFrame.scripts.OnKeyDown()
assert(string.find(OctoPort.rawTestFrame.last.text, "LT / Action layer", 1, true), "left/right modifier signal was not normalized")

arg1 = "ESCAPE"
OctoPort.rawTestFrame.scripts.OnKeyDown()
assert(OctoPort.rawTestFrame.visible, "Escape incorrectly closed raw testing")
assert(string.find(OctoPort.rawTestFrame.last.text, "ESCAPE", 1, true), "Escape was not shown as raw input")
OctoPort.rawTestFrame.menuButton.scripts.OnClick()
assert(OctoPort.testMenuKey == "ESCAPE", "last working input could not be assigned to menu")

OctoPort.rawTestFrame:Show()
arg1 = "LeftButton"
OctoPort.rawTestFrame.scripts.OnMouseDown()
assert(string.find(OctoPort.rawTestFrame.last.text, "LB / Mouse Left", 1, true), "raw mouse signal was not identified")

-- The focused ABXY wizard captures the physical signals actually emitted by
-- Desktop Mode, including Enter/Escape, while selecting native action slots.
OctoPort.configFrame = NewRegion()
OctoPort.captureFrame = NewRegion()
OctoPort.captureFrame.instruction = NewRegion()
OctoPort.captureFrame.progress = NewRegion()
OctoPort.captureFrame.skip = NewRegion()
OctoPort.ShowConfigTab = function() end
OctoPort:StartFaceBindingWizard()
OctoPort:CaptureControllerKey("ENTER")
OctoPort:CaptureControllerKey("ESCAPE")
OctoPort:CaptureControllerKey("F1")
OctoPort:CaptureControllerKey("F2")
assert(OctoPort.config.controllerKeys.A == "ENTER", "physical A was not captured")
assert(OctoPort.config.controllerKeys.B == "ESCAPE", "physical B was not captured")
assert(OctoPort.config.controllerKeys.X == "F1" and OctoPort.config.controllerKeys.Y == "F2", "physical X/Y were not captured")
assert(OctoPort.config.nativeFaceButtons == true, "captured ABXY were not switched to native action slots")

-- The HUD owns exactly 20 editable action mirrors: four base face buttons,
-- plus eight inputs for each trigger layer.
local function CountKeys(values)
  local count = 0
  for _ in pairs(values) do count = count + 1 end
  return count
end

OctoPort:CreateRoot()
assert(CountKeys(OctoPort.layers.base.buttons) == 4, "base layer does not contain four actions")
assert(CountKeys(OctoPort.layers.lt.buttons) == 8, "LT layer does not contain eight actions")
assert(CountKeys(OctoPort.layers.rt.buttons) == 8, "RT layer does not contain eight actions")
assert(OctoPort:GetActionSlot("lt", "A") == 61 and OctoPort:GetActionSlot("lt", "DUP") == 65, "LT action slots are wrong")
assert(OctoPort:GetActionSlot("rt", "A") == 49 and OctoPort:GetActionSlot("rt", "DLEFT") == 56, "RT action slots are wrong")

shiftDown = true
assert(OctoPort:GetActiveLayer() == "lt", "SHIFT did not select the LT layer")
shiftDown = false
controlDown = true
assert(OctoPort:GetActiveLayer() == "rt", "CTRL did not select the RT layer")
controlDown = false

OctoPort.config.editMode = true
local editButton = OctoPort.layers.lt.buttons.A
editButton.action = 61
this = editButton
arg1 = "RightButton"
editButton.scripts.OnClick()
assert(pickedAction == 61, "custom HUD action could not be picked up for editing")

print("minimap/raw input harness: OK")
