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
bindings["1"] = "OPENCHAT"
bindings.W = "OPENCHAT"
bindings.UP = "PREVIOUSACTIONPAGE"
bindings.BUTTON1 = "CAMERAORSELECTORMOVE"
bindings.BUTTON2 = "TURNORACTION"
OctoPort:ApplyRecommendedBindings()
assert(bindings["1"] == "OPENCHAT", "profile selection changed a live face-button binding")
assert(bindings.BUTTON1 == "CAMERAORSELECTORMOVE", "profile selection stole native left click")
assert(bindings.BUTTON2 == "TURNORACTION", "profile selection stole native right click")
assert(saveCount == 0, "normal profile selection persisted bindings")

-- Enabling applies a temporary command and disabling restores it exactly.
OctoPort.config.enabled = true
assert(OctoPort:ActivateSessionBindings(), "session profile did not activate")
assert(bindings["1"] == "ACTIONBUTTON1", "native A/action 1 binding missing")
assert(bindings.W == "MOVEFORWARD", "native forward binding missing")
assert(bindings.S == "MOVEBACKWARD", "native backward binding missing")
assert(bindings.A == "STRAFELEFT", "native left strafe binding missing")
assert(bindings.D == "STRAFERIGHT", "native right strafe binding missing")
assert(bindings.UP == "OCTOPORT_TARGET_UP", "D-pad targeting was not active beside movement")
assert(bindings.NUMLOCK == "TOGGLEAUTORUN", "native L3 autorun binding missing")
assert(bindings.SPACE == "JUMP", "native R3 jump binding missing")
assert(bindings.BUTTON1 == "CAMERAORSELECTORMOVE", "session activation stole native left click")
assert(bindings.BUTTON2 == "TURNORACTION", "session activation stole native right click")
assert(saveCount == 0, "session activation persisted bindings")
OctoPort:DeactivateSessionBindings()
assert(bindings["1"] == "OPENCHAT", "session cleanup did not restore original A binding")
assert(bindings.W == "OPENCHAT", "session cleanup did not restore original movement binding")
assert(bindings.UP == "PREVIOUSACTIONPAGE", "session cleanup did not restore original D-pad binding")
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
assert(bindings["1"] == "OPENCHAT", "menu-only mode activated unrelated face buttons")
assert(bindings.W == "OPENCHAT", "menu-only mode activated movement")
OctoPort:DeactivateSessionBindings()
assert(bindings.F4 == "TOGGLECHARACTER0", "quick menu key was not restored")

-- Updating a shared-arrow profile restores the intended direct layout. Stick
-- and D-pad bindings are active simultaneously and never share a key.
OctoPort.config.enabled = false
OctoPort.config.bindingVersion = 9
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
assert(OctoPort.config.arrowMovementFallback == false, "shared-arrow mode survived the upgrade")
assert(OctoPort.config.reticleEnabled == false, "reticle survived the direct-control upgrade")
OctoPort:RefreshSetupState()
OctoPort.config.enabled = true
assert(OctoPort:ActivateSessionBindings(), "direct-control profile did not activate")
assert(bindings.W == "MOVEFORWARD", "stick movement was not active")
assert(bindings.UP == "OCTOPORT_TARGET_UP", "D-pad targeting was not active simultaneously")
assert(bindings["1"] == "ACTIONBUTTON1" and bindings["4"] == "ACTIONBUTTON4", "native ABXY actions were not active")
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
bindings.ENTER = "OPENCHAT"
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
assert(bindings.ENTER == "OPENCHAT" and bindings.ESCAPE == "TOGGLEGAMEMENU", "captured A/B restore lost existing actions")
assert(bindings.F1 == "TOGGLECHARACTER0" and bindings.F2 == "TOGGLESPELLBOOK", "captured X/Y restore lost existing actions")
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
