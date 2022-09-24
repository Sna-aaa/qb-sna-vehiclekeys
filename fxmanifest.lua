fx_version 'cerulean'

game 'gta5'

description 'QB Sna VehicleKeys'

version '1.0.0'

shared_scripts {
    '@qb-core/shared/locale.lua',
    'locales/*.lua',
    'config.lua',
}

client_script 'client/main.lua'

server_scripts {	
    '@oxmysql/lib/MySQL.lua',
    'server/main.lua'
}


lua54 'yes'