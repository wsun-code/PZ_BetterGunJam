require "TimedActions/ISReloadWeaponAction"

local SETTINGS = {
    options = { 
        threhold = 3
    },
    names = {
        threhold = "Gun Jam Threhold"
    },
    mod_id = "betterGUNJAM",
    mod_shortname = "Better Gun Jam Options",
  }

if ModOptions and ModOptions.getInstance then
    local settings = ModOptions:getInstance(SETTINGS)
    local drop1 = settings:getData("threhold")
    drop1[1] = "90%"
    drop1[2] = "80%"
    drop1[3] = "70%"
    drop1[4] = "60%"
    drop1[5] = "50%"
    drop1[6] = "40%"
    drop1[7] = "30%"
    drop1[8] = "20%"
    drop1[9] = "10%"
    drop1[10] = "0%"
    drop1.tooltip = "Gun condition threhold above which guns do not jam. 0% means guns never jam."
end

local ori_onshoot = ISReloadWeaponAction.onShoot
Events.OnWeaponSwingHitPoint.Remove(ISReloadWeaponAction.onShoot)

ISReloadWeaponAction.onShoot = function(player, weapon)
    ori_onshoot(player, weapon)
    if weapon:isRanged() then 
        local threhold = (10 - SETTINGS.options.threhold)*10
        local condition = weapon:getCondition()/weapon:getConditionMax()*100
        if condition > threhold or ZombRand(100) > (threhold-100)/threhold/2*condition+100 then
            weapon:setJammed(false)
            return
        end 
    end
end

Events.OnWeaponSwingHitPoint.Add(ISReloadWeaponAction.onShoot)