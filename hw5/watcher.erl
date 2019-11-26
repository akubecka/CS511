-module(watcher).
-compile(export_all).
-author("Alex Kubecka").

start2(List) ->
    startProcess(List, []).

startProcess(List, TupleList) ->
    case length(List) == 0 of 
        true -> 
            io:fwrite("Watcher #~p starting - ~p~n",[self(), TupleList]),
            watcher(TupleList);
        false -> 
            [H|T] = List,
            {SensorPID, _} = spawn_monitor(sensor, sensorFunc, [self(), H]),
            startProcess(T, lists:append(TupleList, [{H, SensorPID}]))
        end.


watcher(TupleList) ->
    receive
        {SensorPID, Measurement} ->
            io:fwrite("Sensor ~4p reported measurement: ~2p~n", [SensorPID, Measurement]),
            watcher(TupleList);
        {'DOWN', _, process, PID, Reason} ->
            {SensorID, _} = lists:keyfind(PID, 2, TupleList),
            io:fwrite("Sensor ~4p died: ~2p~n", [SensorID, Reason]),
            restart(lists:delete({SensorID, PID}, TupleList), SensorID)
        end.

restart(TupleList, SensorID) ->
    {New_PID, _} = spawn_monitor(sensor, sensorFunc, [self(), SensorID]),
    io:fwrite("Watcher ~p new sensor list: ~w~n", [self(), lists:append(TupleList, [{SensorID, New_PID}])]),
    watcher(lists:append(TupleList, [{SensorID, New_PID}])).

