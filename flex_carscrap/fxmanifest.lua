fx_version 'cerulean'
game 'gta5'
author 'Flexiboii'
description 'Car Scrap'
lua54 'yes'

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua',
    'locale/*.lua',
    'client/bridge/*.lua',
    'server/bridge/*.lua',
}

client_scripts {
    '@PolyZone/client.lua',
    'client/main.lua',
}

server_scripts {
    'server/**.lua',
}

dependency '/assetpacks'