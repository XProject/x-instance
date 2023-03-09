fx_version  "cerulean"
use_experimental_fxv2_oal   "yes"
lua54       "yes"
game        "gta5"

name        "x-instance"
version     "0.6.0"
repository  "https://github.com/XProject/x-instance"
description "Project-X Instance: Player instancing system like Rockstar"

shared_scripts {
    "shared/*.lua",
}

server_scripts {
    "server/*.lua"
}

client_scripts {
    "client/*.lua",
}