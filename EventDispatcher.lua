local EventDispatcher = {}

EventDispatcher.create = function ()
    local export = {};

    local listeners;
    local listenersCount = 0;

    function export.addListener(listener)
        print('add', listener);
        listeners = { next = listeners, value = listener };
        listenersCount = listenersCount + 1;
    end

    function export.removeListener(listener)
        local current = listeners
        local prev;

        while current do
            if (current.value == listener) then
                prev = next;
                listenersCount = listenersCount - 1;
                break;
            end

            prev = current;
            current = current.next;
        end
    end

    function export.dispatch(data, callback)
        if (listenersCount == 0) then
            callback();
            return;
        end

        local callbacksFinishedCount = 0;

        local current = listeners

        while current do
            print(current);
            local listener = current.value;
            listener(data, function ()
                callbacksFinishedCount = callbacksFinishedCount + 1;
                if (callbacksFinishedCount == listenersCount) then
                    callback();
                end
            end);
            current = current.next;
        end
    end

    return export;
end

return EventDispatcher;
