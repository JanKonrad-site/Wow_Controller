-- Minimal binding API harness. It verifies the safety contract without a WoW
-- client; visual/API compatibility is covered separately by in-game testing.

local bindings = {}
local saveCount = 0

function GetBindingAction(key)
  return bindings[key] or ""
end

function GetBindingKey(command)
  local first = nil
  local second = nil
  for key, action in pairs(bindings) do
    if action == command then
      if not first then first = key elseif not second then second = key end
    end
  end
  return first, second
end

function SetBinding(key, command)
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
    nativeModifiers = { SHIFT = "shift", CTRL = "ctrl" },
    rearActions = { M1 = "settings", M2 = "interact" },
  },
}

function OctoPort:Print() end

dofile("Bindings.lua")

-- Existing profiles gain safe left-stick and complete ROG Ally defaults
-- without touching the live or persisted WoW binding set.
OctoPort:EnsureMovementDefaults()
assert(OctoPort.config.controllerKeys.LSUP == "W", "forward movement default missing")
assert(OctoPort.config.controllerKeys.LSDOWN == "S", "backward movement default missing")
assert(OctoPort.config.controllerKeys.LSLEFT == "A", "left strafe default missing")
assert(OctoPort.config.controllerKeys.LSRIGHT == "D", "right strafe default missing")
assert(OctoPort.config.controllerKeys.RB == "BUTTON1", "native RB default missing")
assert(OctoPort.config.controllerKeys.RT == "BUTTON2", "native RT default missing")
assert(OctoPort.config.controllerKeys.L3 == "NUMLOCK", "L3 default missing")
assert(OctoPort.config.controllerKeys.R3 == "SPACE", "R3 default missing")
assert(saveCount == 0, "movement defaults persisted bindings")

-- Setup stores a profile but must not touch or persist WoW bindings.
bindings.F9 = "OPENCHAT"
bindings.W = "OPENCHAT"
bindings.BUTTON1 = "CAMERAORSELECTORMOVE"
bindings.BUTTON2 = "TURNORACTION"
OctoPort:ApplyRecommendedBindings()
assert(bindings.F9 == "OPENCHAT", "profile selection changed a live binding")
assert(bindings.BUTTON1 == "CAMERAORSELECTORMOVE", "profile selection stole native left click")
assert(bindings.BUTTON2 == "TURNORACTION", "profile selection stole native right click")
assert(saveCount == 0, "normal profile selection persisted bindings")

-- Enabling applies a temporary command and disabling restores it exactly.
OctoPort.config.enabled = true
assert(OctoPort:ActivateSessionBindings(), "session profile did not activate")
assert(bindings.F9 == "OCTOPORT_ACTION_A", "temporary A binding missing")
assert(bindings.W == "MOVEFORWARD", "native forward binding missing")
assert(bindings.S == "MOVEBACKWARD", "native backward binding missing")
assert(bindings.A == "STRAFELEFT", "native left strafe binding missing")
assert(bindings.D == "STRAFERIGHT", "native right strafe binding missing")
assert(bindings.NUMLOCK == "TOGGLEAUTORUN", "native L3 autorun binding missing")
assert(bindings.SPACE == "JUMP", "native R3 jump binding missing")
assert(bindings.BUTTON1 == "CAMERAORSELECTORMOVE", "session activation stole native left click")
assert(bindings.BUTTON2 == "TURNORACTION", "session activation stole native right click")
assert(saveCount == 0, "session activation persisted bindings")
OctoPort:DeactivateSessionBindings()
assert(bindings.F9 == "OPENCHAT", "session cleanup did not restore original A binding")
assert(bindings.W == "OPENCHAT", "session cleanup did not restore original movement binding")
assert(bindings.S == nil and bindings.A == nil and bindings.D == nil, "session cleanup left native movement bindings behind")
assert(bindings.NUMLOCK == nil and bindings.SPACE == nil, "session cleanup left stick-click bindings behind")
assert(bindings.BUTTON1 == "CAMERAORSELECTORMOVE", "session cleanup changed native left click")
assert(bindings.BUTTON2 == "TURNORACTION", "session cleanup changed native right click")
assert(saveCount == 0, "session cleanup persisted bindings")

-- Duplicate device signals are surfaced instead of silently looking valid.
OctoPort.config.enabled = false
assert(OctoPort:BindControllerKey("DUP", "W"), "duplicate input capture failed")
assert(OctoPort.config.controllerKeys.LSUP == nil, "duplicate signal still owns two controls")
assert(OctoPort.config.lastBindingCollision and OctoPort.config.lastBindingCollision.previous == "LSUP", "duplicate signal was not reported")
OctoPort:ApplyRecommendedBindings()
assert(OctoPort.config.lastBindingCollision == nil, "preset did not clear old collision warning")

-- A working raw key can enable a menu-only session without activating the
-- rest of an incomplete controller profile.
bindings.F4 = "TOGGLECHARACTER0"
OctoPort.config.enabled = false
assert(OctoPort:SetQuickMenuKey("F4"), "quick menu key was rejected")
assert(OctoPort.config.menuOnlyMode == true, "quick menu did not use menu-only safety mode")
assert(bindings.F4 == "OCTOPORT_OPENCONFIG", "quick menu binding was not activated")
assert(bindings.F9 == "OPENCHAT", "menu-only mode activated unrelated face buttons")
assert(bindings.W == "OPENCHAT", "menu-only mode activated movement")
OctoPort:DeactivateSessionBindings()
assert(bindings.F4 == "TOGGLECHARACTER0", "quick menu key was not restored")

