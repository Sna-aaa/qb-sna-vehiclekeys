local QBCore = exports['qb-core']:GetCoreObject()
local KeyMaster
local IsHotwiring = false
local Hotwired
local AlertSend = false

local function DrawText3D(x, y, z, text)
    SetTextScale(0.35, 0.35)
    SetTextFont(4)
    SetTextProportional(1)
    SetTextColour(255, 255, 255, 215)
    SetTextEntry("STRING")
    SetTextCentre(true)
    AddTextComponentString(text)
    SetDrawOrigin(x, y, z, 0)
    DrawText(0.0, 0.0)
    local factor = (string.len(text)) / 370
    DrawRect(0.0, 0.0 + 0.0125, 0.017 + factor, 0.03, 0, 0, 0, 75)
    ClearDrawOrigin()
end

local function AttemptPoliceAlert(type)
    if not AlertSend then
        local chance = Config.PoliceAlertChance
        if GetClockHours() >= 1 and GetClockHours() <= 6 then
            chance = Config.PoliceNightAlertChance
        end
        if math.random() <= chance then
           TriggerServerEvent('police:server:policeAlert', 'Vehicle theft in progress. Type: ' .. type)
        end
        AlertSend = true
        SetTimeout(Config.AlertCooldown, function()
            AlertSend = false
        end)
    end
end

RegisterNetEvent('qb-vehiclekeys:client:ToggleEngine', function()
    local EngineOn = GetIsVehicleEngineRunning(GetVehiclePedIsIn(PlayerPedId()))
    local vehicle = GetVehiclePedIsIn(PlayerPedId(), true)
    if HasKeys(QBCore.Functions.GetPlate(vehicle)) then
        if EngineOn then
            SetVehicleEngineOn(vehicle, false, false, true)
        else
            SetVehicleEngineOn(vehicle, true, false, true)
        end
    end
end)


function HasKeys(plate)
	QBCore.Functions.TriggerCallback('qb-vehiclekeys:server:HasKey', function(result)
		return result
	end, plate)
end
exports('HasKeys', HasKeys)

local function isBlacklistedVehicle(vehicle)
    local isBlacklisted = false
    for _,v in ipairs(Config.NoLockVehicles) do
        if GetHashKey(v) == GetEntityModel(vehicle) then
            isBlacklisted = true
            break;
        end
    end
    if Entity(vehicle).state.ignoreLocks or GetVehicleClass(vehicle) == 13 then isBlacklisted = true end
    return isBlacklisted
end

local function loadAnimDict(dict)
    while (not HasAnimDictLoaded(dict)) do
        RequestAnimDict(dict)
        Wait(0)
    end
end

local function ToggleVehicleLocks(veh)
    if veh then
        if not isBlacklistedVehicle(veh) then
			QBCore.Functions.TriggerCallback('qb-vehiclekeys:server:HasKey', function(result)
				if result then
					local ped = PlayerPedId()
					local vehLockStatus = GetVehicleDoorLockStatus(veh)
	
					loadAnimDict("anim@mp_player_intmenu@key_fob@")
					TaskPlayAnim(ped, 'anim@mp_player_intmenu@key_fob@', 'fob_click', 3.0, 3.0, -1, 49, 0, false, false, false)
	
					TriggerServerEvent("InteractSound_SV:PlayWithinDistance", 5, "lock", 0.3)
	
					NetworkRequestControlOfEntity(veh)
					if vehLockStatus == 1 then
						SetVehicleDoorsLocked(veh, 2)
						QBCore.Functions.Notify("Vehicle locked!", "primary")
					else
						SetVehicleDoorsLocked(veh, 1)
						QBCore.Functions.Notify("Vehicle unlocked!", "success")
					end
	
					SetVehicleLights(veh, 2)
					Wait(250)
					SetVehicleLights(veh, 1)
					Wait(200)
					SetVehicleLights(veh, 0)
					Wait(300)
					ClearPedTasks(ped)
				else
					QBCore.Functions.Notify("You don't have keys to this vehicle.", 'error')
				end
			end, QBCore.Functions.GetPlate(veh))
        else
            SetVehicleDoorsLocked(veh, 1)
        end
    end
