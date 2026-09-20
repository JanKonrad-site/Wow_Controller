-- One-way safety bridge from WOW Controller 0.x to the native pass-through
-- profile. Normal gameplay never calls SetBinding or SaveBindings. These APIs
-- are used only when verifiable recovery evidence from an older release exists.

OctoPort = OctoPort or {}
OctoPort.basicMigrationVersion = 1

-- Keep every command shipped by versions 0.1-0.9.1 so users who skipped an
-- update can still remove an old persistent binding safely.
local legacyCommands = {
  "OCTOPORT_MOVE_FORWARD",
  "OCTOPORT_MOVE_BACKWARD",
  "OCTOPORT_MOVE_LEFT",
  "OCTOPORT_MOVE_RIGHT",
  "OCTOPORT_ACTION_A",
  "OCTOPORT_ACTION_B",
  "OCTOPORT_ACTION_X",
  "OCTOPORT_ACTION_Y",
  "OCTOPORT_RADIAL",
  "OCTOPORT_TARGET_UP",
  "OCTOPORT_TARGET_DOWN",
  "OCTOPORT_TARGET_LEFT",
  "OCTOPORT_TARGET_RIGHT",
  "OCTOPORT_LAYER_LB",
  "OCTOPORT_LAYER_LT",
  "OCTOPORT_LAYER_RT",
  "OCTOPORT_OPENCONFIG",
  "OCTOPORT_TOGGLEMODE",
  "OCTOPORT_REAR_M1",
  "OCTOPORT_REAR_M2",
  "OCTOPORT_TOGGLEBAGS",
  "OCTOPORT_TOGGLEHELP",
}

OctoPort.legacyCommands = legacyCommands

-- Bindings.xml keeps the historical command names discoverable for one bridge
-- release. Any key that fires before cleanup is intentionally a no-op.
function OctoPort_LegacyNoop()
end

BINDING_HEADER_OCTOPORT = "WOW Controller (legacy cleanup)"
BINDING_NAME_OCTOPORT_MOVE_FORWARD = "Legacy controller binding (inactive)"
BINDING_NAME_OCTOPORT_MOVE_BACKWARD = "Legacy controller binding (inactive)"
BINDING_NAME_OCTOPORT_MOVE_LEFT = "Legacy controller binding (inactive)"
BINDING_NAME_OCTOPORT_MOVE_RIGHT = "Legacy controller binding (inactive)"
BINDING_NAME_OCTOPORT_ACTION_A = "Legacy controller binding (inactive)"
BINDING_NAME_OCTOPORT_ACTION_B = "Legacy controller binding (inactive)"
BINDING_NAME_OCTOPORT_ACTION_X = "Legacy controller binding (inactive)"
BINDING_NAME_OCTOPORT_ACTION_Y = "Legacy controller binding (inactive)"
BINDING_NAME_OCTOPORT_RADIAL = "Legacy controller binding (inactive)"
BINDING_NAME_OCTOPORT_TARGET_UP = "Legacy controller binding (inactive)"
BINDING_NAME_OCTOPORT_TARGET_DOWN = "Legacy controller binding (inactive)"
BINDING_NAME_OCTOPORT_TARGET_LEFT = "Legacy controller binding (inactive)"
BINDING_NAME_OCTOPORT_TARGET_RIGHT = "Legacy controller binding (inactive)"
BINDING_NAME_OCTOPORT_LAYER_LB = "Legacy controller binding (inactive)"
BINDING_NAME_OCTOPORT_LAYER_LT = "Legacy controller binding (inactive)"
BINDING_NAME_OCTOPORT_LAYER_RT = "Legacy controller binding (inactive)"
BINDING_NAME_OCTOPORT_OPENCONFIG = "Legacy controller binding (inactive)"
BINDING_NAME_OCTOPORT_TOGGLEMODE = "Legacy controller binding (inactive)"
BINDING_NAME_OCTOPORT_REAR_M1 = "Legacy controller binding (inactive)"
BINDING_NAME_OCTOPORT_REAR_M2 = "Legacy controller binding (inactive)"
BINDING_NAME_OCTOPORT_TOGGLEBAGS = "Legacy controller binding (inactive)"
BINDING_NAME_OCTOPORT_TOGGLEHELP = "Legacy controller binding (inactive)"

