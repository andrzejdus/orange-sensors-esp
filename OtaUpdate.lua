local OtaUpdate = {};

function OtaUpdate.create()
    local export = {};

    local OTA_BASE_URL = 'http://raw.githubusercontent.com/andrzejdus/orange-sensors-esp/master';

    function export.startUpdate(finishedCallback, retryCount)
        getOtaFile('ota-files.json', function (code, body)
            if (code ~= -1) then
                local filesList = sjson.decode(body);
                for key, filename in pairs(filesList) do
                    print('Will try to update', key, filename);
                end
                updateFiles(filesList, 1, 0);
            else
                print('Error updating, response', body);

                if (retryCount == nil) then
                    retryCount = 0;
                end

                if (retryCount < 3) then
                    print('Retrying OTA update, times', retryCount + 1);
                    export.startUpdate(finishedCallback, retryCount + 1);
                else
                    finishedCallback();
                end
            end
        end);
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
        getFile(string.format('%s/%s', OTA_BASE_URL, filename), finishedCallback);
    end

    function updateFiles(filesList, index, retryCount)
        local filename = filesList[index];
        print('Getting ', filename);
        getOtaFile(filename, function (code, body)
            if (code ~= -1) then
                print(body);

                saveFile(content);

                if (index + 1 <= table.getn(filesList)) then
                    updateFiles(filesList, index + 1, 0);
                end
            else
                if (retryCount < 10) then
                    updateFiles(filesList, index, retryCount + 1);
                else
                    print('Max retries for file reached, filename', filename);
                    updateFiles(filesList, index + 1, 0);
                end
            end
        end);
    end

    function saveFile(content)
        if file.open(string.format('_%s', filename), 'a+') then
            file.writeline(content);
            file.close();
        end
    end

    return export;
end

return OtaUpdate;