end

local function LockpickDoor(isAdvanced)
    local ped = PlayerPedId()
    local pos = GetEntityCoords(ped)
    local vehicle = QBCore.Functions.GetClosestVehicle()

    if vehicle == nil or vehicle == 0 then return end
    if HasKeys(QBCore.Functions.GetPlate(vehicle)) then return end
    if #(pos - GetEntityCoords(vehicle)) > 2.5 then return end
    if GetVehicleDoorLockStatus(vehicle) <= 0 then return end

    usingAdvanced = isAdvanced
    TriggerEvent('qb-lockpick:client:openLockpick', lockpickFinish)
end

function lockpickFinish(success)
    local vehicle = QBCore.Functions.GetClosestVehicle()

    local chance = math.random()
    if success then
        TriggerServerEvent('hud:server:GainStress', math.random(1, 4))
        lastPickedVehicle = vehicle

        if GetPedInVehicleSeat(vehicle, -1) == PlayerPedId() then
            TriggerServerEvent('qb-vehiclekeys:server:AcquireVehicleKeys', QBCore.Functions.GetPlate(vehicle))
        else
            QBCore.Functions.Notify('You managed to pick the door lock open!', 'success')
            SetVehicleDoorsLocked(vehicle, 1)
        end

    else
        TriggerServerEvent('hud:server:GainStress', math.random(1, 4))
        AttemptPoliceAlert("steal")
    end

    if usingAdvanced then
        if chance <= Config.RemoveLockpickAdvanced then
            TriggerServerEvent("qb-vehiclekeys:server:breakLockpick", "advancedlockpick")
        end
    else
        if chance <= Config.RemoveLockpickNormal then
            TriggerServerEvent("qb-vehiclekeys:server:breakLockpick", "lockpick")
        end
    end
end

local function Hotwire(vehicle, plate)
    local hotwireTime = math.random(Config.minHotwireTime, Config.maxHotwireTime)
    local ped = PlayerPedId()
    IsHotwiring = true

    SetVehicleAlarm(vehicle, true)
    SetVehicleAlarmTimeLeft(vehicle, hotwireTime)
    QBCore.Functions.Progressbar("hotwire_vehicle", "Hotwiring the vehicle...", hotwireTime, false, true, {
        disableMovement = true,
        disableCarMovement = true,
        disableMouse = false,
        disableCombat = true
    }, {
        animDict = "anim@amb@clubhouse@tutorial@bkr_tut_ig3@",
        anim = "machinic_loop_mechandplayer",
        flags = 16
    }, {}, {}, function() -- Done
        StopAnimTask(ped, "anim@amb@clubhouse@tutorial@bkr_tut_ig3@", "machinic_loop_mechandplayer", 1.0)
        TriggerServerEvent('hud:server:GainStress', math.random(1, 4))
        if (math.random() <= Config.HotwireChance) then
			SetVehicleEngineOn(vehicle, true, false, true)
			Hotwired = plate
			IsHotwiring = false
        else
			QBCore.Functions.Notify("You fail to hotwire the car and get frustrated.", "error")
			Wait(Config.TimeBetweenHotwires)
			IsHotwiring = false
        end
    end, function() -- Cancel
        StopAnimTask(ped, "anim@amb@clubhouse@tutorial@bkr_tut_ig3@", "machinic_loop_mechandplayer", 1.0)
        IsHotwiring = false
    end)

    Wait(10000)
    AttemptPoliceAlert("steal")
end

local function GetVehicleInDirection(coordFromOffset, coordToOffset)
    local ped = PlayerPedId()
    local coordFrom = GetOffsetFromEntityInWorldCoords(ped, coordFromOffset.x, coordFromOffset.y, coordFromOffset.z)
    local coordTo = GetOffsetFromEntityInWorldCoords(ped, coordToOffset.x, coordToOffset.y, coordToOffset.z)

    local rayHandle = CastRayPointToPoint(coordFrom.x, coordFrom.y, coordFrom.z, coordTo.x, coordTo.y, coordTo.z, 10, GetPlayerPed(-1), 0)
    local _, _, _, _, vehicle = GetShapeTestResult(rayHandle)
    return vehicle