local function CurrentBinding(key)
  if GetBindingAction then return GetBindingAction(key) or "" end
  return ""
end

local function IsLocked()
  if InCombatLockdown and InCombatLockdown() then return true end
  if UnitAffectingCombat and UnitAffectingCombat("player") then return true end
  return false
end

local function SetBindingChecked(key, command)
  if not key or key == "" or not SetBinding then return false, "unavailable" end
  if IsLocked() then return nil, "deferred" end
  local ok, result = pcall(SetBinding, key, command)
  if not ok or not result then return false, "rejected" end
  local expected = command or ""
  if GetBindingAction and CurrentBinding(key) ~= expected then return false, "verify" end
  return true
end

local function ClearCommand(command)
  local guard = 0
  while guard < 16 do
    local key1, key2
    if GetBindingKey then key1, key2 = GetBindingKey(command) end
    if not key1 and not key2 then return true end
    if key1 then
      local cleared, reason = SetBindingChecked(key1, nil)
      if not cleared then return cleared, reason end
    end
    if key2 and key2 ~= key1 then
      local cleared, reason = SetBindingChecked(key2, nil)
      if not cleared then return cleared, reason end
    end
    guard = guard + 1
  end
  local key1, key2
  if GetBindingKey then key1, key2 = GetBindingKey(command) end
  return not key1 and not key2, "verify"
end

local function NewSnapshot()
  return { version = 1, keys = {}, commands = {} }
end

local function SnapshotCommand(snapshot, command)
  if not snapshot or not command or command == "" or snapshot.commands[command] then return end
  snapshot.commands[command] = true
  local key1, key2
  if GetBindingKey then key1, key2 = GetBindingKey(command) end
  if key1 and snapshot.keys[key1] == nil then snapshot.keys[key1] = command end
  if key2 and snapshot.keys[key2] == nil then snapshot.keys[key2] = command end
end

local function SnapshotMutation(snapshot, key, command)
  if not snapshot or not key or key == "" then return end
  local current = CurrentBinding(key)
  SnapshotCommand(snapshot, current)
  if snapshot.keys[key] == nil then snapshot.keys[key] = current end
  SnapshotCommand(snapshot, command)
end

local function IsValidSnapshot(snapshot)
  if type(snapshot) ~= "table" or snapshot.version ~= 1 then return false end
  if type(snapshot.keys) ~= "table" or type(snapshot.commands) ~= "table" then return false end
  for key, command in pairs(snapshot.keys) do
    if type(key) ~= "string" or key == "" or type(command) ~= "string" then return false end
    if command ~= "" and snapshot.commands[command] ~= true then return false end
  end
  for command, captured in pairs(snapshot.commands) do
    if type(command) ~= "string" or command == "" or captured ~= true then return false end
  end
  return true
end

local function RestoreSnapshot(snapshot)
  if not IsValidSnapshot(snapshot) then return false, "corrupt" end
  if IsLocked() then return nil, "deferred" end

  for command in pairs(snapshot.commands) do
    local cleared, reason = ClearCommand(command)
    if not cleared then return cleared, reason end
  end
  for key in pairs(snapshot.keys) do
    if CurrentBinding(key) ~= "" then
      local cleared, reason = SetBindingChecked(key, nil)
      if not cleared then return cleared, reason end
    end
  end
  for key, command in pairs(snapshot.keys) do
    if command ~= "" then
      local restored, reason = SetBindingChecked(key, command)
      if not restored then return restored, reason end
    end
  end
  for key, command in pairs(snapshot.keys) do
    if CurrentBinding(key) ~= command then return false, "verify" end
  end
  return true
end

local function HasTableEntries(value)
  if type(value) ~= "table" then return false end
  for _ in pairs(value) do return true end
  return false
end

local function IsValidLegacyBackup(backup)
  if backup == nil then return true end
  if type(backup) ~= "table" then return false end
  for key, command in pairs(backup) do
    if type(key) ~= "string" or key == "" or type(command) ~= "string" then return false end
  end
  return true
end

