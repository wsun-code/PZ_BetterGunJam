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

test("registers a localizable singleplayer threshold in native mod options", function()
    local options = PZAPI.ModOptions:getOptions("betterGUNJAM")
    expect(options ~= nil, "singleplayer mod-options group was not registered")
    expect(options.name == "UI_BetterGunJam", "singleplayer group does not use a translation key")

    local threshold = options:getOption("threshold")
    expect(threshold ~= nil, "singleplayer threshold was not registered")
    expect(threshold.name == "UI_BetterGunJam_Threshold", "singleplayer threshold does not use a translation key")
    expect(
        threshold.tooltip == "UI_BetterGunJam_Threshold_tooltip",
        "singleplayer threshold tooltip does not use a translation key"
    )
    expect(
        options.data[1].type == "description"
            and options.data[1].text == "0% = no jamming at anytime.",
        "singleplayer threshold explanation was not safely resolved"
    )
    expect(#threshold.values == 10, "singleplayer threshold does not have ten choices")
    expect(threshold.values[1] == "90%" and threshold.values[10] == "0%", "singleplayer choices are wrong")
    expect(threshold:getValue() == 3, "singleplayer threshold default is not 70%")
end)

test("reads live singleplayer mod-option changes and ignores sandbox", function()
    local threshold = PZAPI.ModOptions:getOptions("betterGUNJAM"):getOption("threshold")
    randomRoll = 0
    SandboxVars.BetterGunJam.Threshold = 10
    threshold:setValue(2)

    local atThreshold = newWeapon(8, false, 1)
    atThreshold.jamOnShoot = true
    ISReloadWeaponAction.onShoot(nil, atThreshold)
    expect(atThreshold:isJammed(), "singleplayer used the sandbox threshold")

    SandboxVars.BetterGunJam.Threshold = 2
    threshold:setValue(3)
    local aboveThreshold = newWeapon(8, false, 1)
    aboveThreshold.jamOnShoot = true
    ISReloadWeaponAction.onShoot(nil, aboveThreshold)
    expect(not aboveThreshold:isJammed(), "live singleplayer threshold change was not used")

    SandboxVars.BetterGunJam.Threshold = 3
end)

test("reads live multiplayer sandbox changes and ignores mod options", function()
    local threshold = PZAPI.ModOptions:getOptions("betterGUNJAM"):getOption("threshold")
    serverMode = true
    randomRoll = 0
    threshold:setValue(10)
    SandboxVars.BetterGunJam.Threshold = 2

    local atThreshold = newWeapon(8, false, 1)
    atThreshold.jamOnShoot = true
    ISReloadWeaponAction.onShoot(nil, atThreshold)
    expect(atThreshold:isJammed(), "multiplayer server used the local mod option")

    SandboxVars.BetterGunJam.Threshold = 3
    local aboveThreshold = newWeapon(8, false, 1)
    aboveThreshold.jamOnShoot = true
    ISReloadWeaponAction.onShoot(nil, aboveThreshold)
    expect(not aboveThreshold:isJammed(), "live multiplayer sandbox change was not used")

    serverMode = false
    threshold:setValue(3)
end)

test("zero percent singleplayer threshold prevents jams at zero condition", function()
    local threshold = PZAPI.ModOptions:getOptions("betterGUNJAM"):getOption("threshold")
    threshold:setValue(10)
    SandboxVars.BetterGunJam.Threshold = 2
    randomRoll = 0
    local brokenWeapon = newWeapon(0, false, 1)
    brokenWeapon.jamOnShoot = true

    ISReloadWeaponAction.onShoot(nil, brokenWeapon)

    threshold:setValue(3)
    SandboxVars.BetterGunJam.Threshold = 3
    expect(not brokenWeapon:isJammed(), "zero percent did not disable singleplayer jams")
end)

test("suppresses and synchronizes a new singleplayer shot jam", function()
    local weapon = newWeapon(8, false, 1)
    weapon.jamOnShoot = true

    local result = ISReloadWeaponAction.onShoot(nil, weapon)

    expect(not weapon:isJammed(), "shot jam was not suppressed")
    expect(weapon.syncedJammed == false, "vanilla synchronized a jam before suppression")
    expect(weapon.syncCalls == 1, "final weapon state was not synchronized exactly once")
    expect(weapon:getJamGunChance() == 1, "jam chance was not restored")
    expect(weapon.shotCalls == 1, "original shot handler was not called exactly once")
    expect(result == "shot-complete", "original shot return value changed")
end)

test("leaves multiplayer client shot prediction vanilla-controlled", function()
    clientMode = true
    local weapon = newWeapon(8, false, 1)
    weapon.jamOnShoot = true

    local result = ISReloadWeaponAction.onShoot(nil, weapon)

    clientMode = false
    expect(weapon:isJammed(), "client prediction was modified before server sync")
    expect(weapon.syncCalls == nil, "client attempted an authoritative weapon sync")
    expect(weapon:getJamGunChance() == 1, "client prediction changed jam chance")
    expect(result == "shot-complete", "client shot return value changed")
end)

test("suppresses multiplayer server jams before final sync", function()
    serverMode = true
    local weapon = newWeapon(8, false, 1)
    weapon.jamOnShoot = true

    ISReloadWeaponAction.onShoot(nil, weapon)

    serverMode = false
    expect(not weapon:isJammed(), "server retained a preventable shot jam")
    expect(weapon.syncedJammed == false, "server synchronized the pre-suppression jam")
    expect(weapon.syncCalls == 1, "server did not synchronize final state exactly once")
    expect(weapon:getJamGunChance() == 1, "server did not restore jam chance")
end)

test("retains a shot jam below the threshold when grace fails", function()
    randomRoll = 0
    local weapon = newWeapon(5, false, 1)
    weapon.jamOnShoot = true

    ISReloadWeaponAction.onShoot(nil, weapon)

    expect(weapon:isJammed(), "shot jam was unexpectedly suppressed")
    expect(weapon.syncedJammed == true, "retained jam was not synchronized")
end)

test("suppresses a shot jam below the threshold when grace succeeds", function()
    randomRoll = 99
    local weapon = newWeapon(5, false, 1)
    weapon.jamOnShoot = true

    ISReloadWeaponAction.onShoot(nil, weapon)

    expect(not weapon:isJammed(), "shot grace was not applied")
    expect(weapon.syncedJammed == false, "grace result was not synchronized")
end)

test("restores shot jam chance and propagates vanilla errors", function()
    local weapon = newWeapon(8, false, 1)
    weapon.throwShoot = true

    local completed = pcall(ISReloadWeaponAction.onShoot, nil, weapon)

    expect(not completed, "shot error was swallowed")
    expect(weapon:getJamGunChance() == 1, "jam chance was not restored after a shot error")
    expect(weapon.syncCalls == nil, "failed shot synchronized partial state")
end)

test("suppresses a new action-cycle jam above the threshold", function()
    local action = { gun = newWeapon(8, false, 1), unjamSucceeds = false }
    action.gun.jamOnRack = true

    local result = ISRackFirearm.rackBullet(action)

    expect(not action.gun:isJammed(), "action-cycle jam was not suppressed")
    expect(action.gun:getJamGunChance() == 1, "jam chance was not restored")
    expect(action.rackCalls == 1, "original action-cycle handler was not called exactly once")
    expect(result == "rack-complete", "original action-cycle return value changed")
    expect(action.gun.syncedJammed == false, "action-cycle result was not synchronized")
end)

test("leaves multiplayer client rack behavior vanilla-controlled", function()
    clientMode = true
    local action = { gun = newWeapon(8, false, 1), unjamSucceeds = false }
    action.gun.jamOnRack = true

    ISRackFirearm.rackBullet(action)

    clientMode = false
    expect(action.gun:isJammed(), "client rack behavior was modified")
    expect(action.gun.syncCalls == nil, "client attempted an authoritative rack sync")
    expect(action.gun:getJamGunChance() == 1, "client rack changed jam chance")
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
