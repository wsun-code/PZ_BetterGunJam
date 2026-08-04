-- Public seams exercised by the tests:
-- Events.OnWeaponSwingHitPoint, ISReloadWeaponAction.onShoot, and
-- ISRackFirearm:rackBullet. These doubles model only their observable weapon state.
require = function(_) end
getText = function(value)
    return value
end

randomRoll = 0
ZombRand = function(_)
    return randomRoll
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
    onShoot = function(_, weapon)
        weapon.shotCalls = (weapon.shotCalls or 0) + 1
        if weapon.jamOnShoot then
            weapon:setJammed(true)
        end
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
                return "old-jam-remains"
            end
            self.gun:setJammed(false)
        end

        if self.gun:getJamGunChance() > 0 and self.gun.jamOnRack then
            self.gun:setJammed(true)
        end
        return "rack-complete"
    end,
}
