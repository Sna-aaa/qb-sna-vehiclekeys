Config = {}

Config.NoLockVehicles = {}
Config.LockpickNPCCars = true

Config.KeyMasterModel = 'cs_floyd'
Config.KeyMasterLocations = {
    vector4(170.01, -1799.37, 28.32, 326.65), 
}
Config.KeyPrice = 300
Config.ResetPrice = 1000

Config.HotwireChance = 0.5 -- Chance for successful hotwire or not
Config.RemoveLockpickNormal = 0.5 -- Chance to remove lockpick on fail
Config.RemoveLockpickAdvanced = 0.2 -- Chance to remove advanced lockpick on fail

Config.TimeBetweenHotwires = 5000
Config.minHotwireTime = 20000
Config.maxHotwireTime = 40000

Config.AlertCooldown = 10000 -- 10 seconds
Config.PoliceAlertChance = 0.75 -- Chance of alerting police during the day
Config.PoliceNightAlertChance = 0.50 -- Chance of alerting police at night (times:01-06)

Config.ImmuneVehicles = { -- These vehicles cannot be jacked
    'stockade'
}
