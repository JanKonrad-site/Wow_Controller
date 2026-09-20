-- Contract test for the cleanup-only/basic controller release.
--
-- The addon must never translate controller input at runtime. Armoury Crate,
-- Steam Input, or another device mapper emits ordinary keyboard keys and WoW
-- consumes those keys through its own action bar and movement bindings. The
-- only permitted binding mutation is the one-time repair of data persisted by
-- older WOW Controller releases.

local function ReadFile(path)
  local handle = assert(io.open(path, "rb"), "missing " .. path)
  local contents = handle:read("*a")
  handle:close()
  return contents
end

local toc = ReadFile("Wow_Controller.toc")
local runtimeFiles = {}
for line in string.gfind(toc, "[^\r\n]+") do
  line = string.gsub(line, "^%s+", "")
  line = string.gsub(line, "%s+$", "")
  if line ~= "" and string.sub(line, 1, 2) ~= "##" and string.sub(line, -4) == ".lua" then
    table.insert(runtimeFiles, line)
  end
end

assert(table.getn(runtimeFiles) == 2 and runtimeFiles[1] == "Cleanup.lua" and runtimeFiles[2] == "Core.lua",
  "basic release TOC must load only Cleanup.lua and Core.lua")

local forbiddenModules = { "Bindings.lua", "UI.lua", "Menu.lua", "Radial.lua", "Quest.lua", "Loot.lua" }
for index = 1, table.getn(forbiddenModules) do
  assert(not string.find(toc, forbiddenModules[index], 1, true),
    "basic release still loads " .. forbiddenModules[index])
end

local protectedCalls = {
  "UseAction", "CastSpell", "CastSpellByName", "UseContainerItem", "AcceptQuest",
  "TargetNearestEnemy", "TargetNearestFriend", "MoveForwardStart", "MoveForwardStop",
  "MoveBackwardStart", "MoveBackwardStop", "StrafeLeftStart", "StrafeLeftStop",
  "StrafeRightStart", "StrafeRightStop", "TurnOrActionStart", "TurnOrActionStop",
  "ToggleAutoRun", "Jump", "PickupAction", "PlaceAction",
}
local frameCreationCount = 0
for index = 1, table.getn(runtimeFiles) do
  local path = runtimeFiles[index]
  local source = ReadFile(path)
  -- Avoid making harmless comments part of the executable-code contract.
  local executable = string.gsub(source, "%-%-[^\r\n]*", "")
  for callIndex = 1, table.getn(protectedCalls) do
    local call = protectedCalls[callIndex]
    assert(not string.find(executable, call .. "%s*%(") ,
      path .. " calls protected gameplay API " .. call)
  end
  if path ~= "Cleanup.lua" then
    assert(not string.find(executable, "SetBinding%s*%(") and
      not string.find(executable, "SaveBindings%s*%(") and
      not string.find(executable, "SetBindingClick%s*%(") and
      not string.find(executable, "SetOverrideBinding"),
      path .. " contains runtime binding mutation")
  end
  local _, count = string.gsub(executable, "CreateFrame%s*%(", "")
  frameCreationCount = frameCreationCount + count
  assert(not string.find(executable, "Minimap", 1, true), path .. " contains minimap UI")
  assert(not string.find(executable, "CreateTexture%s*%(") and
    not string.find(executable, "CreateFontString%s*%(") and
    not string.find(executable, 'CreateFrame%s*%(%s*"Button"') and
    not string.find(executable, "CreateFrame%s*%(%s*'Button'"),
    path .. " creates controller UI")
end
assert(frameCreationCount <= 1,
  "basic runtime may create at most one invisible event dispatcher frame")

-- Vanilla discovers Bindings.xml automatically. Historical binding names may
-- remain for one migration release, but every body must be the same inert
-- cleanup bridge rather than an action, target, movement, or UI callback.
local bindingsXml = ReadFile("Bindings.xml")
local xmlBindingCount = 0
for line in string.gfind(bindingsXml, "[^\r\n]+") do
  if string.find(line, "<Binding ", 1, true) then
    xmlBindingCount = xmlBindingCount + 1
    assert(string.find(line, ">OctoPort_LegacyNoop()</Binding>", 1, true),
      "Bindings.xml contains an active legacy callback")
  end
end
assert(xmlBindingCount > 0, "Bindings.xml no longer exposes legacy names for one-time cleanup")

