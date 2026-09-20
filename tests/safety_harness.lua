-- Minimal binding API harness. It verifies the safety contract without a WoW
-- client; visual/API compatibility is covered separately by in-game testing.

local bindings = {}
local saveCount = 0
local setBindingCount = 0
local inCombat = false
local evictSecondOnNextBinding = {}

function UnitAffectingCombat(unit)
  return unit == "player" and inCombat
end

function GetBindingAction(key)
  return bindings[key] or ""
end

function GetBindingKey(command)
  local keys = {}
  for key, action in pairs(bindings) do
    if action == command then
      table.insert(keys, key)
    end
  end
  table.sort(keys)
  return keys[1], keys[2]
end

function SetBinding(key, command)
  assert(not inCombat, "SetBinding was called during combat")
  setBindingCount = setBindingCount + 1
  -- Vanilla may evict the existing second key when a third key is assigned to
  -- a command. Trigger that behavior selectively for restoration regressions.
  if command and evictSecondOnNextBinding[command] then
    local key1, key2 = GetBindingKey(command)
    if key2 and key ~= key1 and key ~= key2 then bindings[key2] = nil end
    evictSecondOnNextBinding[command] = nil
  end
  bindings[key] = command
  return 1
end

function SaveBindings()
  saveCount = saveCount + 1
end

function GetCurrentBindingSet()
  return 2
end

function GetTime()
  return 1
end

OctoPort = {
  config = {
    enabled = false,
    controllerKeys = {},
    nativeModifiers = { SHIFT = "lt", CTRL = "rt" },
    rearActions = { M1 = "settings", M2 = "interact" },
  },
}

function OctoPort:Print() end

dofile("Bindings.lua")

local directionIds = { "LSUP", "LSDOWN", "LSLEFT", "LSRIGHT", "DUP", "DDOWN", "DLEFT", "DRIGHT" }
local function VerifyConfiguredDirections()
  for index = 1, table.getn(directionIds) do
    local id = directionIds[index]
    assert(OctoPort:MarkDirectionVerified(id, OctoPort.config.controllerKeys[id]), "could not mark live direction " .. id)
  end
end

-- Existing profiles gain safe left-stick and complete ROG Ally defaults
-- without touching the live or persisted WoW binding set.
OctoPort:EnsureMovementDefaults()
assert(OctoPort.config.controllerKeys.LSUP == "W", "forward movement default missing")
assert(OctoPort.config.controllerKeys.LSDOWN == "S", "backward movement default missing")
assert(OctoPort.config.controllerKeys.LSLEFT == "A", "left strafe default missing")
assert(OctoPort.config.controllerKeys.LSRIGHT == "D", "right strafe default missing")
assert(OctoPort.config.controllerKeys.LB == "BUTTON1", "native LB left-click default missing")
assert(OctoPort.config.controllerKeys.RB == "BUTTON2", "native RB right-click default missing")
assert(OctoPort.config.controllerKeys.L3 == "NUMLOCK", "L3 default missing")
assert(OctoPort.config.controllerKeys.R3 == "SPACE", "R3 default missing")
assert(saveCount == 0, "movement defaults persisted bindings")

-- Setup stores a profile but must not touch or persist WoW bindings.
bindings["1"] = "OPENCHAT"
bindings.W = "OPENCHAT"
bindings.UP = "PREVIOUSACTIONPAGE"
bindings.BUTTON1 = "CAMERAORSELECTORMOVE"
bindings.BUTTON2 = "TURNORACTION"
bindings["SHIFT-1"] = "CHATBOTTOM"
bindings["SHIFT-UP"] = "PREVIOUSACTIONPAGE"
bindings["CTRL-1"] = "TOGGLECHARACTER0"
bindings["CTRL-UP"] = "NEXTACTIONPAGE"
bindings["SHIFT-W"] = "CUSTOMSHIFTW"
bindings["CTRL-W"] = "OPENCHATSLASH"
OctoPort:ApplyRecommendedBindings()
VerifyConfiguredDirections()
assert(bindings["1"] == "OPENCHAT", "profile selection changed a live face-button binding")
assert(bindings.BUTTON1 == "CAMERAORSELECTORMOVE", "profile selection stole native left click")
assert(bindings.BUTTON2 == "TURNORACTION", "profile selection stole native right click")
assert(saveCount == 0, "normal profile selection persisted bindings")

