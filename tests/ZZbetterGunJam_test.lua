local testsRun = 0

local function test(name, body)
    local completed, failure = pcall(body)
    if not completed then
        error(name .. ": " .. tostring(failure), 0)
    end
    testsRun = testsRun + 1
    print("PASS " .. name)
end

local function expect(value, message)
    if not value then
        error(message, 0)
    end
end

test("replaces the vanilla shot event without registering it twice", function()
    expect(Events.OnWeaponSwingHitPoint.removed ~= nil, "vanilla shot hook was not removed")
    expect(
        Events.OnWeaponSwingHitPoint.added == ISReloadWeaponAction.onShoot,
        "wrapped shot hook was not registered"
    )
end)

test("registers the threshold with native b42 mod options", function()
    local options = PZAPI.ModOptions:getOptions("betterGUNJAM")
    expect(options ~= nil, "native options group was not registered")
    expect(options.name == "Better Gun Jam", "native options group has the wrong name")

    local threshold = options:getOption("threshold")
    expect(threshold ~= nil, "native threshold option was not registered")
    expect(threshold.name == "Gun Jam Threshold", "native threshold has the wrong label")
    expect(#threshold.values == 10, "native threshold does not have ten choices")
    expect(threshold.values[1] == "90%" and threshold.values[10] == "0%", "native threshold choices are wrong")
    expect(threshold:getValue() == 3, "native threshold default is not 70%")
end)

test("reads native threshold changes without reloading the mod", function()
    local threshold = PZAPI.ModOptions:getOptions("betterGUNJAM"):getOption("threshold")
    randomRoll = 0
    threshold:setValue(2)

    local atThreshold = newWeapon(8, false, 1)
    atThreshold.jamOnShoot = true
    ISReloadWeaponAction.onShoot(nil, atThreshold)
    expect(atThreshold:isJammed(), "80% condition was treated as above an 80% threshold")

    threshold:setValue(3)
    local aboveThreshold = newWeapon(8, false, 1)
    aboveThreshold.jamOnShoot = true
    ISReloadWeaponAction.onShoot(nil, aboveThreshold)
    expect(not aboveThreshold:isJammed(), "live threshold change was not used")
end)

test("suppresses a new shot jam above the threshold", function()
    local weapon = newWeapon(8, false, 1)
    weapon.jamOnShoot = true

    ISReloadWeaponAction.onShoot(nil, weapon)

    expect(not weapon:isJammed(), "shot jam was not suppressed")
    expect(weapon.shotCalls == 1, "original shot handler was not called exactly once")
end)

test("retains a shot jam below the threshold when grace fails", function()
    randomRoll = 0
    local weapon = newWeapon(5, false, 1)
    weapon.jamOnShoot = true

    ISReloadWeaponAction.onShoot(nil, weapon)

    expect(weapon:isJammed(), "shot jam was unexpectedly suppressed")
end)

test("suppresses a shot jam below the threshold when grace succeeds", function()
    randomRoll = 99
    local weapon = newWeapon(5, false, 1)
    weapon.jamOnShoot = true

    ISReloadWeaponAction.onShoot(nil, weapon)

    expect(not weapon:isJammed(), "shot grace was not applied")
end)

test("suppresses a new action-cycle jam above the threshold", function()
    local action = { gun = newWeapon(8, false, 1), unjamSucceeds = false }
    action.gun.jamOnRack = true

    local result = ISRackFirearm.rackBullet(action)

    expect(not action.gun:isJammed(), "action-cycle jam was not suppressed")
    expect(action.gun:getJamGunChance() == 1, "jam chance was not restored")
    expect(action.rackCalls == 1, "original action-cycle handler was not called exactly once")
    expect(result == "rack-complete", "original action-cycle return value changed")
end)

test("retains an action-cycle jam below the threshold when grace fails", function()
    randomRoll = 0
    local action = { gun = newWeapon(5, false, 1), unjamSucceeds = false }
    action.gun.jamOnRack = true

    ISRackFirearm.rackBullet(action)

    expect(action.gun:isJammed(), "action-cycle jam was unexpectedly suppressed")
end)

test("suppresses an action-cycle jam below the threshold when grace succeeds", function()
    randomRoll = 99
    local action = { gun = newWeapon(5, false, 1), unjamSucceeds = false }
    action.gun.jamOnRack = true

    ISRackFirearm.rackBullet(action)

    expect(not action.gun:isJammed(), "action-cycle grace was not applied")
end)

test("preserves an existing jam after a failed manual unjam", function()
    local action = { gun = newWeapon(8, true, 1), unjamSucceeds = false }
    action.gun.jamOnRack = true

    ISRackFirearm.rackBullet(action)

    expect(action.gun:isJammed(), "existing jam was cleared without a successful unjam")
    expect(action.gun:getJamGunChance() == 1, "jam chance was not restored")
end)

test("suppresses a new action-cycle jam after clearing an existing jam", function()
    local action = { gun = newWeapon(8, true, 1), unjamSucceeds = true }
    action.gun.jamOnRack = true

    ISRackFirearm.rackBullet(action)

    expect(not action.gun:isJammed(), "new action-cycle jam was not suppressed")
end)

test("restores jam chance and propagates action-cycle errors", function()
    local action = { gun = newWeapon(8, false, 1), throwRack = true }

    local completed = pcall(ISRackFirearm.rackBullet, action)

    expect(not completed, "action-cycle error was swallowed")
    expect(action.gun:getJamGunChance() == 1, "jam chance was not restored after an error")
end)

print(string.format("Better Gun Jam: %d scenarios passed", testsRun))
