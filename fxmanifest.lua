fx_version 'cerulean'
game 'gta5'

author 'Thendra'
description 'QB-Core Vehicleshop (thd_vehicleshop)'
version '1.0.0'

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/style.css',
    'html/script.js'
}

shared_scripts {
    '@qb-core/shared/locale.lua',
    'config.lua',
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/server.lua',
    'server/statloader.lua',
}

client_scripts {
    'client/client.lua'
}

lua54 'yes'