-- Shared-arrow mode makes an arrow-emitting stick usable immediately and
-- safely switches the same four signals between movement and targeting.
bindings.UP = "PREVIOUSACTIONPAGE"
bindings.ESCAPE = "TOGGLEGAMEMENU"
OctoPort.config.enabled = false
OctoPort:ApplyArrowMovementFallback()
assert(OctoPort.config.arrowInputMode == "movement", "arrow fallback did not start in movement mode")
assert(bindings.UP == "MOVEFORWARD", "arrow fallback did not bind forward movement")
assert(bindings.DOWN == "MOVEBACKWARD", "arrow fallback did not bind backward movement")
assert(bindings.LEFT == "STRAFELEFT" and bindings.RIGHT == "STRAFERIGHT", "arrow fallback did not bind strafing")
assert(bindings.ESCAPE == "OCTOPORT_OPENCONFIG", "arrow fallback did not provide a menu key")
assert(OctoPort.config.controllerKeys.DUP == nil and OctoPort.config.controllerKeys.DDOWN == nil, "arrow fallback left conflicting D-pad targets")
assert(OctoPort.config.setupComplete == true, "arrow fallback was marked incomplete")

assert(OctoPort:ToggleArrowInputMode(), "shared arrows did not switch to targeting")
assert(OctoPort.config.arrowInputMode == "target", "target mode was not stored")
assert(bindings.UP == "OCTOPORT_TARGET_UP" and bindings.DOWN == "OCTOPORT_TARGET_DOWN", "vertical friend targeting was not bound")
assert(bindings.LEFT == "OCTOPORT_TARGET_LEFT" and bindings.RIGHT == "OCTOPORT_TARGET_RIGHT", "horizontal enemy targeting was not bound")
assert(OctoPort:ToggleArrowInputMode(), "shared arrows did not switch back to movement")
assert(bindings.UP == "MOVEFORWARD" and bindings.LEFT == "STRAFELEFT", "movement mode was not restored")

bindings.F3 = "TOGGLEWORLDMAP"
assert(OctoPort:SetQuickModeKey("F3"), "quick mode key was rejected")
assert(bindings.F3 == "OCTOPORT_TOGGLEMODE", "quick mode key was not activated")
assert(OctoPort:SetQuickModeKey("UP") == false, "a shared arrow was accepted as its own mode switch")
OctoPort:DeactivateSessionBindings()
assert(bindings.UP == "PREVIOUSACTIONPAGE", "arrow fallback did not restore original arrow binding")
assert(bindings.ESCAPE == "TOGGLEGAMEMENU", "arrow fallback did not restore Escape")
assert(bindings.F3 == "TOGGLEWORLDMAP", "quick mode key did not restore its original action")
assert(saveCount == 0, "fallback modes persisted bindings")

-- The optional ABXY preset uses Blizzard's native action-button commands and
-- restores whatever was assigned to 1-4 before the controller session.
bindings["1"] = "BONUSACTIONBUTTON1"
bindings["2"] = "BONUSACTIONBUTTON2"
OctoPort.config.enabled = false
OctoPort:ApplyNativeFaceButtons()
OctoPort.config.enabled = true
assert(OctoPort:ActivateSessionBindings(), "native face-button profile did not activate")
assert(bindings["1"] == "ACTIONBUTTON1" and bindings["2"] == "ACTIONBUTTON2", "A/B did not map to native action buttons 1/2")
assert(bindings["3"] == "ACTIONBUTTON3" and bindings["4"] == "ACTIONBUTTON4", "X/Y did not map to native action buttons 3/4")
OctoPort:DeactivateSessionBindings()
assert(bindings["1"] == "BONUSACTIONBUTTON1" and bindings["2"] == "BONUSACTIONBUTTON2", "native AB restore lost existing actions")
assert(bindings["3"] == nil and bindings["4"] == nil, "native XY restore left temporary actions behind")
assert(saveCount == 0, "native face-button profile persisted bindings")

-- Migration is intentionally the sole persistent write. It repairs commands
-- saved by versions 0.1-0.4 and then leaves the addon disabled.
bindings.W = "OCTOPORT_MOVE_FORWARD"
bindings.F9 = "OCTOPORT_ACTION_A"
OctoPort.config.bindingBackup = { W = "MOVEFORWARD", F9 = "OPENCHAT" }
OctoPort.config.controllerKeys = {}
OctoPort.needsSafetyMigration = true
assert(OctoPort:RecoverLegacyBindings(), "legacy migration did not run")
assert(bindings.W == "MOVEFORWARD", "migration did not restore movement")
assert(bindings.F9 == "OPENCHAT", "migration did not restore face-button key")
assert(saveCount == 1, "migration must persist exactly one repaired binding set")
assert(OctoPort.config.enabled == false, "migration must leave addon disabled")

print("binding safety harness: OK")
