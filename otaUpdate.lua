local otaUpdate = {};

function otaUpdate.create()
    local export = {};

    local OTA_BASE_URL = 'https://api.github.com';

    function export.listFiles()
        local url = string.format('%s/%s', OTA_BASE_URL, 'repos/andrzejdus/orange-sensors-esp/contents/');
        local headers = 'Content-Type: application/json\n';

        print(string.format('Getting file list from %s', url));
        http.get(url, headers, function (code, body, headers)
            if (code ~= 200) then
                print(string.format('HTTP request failed, status %s', code));
            else
                local decodedBody = sjson.decode(body);

                print(body);
                for key, value in pairs(decodedBody) do
                    print(key, value);
                end
            end
        end);
    end

    return export;
end

return otaUpdate;
