local otaUpdate = {};

function otaUpdate.create()
    local export = {};

    local OTA_BASE_URL = 'https://api.github.com/repos/andrzejdus/orange-sensors-esp/contents';

    function getFile(url, onSuccess)
        local headers = 'Content-Type: application/json\n';

        print(string.format('Getting file list from %s', url));
        http.get(url, headers, function (code, body, headers)
            if (code ~= 200) then
                print(string.format('HTTP request failed, status %s', code));
            else
                onSuccess(body);
            end
        end);
    end

    function getGitHubFile(filename, onSuccess)
        getFile(string.format('%s/%s', OTA_BASE_URL, filename), 
                function (body)
            local decodedBody = sjson.decode(body);

            getFile(decodedBody.download_url, onSuccess);
        end);
    end

    function export.listFiles()
        getGitHubFile('ota-files.json', function (body)
            local filesList = sjson.decode(body);
            for key, filename in pairs(filesList) do
                print('Getting', filename);
                getGitHubFile(filename, function (body)
                    print(body);
                end);
            end
        end);
    end

    return export;
end

return otaUpdate;
