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

-- Existing 0.5 profiles gain safe left-stick defaults without touching the
-- live or persisted WoW binding set.
OctoPort:EnsureMovementDefaults()
assert(OctoPort.config.controllerKeys.LSUP == "W", "forward movement default missing")
assert(OctoPort.config.controllerKeys.LSDOWN == "S", "backward movement default missing")
assert(OctoPort.config.controllerKeys.LSLEFT == "A", "left strafe default missing")
assert(OctoPort.config.controllerKeys.LSRIGHT == "D", "right strafe default missing")
assert(saveCount == 0, "movement defaults persisted bindings")

-- Setup stores a profile but must not touch or persist WoW bindings.
bindings.F9 = "OPENCHAT"
bindings.W = "OPENCHAT"
OctoPort:ApplyRecommendedBindings()
assert(bindings.F9 == "OPENCHAT", "profile selection changed a live binding")
assert(saveCount == 0, "normal profile selection persisted bindings")

-- Enabling applies a temporary command and disabling restores it exactly.
OctoPort.config.enabled = true
assert(OctoPort:ActivateSessionBindings(), "session profile did not activate")
assert(bindings.F9 == "OCTOPORT_ACTION_A", "temporary A binding missing")
assert(bindings.W == "MOVEFORWARD", "native forward binding missing")
assert(bindings.S == "MOVEBACKWARD", "native backward binding missing")
assert(bindings.A == "STRAFELEFT", "native left strafe binding missing")
assert(bindings.D == "STRAFERIGHT", "native right strafe binding missing")
assert(saveCount == 0, "session activation persisted bindings")
OctoPort:DeactivateSessionBindings()
assert(bindings.F9 == "OPENCHAT", "session cleanup did not restore original A binding")
assert(bindings.W == "OPENCHAT", "session cleanup did not restore original movement binding")
assert(bindings.S == nil and bindings.A == nil and bindings.D == nil, "session cleanup left native movement bindings behind")
assert(saveCount == 0, "session cleanup persisted bindings")

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
