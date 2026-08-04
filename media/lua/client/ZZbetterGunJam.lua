require "TimedActions/ISReloadWeaponAction"
require "TimedActions/ISRackFirearm"

local options = PZAPI.ModOptions:create("betterGUNJAM", "Better Gun Jam")
local thresholdOption = options:addComboBox(
    "threshold",
    "Gun Jam Threshold",
    "Gun condition threshold above which guns do not jam. 0% means guns never jam."
)

for threshold = 90, 0, -10 do
    thresholdOption:addItem(tostring(threshold) .. "%", threshold == 70)
end

local function shouldPreventJam(weapon)
    if not weapon:isRanged() then
        return false
    end

    local threshold = (10 - thresholdOption:getValue()) * 10
    local condition = weapon:getCondition() / weapon:getConditionMax() * 100
    return condition > threshold or ZombRand(100) > (threshold - 100) / threshold / 2 * condition + 100
end

local ori_onshoot = ISReloadWeaponAction.onShoot
Events.OnWeaponSwingHitPoint.Remove(ISReloadWeaponAction.onShoot)

ISReloadWeaponAction.onShoot = function(player, weapon)
    ori_onshoot(player, weapon)
    if shouldPreventJam(weapon) then
        weapon:setJammed(false)
    end
end

Events.OnWeaponSwingHitPoint.Add(ISReloadWeaponAction.onShoot)

local ori_rackBullet = ISRackFirearm.rackBullet

function ISRackFirearm:rackBullet()
    local jamGunChance = self.gun:getJamGunChance()
    if jamGunChance <= 0 or not shouldPreventJam(self.gun) then
        return ori_rackBullet(self)
    end

    -- Keep existing jams in the normal unjam flow while suppressing only a new
    -- jam roll caused by this action cycle.
    self.gun:setJamGunChance(0)
    local completed, result = pcall(ori_rackBullet, self)
    self.gun:setJamGunChance(jamGunChance)

    if not completed then
        error(result, 0)
    end
    return result
end