local directBindings = {
  ["1"] = "ACTIONBUTTON1",
  ["2"] = "ACTIONBUTTON2",
  ["3"] = "ACTIONBUTTON3",
  ["4"] = "ACTIONBUTTON4",
  ["5"] = "ACTIONBUTTON5",
  ["6"] = "ACTIONBUTTON6",
  ["7"] = "ACTIONBUTTON7",
  ["8"] = "ACTIONBUTTON8",
  ["9"] = "ACTIONBUTTON9",
  ["0"] = "ACTIONBUTTON10",
  ["-"] = "ACTIONBUTTON11",
  ["="] = "ACTIONBUTTON12",
  W = "MOVEFORWARD",
  S = "MOVEBACKWARD",
  A = "STRAFELEFT",
  D = "STRAFERIGHT",
}

local bindings = {}
local setBindingCount = 0
local saveBindingsCount = 0
local inCombat = false
local rejectNextSet = false
local rejectNextSave = false

local function CopyMap(source)
  local result = {}
  for key, value in pairs(source or {}) do result[key] = value end
  return result
end

local function AssertDirectBindings(message)
  for key, command in pairs(directBindings) do
    assert(bindings[key] == command,
      message .. ": changed direct key " .. key .. " from " .. command .. " to " .. tostring(bindings[key]))
  end
end

local function AssertNoLegacyCommands(message)
  for key, command in pairs(bindings) do
    assert(type(command) ~= "string" or string.sub(command, 1, 9) ~= "OCTOPORT_",
      message .. ": left " .. key .. " -> " .. tostring(command))
  end
end

function GetBindingAction(key)
  return bindings[key] or ""
end

function GetBindingKey(command)
  local keys = {}
  for key, action in pairs(bindings) do
    if action == command then table.insert(keys, key) end
  end
  table.sort(keys)
  return keys[1], keys[2]
end

function SetBinding(key, command)
  assert(not inCombat, "SetBinding was called in combat")
  setBindingCount = setBindingCount + 1
  if rejectNextSet then
    rejectNextSet = false
    return nil
  end
  if command and bindings[key] ~= command then
    local key1, key2 = GetBindingKey(command)
    -- Vanilla retains at most two keys for one command. This makes recovery
    -- tests catch ordering that would silently evict one of the player's keys.
    if key1 and key2 and key ~= key1 and key ~= key2 then bindings[key2] = nil end
  end
  bindings[key] = command
  return 1
end

function SaveBindings()
  assert(not inCombat, "SaveBindings was called in combat")
  saveBindingsCount = saveBindingsCount + 1
  if rejectNextSave then
    rejectNextSave = false
    error("simulated SaveBindings failure")
  end
  return 1
end

function GetCurrentBindingSet() return 2 end
function InCombatLockdown() return inCombat end
function UnitAffectingCombat(unit) return unit == "player" and inCombat end

-- Cleanup code must never execute gameplay or UI actions. Keep these mocks as
-- hard failures so a future convenience feature cannot silently reintroduce
-- taint/protected-action failures.
local function Forbidden(name)
  return function() error(name .. " is forbidden in the basic runtime") end
end

UseAction = Forbidden("UseAction")
CastSpell = Forbidden("CastSpell")
CastSpellByName = Forbidden("CastSpellByName")
UseContainerItem = Forbidden("UseContainerItem")
AcceptQuest = Forbidden("AcceptQuest")
TargetNearestEnemy = Forbidden("TargetNearestEnemy")
TargetNearestFriend = Forbidden("TargetNearestFriend")
MoveForwardStart = Forbidden("MoveForwardStart")
MoveForwardStop = Forbidden("MoveForwardStop")
MoveBackwardStart = Forbidden("MoveBackwardStart")
MoveBackwardStop = Forbidden("MoveBackwardStop")
StrafeLeftStart = Forbidden("StrafeLeftStart")
StrafeLeftStop = Forbidden("StrafeLeftStop")
StrafeRightStart = Forbidden("StrafeRightStart")
StrafeRightStop = Forbidden("StrafeRightStop")
TurnOrActionStart = Forbidden("TurnOrActionStart")
TurnOrActionStop = Forbidden("TurnOrActionStop")
ToggleAutoRun = Forbidden("ToggleAutoRun")
Jump = Forbidden("Jump")

local function LoadCleanup(config, liveBindings)
  OctoPortConfig = config
  OctoPort = { config = config }
  bindings = CopyMap(liveBindings)
  setBindingCount = 0
  saveBindingsCount = 0
  inCombat = false
  rejectNextSet = false
  rejectNextSave = false
  dofile("Cleanup.lua")
  assert(type(OctoPort.RunLegacyCleanup) == "function",
    "Cleanup.lua must expose OctoPort:RunLegacyCleanup()")