-- Enabling applies a temporary command and disabling restores it exactly.
bindings.F13 = "ACTIONBUTTON1"
bindings.F14 = "ACTIONBUTTON1"
evictSecondOnNextBinding.ACTIONBUTTON1 = true
OctoPort.config.enabled = true
assert(OctoPort:ActivateSessionBindings(), "session profile did not activate")
assert(bindings.F14 == nil, "session two-key eviction fixture did not run")
assert(bindings["1"] == "ACTIONBUTTON1", "native A/action 1 binding missing")
assert(bindings.W == "MOVEFORWARD", "native forward binding missing")
assert(bindings.S == "MOVEBACKWARD", "native backward binding missing")
assert(bindings.A == "STRAFELEFT", "native left strafe binding missing")
assert(bindings.D == "STRAFERIGHT", "native right strafe binding missing")
assert(bindings.UP == "TARGETPREVIOUSFRIEND", "native D-pad targeting was not active beside movement")
assert(bindings.DOWN == "TARGETNEARESTFRIEND", "D-pad down did not target the next friend")
assert(bindings.LEFT == "TARGETPREVIOUSENEMY", "D-pad left did not target the previous enemy")
assert(bindings.RIGHT == "TARGETNEARESTENEMY", "D-pad right did not target the next enemy")
assert(bindings["SHIFT-1"] == "MULTIACTIONBAR1BUTTON1", "LT+A native action missing")
assert(bindings["SHIFT-UP"] == "MULTIACTIONBAR1BUTTON5", "LT+D-pad native action missing")
assert(bindings["CTRL-1"] == "MULTIACTIONBAR2BUTTON1", "RT+A native action missing")
assert(bindings["CTRL-UP"] == "MULTIACTIONBAR2BUTTON5", "RT+D-pad native action missing")
assert(bindings["SHIFT-W"] == nil, "LT+W was not cleared to fall through to base movement")
assert(bindings["CTRL-W"] == nil, "RT+W was not cleared to fall through to base movement")
local actionKeys = { "1", "2", "3", "4", "UP", "RIGHT", "DOWN", "LEFT" }
for index = 1, 8 do
  assert(bindings["SHIFT-" .. actionKeys[index]] == "MULTIACTIONBAR1BUTTON" .. index, "LT action " .. index .. " is missing")
  assert(bindings["CTRL-" .. actionKeys[index]] == "MULTIACTIONBAR2BUTTON" .. index, "RT action " .. index .. " is missing")
end
local movementKeys = { "S", "A", "D" }
for index = 1, table.getn(movementKeys) do
  local key = movementKeys[index]
  assert(bindings["SHIFT-" .. key] == nil, "LT created a third movement alias for " .. key)
  assert(bindings["CTRL-" .. key] == nil, "RT created a third movement alias for " .. key)
end
assert(bindings.NUMLOCK == "TOGGLEAUTORUN", "native L3 autorun binding missing")
assert(bindings.SPACE == "JUMP", "native R3 jump binding missing")
assert(bindings.BUTTON1 == "CAMERAORSELECTORMOVE", "session activation stole native left click")
assert(bindings.BUTTON2 == "TURNORACTION", "session activation stole native right click")
assert(saveCount == 0, "session activation persisted bindings")
OctoPort:DeactivateSessionBindings()
assert(bindings["1"] == "OPENCHAT", "session cleanup did not restore original A binding")
assert(bindings.W == "OPENCHAT", "session cleanup did not restore original movement binding")
assert(bindings.UP == "PREVIOUSACTIONPAGE", "session cleanup did not restore original D-pad binding")
assert(bindings["SHIFT-1"] == "CHATBOTTOM" and bindings["SHIFT-UP"] == "PREVIOUSACTIONPAGE", "LT layer bindings were not restored")
assert(bindings["CTRL-1"] == "TOGGLECHARACTER0" and bindings["CTRL-UP"] == "NEXTACTIONPAGE", "RT layer bindings were not restored")
assert(bindings["SHIFT-W"] == "CUSTOMSHIFTW" and bindings["CTRL-W"] == "OPENCHATSLASH", "modified movement bindings were not restored")
assert(bindings.S == nil and bindings.A == nil and bindings.D == nil, "session cleanup left native movement bindings behind")
assert(bindings.NUMLOCK == nil and bindings.SPACE == nil, "session cleanup left stick-click bindings behind")
assert(bindings.BUTTON1 == "CAMERAORSELECTORMOVE", "session cleanup changed native left click")
assert(bindings.BUTTON2 == "TURNORACTION", "session cleanup changed native right click")
assert(bindings.F13 == "ACTIONBUTTON1" and bindings.F14 == "ACTIONBUTTON1", "session cleanup lost a command's evicted second key")
assert(saveCount == 0, "session cleanup persisted bindings")
bindings.F13, bindings.F14 = nil, nil