end

-- If in vehicle returns that, otherwise tries 3 different raycasts to get the vehicle they are facing.
-- Raycasts picture: https://i.imgur.com/FRED0kV.png
local function GetVehicle()
    local vehicle = GetVehiclePedIsIn(PlayerPedId(), false)

    local RaycastOffsetTable = {
        { ['fromOffset'] = vector3(0.0, 0.0, 0.0), ['toOffset'] = vector3(0.0, 20.0, -10.0) }, -- Waist to ground 45 degree angle
        { ['fromOffset'] = vector3(0.0, 0.0, 0.7), ['toOffset'] = vector3(0.0, 10.0, -10.0) }, -- Head to ground 30 degree angle
        { ['fromOffset'] = vector3(0.0, 0.0, 0.7), ['toOffset'] = vector3(0.0, 10.0, -20.0) }, -- Head to ground 15 degree angle
    }

    local count = 0
    while vehicle == 0 and count < #RaycastOffsetTable do
        count = count + 1
        vehicle = GetVehicleInDirection(RaycastOffsetTable[count]['fromOffset'], RaycastOffsetTable[count]['toOffset'])
    end

    if not IsEntityAVehicle(vehicle) then vehicle = nil end
    return vehicle
end

RegisterKeyMapping('togglelocks', 'Toggle Vehicle Locks', 'keyboard', 'L')
RegisterCommand('togglelocks', function()
    ToggleVehicleLocks(GetVehicle())
end)

RegisterNetEvent('lockpicks:UseLockpick', function(isAdvanced)
    LockpickDoor(isAdvanced)
end)


local function CreateNpc()
    RequestModel('cs_floyd')
    while not HasModelLoaded('cs_floyd') do
        Citizen.Wait(5)
    end
    
	KeyMaster = CreatePed(4, GetHashKey('cs_floyd'), Config.KeyMasterLocation.x, Config.KeyMasterLocation.y, Config.KeyMasterLocation.z, Config.KeyMasterLocation.w, false, false)
	SetEntityAsMissionEntity(KeyMaster, true, true)
	SetPedHearingRange(KeyMaster, 0.0)
	SetPedSeeingRange(KeyMaster, 0.0)
	SetPedAlertness(KeyMaster, 0.0)
	SetPedFleeAttributes(KeyMaster, 0, 0)
	SetBlockingOfNonTemporaryEvents(KeyMaster, true)
	SetPedCombatAttributes(KeyMaster, 46, true)
	SetPedFleeAttributes(KeyMaster, 0, 0)
	--TaskStartScenarioInPlace(KeyMaster, Scenario, 0, true)
	SetEntityInvincible(KeyMaster, true)
	SetEntityCanBeDamaged(KeyMaster, false)
	SetEntityProofs(KeyMaster, true, true, true, true, true, true, 1, true)
	FreezeEntityPosition(KeyMaster, true)
	SetEntityAsMissionEntity(KeyMaster, true, true)

	exports['qb-target']:AddTargetEntity(KeyMaster, {
        options = {
            {
                Type = "client",
                event = "qb-vehiclekeys:client:GiveKeyMenu",
                icon = "fas fa-car",
                label = Lang:t("info.givekey"),
                targeticon = 'fas fa-car-side' -- This is the icon of the target itself, the icon changes to this when it turns blue on this specific option, this is OPTIONAL
            },
            {
                Type = "client",
                event = "qb-vehiclekeys:client:ResetLocksMenu",
                icon = "fas fa-car",
                label = Lang:t("info.resetlocks"),
                targeticon = 'fas fa-car-side' -- This is the icon of the target itself, the icon changes to this when it turns blue on this specific option, this is OPTIONAL
            }
        },
        distance = 1.0
    })

	local Blip = AddBlipForCoord(Config.KeyMasterLocation.x, Config.KeyMasterLocation.y, Config.KeyMasterLocation.z)
	SetBlipSprite(Blip, 134)
	SetBlipColour(Blip, 3)
	--SetBlipScale(Blip, 0.8)
	SetBlipDisplay(Blip, 4)
	SetBlipAsShortRange(Blip, true)
	BeginTextCommandSetBlipName("STRING")
	AddTextComponentSubstringPlayerName(Lang:t('info.blip'))
	EndTextCommandSetBlipName(Blip)