end

local function RunCleanup()
  return OctoPort:RunLegacyCleanup()
end

-- Fresh/basic installs are inert. Even the first marker upgrade must not call
-- either binding mutation API when there is no old damage to repair.
LoadCleanup({ enabled = true }, directBindings)
assert(RunCleanup() == true, "fresh-install cleanup did not finish")
assert(OctoPort.config.basicMigrationVersion == 1, "fresh install did not record cleanup marker")
assert(not OctoPort.config.enabled, "old runtime-enabled flag survived basic migration")
assert(setBindingCount == 0 and saveBindingsCount == 0,
  "fresh install mutated or persisted bindings")
AssertDirectBindings("fresh install")

local freshSetCount, freshSaveCount = setBindingCount, saveBindingsCount
assert(RunCleanup() == true, "marker-complete cleanup was not idempotent")
assert(setBindingCount == freshSetCount and saveBindingsCount == freshSaveCount,
  "normal repeated startup mutated bindings")
AssertDirectBindings("repeated startup")

-- Persisted bindings from old releases are repaired exactly once. Unbacked
-- OCTOPORT commands are removed, backed keys are restored, and direct native
-- action/movement keys remain entirely owned by Blizzard.
local dirtyBindings = CopyMap(directBindings)
dirtyBindings.F8 = "OCTOPORT_RADIAL"
dirtyBindings.F9 = "OCTOPORT_ACTION_A"
dirtyBindings.F10 = "OCTOPORT_MOVE_FORWARD"
LoadCleanup({
  enabled = true,
  bindingBackup = { F8 = "TOGGLEWORLDMAP", F9 = "OPENCHAT" },
}, dirtyBindings)
assert(RunCleanup() == true, "legacy cleanup failed")
assert(bindings.F8 == "TOGGLEWORLDMAP" and bindings.F9 == "OPENCHAT",
  "legacy backup was not restored")
assert(bindings.F10 == nil, "unbacked legacy command was not removed")
assert(OctoPort.config.bindingBackup == nil, "successful cleanup retained old bindingBackup")
assert(OctoPort.config.basicMigrationVersion == 1, "successful cleanup did not advance marker")
assert(saveBindingsCount == 1, "damaged persistent bindings must be saved exactly once")
AssertDirectBindings("legacy cleanup")
AssertNoLegacyCommands("legacy cleanup")

local migratedMap = CopyMap(bindings)
local migratedSetCount, migratedSaveCount = setBindingCount, saveBindingsCount
assert(RunCleanup() == true, "completed legacy cleanup was not idempotent")
assert(setBindingCount == migratedSetCount and saveBindingsCount == migratedSaveCount,
  "completed cleanup ran binding APIs a second time")
for key, command in pairs(migratedMap) do
  assert(bindings[key] == command, "completed cleanup changed " .. key)
end

-- A v0.9.x crash-recovery snapshot has priority over the older persistent
-- backup. The exact pre-addon map is rebuilt before the repaired set is saved.
local interruptedBindings = CopyMap(directBindings)
interruptedBindings["1"] = "OCTOPORT_ACTION_A"
interruptedBindings.F13 = "ACTIONBUTTON1"
interruptedBindings.F8 = "OCTOPORT_RADIAL"
interruptedBindings.W = "OCTOPORT_MOVE_FORWARD"
local recoverySnapshot = {
  version = 1,
  keys = {
    ["1"] = "ACTIONBUTTON1",
    F13 = "ACTIONBUTTON1",
  },
  commands = {
    ACTIONBUTTON1 = true,
    OCTOPORT_ACTION_A = true,
  },
}
LoadCleanup({
  enabled = true,
  bindingRecoverySnapshot = recoverySnapshot,
  bindingBackup = { W = "MOVEFORWARD", F8 = "TOGGLEWORLDMAP" },
}, interruptedBindings)
assert(RunCleanup() == true, "combined recovery and legacy cleanup failed")
assert(OctoPort.config.bindingRecoverySnapshot == nil, "successful recovery retained snapshot")
assert(bindings["1"] == "ACTIONBUTTON1" and bindings.F13 == "ACTIONBUTTON1",
  "two-key command recovery was not exact")
assert(bindings.W == "MOVEFORWARD" and bindings.F8 == "TOGGLEWORLDMAP",
  "legacy backup did not run after snapshot recovery")
assert(saveBindingsCount == 1, "combined recovery persisted more than once")
AssertDirectBindings("combined recovery")
AssertNoLegacyCommands("combined recovery")