-- Duplicate device signals are surfaced instead of silently looking valid.
OctoPort.config.enabled = false
assert(OctoPort:BindControllerKey("DUP", "W"), "duplicate input capture failed")
assert(OctoPort.config.controllerKeys.LSUP == nil, "duplicate signal still owns two controls")
assert(OctoPort.config.lastBindingCollision and OctoPort.config.lastBindingCollision.previous == "LSUP", "duplicate signal was not reported")
OctoPort:ApplyRecommendedBindings()
VerifyConfiguredDirections()
assert(OctoPort.config.lastBindingCollision == nil, "preset did not clear old collision warning")

-- The controller cannot be enabled when a stick direction and D-pad signal
-- collapse to the same input. No partial session bindings may remain active.
OctoPort.config.controllerKeys.DUP = OctoPort.config.controllerKeys.LSUP
OctoPort.config.enabled = true
assert(not OctoPort:ActivateSessionBindings(), "conflicting direction profile was accepted")
assert(OctoPort.sessionBindingsActive == false, "failed calibration left a partial session active")
OctoPort:ApplyRecommendedBindings()
VerifyConfiguredDirections()

-- A working raw key can enable a menu-only session without activating the
-- rest of an incomplete controller profile.
bindings.F4 = "TOGGLECHARACTER0"
OctoPort.config.enabled = false
assert(OctoPort:SetQuickMenuKey("F4"), "quick menu key was rejected")
assert(OctoPort.config.menuOnlyMode == true, "quick menu did not use menu-only safety mode")
assert(bindings.F4 == "OCTOPORT_OPENCONFIG", "quick menu binding was not activated")
assert(bindings["1"] == "OPENCHAT", "menu-only mode activated unrelated face buttons")
assert(bindings.W == "OPENCHAT", "menu-only mode activated movement")
OctoPort:DeactivateSessionBindings()
assert(bindings.F4 == "TOGGLECHARACTER0", "quick menu key was not restored")

-- Updating a shared-arrow profile restores the intended direct layout. Stick
-- and D-pad bindings are active simultaneously and never share a key.
OctoPort.config.enabled = false
OctoPort.config.bindingVersion = 10
OctoPort.config.controlSchemaVersion = 11
OctoPort.config.arrowMovementFallback = true
OctoPort.config.reticleEnabled = true
OctoPort.config.controllerKeys = {
  LSUP = "UP", LSDOWN = "DOWN", LSLEFT = "LEFT", LSRIGHT = "RIGHT",
  A = "F9", B = "F10", X = "F11", Y = "F12",
}
assert(OctoPort:EnsureDirectControlDefaults(), "direct-control upgrade did not run")
assert(OctoPort.config.controllerKeys.LSUP == "W" and OctoPort.config.controllerKeys.LSLEFT == "A", "stick was not restored to W/A/S/D")
assert(OctoPort.config.controllerKeys.DUP == "UP" and OctoPort.config.controllerKeys.DLEFT == "LEFT", "D-pad target keys were not restored")
assert(OctoPort.config.controllerKeys.A == "1" and OctoPort.config.controllerKeys.Y == "4", "ABXY defaults were not upgraded to 1-4")
assert(OctoPort.config.nativeModifiers.SHIFT == "lt" and OctoPort.config.nativeModifiers.CTRL == "rt", "LT/RT modifier migration failed")
assert(OctoPort.config.controllerKeys.LB == "BUTTON1" and OctoPort.config.controllerKeys.RB == "BUTTON2", "mouse click migration failed")
assert(OctoPort.config.arrowMovementFallback == false, "shared-arrow mode survived the upgrade")
assert(OctoPort.config.reticleEnabled == false, "reticle survived the direct-control upgrade")
OctoPort:RefreshSetupState()
VerifyConfiguredDirections()
OctoPort.config.enabled = true
assert(OctoPort:ActivateSessionBindings(), "direct-control profile did not activate")
assert(bindings.W == "MOVEFORWARD", "stick movement was not active")
assert(bindings.UP == "TARGETPREVIOUSFRIEND", "native D-pad targeting was not active simultaneously")
assert(bindings["1"] == "ACTIONBUTTON1" and bindings["4"] == "ACTIONBUTTON4", "native ABXY actions were not active")
assert(bindings["SHIFT-1"] == "MULTIACTIONBAR1BUTTON1" and bindings["CTRL-1"] == "MULTIACTIONBAR2BUTTON1", "20-action layers were not active")
OctoPort:DeactivateSessionBindings()
assert(bindings.W == "OPENCHAT" and bindings.UP == "PREVIOUSACTIONPAGE", "direct controls did not restore previous bindings")
assert(bindings["1"] == "OPENCHAT" and bindings["4"] == nil, "direct ABXY did not restore previous bindings")
assert(saveCount == 0, "direct-control upgrade persisted bindings")

