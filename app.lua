enduser_setup.start()

local wifiHandler = require 'wifiHandler';
local distance = require 'distance';

wifiHandler.init(function ()
    distance.start();
end, function ()
    distance.stop();
end);
