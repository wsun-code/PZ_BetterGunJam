require "TimedActions/ISReloadWeaponAction"
require "TimedActions/ISRackFirearm"

local DEFAULT_THRESHOLD_OPTION = 3

local function getThresholdOption()
    if isMultiplayer() then
        local options = SandboxVars and SandboxVars.BetterGunJam
        return options and options.Threshold or DEFAULT_THRESHOLD_OPTION
    end

    -- PZAPI.ModOptions is client-only and registers after shared Lua. The
    -- getter is available by the time an in-world singleplayer action runs.
    if BetterGunJam and BetterGunJam.getSingleplayerThresholdOption then
        return BetterGunJam.getSingleplayerThresholdOption()
    end
    return DEFAULT_THRESHOLD_OPTION
end

local function getThreshold()
    return (10 - getThresholdOption()) * 10
end

local function shouldPreventJam(weapon)
    if not weapon:isRanged() then
        return false
    end

    local threshold = getThreshold()
    if threshold <= 0 then
        return true
    end

    local condition = weapon:getCondition() / weapon:getConditionMax() * 100
    return condition > threshold
        or ZombRand(100) > (threshold - 100) / threshold / 2 * condition + 100
end

local function runWithoutNewJam(weapon, callback, receiver, argument)
    local jamGunChance = weapon:getJamGunChance()
    if isClient() or jamGunChance <= 0 or not shouldPreventJam(weapon) then
        return callback(receiver, argument)
    end

    -- Keep existing jams in the normal unjam flow while suppressing only the
    -- next jam roll. Vanilla then synchronizes the final authoritative state.
    weapon:setJamGunChance(0)
    local completed, result = pcall(callback, receiver, argument)
    weapon:setJamGunChance(jamGunChance)

    if not completed then
        error(result, 0)
    end
    return result
end

local originalOnShoot = ISReloadWeaponAction.onShoot
Events.OnWeaponSwingHitPoint.Remove(originalOnShoot)

ISReloadWeaponAction.onShoot = function(player, weapon)
    return runWithoutNewJam(weapon, originalOnShoot, player, weapon)
end

Events.OnWeaponSwingHitPoint.Add(ISReloadWeaponAction.onShoot)

local originalRackBullet = ISRackFirearm.rackBullet

function ISRackFirearm:rackBullet()
    return runWithoutNewJam(self.gun, originalRackBullet, self)
end
