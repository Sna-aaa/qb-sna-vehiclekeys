local Translations = {
    info = {
        givekey = "Conseguir una llave",
        resetlocks = "Cambiar las cerraduras del coche",
        givekeyheader = "Elija el coche para obtener una llave",
        givekeyitem = "%{value} (%{value2})",
        resetkeyheader = "Elija el coche para restablecer las cerraduras",
        resetkeyitem = "%{value} (%{value2})",
        blip = "Cerrajero",
        hotwire = "~g~[H]~w~ - Hacer puente",
        engine = 'Alternar el motor',
    },
    message = {
        not_initialized = "Las cerraduras no se han inicializado, por favor reinicie las cerraduras",
        key_received = "Has recibido la llave",
        locks_reset = "Se cambio la cerradura del coche",
        not_enough_money = "No tienes suficiente dinero",
        temp_key_received = "Has recibido una llave temporal",
        vehicle_locked = "¡Vehículo cerrado!",
        vehicle_unlocked = "¡Vehículo desbloqueado!",
        no_key = "No tienes las llaves de este vehículo",
        police = "Robo de vehículo en curso. Tipo: %{value}",
        lockpicked = "¡Has conseguido abrir la cerradura de la puerta!",
        hotwiring = "Realizando el puente del vehículo...",
        hotwiring_fail = "No consigues hacer el puente del coche y te frustras",
    }
}

local templocale = Locale:new({
    phrases = Translations,
    warnOnMissing = true,
    locale = "es"
}) 
if templocale then
    Lang = templocale
end