-- Captured physical buttons may emit Enter/Escape/F-keys. They still map
-- directly to Blizzard action slots 1-4 instead of opening chat or menus.
OctoPort.config.controllerKeys.A = "ENTER"
OctoPort.config.controllerKeys.B = "ESCAPE"
OctoPort.config.controllerKeys.X = "F1"
OctoPort.config.controllerKeys.Y = "F2"
bindings.ENTER = "CUSTOMCHAT"
bindings.ESCAPE = "TOGGLEGAMEMENU"
bindings.F1 = "TOGGLECHARACTER0"
bindings.F2 = "TOGGLESPELLBOOK"
OctoPort.config.enabled = false
OctoPort:ApplyNativeFaceButtons()
OctoPort.config.enabled = true
assert(OctoPort:ActivateSessionBindings(), "native face-button profile did not activate")
assert(bindings.ENTER == "ACTIONBUTTON1" and bindings.ESCAPE == "ACTIONBUTTON2", "captured A/B did not map to action buttons 1/2")
assert(bindings.F1 == "ACTIONBUTTON3" and bindings.F2 == "ACTIONBUTTON4", "captured X/Y did not map to action buttons 3/4")
OctoPort:DeactivateSessionBindings()
assert(bindings.ENTER == "CUSTOMCHAT" and bindings.ESCAPE == "TOGGLEGAMEMENU", "captured A/B restore lost existing actions")
assert(bindings.F1 == "TOGGLECHARACTER0" and bindings.F2 == "TOGGLESPELLBOOK", "captured X/Y restore lost existing actions")
assert(saveCount == 0, "native face-button profile persisted bindings")

-- Opening controller settings temporarily routes ABXY to menu navigation, and
-- closing it restores native combat actions without persisting anything.
OctoPort.config.enabled = true
assert(OctoPort:ActivateSessionBindings(), "profile did not reactivate for menu navigation test")
assert(OctoPort:ActivateConfigNavigationBindings(), "ABXY menu navigation did not activate")
assert(bindings.ENTER == "OCTOPORT_ACTION_A" and bindings.ESCAPE == "OCTOPORT_ACTION_B", "settings did not receive captured A/B")
assert(bindings.UP == "OCTOPORT_TARGET_UP", "settings did not receive D-pad navigation")
assert(OctoPort:ActivateSessionBindings(), "combat bindings did not restore after menu close")
assert(bindings.ENTER == "ACTIONBUTTON1" and bindings.ESCAPE == "ACTIONBUTTON2", "menu close did not restore native A/B")
assert(bindings.UP == "TARGETPREVIOUSFRIEND", "menu close did not restore native D-pad targeting")
OctoPort:DeactivateSessionBindings()

-- Settings are also a recovery surface. Even with the controller runtime OFF
-- and an invalid directional profile, its known ABXY/D-pad keys temporarily
-- navigate the menu, then restore the user's bindings exactly on close.
OctoPort.config.enabled = false
OctoPort.config.controllerKeys.LSDOWN = OctoPort.config.controllerKeys.LSUP
local directionsValid = OctoPort:ValidateDirectionalInputs()
assert(not directionsValid, "test profile was expected to have a direction collision")
bindings.ENTER = "CUSTOMCHAT"
bindings.ESCAPE = "TOGGLEGAMEMENU"
bindings.F1 = "TOGGLECHARACTER0"
bindings.F2 = "TOGGLESPELLBOOK"
bindings.UP = "PREVIOUSACTIONPAGE"
bindings.DOWN = "NEXTACTIONPAGE"
bindings.LEFT = "CAMERAZOOMIN"
bindings.RIGHT = "CAMERAZOOMOUT"
bindings.F15 = "OCTOPORT_ACTION_A"
bindings.F16 = "OCTOPORT_ACTION_A"
evictSecondOnNextBinding.OCTOPORT_ACTION_A = true

local configActionCount, configDirectionCount = 0, 0
OctoPort.configFrame = { IsVisible = function() return true end }
function OctoPort:HandleConfigAction(slot, keystate)
  if slot == 1 and keystate == "up" then configActionCount = configActionCount + 1 end
  return true
end
function OctoPort:HandleControllerAction(slot, keystate)
  return self:HandleConfigAction(slot, keystate)
end
function OctoPort:HandleConfigDirection(direction)
  if direction == "down" then configDirectionCount = configDirectionCount + 1 end
  return true
end
function TargetNearestFriend() error("disabled config navigation leaked into game targeting") end
function TargetNearestEnemy() error("disabled config navigation leaked into game targeting") end

