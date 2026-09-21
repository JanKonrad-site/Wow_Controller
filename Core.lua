-- WOW Controller 1.0.1
--
-- Native pass-through profile for OctoWoW / World of Warcraft 1.12.x.
-- The addon deliberately creates no controller UI and owns no gameplay keys.

OctoPort = OctoPort or {}
OctoPort.version = "1.0.1"

function OctoPort:Print(message)
  if DEFAULT_CHAT_FRAME then
    DEFAULT_CHAT_FRAME:AddMessage("|cff3dd6d0WOW Controller:|r " .. tostring(message))
  end
end

function OctoPort:InitializeConfig()
  if type(OctoPortConfig) ~= "table" then OctoPortConfig = {} end
  self.config = OctoPortConfig

  -- These flags belonged to removed modules. Force them off before cleanup so
  -- an update can never reactivate the old HUD, quest automation or bindings.
  self.config.enabled = false
  self.config.autoTarget = false
  self.config.autoAcceptQuests = false
  self.config.editMode = false
  self.config.moveMode = false
end

function OctoPort:RunStartupCleanup()
  if not self.config then self:InitializeConfig() end
  local wasMigrated = (tonumber(self.config.basicMigrationVersion) or 0) >= self.basicMigrationVersion
  local completed, reason, changed = self:RunLegacyCleanup()

  if completed then
    self.cleanupPending = nil
    if not wasMigrated then
      if changed then
        self:Print("Stare controller bindy byly bezpecne obnoveny. v1.0 je bez UI a do vstupu uz nezasahuje.")
      else
        self:Print("v1.0 nactena: bez HUDu, radialu a prepisovani klaves. Ovladac jde primo do Blizzard action baru.")
      end
    end
    return true
  end

  if reason == "deferred" then
    if not self.cleanupPending then
      self:Print("Obnova starych bindu pocka do konce boje; zatim nebyla provedena zadna zmena.")
    end
    self.cleanupPending = true
    return nil, reason
  end

  self.cleanupPending = true
  self:Print("Stare bindy se nepodarilo presne obnovit. Data pro obnovu zustala zachovana; restartuj hru mimo boj.")
  return false, reason
end

local events = CreateFrame("Frame", "OctoPortEvents")
events:RegisterEvent("ADDON_LOADED")
events:RegisterEvent("PLAYER_LOGIN")
events:RegisterEvent("PLAYER_REGEN_ENABLED")
events:SetScript("OnEvent", function()
  if event == "ADDON_LOADED" and (arg1 == "Wow_Controller" or arg1 == "OctoPort") then
    OctoPort:InitializeConfig()
  elseif event == "PLAYER_LOGIN" then
    OctoPort:RunStartupCleanup()
  elseif event == "PLAYER_REGEN_ENABLED" and OctoPort.cleanupPending then
    OctoPort:RunStartupCleanup()
  end
end)