local function HasLegacyBindings()
  if not GetBindingKey then return false end
  for index = 1, table.getn(legacyCommands) do
    local key1, key2 = GetBindingKey(legacyCommands[index])
    if key1 or key2 then return true end
  end
  return false
end

local function RollBack(snapshot)
  if IsValidSnapshot(snapshot) and not IsLocked() then RestoreSnapshot(snapshot) end
end

function OctoPort:RunLegacyCleanup()
  local config = self.config or OctoPortConfig
  if type(config) ~= "table" then
    config = {}
    OctoPortConfig = config
    self.config = config
  end

  config.enabled = false
  config.autoTarget = false
  config.autoAcceptQuests = false

  local recovery = config.bindingRecoverySnapshot
  local backup = config.bindingBackup
  local markerComplete = (tonumber(config.basicMigrationVersion) or 0) >= self.basicMigrationVersion

  if not IsValidLegacyBackup(backup) then
    config.lastBindingRecoveryError = "corrupt legacy backup"
    return false, "corrupt", false
  end

  -- A completed clean profile is fully inert on every later login. Do not even
  -- probe the binding API unless new recovery evidence somehow appears.
  if markerComplete and recovery == nil and not HasTableEntries(backup) then
    return true, nil, false
  end

  local changed = false
  if recovery ~= nil then
    if not IsValidSnapshot(recovery) then
      config.lastBindingRecoveryError = "corrupt snapshot"
      return false, "corrupt", false
    end
    local restored, reason = RestoreSnapshot(recovery)
    if not restored then
      config.lastBindingRecoveryError = reason or "restore failed"
      return restored, reason, false
    end
    -- Keep the durable snapshot until the entire migration, including any
    -- persistent legacy cleanup below, succeeds. If SetBinding/SaveBindings
    -- fails later, the next login can replay the exact v0.9 baseline.
    config.lastBindingRecoveryError = nil
    changed = true
  end

  local persistentWork = HasTableEntries(backup) or HasLegacyBindings()
  if persistentWork then
    if IsLocked() then return nil, "deferred", changed end

    local rollback = NewSnapshot()
    for index = 1, table.getn(legacyCommands) do
      SnapshotCommand(rollback, legacyCommands[index])
    end
    if type(backup) == "table" then
      for key, command in pairs(backup) do SnapshotMutation(rollback, key, command) end
    end

    for index = 1, table.getn(legacyCommands) do
      local cleared, reason = ClearCommand(legacyCommands[index])
      if not cleared then
        RollBack(rollback)
        config.lastBindingRecoveryError = reason or "legacy cleanup failed"
        return cleared, reason, changed
      end
    end

    if type(backup) == "table" then
      for key, command in pairs(backup) do
        local restored, reason = SetBindingChecked(key, command ~= "" and command or nil)
        if not restored then
          RollBack(rollback)
          config.lastBindingRecoveryError = reason or "legacy backup failed"
          return restored, reason, changed
        end
      end
      for key, command in pairs(backup) do
        if CurrentBinding(key) ~= command then
          RollBack(rollback)
          config.lastBindingRecoveryError = "legacy verification failed"
          return false, "verify", changed
        end
      end
    end

    if SaveBindings then
      local bindingSet = GetCurrentBindingSet and GetCurrentBindingSet() or 1
      local ok = pcall(SaveBindings, bindingSet)
      if not ok then
        RollBack(rollback)
        config.lastBindingRecoveryError = "persistent cleanup failed"
        return false, "save", changed
      end
    else
      RollBack(rollback)
      config.lastBindingRecoveryError = "SaveBindings unavailable"
      return false, "unavailable", changed
    end
    changed = true
  end

  -- Drop every obsolete feature setting only after all recovery work succeeds.
  local cleanConfig = {
    basicMigrationVersion = self.basicMigrationVersion,
    profile = "native-pass-through",
  }
  self.sessionBindingBackup = nil
  self.configNavigationBindingBackup = nil
  self.sessionBindingsActive = false
  self.configNavigationBindingsActive = false
  OctoPortConfig = cleanConfig
  self.config = cleanConfig
  self.cleanupPending = nil
  return true, nil, changed
end
