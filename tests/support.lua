-- Public seams exercised by the tests: SandboxVars, authority mode,
-- Events.OnWeaponSwingHitPoint, ISReloadWeaponAction.onShoot, and
-- ISRackFirearm:rackBullet. Doubles model only observable weapon state and sync.
require = function(_) end
-- B42.20's getText validates Java-style format strings.  The native
-- ModOptions adapter calls it for every combobox item, so literal percent
-- labels must enter as translation keys whose values escape '%' as '%%'.
local optionText = {
    UI_BetterGunJam_Threshold_tooltip = "0%% = no jamming at anytime.",
    UI_BetterGunJam_Threshold_option1 = "90%%",
    UI_BetterGunJam_Threshold_option2 = "80%%",
    UI_BetterGunJam_Threshold_option3 = "70%%",
    UI_BetterGunJam_Threshold_option4 = "60%%",
    UI_BetterGunJam_Threshold_option5 = "50%%",
    UI_BetterGunJam_Threshold_option6 = "40%%",
    UI_BetterGunJam_Threshold_option7 = "30%%",
    UI_BetterGunJam_Threshold_option8 = "20%%",
    UI_BetterGunJam_Threshold_option9 = "10%%",
    UI_BetterGunJam_Threshold_option10 = "0%%",
}
getText = function(key)
    local text = optionText[key]
    if text ~= nil then
        return string.format(text)
    end
    if string.find(key, "%%") then
        error("literal percent labels must be passed through a translation key", 0)
    end
    return key
end

randomRoll = 0
ZombRand = function(_)
    return randomRoll
end
clientMode = false
serverMode = false
isClient = function()
    return clientMode
end
isServer = function()
    return serverMode
end
isMultiplayer = function()
    return clientMode or serverMode
end

SandboxVars = {
    BetterGunJam = {
        Threshold = 3,
    },
}

syncHandWeaponFields = function(_, weapon)
    if isClient() then
        return
    end

    weapon.syncCalls = (weapon.syncCalls or 0) + 1
    weapon.syncedJammed = weapon:isJammed()
end

Events = {
    OnWeaponSwingHitPoint = {
        removed = nil,
        added = nil,
        Remove = function(callback)
            Events.OnWeaponSwingHitPoint.removed = callback
        end,
        Add = function(callback)
            Events.OnWeaponSwingHitPoint.added = callback
        end,
    },
}

function newWeapon(condition, jammed, jamChance)
    local weapon = {
        condition = condition,
        jammed = jammed,
        jamChance = jamChance,
        ranged = true,
        jamOnShoot = false,
        jamOnRack = false,
    }

    function weapon:isRanged()
        return self.ranged
    end

    function weapon:getCondition()
        return self.condition
    end

    function weapon:getConditionMax()
        return 10
    end

    function weapon:isJammed()
        return self.jammed
    end

    function weapon:setJammed(value)
        self.jammed = value
    end

    function weapon:getJamGunChance()
        return self.jamChance
    end

    function weapon:setJamGunChance(value)
        self.jamChance = value
    end

    return weapon
end

ISReloadWeaponAction = {
    onShoot = function(player, weapon)
        weapon.shotCalls = (weapon.shotCalls or 0) + 1
        if weapon.throwShoot then
            error("shot failure")
        end

        if weapon:getJamGunChance() > 0 and weapon.jamOnShoot then
            weapon:setJammed(true)
        end
        syncHandWeaponFields(player, weapon)
        return "shot-complete"
    end,
}

ISRackFirearm = {
    rackBullet = function(self)
        self.rackCalls = (self.rackCalls or 0) + 1
        if self.throwRack then
            error("rack failure")
        end

        if self.gun:isJammed() then
            if not self.unjamSucceeds then
                syncHandWeaponFields(self.character, self.gun)
                return "old-jam-remains"
            end
            self.gun:setJammed(false)
        end

        if self.gun:getJamGunChance() > 0 and self.gun.jamOnRack then
            self.gun:setJammed(true)
        end
        syncHandWeaponFields(self.character, self.gun)
        return "rack-complete"
    end,
}
