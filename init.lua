local delay = 5000;

function startApp()
    print('Starting app.lua');
    dofile('app.lua');
end

print('---------------------------');
print(string.format('Waiting %s ms before running app.lua (you can delete it now)', delay));

tmr.alarm(0, delay, 0, function()
    local OtaUpdate = require 'OtaUpdate';
    local otaUpdate = OtaUpdate.create();

    sntp.sync({'0.pool.ntp.org', '1.pool.ntp.org'}, function (seconds, microseconds, server, info)
        print('NTP sync finished', seconds, microseconds, server, info);

        local isUpdateAvailable = false;
        if (isUpdateAvailable) then
            otaUpdate.checkAndUpdate(function ()
                node.restart()
            end);
        else
            startApp();
        end

    end, function (code, message)
        print('NTP sync error, code', code, message);

        startApp();
    end);

end);