assert(OctoPort:ActivateConfigNavigationBindings(), "disabled/invalid controller could not activate recovery-menu navigation")
assert(bindings.F16 == nil, "config-navigation two-key eviction fixture did not run")
assert(bindings.ENTER == "OCTOPORT_ACTION_A" and bindings.ESCAPE == "OCTOPORT_ACTION_B", "disabled settings did not receive ABXY")
assert(bindings.UP == "OCTOPORT_TARGET_UP" and bindings.DOWN == "OCTOPORT_TARGET_DOWN", "disabled settings did not receive D-pad navigation")
OctoPort_ActionKey(1, "down")
OctoPort_ActionKey(1, "up")
OctoPort_Target("down", "down")
OctoPort_Target("down", "up")
assert(configActionCount == 1, "A did not activate the focused control while runtime was disabled")
assert(configDirectionCount == 1, "D-pad did not navigate settings while runtime was disabled")
assert(not OctoPort.sessionBindingsActive, "menu recovery mode activated gameplay bindings")

OctoPort:DeactivateConfigNavigationBindings()
assert(bindings.ENTER == "CUSTOMCHAT" and bindings.ESCAPE == "TOGGLEGAMEMENU", "closing disabled settings did not restore ABXY")
assert(bindings.UP == "PREVIOUSACTIONPAGE" and bindings.DOWN == "NEXTACTIONPAGE", "closing disabled settings did not restore D-pad")
assert(bindings.LEFT == "CAMERAZOOMIN" and bindings.RIGHT == "CAMERAZOOMOUT", "closing disabled settings lost horizontal D-pad bindings")
assert(bindings.F15 == "OCTOPORT_ACTION_A" and bindings.F16 == "OCTOPORT_ACTION_A", "closing settings lost a command's evicted second key")
assert(saveCount == 0, "temporary disabled-menu navigation persisted bindings")
bindings.F15, bindings.F16 = nil, nil

-- If a modal closes after combat has already deferred restoration, its old
-- OCTOPORT_TARGET binding can fire once while no modal is visible. It must be
-- inert: gameplay targeting belongs exclusively to native TARGET* commands.
OctoPort.config.enabled = true
OctoPort.configFrame = { IsVisible = function() return false end }
function OctoPort:HandleConfigDirection() return false end
function OctoPort:HandleRadialDirection() return false end
inCombat = true
assert(pcall(OctoPort_Target, "right", "down"), "stale modal D-pad binding attempted Lua targeting in combat")
inCombat = false
OctoPort.config.enabled = false
OctoPort.configFrame = nil

-- The radial editor is the same kind of recovery surface as Settings. Its
-- temporary ABXY/D-pad layer must work while gameplay is OFF, and every close
-- path must restore the player's exact bindings instead of leaking navigation
-- commands into the world.
UIParent = {}
function CreateFrame()
  return { SetScript = function() end }
end
function PlaySound() end
dofile("Radial.lua")

local radialActionCount, radialDirectionCount = 0, 0
local previousControllerAction = OctoPort.HandleControllerAction
local previousRadialDirection = OctoPort.HandleRadialDirection
local previousConfigAction = OctoPort.HandleConfigAction
local previousConfigDirection = OctoPort.HandleConfigDirection
function OctoPort:HandleConfigAction() return false end
function OctoPort:HandleConfigDirection() return false end
function OctoPort:HandleControllerAction(slot, keystate)
  if keystate ~= "down" then return end
  radialActionCount = radialActionCount + 1
  if slot == 2 then self:HideRadial() end
end
function OctoPort:HandleRadialDirection(direction)
  if not self.radialFrame or not self.radialFrame:IsVisible() then return false end
  if direction == "right" then radialDirectionCount = radialDirectionCount + 1 end
  return true
end

local radialFrame = { visible = true }
function radialFrame:IsVisible() return self.visible end
function radialFrame:Hide() self.visible = false end
OctoPort.radialFrame = radialFrame
OctoPort.radialEditor = true
OctoPort.radialSelection = nil
OctoPort.configFrame = nil
OctoPort.config.enabled = false

local radialBaseline = {}
for key, command in pairs(bindings) do radialBaseline[key] = command end
assert(OctoPort:ActivateConfigNavigationBindings(), "disabled radial editor could not activate temporary navigation")
OctoPort_ActionKey(1, "down")
OctoPort_Target("right", "down")
assert(radialActionCount == 1, "ABXY did not reach the radial editor while gameplay was disabled")
assert(radialDirectionCount == 1, "D-pad did not reach the radial editor while gameplay was disabled")
OctoPort_ActionKey(2, "down")
assert(radialActionCount == 2 and not radialFrame:IsVisible(), "B did not close the disabled radial editor")
assert(not OctoPort.configNavigationBindingsActive, "closing the disabled radial editor left temporary navigation active")
for key, command in pairs(radialBaseline) do
  assert(bindings[key] == command, "radial editor close did not restore " .. key)