-- Protected cleanup is deferred atomically. Neither evidence nor completion
-- markers may be discarded until the retry can really repair the binding set.
dirtyBindings = CopyMap(directBindings)
dirtyBindings.F8 = "OCTOPORT_RADIAL"
LoadCleanup({ bindingBackup = { F8 = "TOGGLEWORLDMAP" } }, dirtyBindings)
inCombat = true
local deferred, reason = RunCleanup()
assert(deferred ~= true and (reason == "deferred" or OctoPort.cleanupDeferred),
  "combat cleanup did not report deferral")
assert(setBindingCount == 0 and saveBindingsCount == 0, "combat cleanup touched protected APIs")
assert(OctoPort.config.basicMigrationVersion ~= 1, "combat cleanup advanced completion marker")
assert(type(OctoPort.config.bindingBackup) == "table", "combat cleanup discarded backup evidence")
inCombat = false
assert(RunCleanup() == true, "deferred cleanup did not succeed after combat")
assert(bindings.F8 == "TOGGLEWORLDMAP" and saveBindingsCount == 1,
  "deferred cleanup did not repair and persist once")

-- Unknown snapshot formats are never guessed or deleted. This is safer than
-- replacing a player's mappings with a partially interpreted recovery map.
local corruptSnapshot = { version = 99, keys = {}, commands = {} }
LoadCleanup({ bindingRecoverySnapshot = corruptSnapshot }, directBindings)
assert(RunCleanup() ~= true, "unknown recovery snapshot version was accepted")
assert(OctoPort.config.bindingRecoverySnapshot == corruptSnapshot,
  "unknown recovery evidence was discarded")
assert(OctoPort.config.basicMigrationVersion ~= 1,
  "unknown recovery snapshot advanced migration marker")
assert(setBindingCount == 0 and saveBindingsCount == 0,
  "unknown recovery snapshot mutated bindings")
AssertDirectBindings("unknown recovery snapshot")

-- A malformed older persistent backup is also evidence, not permission to
-- guess. Preserve it and leave the clean marker unset.
local corruptBackup = "not-a-key-map"
LoadCleanup({ bindingBackup = corruptBackup }, directBindings)
assert(RunCleanup() ~= true, "malformed legacy backup was accepted")
assert(OctoPort.config.bindingBackup == corruptBackup,
  "malformed legacy backup was discarded")
assert(OctoPort.config.basicMigrationVersion ~= 1,
  "malformed legacy backup advanced migration marker")
assert(setBindingCount == 0 and saveBindingsCount == 0,
  "malformed legacy backup mutated bindings")

-- A rejected binding write is not success. The backup and marker must remain
-- available for a later retry, and no half-repair may be persisted.
dirtyBindings = CopyMap(directBindings)
dirtyBindings.F8 = "OCTOPORT_RADIAL"
dirtyBindings.M = "TOGGLEWORLDMAP"
dirtyBindings["SHIFT-M"] = "TOGGLEWORLDMAP"
LoadCleanup({ bindingBackup = { F8 = "TOGGLEWORLDMAP" } }, dirtyBindings)
rejectNextSet = true
assert(RunCleanup() ~= true, "rejected SetBinding was reported as success")
assert(OctoPort.config.basicMigrationVersion ~= 1, "failed cleanup advanced marker")
assert(type(OctoPort.config.bindingBackup) == "table", "failed cleanup discarded backup")
assert(saveBindingsCount == 0, "failed cleanup persisted a partial repair")
assert(bindings.M == "TOGGLEWORLDMAP" and bindings["SHIFT-M"] == "TOGGLEWORLDMAP",
  "failed cleanup rollback lost a command's secondary key")

-- A persistence failure rolls the live map back and likewise leaves all
-- recovery evidence available for the next login.
dirtyBindings = CopyMap(directBindings)
dirtyBindings.F8 = "OCTOPORT_RADIAL"
LoadCleanup({ bindingBackup = { F8 = "TOGGLEWORLDMAP" } }, dirtyBindings)
rejectNextSave = true
assert(RunCleanup() ~= true, "failed SaveBindings was reported as success")
assert(OctoPort.config.basicMigrationVersion ~= 1, "save failure advanced marker")
assert(type(OctoPort.config.bindingBackup) == "table", "save failure discarded backup")
assert(bindings.F8 == "OCTOPORT_RADIAL", "save failure did not roll live bindings back")
assert(saveBindingsCount == 1, "save failure fixture did not execute")