end

local function DeleteNpc()
	if DoesEntityExist(KeyMaster) then
		DeletePed(KeyMaster)
	end
end

local function KeyMenu(type)
    local vehMenu = {
        [1] = {
            header = Lang:t("info."..type.."keyheader"),
            isMenuHeader = true,
        }
    }
	QBCore.Functions.TriggerCallback('qb-garage:server:GetPlayerVehicles', function(vehicles)
		for k, v in pairs(vehicles) do
			local price
			local event
			if type == "give" then
				price = Config.KeyPrice
				event = "qb-vehiclekeys:server:GiveKey"
			else
				price = Config.ResetPrice
				event = "qb-vehiclekeys:server:ChangeLocks"
			end
            vehMenu[#vehMenu+1] = {
                id = k+1,
                header = Lang:t('info.'..type..'keyitem', {value = v.fullname, value2 = v.plate}),
                txt = price,
                params = {
					isServer = true,
                    event = event,
                    args = {
                        plate = v.plate,
						model = v.fullname,
                    }
                }
            }
		end
		exports['qb-menu']:openMenu(vehMenu)
	end)	
end
-- Events
-- Backwards Compatibility ONLY -- Remove at some point --
RegisterNetEvent('vehiclekeys:client:SetOwner', function(plate)
    TriggerServerEvent('qb-vehiclekeys:server:GiveTempKey', plate)
end)
-- Backwards Compatibility ONLY -- Remove at some point --

RegisterNetEvent('qb-vehiclekeys:client:GiveKeyMenu', function(data)
	KeyMenu("give")
end)

RegisterNetEvent('qb-vehiclekeys:client:ResetLocksMenu', function(data)
	KeyMenu("reset")
end)

RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    CreateNpc()
end)

-- Handlers
AddEventHandler('onResourceStart', function(resource)
    if GetCurrentResourceName() == resource then
        CreateNpc()
    end
end)

AddEventHandler('onResourceStop', function(resource)
    if resource == GetCurrentResourceName() then
        DeleteNpc()
    end
end)

local HwText
local EngShut
local HwVehicle
local HwVehiclePos
local HwVehiclePlate

-----------------------
----   Threads     ----
-----------------------
CreateThread(function()
    while true do
        local sleep = 1000
        if LocalPlayer.state.isLoggedIn then
			local ped = PlayerPedId()

			if IsPedInAnyVehicle(ped, false) then
				HwVehicle = GetVehiclePedIsIn(ped)
				HwVehiclePlate = QBCore.Functions.GetPlate(HwVehicle)

                QBCore.Functions.TriggerCallback('qb-vehiclekeys:server:HasKey', function(result)
                    if not result then
                        if GetPedInVehicleSeat(HwVehicle, -1) == ped and not isBlacklistedVehicle(HwVehicle) and Hotwired ~= HwVehiclePlate then
                            EngShut = true
                        else
                            EngShut = false
                        end
                        if GetPedInVehicleSeat(HwVehicle, -1) == ped and not IsHotwiring and Hotwired ~= HwVehiclePlate then
                            HwVehiclePos = GetOffsetFromEntityInWorldCoords(HwVehicle, 0.0, 1.0, 0.5)
                            HwText = true
                        else
                            HwText = false
                        end
                    else
                        EngShut = false
                        HwText = false
                    end
                end, HwVehiclePlate)
			else
				HwText = false
			end
        end
        Wait(sleep)
    end
end)

CreateThread(function()
    while true do
        local sleep = 300

		if HwText then
			sleep = 0
			DrawText3D(HwVehiclePos.x, HwVehiclePos.y, HwVehiclePos.z, "~g~[H]~w~ - Hotwire")
			if IsControlJustPressed(0, 74) and not IsHotwiring then
				Hotwire(HwVehicle, HwVehiclePlate)
			end
		end
		if EngShut then
			sleep = 0
			SetVehicleEngineOn(HwVehicle, false, false, true)
		end
		Wait(sleep)
    end
end)
