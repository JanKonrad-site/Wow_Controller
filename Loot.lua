-- Places the loot window near the controller-driven cursor.

local tracker = CreateFrame("Frame", "OctoPortLootTracker", UIParent)
tracker.elapsed = 0
tracker.wasVisible = false

local function Clamp(value, minimum, maximum)
  if value < minimum then return minimum end
  if value > maximum then return maximum end
  return value
end

local function MoveLootToCursor()
  if not LootFrame or not LootFrame:IsVisible() then return end

  local x, y = GetCursorPosition()
  local scale = LootFrame:GetEffectiveScale()
  if not scale or scale == 0 then scale = 1 end
  x = x / scale
  y = y / scale

  local width = LootFrame:GetWidth() or 200
  local height = LootFrame:GetHeight() or 250
  x = Clamp(x + 16, 12, UIParent:GetWidth() - width - 12)
  y = Clamp(y + height / 2, height + 12, UIParent:GetHeight() - 12)

  LootFrame:ClearAllPoints()
  LootFrame:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", x, y)
end

tracker:SetScript("OnUpdate", function()
  this.elapsed = this.elapsed + arg1
  if this.elapsed < 0.10 then return end
  this.elapsed = 0

  if OctoPort.config and not OctoPort.config.enabled then
    this.wasVisible = false
    return
  end

  local visible = LootFrame and LootFrame:IsVisible()
  if visible and not this.wasVisible then MoveLootToCursor() end
  this.wasVisible = visible and true or false
end)