end
for key, command in pairs(bindings) do
  assert(radialBaseline[key] == command, "radial editor close leaked " .. key .. " -> " .. command)
end
assert(saveCount == 0, "radial editor navigation persisted bindings")

-- If opening the editor was deferred by combat, reconciliation must notice the
-- still-visible radial (not only Settings), install navigation after combat,
-- and restore it again when the editor closes.
radialFrame.visible = true
OctoPort.radialEditor = true
inCombat = true
local radialActivated, radialReason = OctoPort:ActivateConfigNavigationBindings()
assert(radialActivated == nil and radialReason == "deferred", "combat radial navigation was not deferred")
inCombat = false
assert(OctoPort:RetryDeferredBindings(), "deferred radial navigation did not retry after combat")
assert(OctoPort.configNavigationBindingsActive, "visible radial editor was ignored during binding reconciliation")
assert(OctoPort:HideRadial(), "radial editor did not restore navigation after deferred activation")
for key, command in pairs(radialBaseline) do
  assert(bindings[key] == command, "deferred radial close did not restore " .. key)
end
for key, command in pairs(bindings) do
  assert(radialBaseline[key] == command, "deferred radial close leaked " .. key .. " -> " .. command)
end

OctoPort.HandleControllerAction = previousControllerAction
OctoPort.HandleRadialDirection = previousRadialDirection
OctoPort.HandleConfigAction = previousConfigAction
OctoPort.HandleConfigDirection = previousConfigDirection
OctoPort.radialFrame = nil
OctoPort.radialEditor = false

-- No protected binding API may be called during combat. Activation and
-- restoration are deferred as one desired-state reconciliation, then retried
-- after PLAYER_REGEN_ENABLED without leaving a partial profile behind.
OctoPort.configFrame = nil
OctoPort:ApplyRecommendedBindings()
VerifyConfiguredDirections()
OctoPort.config.enabled = true
local callsBeforeCombat = setBindingCount
local bindingBeforeCombat = bindings.W
inCombat = true
local activated, activationReason = OctoPort:ActivateSessionBindings()
assert(activated == nil and activationReason == "deferred", "combat activation was not deferred")
assert(setBindingCount == callsBeforeCombat and bindings.W == bindingBeforeCombat, "combat activation mutated a binding")
assert(OctoPort.bindingMutationDeferred and OctoPort.pendingBindingOperation == "reconcile", "combat activation did not publish pending state")
inCombat = false
assert(OctoPort:RetryDeferredBindings(), "deferred activation did not retry after combat")
assert(bindings.W == "MOVEFORWARD" and OctoPort.sessionBindingsActive, "deferred activation left a partial session")
assert(not OctoPort.bindingMutationDeferred, "successful retry left stale pending state")

OctoPort.config.enabled = false
callsBeforeCombat = setBindingCount
inCombat = true
local deactivated, deactivationReason = OctoPort:DeactivateSessionBindings()
assert(deactivated == nil and deactivationReason == "deferred", "combat restore was not deferred")
assert(setBindingCount == callsBeforeCombat and bindings.W == "MOVEFORWARD", "combat restore partially changed the session")
inCombat = false
assert(OctoPort:RetryDeferredBindings(), "deferred restore did not retry after combat")
assert(bindings.W == bindingBeforeCombat and not OctoPort.sessionBindingsActive, "deferred restore did not recover the original binding")

-- A profile can become invalid while an enable request is waiting in combat.
-- The eventual hard failure must turn the desired state back OFF instead of
-- leaving an enabled flag and visible HUD with no installed gameplay layer.
OctoPort:ApplyRecommendedBindings()
VerifyConfiguredDirections()
OctoPort.config.controllerKeys.LSDOWN = OctoPort.config.controllerKeys.LSUP
OctoPort.config.directionVerifiedKeys.LSDOWN = OctoPort.config.controllerKeys.LSDOWN
OctoPort.config.enabled = true
inCombat = true
local invalidActivated, invalidActivationReason = OctoPort:ActivateSessionBindings()
assert(invalidActivated == nil and invalidActivationReason == "deferred", "invalid combat enable was not initially deferred")
inCombat = false
assert(OctoPort:RetryDeferredBindings() == false, "invalid deferred enable unexpectedly succeeded")
assert(OctoPort.config.enabled == false and not OctoPort.sessionBindingsActive, "failed deferred enable left the controller marked ON")
OctoPort:ApplyRecommendedBindings()
VerifyConfiguredDirections()

