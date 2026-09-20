-- Minimal WoW 1.12 frame mock for the persistent minimap button and raw test.

local function NewRegion(parent)
  local region = {
    visible = true,
    text = "",
    scripts = {},
    parent = parent,
    mouseEnabled = true,
    registeredEvents = {},
  }
  local noops = {
    "SetFrameStrata", "SetFrameLevel", "RegisterForClicks", "SetBackdrop",
    "SetBackdropColor", "SetJustifyH",
    "SetJustifyV", "EnableKeyboard",
    "SetClampedToScreen", "SetMovable", "RegisterForDrag", "SetAllPoints", "SetScale",
    "SetAlpha", "SetVertexColor", "LockHighlight", "UnlockHighlight",
    "StartMoving", "StopMovingOrSizing",
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
  function region:SetBackdropBorderColor(...) self.borderColor = { ... } end
  function region:RegisterEvent(name) self.registeredEvents[name] = true end
  function region:EnableMouse(value) self.mouseEnabled = value and true or false end
  function region:SetScript(name, handler) self.scripts[name] = handler end
  function region:Show() self.visible = true end
  function region:Hide() self.visible = false end
  function region:IsVisible()
    if not self.visible then return false end
    if self.parent and self.parent.IsVisible then return self.parent:IsVisible() end
    return true
  end
  function region:GetFrameLevel() return 1 end
  function region:CreateFontString() return NewRegion(self) end
  function region:CreateTexture() return NewRegion(self) end
  function region:Click(button)
    local oldThis, oldArg1 = this, arg1
    this, arg1 = self, button or "LeftButton"
    if self.scripts.OnClick then self.scripts.OnClick() end
    this, arg1 = oldThis, oldArg1
  end
  return region
end

function CreateFrame(_, name, parent)
  local frame = NewRegion(parent)
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
local mockTime = 1
function GetTime() return mockTime end
local shiftDown = false
local controlDown = false
local bindingCombat = false
function IsShiftKeyDown() return shiftDown end
function IsControlKeyDown() return controlDown end
function IsAltKeyDown() return false end

local pickedAction = nil
local placedAction = nil
local cursorAction = nil
local actionSlots = {}
function PickupAction(action)
  pickedAction = action
  cursorAction = actionSlots[action]
end
function PlaceAction(action)
  placedAction = action
  actionSlots[action] = cursorAction
  cursorAction = nil
end
function CursorHasItem() return cursorAction and cursorAction.kind == "item" end
function CursorHasSpell() return cursorAction and cursorAction.kind == "spell" end
function CursorHasMacro() return cursorAction and cursorAction.kind == "macro" end
function GetActionTexture(action) return actionSlots[action] and actionSlots[action].texture end
function IsUsableAction() return 1 end
function IsActionInRange() return 1 end
function GetActionCount() return 0 end
local targetExists = false
local targetName = nil
local targetHostile = false
function UnitExists(unit) return unit == "target" and targetExists end
function UnitName(unit) return unit == "target" and targetName or nil end
function UnitCanAttack(source, unit) return source == "player" and unit == "target" and targetHostile end

OctoPort = {
  version = "0.9.1",
  config = {
    enabled = false,
    editMode = false,
    moveMode = false,
    scale = 1,
    x = 0,
    y = 122,
    nativeFaceButtons = true,
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

function OctoPort:IsBindingMutationLocked()
  return bindingCombat
end

function OctoPort:DeferBindingOperation(operation, status)
  self.bindingMutationDeferred = true
  self.pendingBindingOperation = operation
  self.bindingMutationStatus = status
  return nil, "deferred"
end

function OctoPort:GetBindingOperationStatus()
  return self.bindingMutationDeferred, self.bindingMutationStatus, self.pendingBindingOperation
end

function OctoPort:SetQuickMenuKey(key)
  self.testMenuKey = key
  return true
end

function OctoPort:GetBindingDefinition(id)
  for index = 1, table.getn(self.bindingDefinitions) do
    if self.bindingDefinitions[index].id == id then return self.bindingDefinitions[index] end
  end
end

function OctoPort:GetControllerBindingKey(definition)
  if type(definition) ~= "table" then definition = self:GetBindingDefinition(definition) end
  if not definition then return nil end
  if definition.layer then
    for modifier, layer in pairs(self.config.nativeModifiers or {}) do
      if layer == definition.layer then return modifier .. " (native)" end
    end
  end
  return self.config.controllerKeys and self.config.controllerKeys[definition.id]
end

function OctoPort:IsDirectionControl(definition)
  local id = type(definition) == "table" and definition.id or definition
  return id == "LSUP" or id == "LSDOWN" or id == "LSLEFT" or id == "LSRIGHT" or
    id == "DUP" or id == "DDOWN" or id == "DLEFT" or id == "DRIGHT"
end

function OctoPort:IsDirectionVerified(definition)
  return self:IsDirectionControl(definition)
end

function OctoPort:BindControllerKey(definition, key)
  self.config.controllerKeys[definition.id] = key
  return true
end

local function FireScript(frame, script, value)
  local oldThis, oldArg1 = this, arg1
  this, arg1 = frame, value
  assert(frame.scripts[script], "missing " .. script .. " handler")
  frame.scripts[script]()
  this, arg1 = oldThis, oldArg1
end

local function FireEvent(frame, eventName, value)
  local oldEvent, oldArg1 = event, arg1
  event, arg1 = eventName, value
  assert(frame.registeredEvents[eventName], "event was not registered: " .. eventName)
  assert(frame.scripts.OnEvent, "missing OnEvent handler")
  frame.scripts.OnEvent()
  event, arg1 = oldEvent, oldArg1
end

SlashCmdList = {}
dofile("Core.lua")
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

-- Original WoW 1.12 embeds Lua 5.0 and has no string.match. Modified RAW
-- inputs must still be parsed without that newer helper.
local savedStringMatch = string.match
string.match = nil
shiftDown = true
arg1 = "1"
OctoPort.rawTestFrame.scripts.OnKeyDown()
shiftDown = false
string.match = savedStringMatch
assert(string.find(OctoPort.rawTestFrame.last.text, "SHIFT%-1"), "Lua 5.0-compatible modified RAW input parsing failed")

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

-- Every manual-mapping row must retain its own binding definition. A shared
-- loop closure used to make visually different rows open the same capture,
-- which looked like a button that did not respond in the in-game UI.
OctoPort:CreateConfigMenu()
OctoPort.bindingRows[1].keyButton:Click()
assert(OctoPort.bindingCaptureActive and OctoPort.captureDefinition.id == "LSUP", "first manual-mapping row opened the wrong input")
OctoPort:StopBindingCapture(false)
local lastBindingRow = OctoPort.bindingRows[table.getn(OctoPort.bindingRows)]
lastBindingRow.keyButton:Click()
assert(OctoPort.bindingCaptureActive and OctoPort.captureDefinition.id == "RB", "last manual-mapping row opened the wrong input")
OctoPort:StopBindingCapture(false)

-- The focused ABXY wizard captures the physical signals actually emitted by
-- Desktop Mode, including Enter/Escape, while selecting native action slots.
OctoPort.configFrame = NewRegion()
OctoPort.ShowConfigTab = function() end

-- Setup must refuse to suspend/reinstall bindings in combat. It publishes a
-- visible deferred state and leaves the capture transaction unopened.
bindingCombat = true
assert(OctoPort:StartDirectionalBindingWizard() == false, "direction capture opened during combat")
assert(not OctoPort.bindingCaptureActive, "combat capture left a half-open transaction")
assert(OctoPort.bindingMutationDeferred and OctoPort.pendingBindingOperation == "reconcile", "combat capture did not expose deferred UI state")
bindingCombat = false
OctoPort.bindingMutationDeferred = nil
OctoPort.pendingBindingOperation = nil
OctoPort.bindingMutationStatus = nil

OctoPort.config.controllerKeys.A = "1"
OctoPort.config.controllerKeys.B = "2"
OctoPort.config.controllerKeys.X = "3"
OctoPort.config.controllerKeys.Y = "4"
OctoPort:CreateCaptureOverlay()
OctoPort:StartFaceBindingWizard()
local faceSignals = { "ENTER", "ESCAPE", "F1", "F2" }
for index = 1, table.getn(faceSignals) do
  FireScript(OctoPort.captureFrame, "OnKeyDown", faceSignals[index])
  assert(OctoPort.captureIndex == index, "capture advanced before the physical button was released")
  FireScript(OctoPort.captureFrame, "OnKeyUp", faceSignals[index])
end
assert(OctoPort.config.controllerKeys.A == "ENTER", "physical A was not captured")
assert(OctoPort.config.controllerKeys.B == "ESCAPE", "physical B was not captured")
assert(OctoPort.config.controllerKeys.X == "F1" and OctoPort.config.controllerKeys.Y == "F2", "physical X/Y were not captured")
assert(OctoPort.config.nativeFaceButtons == true, "captured ABXY were not switched to native action slots")

-- Direction calibration is a live, transactional eight-input test. Existing
-- assignments may be swapped, but a physical signal repeated within the new
-- calibration is rejected. Key repeat cannot spill into the following step.
local oldDirections = {
  LSUP = "UP", LSDOWN = "DOWN", LSLEFT = "LEFT", LSRIGHT = "RIGHT",
  DUP = "W", DDOWN = "S", DLEFT = "A", DRIGHT = "D",
}
for id, key in pairs(oldDirections) do OctoPort.config.controllerKeys[id] = key end

local function AssertOldDirections(message)
  for id, key in pairs(oldDirections) do
    assert(OctoPort.config.controllerKeys[id] == key, message .. ": " .. id .. " changed early")
  end
end

local deactivateCount, activateCount = 0, 0
function OctoPort:DeactivateSessionBindings()
  deactivateCount = deactivateCount + 1
  self.sessionBindingsActive = false
end
function OctoPort:ActivateSessionBindings()
  activateCount = activateCount + 1
  self.sessionBindingsActive = true
  return true
end

OctoPort.config.enabled = true
OctoPort.sessionBindingsActive = true
OctoPort:StartDirectionalBindingWizard()
assert(deactivateCount == 1 and not OctoPort.sessionBindingsActive, "direction wizard did not suspend the active binding session")

FireScript(OctoPort.captureFrame, "OnKeyDown", "W")
FireScript(OctoPort.captureFrame, "OnKeyDown", "W")
assert(OctoPort.captureIndex == 1, "held stick direction advanced before key release")
assert(activateCount == 0, "binding session reactivated during direction capture")
AssertOldDirections("first staged direction")
FireScript(OctoPort.captureFrame, "OnKeyUp", "W")
assert(OctoPort.captureIndex == 2, "released stick direction did not advance exactly one step")

-- A second physical control emitting W is indistinguishable from the first
-- and must be rejected even after W was released.
FireScript(OctoPort.captureFrame, "OnKeyDown", "W")
FireScript(OctoPort.captureFrame, "OnKeyUp", "W")
assert(OctoPort.captureIndex == 2, "duplicate raw direction was accepted")
assert(string.find(OctoPort.captureFrame.progress.text, "KOLIZE", 1, true), "duplicate direction did not show a collision")
AssertOldDirections("rejected duplicate direction")

local remainingDirections = { "S", "A", "D", "UP", "DOWN", "LEFT", "RIGHT" }
for index = 1, table.getn(remainingDirections) do
  local key = remainingDirections[index]
  FireScript(OctoPort.captureFrame, "OnKeyDown", key)
  FireScript(OctoPort.captureFrame, "OnKeyDown", key)
  assert(activateCount == 0, "binding session reactivated before direction capture completed")
  if index < table.getn(remainingDirections) then AssertOldDirections("staged direction " .. key) end
  FireScript(OctoPort.captureFrame, "OnKeyUp", key)
end

local expectedDirections = {
  LSUP = "W", LSDOWN = "S", LSLEFT = "A", LSRIGHT = "D",
  DUP = "UP", DDOWN = "DOWN", DLEFT = "LEFT", DRIGHT = "RIGHT",
}
for id, key in pairs(expectedDirections) do
  assert(OctoPort.config.controllerKeys[id] == key, "completed direction calibration did not commit " .. id)
end
assert(not OctoPort.bindingCaptureActive, "completed direction calibration left capture active")
assert(activateCount == 1 and OctoPort.sessionBindingsActive, "binding session was not restored exactly once after capture")

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

-- Normal HUD geometry reserves independent header/content/footer bands. The
-- entire target pad (including captions) must fit inside the content band.
OctoPort:SetUIEnabled(true)
assert(OctoPort.root.width == 510 and OctoPort.root.height == 206, "normal HUD dimensions regressed")
assert(OctoPort.root.point[5] == 122, "normal HUD did not keep its configured vertical position")
assert(OctoPort.layers.base.point[5] == -3, "normal action content is not vertically centered in its band")
assert(OctoPort.targetPad.width == 232 and OctoPort.targetPad.height == 140, "target pad bounds do not include its captions")
assert(OctoPort.targetPad.point[4] == -130 and OctoPort.targetPad.point[5] == 0, "target pad is not placed in the left content column")
assert(OctoPort.targetNameText.point[1] == "TOPLEFT" and OctoPort.targetNameText.point[5] == -12, "target name is not anchored inside the header")
assert(OctoPort.hintText:IsVisible() and OctoPort.hintText.point[1] == "BOTTOM", "normal HUD hint is not anchored in the footer")

local normalPadTop = OctoPort.layers.base.point[5] + OctoPort.targetPad.point[5] + (OctoPort.targetPad.height / 2)
local normalPadBottom = OctoPort.layers.base.point[5] + OctoPort.targetPad.point[5] - (OctoPort.targetPad.height / 2)
local normalHeaderBottom = (OctoPort.root.height / 2) - 36
local normalFooterTop = -(OctoPort.root.height / 2) + 28
assert(normalPadTop <= normalHeaderBottom, "target pad overlaps the normal HUD header")
assert(normalPadBottom >= normalFooterTop, "target pad overlaps the normal HUD footer")
local normalPadLeft = OctoPort.targetPad.point[4] - (OctoPort.targetPad.width / 2)
local normalPadRight = OctoPort.targetPad.point[4] + (OctoPort.targetPad.width / 2)
assert(normalPadLeft >= -(OctoPort.root.width / 2) and normalPadRight <= (OctoPort.root.width / 2), "target pad is outside the HUD horizontally")

local targetNodes = {}
for index = 1, 4 do targetNodes[OctoPort.targetPad[index].direction] = OctoPort.targetPad[index] end
assert(targetNodes.up.captionText.point[1] == "BOTTOM", "up target caption is misplaced")
assert(targetNodes.down.captionText.point[1] == "TOP", "down target caption is misplaced")
assert(targetNodes.left.captionText.point[1] == "RIGHT", "left target caption is misplaced")
assert(targetNodes.right.captionText.point[1] == "LEFT", "right target caption is misplaced")

-- Gameplay target feedback is passive: Blizzard's native TARGET* binding
-- changes the target, then PLAYER_TARGET_CHANGED mirrors the result. Because
-- the event does not expose previous/next, both nodes in that category pulse.
local function AssertBorder(node, red, green, blue, alpha, message)
  local color = node.borderColor or {}
  assert(color[1] == red and color[2] == green and color[3] == blue and color[4] == alpha, message)
end

assert(OctoPortEvents.registeredEvents.PLAYER_TARGET_CHANGED, "PLAYER_TARGET_CHANGED was not registered")
targetExists = true
targetName = "Forest Gnoll"
targetHostile = true
mockTime = 10
FireEvent(OctoPortEvents, "PLAYER_TARGET_CHANGED")
assert(OctoPort.targetNameText.text == "FOREST GNOLL", "hostile target name was not updated immediately")
assert(OctoPort.targetNameText.textColor[1] == 1.0 and OctoPort.targetNameText.textColor[2] == 0.28, "hostile target name did not use hostile color")
AssertBorder(targetNodes.left, 0.24, 0.94, 0.88, 1, "hostile target did not pulse the left node")
AssertBorder(targetNodes.right, 0.24, 0.94, 0.88, 1, "hostile target did not pulse the right node")
AssertBorder(targetNodes.up, 0.72, 0.78, 0.82, 0.90, "hostile target falsely pulsed previous/next friend")
AssertBorder(targetNodes.down, 0.72, 0.78, 0.82, 0.90, "hostile target falsely pulsed previous/next friend")
assert(not OctoPort.targetFlashDirection, "target event pretended to know previous/next direction")

mockTime = 10.31
OctoPort:UpdateTargetDisplay()
AssertBorder(targetNodes.left, 0.72, 0.78, 0.82, 0.90, "hostile category pulse did not expire")
AssertBorder(targetNodes.right, 0.72, 0.78, 0.82, 0.90, "hostile category pulse did not expire")

targetName = "Stormwind Guard"
targetHostile = false
mockTime = 11
FireEvent(OctoPortEvents, "PLAYER_TARGET_CHANGED")
assert(OctoPort.targetNameText.text == "STORMWIND GUARD", "friendly target name was not updated immediately")
assert(OctoPort.targetNameText.textColor[1] == 0.30 and OctoPort.targetNameText.textColor[2] == 0.95, "friendly target name did not use friendly color")
AssertBorder(targetNodes.up, 0.24, 0.94, 0.88, 1, "friendly target did not pulse the up node")
AssertBorder(targetNodes.down, 0.24, 0.94, 0.88, 1, "friendly target did not pulse the down node")
AssertBorder(targetNodes.left, 0.72, 0.78, 0.82, 0.90, "friendly target falsely pulsed previous/next enemy")
AssertBorder(targetNodes.right, 0.72, 0.78, 0.82, 0.90, "friendly target falsely pulsed previous/next enemy")

targetExists = false
targetName = nil
mockTime = 12
FireEvent(OctoPortEvents, "PLAYER_TARGET_CHANGED")
assert(OctoPort.targetNameText.text == "BEZ CILE", "clearing the target did not update the HUD immediately")
assert(not OctoPort.targetFlashCategory and not OctoPort.targetFlashUntil, "clearing the target left a stale pulse")
for direction, node in pairs(targetNodes) do
  AssertBorder(node, 0.72, 0.78, 0.82, 0.90, "clearing target left the " .. direction .. " node highlighted")
end

shiftDown = true
assert(OctoPort:GetActiveLayer() == "lt", "SHIFT did not select the LT layer")
shiftDown = false
controlDown = true
assert(OctoPort:GetActiveLayer() == "rt", "CTRL did not select the RT layer")
controlDown = false

-- Editing is a setup preview, not gameplay. It must be visible and interactive
-- while runtime controller bindings remain disabled.
OctoPort.config.enabled = false
OctoPort.sessionBindingsActive = false
OctoPort:SetUIEnabled(false)
local activationsBeforeEdit = activateCount
OctoPort:SetActionEditMode(true)
assert(OctoPort.config.editMode, "action editor did not enter edit mode")
assert(OctoPort.root:IsVisible(), "disabled controller hid the action editor")
assert(OctoPort.root.height == 520, "action editor used the collapsed HUD layout")
assert(OctoPort.root.point[5] == 270, "expanded editor was not kept on screen")
assert(OctoPort.root.mouseEnabled, "action editor root did not accept mouse input")
assert(OctoPort.layers.base:IsVisible() and OctoPort.layers.lt:IsVisible() and OctoPort.layers.rt:IsVisible(), "action editor did not display all three layers")
assert(activateCount == activationsBeforeEdit and not OctoPort.sessionBindingsActive, "opening the editor activated gameplay bindings")

-- All 20 buttons occupy three non-overlapping rows between the editor header
-- and footer. The target pad shares the base row without touching LT.
assert(OctoPort.layers.base.point[5] == 142 and OctoPort.layers.lt.point[5] == 0 and OctoPort.layers.rt.point[5] == -142, "editor rows are not evenly separated")
assert(OctoPort.hintText:IsVisible() and OctoPort.hintText.point[1] == "BOTTOMLEFT", "editor hint is not visible in its footer row")
assert(OctoPort.editorStatusText:IsVisible() and OctoPort.editorStatusText.point[5] == 30, "editor status is not in its own footer row")
assert(OctoPort.editorDoneButton:IsVisible(), "editor Done button is not visible")

local function ActionRowBounds(layer)
  local low, high = nil, nil
  for _, button in pairs(layer.buttons) do
    local center = layer.point[5] + button.point[5]
    local bottom = center - (button.height / 2)
    local top = center + (button.height / 2)
    if not low or bottom < low then low = bottom end
    if not high or top > high then high = top end
  end
  return low, high
end

local baseLow, baseHigh = ActionRowBounds(OctoPort.layers.base)
local ltLow, ltHigh = ActionRowBounds(OctoPort.layers.lt)
local rtLow, rtHigh = ActionRowBounds(OctoPort.layers.rt)
local editorHeaderBottom = (OctoPort.root.height / 2) - 42
local editorFooterTop = -(OctoPort.root.height / 2) + 45
local editorPadTop = OctoPort.layers.base.point[5] + (OctoPort.targetPad.height / 2)
local editorPadBottom = OctoPort.layers.base.point[5] - (OctoPort.targetPad.height / 2)
assert(math.max(baseHigh, editorPadTop) <= editorHeaderBottom, "base row overlaps the editor header")
assert(math.min(rtLow, editorPadBottom) >= editorFooterTop, "bottom row overlaps the editor footer")
assert(editorPadBottom > ltHigh, "target pad overlaps the LT action row")
assert(ltLow > rtHigh, "LT and RT action rows overlap")

local editButton = OctoPort.layers.lt.buttons.A
assert(editButton.action == 61, "disabled action editor did not initialize LT+A")
assert(editButton.mouseEnabled, "editable action slot did not accept mouse input")
FireScript(editButton, "OnClick", "RightButton")
assert(pickedAction == 61, "custom HUD action could not be picked up for editing")

cursorAction = { kind = "spell", texture = "Interface\\Icons\\Spell_Test" }
FireScript(editButton, "OnReceiveDrag")
assert(placedAction == 61 and actionSlots[61], "spell was not assigned to the selected custom action slot")
assert(editButton.icon.texture == "Interface\\Icons\\Spell_Test", "action mirror did not refresh after assignment")

OctoPort:SetActionEditMode(false)
assert(not OctoPort.config.editMode, "action editor did not leave edit mode")
assert(not OctoPort.root:IsVisible(), "disabled gameplay HUD stayed visible after closing the editor")
assert(not OctoPort.root.mouseEnabled, "closed action editor still captured mouse input")
assert(OctoPort.root.height == 206 and OctoPort.hintText.point[1] == "BOTTOM", "closing the editor did not restore normal HUD geometry")
assert(activateCount == activationsBeforeEdit and not OctoPort.sessionBindingsActive, "closing the editor activated gameplay bindings")

print("minimap/raw input harness: OK")
