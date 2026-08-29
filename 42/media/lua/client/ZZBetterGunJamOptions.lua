local options = PZAPI.ModOptions:create("betterGUNJAM", "UI_BetterGunJam")
local explanation = "UI_BetterGunJam_Threshold_tooltip"

options:addDescription(explanation)
local thresholdOption = options:addComboBox(
    "threshold",
    "UI_BetterGunJam_Threshold",
    explanation
)

-- addItem resolves its name with getText, where '%' starts a format directive.
-- The translation values therefore escape their literal percent signs as '%%'.
for option = 1, 10 do
    thresholdOption:addItem("UI_BetterGunJam_Threshold_option" .. option, option == 3)
end

BetterGunJam = BetterGunJam or {}

function BetterGunJam.getSingleplayerThresholdOption()
    return thresholdOption:getValue()
end