-- The recovery-menu layer follows the same rule and remains completely inert
-- in combat rather than triggering Blizzard's protected-action warning.
OctoPort.configFrame = { IsVisible = function() return true end }
callsBeforeCombat = setBindingCount
inCombat = true
local configActivated, configReason = OctoPort:ActivateConfigNavigationBindings()
assert(configActivated == nil and configReason == "deferred", "combat menu binding change was not deferred")
assert(setBindingCount == callsBeforeCombat, "combat menu activation mutated bindings")
inCombat = false
assert(OctoPort:RetryDeferredBindings(), "deferred menu bindings did not activate after combat")
assert(OctoPort.configNavigationBindingsActive, "deferred menu layer stayed inactive")
OctoPort:DeactivateConfigNavigationBindings()
OctoPort.configFrame = nil

-- Disabling during combat while Settings owns its nested navigation layer
-- must unwind both layers after combat. Reapplying Settings directly over the
-- stale gameplay layer would leave movement active after the menu closes.
local disableWhileOpenBaseline = bindings.W
OctoPort:ApplyRecommendedBindings()
VerifyConfiguredDirections()
OctoPort.config.enabled = true
assert(OctoPort:ActivateSessionBindings(), "open-settings disable fixture could not activate gameplay")
OctoPort.configFrame = { IsVisible = function() return true end }
assert(OctoPort:ActivateConfigNavigationBindings(), "open-settings disable fixture could not activate navigation")
inCombat = true
OctoPort.config.enabled = false
local openDeactivated, openDeactivateReason = OctoPort:DeactivateSessionBindings()
assert(openDeactivated == nil and openDeactivateReason == "deferred", "open-settings combat disable was not deferred")
inCombat = false
assert(OctoPort:RetryDeferredBindings(), "open-settings combat disable did not reconcile")
assert(not OctoPort.sessionBindingsActive, "combat disable left the gameplay layer active behind Settings")
assert(OctoPort.configNavigationBindingsActive, "combat disable did not preserve safe Settings navigation")
assert(bindings.W == disableWhileOpenBaseline, "combat disable left movement bound while only Settings should be active")
OctoPort.configFrame = nil
assert(OctoPort:DeactivateConfigNavigationBindings(), "closing Settings after combat disable failed")
assert(bindings.W == disableWhileOpenBaseline, "closing Settings after combat disable restored stale gameplay bindings")
assert(OctoPort.config.bindingRecoverySnapshot == nil, "combat disable left a stale recovery baseline")

-- A combat /reload destroys Lua-local session/config backups while the live
-- temporary bindings may remain installed. The plain SavedVariables snapshot
-- must survive a brand-new OctoPort table, win over deferred reconciliation,
-- and restore both nested layers exactly without SaveBindings.
bindings = {
  ["1"] = "OPENCHAT",
  ["2"] = "TOGGLEGAMEMENU",
  W = "OPENCHATSLASH",
  UP = "PREVIOUSACTIONPAGE",
  DOWN = "NEXTACTIONPAGE",
  LEFT = "CAMERAZOOMIN",
  RIGHT = "CAMERAZOOMOUT",
  ["SHIFT-1"] = "CHATBOTTOM",
  ["CTRL-1"] = "TOGGLECHARACTER0",
  F15 = "OCTOPORT_ACTION_A",
  F16 = "OCTOPORT_ACTION_A",
}
local reloadBaseline = {}
for key, command in pairs(bindings) do reloadBaseline[key] = command end
local savesBeforeReloadRecovery = saveCount

OctoPort:ApplyRecommendedBindings()
VerifyConfiguredDirections()
OctoPort.config.enabled = true
assert(OctoPort:ActivateSessionBindings(), "reload fixture could not activate gameplay bindings")
evictSecondOnNextBinding.OCTOPORT_ACTION_A = true
assert(OctoPort:ActivateConfigNavigationBindings(), "reload fixture could not activate nested Settings bindings")
assert(bindings.F16 == nil and bindings["1"] == "OCTOPORT_ACTION_A", "nested temporary layer fixture did not run")
assert(type(OctoPort.config.bindingRecoverySnapshot) == "table", "temporary mutation did not persist a recovery baseline")

inCombat = true
local logoutRecovered, logoutReason = OctoPort:RecoverPersistedBindingSnapshot()
assert(logoutRecovered == nil and logoutReason == "deferred", "combat logout recovery was not deferred")
assert(type(OctoPort.config.bindingRecoverySnapshot) == "table", "combat logout discarded the durable recovery baseline")
local reloadedConfig = OctoPort.config

