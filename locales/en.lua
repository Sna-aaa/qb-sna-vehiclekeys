local Translations = {
    info = {
        givekey = "Get a key",
        resetlocks = "Change car locks",
        givekeyheader = "Choose car to get a key",
        givekeyitem = "%{value} (%{value2})",
        resetkeyheader = "Choose car to reset locks",
        resetkeyitem = "%{value} (%{value2})",
        blip = "Locksmith",
    },
    message = {
        not_initialized = "Locks are not initialized, please reset locks",
        key_received = "You received the key",
        locks_reset = "Locks changed for car",
        not_enough_money = "You have not enough money",
        temp_key_received = "You received a temporary key",
    }
}

local templocale = Locale:new({
    phrases = Translations,
    warnOnMissing = true,
    locale = "en"
}) 
if templocale then
    Lang = templocale
end