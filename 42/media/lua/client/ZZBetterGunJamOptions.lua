local options = PZAPI.ModOptions:create("betterGUNJAM", "UI_BetterGunJam")
local explanation = "UI_BetterGunJam_Threshold_tooltip"

options:addDescription(explanation)
local thresholdOption = options:addComboBox(
    "threshold",
    "UI_BetterGunJam_Threshold",
    explanation
)

for threshold = 90, 0, -10 do
    thresholdOption:addItem(tostring(threshold) .. "%", threshold == 70)
end

BetterGunJam = BetterGunJam or {}

function BetterGunJam.getSingleplayerThresholdOption()
    return thresholdOption:getValue()
end
