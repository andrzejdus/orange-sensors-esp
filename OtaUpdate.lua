local Config = require 'Config';

local OtaUpdate = {};

function OtaUpdate.create()
    local export = {};

    function export.checkAndUpdate(finishedCallback, retryCount)
        getOtaFile('ota-files.json', function (code, body)
            if (code ~= -1) then
                local filesList = sjson.decode(body);
                for key, filename in pairs(filesList) do
                    print('Will try to update', key, filename);
                end
                updateFiles(filesList, 1, 0, finishedCallback);
            else
                print('Error updating, response', body);

                if (retryCount == nil) then
                    retryCount = 0;
                end

                if (retryCount < 3) then
                    print('Retrying OTA update, times', retryCount + 1);
                    export.startUpdate(finishedCallback, retryCount + 1);
                else
                    finishedCallback(false);
                end
            end
        end);
    end

    function getCurrentVersion()
    end

    function getFile(url, finishedCallback)
        local headers = 'Content-Type: application/json\n';

        print(string.format('Getting file from %s', url));
        http.get(url, headers, function (code, body, headers)
            if (code == -1) then
                print(string.format('HTTP request failed, URL %s, status %s', url, code));
            else
                print(string.format('HTTP request successful, URL %s', url));
            end
            finishedCallback(code, body);
        end);
    end

    function getOtaFile(filename, finishedCallback)
        getFile(string.format('%s/%s', Config.OTA_URL, filename), finishedCallback);
    end

    function updateFiles(filesList, index, retryCount, finishedCallback)
        local filename = filesList[index];
        print('Getting ', filename);
        getOtaFile(filename, function (code, body)
            if (code ~= -1) then
                saveFile(filename, body);

                if (index + 1 <= table.getn(filesList)) then
                    updateFiles(filesList, index + 1, 0, finishedCallback);
                else
                    finishedCallback();
                end
            else
                if (retryCount < 10) then
                    updateFiles(filesList, index, retryCount + 1, finishedCallback);
                else
                    print('Max retries for file reached, filename', filename);
                    updateFiles(filesList, index + 1, 0, finishedCallback);
                end
            end
        end);
    end

    function saveFile(filename, content)
        if file.open(string.format('_%s', filename), 'w+') then
            file.writeline(content);
            file.close();
        end
    end

    return export;
end

return OtaUpdate;
