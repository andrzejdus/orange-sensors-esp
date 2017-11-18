local diode = require 'diode';
local config = require 'config';

local wifiHandler = {};

function wifiHandler.init(wifiReadyCallback, wifiInteruppedCallback)
    local statusDiode = diode.create(config.STATUS_DIODE_PIN);

    function wifiConnected(ssid)
        print(string.format('Wi-Fi "%s" is connected', ssid));
    end
    
    function gotIp(ip, netmask, gateway)
        print(string.format('IP is: %s, netmask: %s, gateway: %s', ip, netmask, gateway));

        statusDiode.turnOn();
        wifiReadyCallback();        
    end
    
    function wifiDisconnect(disconnectReason)
        print(string.format('Wi-Fi disconnected, reason %s', disconnectReason));

        statusDiode.blink();
        wifiInteruppedCallback();
    end

    print('Waiting for wifi...');
    statusDiode.blink();

    if (wifi.sta.status() == 5) then
        wifiConnected(wifi.sta.getconfig(true).ssid);
        local ip, netmask, gateway = wifi.sta.getip();
        gotIp(ip, netmask, gateway)
    else
        wifi.eventmon.register(wifi.eventmon.STA_CONNECTED, function(T)
            wifiConnected(T.SSID);
        end);

        wifi.eventmon.register(wifi.eventmon.STA_GOT_IP, function(T)
            gotIp(wifi.sta.getip(), T.netmask, T.gateway);
        end);
        
        wifi.eventmon.register(wifi.eventmon.STA_DISCONNECTED, function(T)
            wifiDisconnect(T.reason);
        end);
    end

    local noWifiCount = 0;
    local wifiCheckInterval = 1000;
    local wifiCheckTimer = tmr.create()
    wifiCheckTimer:register(wifiCheckInterval, tmr.ALARM_AUTO, function ()
        local isWifiConnected = wifi.sta.status() == 5;

        if (not isWifiConnected) then
            noWifiCount = noWifiCount + 1;
            local noWifiSeconds = noWifiCount * wifiCheckInterval / 1000;

            print(string.format('Wifi not connected for %d seconds', noWifiSeconds));
    
            if (noWifiSeconds > 15) then
                print('Reconnecting wifi');
                wifi.sta.disconnect();
                wifi.sta.connect();
    
                noWifiCount = 0;
            end
        else
            noWifiCount = 0;
        end
    end)
    wifiCheckTimer:start();
end

return wifiHandler;
