-- Recommended keyboard layer used by the ROG Ally X Desktop Mode profile.
-- The addon never applies it silently. The player must use /octoport setup.

local bindings = {}

for i = 1, 8 do
  table.insert(bindings, { tostring(i), "ACTIONBUTTON" .. i })
  table.insert(bindings, { "SHIFT-" .. i, "MULTIACTIONBAR1BUTTON" .. i })
  table.insert(bindings, { "CTRL-" .. i, "MULTIACTIONBAR2BUTTON" .. i })
end

table.insert(bindings, { "TAB", "TARGETNEARESTENEMY" })
table.insert(bindings, { "SHIFT-TAB", "TARGETPREVIOUSENEMY" })
table.insert(bindings, { "CTRL-TAB", "TARGETNEARESTFRIEND" })
table.insert(bindings, { "F", "TURNORACTION" })
table.insert(bindings, { "R", "OCTOPORT_TOGGLEBAGS" })
table.insert(bindings, { "M", "TOGGLEWORLDMAP" })
table.insert(bindings, { "SPACE", "JUMP" })
table.insert(bindings, { "NUMLOCK", "TOGGLEAUTORUN" })

OctoPort.recommendedBindings = bindings

local function CurrentBinding(key)
  if GetBindingAction then
    return GetBindingAction(key) or ""
  end
  return ""
end

function OctoPort:ApplyRecommendedBindings()
  if not self.config then self:InitializeConfig() end

  if not self.config.bindingBackup then
    self.config.bindingBackup = {}
    for i = 1, table.getn(bindings) do
      local key = bindings[i][1]
      self.config.bindingBackup[key] = CurrentBinding(key)
    end
  end

  local failed = 0
  for i = 1, table.getn(bindings) do
    local key = bindings[i][1]
    local command = bindings[i][2]
    if not SetBinding(key, command) then failed = failed + 1 end
  end

  SaveBindings(GetCurrentBindingSet())
  self.config.setupComplete = failed == 0

  if failed == 0 then
    self:Print("Controller bindings applied and saved.")
    self:Print("Now create the OctoPort Desktop Mode profile in Armoury Crate SE.")
  else
    self:Print("Could not apply " .. failed .. " bindings. Try again outside combat.")
  end

  if self.RefreshButtonLabels then self:RefreshButtonLabels() end
end

function OctoPort:RestoreBindings()
  if not self.config or not self.config.bindingBackup then
    self:Print("No OctoPort binding backup exists for this character.")
    return
  end

  for key, command in pairs(self.config.bindingBackup) do
    if command and command ~= "" then
      SetBinding(key, command)
    else
      SetBinding(key)
    end
  end

  SaveBindings(GetCurrentBindingSet())
  self.config.bindingBackup = nil
  self.config.setupComplete = false
  self:Print("Original bindings restored.")
end

function OctoPort_ToggleBags()
  local anyOpen = false
  for i = 1, 12 do
    local frame = getglobal("ContainerFrame" .. i)
    if frame and frame:IsVisible() then
      anyOpen = true
      break
    end
  end

  if anyOpen then
    CloseAllBags()
  else
    OpenAllBags()
  end
end

function OctoPort_ToggleHelp()
  if OctoPort and OctoPort.ToggleHelp then OctoPort:ToggleHelp() end
end
