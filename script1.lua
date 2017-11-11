enduser_setup.start()

local wifiHandler = require 'wifiHandler';
local distance = require 'distance';

wifiHandler.init(1, function ()
    distance.start();
end, function ()
    distance.stop();
end);

-- pwm.setup(5, 120, 500)
-- pwm.start(5)