-- Simulate /reload: only SavedVariables and WoW's live binding set survive.
OctoPort = { config = reloadedConfig }
function OctoPort:Print() end
dofile("Bindings.lua")
local earlyRecovery, earlyReason = OctoPort:RecoverPersistedBindingSnapshot()
assert(earlyRecovery == nil and earlyReason == "deferred", "new UI instance touched protected bindings during combat")
assert(type(OctoPort.config.bindingRecoverySnapshot) == "table", "new UI instance lost its recovery baseline")

-- The real startup opens Settings when recovery is waiting. After the exact
-- baseline has been recovered, controller navigation must be layered back on
-- so a gamepad-only user is not trapped in a non-responsive window.
OctoPort.configFrame = { IsVisible = function() return true end }

inCombat = false
assert(OctoPort:RetryDeferredBindings(), "persisted recovery did not retry after combat")
assert(not OctoPort.sessionBindingsActive, "combat-reload recovery unexpectedly re-enabled gameplay")
assert(OctoPort.configNavigationBindingsActive, "combat-reload recovery did not restore Settings navigation")
assert(bindings.W == reloadBaseline.W, "Settings navigation after recovery changed movement")
OctoPort.configFrame = nil
assert(OctoPort:DeactivateConfigNavigationBindings(), "closing recovered Settings navigation failed")
for key, command in pairs(reloadBaseline) do
  assert(bindings[key] == command, "reload recovery did not restore " .. key .. " exactly")
end
for key, command in pairs(bindings) do
  assert(reloadBaseline[key] == command, "reload recovery left temporary binding " .. key .. " -> " .. command)
end
assert(OctoPort.config.bindingRecoverySnapshot == nil, "successful exact recovery retained a stale snapshot")
assert(not OctoPort.sessionBindingsActive and not OctoPort.configNavigationBindingsActive, "reload recovery retained an active temporary layer")
assert(saveCount == savesBeforeReloadRecovery, "reload recovery persisted the live WoW binding set")

-- Structurally corrupt or unknown-version recovery data is never interpreted
-- as a binding map. It leaves both the live set and the evidence intact while
-- forcing the controller off for manual recovery.
local callsBeforeCorruptRecovery = setBindingCount
local bindingBeforeCorruptRecovery = bindings.W
OctoPort.config.enabled = true
OctoPort.config.bindingRecoverySnapshot = { version = 99, keys = {}, commands = {} }
assert(not OctoPort:RecoverPersistedBindingSnapshot(), "unknown recovery snapshot version was accepted")
assert(setBindingCount == callsBeforeCorruptRecovery and bindings.W == bindingBeforeCorruptRecovery, "corrupt recovery snapshot changed live bindings")
assert(OctoPort.config.enabled == false, "corrupt recovery snapshot did not force the controller off")
assert(type(OctoPort.config.bindingRecoverySnapshot) == "table", "corrupt recovery evidence was discarded")
OctoPort.config.bindingRecoverySnapshot = nil
OctoPort.config.lastBindingRecoveryError = nil
OctoPort.bindingRecoveryPending = nil

-- Migration is intentionally the sole persistent write. It repairs commands
-- saved by versions 0.1-0.4 and then leaves the addon disabled.
bindings.W = "OCTOPORT_MOVE_FORWARD"
bindings.F9 = "OCTOPORT_ACTION_A"
OctoPort.config.bindingBackup = { W = "MOVEFORWARD", F9 = "OPENCHAT" }
OctoPort.config.controllerKeys = {}
OctoPort.needsSafetyMigration = true
OctoPort.configFrame = { IsVisible = function() return true end }
callsBeforeCombat = setBindingCount
inCombat = true
local migrated, migrationReason = OctoPort:RecoverLegacyBindings()
assert(migrated == nil and migrationReason == "deferred", "combat migration was not deferred")
assert(setBindingCount == callsBeforeCombat and saveCount == 0, "combat migration touched the binding set")
inCombat = false
assert(OctoPort:RetryDeferredBindings(), "legacy migration did not retry after combat")
assert(bindings.W == "MOVEFORWARD", "migration did not restore movement")
assert(bindings.F9 == "OPENCHAT", "migration did not restore face-button key")
assert(saveCount == 1, "migration must persist exactly one repaired binding set")
assert(OctoPort.config.enabled == false, "migration must leave addon disabled")
assert(OctoPort.configNavigationBindingsActive, "visible Settings lost controller navigation after deferred emergency recovery")
OctoPort.configFrame = nil
assert(OctoPort:DeactivateConfigNavigationBindings(), "closing Settings after emergency recovery failed")
assert(bindings.W == "MOVEFORWARD" and bindings.F9 == "OPENCHAT", "Settings close changed the repaired persistent binding set")
assert(OctoPort.config.bindingRecoverySnapshot == nil, "emergency recovery navigation left a stale snapshot")

print("binding safety harness: OK")
