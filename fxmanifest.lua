fx_version 'cerulean'
rdr3_warning 'I acknowledge that this is a prerelease build of RedM, and I am aware my resources *will* become incompatible once RedM ships.'
game 'rdr3'

description 'rex-lootnpc'
version '2.1.2'

shared_scripts {
    '@ox_lib/init.lua',
    'shared/config.lua',
}

client_scripts {
    'client/client.lua',
    'client/client.js'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/discord.lua',
    'server/server.lua',
    'server/versionchecker.lua'
}

dependencies {
    'rsg-core',
    'ox_lib',
}

exports {
    'DataViewNativeGetEventData2'
}

files {
  'locales/*.json'
}

lua54 'yes'