-- Even after an exact live snapshot restore, do not discard that durable
-- evidence until the following persistent legacy cleanup is also committed.
interruptedBindings = CopyMap(directBindings)
interruptedBindings["1"] = "OCTOPORT_ACTION_A"
interruptedBindings.F13 = "ACTIONBUTTON1"
interruptedBindings.F8 = "OCTOPORT_RADIAL"
recoverySnapshot = {
  version = 1,
  keys = {
    ["1"] = "ACTIONBUTTON1",
    F13 = "ACTIONBUTTON1",
  },
  commands = {
    ACTIONBUTTON1 = true,
    OCTOPORT_ACTION_A = true,
  },
}
LoadCleanup({
  bindingRecoverySnapshot = recoverySnapshot,
  bindingBackup = { F8 = "TOGGLEWORLDMAP" },
}, interruptedBindings)
rejectNextSave = true
assert(RunCleanup() ~= true, "combined save failure was reported as success")
assert(OctoPort.config.bindingRecoverySnapshot == recoverySnapshot,
  "later legacy save failure discarded exact v0.9 recovery evidence")
assert(OctoPort.config.basicMigrationVersion ~= 1,
  "combined save failure advanced migration marker")
assert(bindings["1"] == "ACTIONBUTTON1" and bindings.F13 == "ACTIONBUTTON1",
  "legacy save rollback undid the already verified v0.9 baseline")

-- Exercise the real Core event path too. One invisible event dispatcher is
-- allowed so a cleanup blocked by combat can retry; no other frame or UI may
-- be created, and ordinary marker-complete login remains mutation-free.
local createdFrames = {}
function CreateFrame(frameType, name, parent)
  assert(frameType == "Frame" and name == "OctoPortEvents" and parent == nil,
    "Core created a visible/controller UI frame")
  local frame = { events = {}, scripts = {} }
  function frame:RegisterEvent(eventName) self.events[eventName] = true end
  function frame:SetScript(scriptName, handler) self.scripts[scriptName] = handler end
  table.insert(createdFrames, frame)
  return frame
end

DEFAULT_CHAT_FRAME = { AddMessage = function() end }
local function FireRuntimeEvent(frame, eventName, firstArgument)
  assert(frame.events[eventName], "Core did not register " .. eventName)
  local oldEvent, oldArg1 = event, arg1
  event, arg1 = eventName, firstArgument
  frame.scripts.OnEvent()
  event, arg1 = oldEvent, oldArg1
end

local function LoadRuntime(config, liveBindings)
  OctoPortConfig = config
  OctoPort = {}
  bindings = CopyMap(liveBindings)
  setBindingCount = 0
  saveBindingsCount = 0
  inCombat = false
  rejectNextSet = false
  rejectNextSave = false
  createdFrames = {}
  dofile("Cleanup.lua")
  dofile("Core.lua")
  assert(table.getn(createdFrames) == 1, "basic runtime must create only one event frame")
  return createdFrames[1]
end

local eventFrame = LoadRuntime({ basicMigrationVersion = 1, profile = "native-pass-through" }, directBindings)
FireRuntimeEvent(eventFrame, "ADDON_LOADED", "Wow_Controller")
FireRuntimeEvent(eventFrame, "PLAYER_LOGIN")
FireRuntimeEvent(eventFrame, "PLAYER_REGEN_ENABLED")
assert(setBindingCount == 0 and saveBindingsCount == 0,
  "normal Core event lifecycle called binding mutation APIs")
AssertDirectBindings("normal Core event lifecycle")
assert(OctoPort.minimapButton == nil and OctoPort.root == nil and OctoPort.configFrame == nil,
  "normal Core lifecycle created removed controller UI")

dirtyBindings = CopyMap(directBindings)
dirtyBindings.F8 = "OCTOPORT_RADIAL"
eventFrame = LoadRuntime({ bindingBackup = { F8 = "TOGGLEWORLDMAP" } }, dirtyBindings)
inCombat = true
FireRuntimeEvent(eventFrame, "ADDON_LOADED", "Wow_Controller")
FireRuntimeEvent(eventFrame, "PLAYER_LOGIN")
assert(OctoPort.cleanupPending and setBindingCount == 0 and saveBindingsCount == 0,
  "Core did not defer startup cleanup atomically in combat")
inCombat = false
FireRuntimeEvent(eventFrame, "PLAYER_REGEN_ENABLED")
assert(not OctoPort.cleanupPending and bindings.F8 == "TOGGLEWORLDMAP" and saveBindingsCount == 1,
  "Core did not finish deferred cleanup after combat")
AssertDirectBindings("deferred Core cleanup")
AssertNoLegacyCommands("deferred Core cleanup")

print("minimal cleanup-only runtime harness: OK")
