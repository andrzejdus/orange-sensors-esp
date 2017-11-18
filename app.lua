enduser_setup.start()

local wifiHandler = require 'wifiHandler';
local distance = require 'distance';

local d = distance.create();
wifiHandler.init(function ()
    d.start();
end, function ()
    d.stop();
end);
