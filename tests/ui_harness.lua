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
function GetCursorPosition() return 100, 100 end
function GetTime() return 1 end
function IsShiftKeyDown() return false end
function IsControlKeyDown() return false end
function IsAltKeyDown() return false end

OctoPort = {
  version = "0.7.2",
  config = {
    enabled = false,
    arrowMovementFallback = false,
    arrowInputMode = "movement",
    controllerKeys = { LSUP = "W", RB = "BUTTON1" },
    nativeModifiers = { SHIFT = "shift", CTRL = "ctrl" },
  },
  bindingDefinitions = {
    { id = "LSUP", label = "L-Stick Up", command = "MOVEFORWARD", movement = "forward" },
    { id = "LB", label = "LB layer", command = "OCTOPORT_LAYER_LB", layer = "shift" },
    { id = "RB", label = "RB / Left Click", passthrough = true },
  },
}

function OctoPort:SignalInput(id, state)
  self.lastControllerInput = id
  self.lastControllerInputState = state
end

function OctoPort:SetQuickMenuKey(key)
  self.testMenuKey = key
  return true
end

function OctoPort:SetQuickModeKey(key)
  self.testModeKey = key
  return true
end

function OctoPort:ToggleArrowInputMode()
  self.config.arrowInputMode = self.config.arrowInputMode == "target" and "movement" or "target"
  self:UpdateArrowModeButton()
  return true
end

dofile("Menu.lua")
dofile("UI.lua")

OctoPort:CreateMinimapButton()
assert(OctoPort.minimapButton and OctoPort.minimapButton.visible, "minimap button was not created")
assert(OctoPort.minimapButton.scripts.OnClick, "minimap button is not clickable")
assert(OctoPort.arrowModeButton and not OctoPort.arrowModeButton.visible, "shared-arrow mode button should start hidden")

OctoPort.config.enabled = true
OctoPort.config.arrowMovementFallback = true
OctoPort:UpdateArrowModeButton()
assert(OctoPort.arrowModeButton.visible and OctoPort.arrowModeButton.label.text == "CHOD", "movement mode indicator was not shown")
OctoPort.arrowModeButton.scripts.OnClick()
assert(OctoPort.config.arrowInputMode == "target" and OctoPort.arrowModeButton.label.text == "CIL", "mode button did not switch to targeting")

arg1 = "LeftButton"
OctoPort.minimapButton.scripts.OnClick()
assert(OctoPort.rawTestFrame and OctoPort.rawTestFrame.visible, "left-click did not open raw testing")

this = OctoPort.rawTestFrame
arg1 = "W"
OctoPort.rawTestFrame.scripts.OnKeyDown()
assert(string.find(OctoPort.rawTestFrame.last.text, "L%-Stick Up"), "raw keyboard signal was not identified")

arg1 = "LSHIFT"
OctoPort.rawTestFrame.scripts.OnKeyDown()
assert(string.find(OctoPort.rawTestFrame.last.text, "LB layer", 1, true), "left/right modifier signal was not normalized")

arg1 = "ESCAPE"
OctoPort.rawTestFrame.scripts.OnKeyDown()
assert(OctoPort.rawTestFrame.visible, "Escape incorrectly closed raw testing")
assert(string.find(OctoPort.rawTestFrame.last.text, "ESCAPE", 1, true), "Escape was not shown as raw input")
OctoPort.rawTestFrame.menuButton.scripts.OnClick()
assert(OctoPort.testMenuKey == "ESCAPE", "last working input could not be assigned to menu")

OctoPort.rawTestFrame:Show()
arg1 = "F3"
OctoPort.rawTestFrame.scripts.OnKeyDown()
OctoPort.rawTestFrame.modeButton.scripts.OnClick()
assert(OctoPort.testModeKey == "F3", "last working input could not be assigned to the movement/target switch")

OctoPort.rawTestFrame:Show()
arg1 = "LeftButton"
OctoPort.rawTestFrame.scripts.OnMouseDown()
assert(string.find(OctoPort.rawTestFrame.last.text, "RB / Left Click", 1, true), "raw mouse signal was not identified")

print("minimap/raw input harness: OK")
