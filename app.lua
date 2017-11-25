enduser_setup.start()

local wifiHandler = require 'wifiHandler';
local distance = require 'distance';
local otaUpdate = require 'otaUpdate';

local d = distance.create();
wifiHandler.init(function ()
    local ota = otaUpdate.create();
    ota.startUpdate(function ()
        d.start();
    end);
end, function ()
    d.stop();
end);
