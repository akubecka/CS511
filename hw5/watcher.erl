-module(watcher).
-compile(export_all).
-author("Alex Kubecka").

start(List) ->
    start2(List, []).

start2(List, TupleList) ->
    case length(List) == 0 of 
        true -> 
            watcher(TupleList);
        false -> 
            {H|T} = List,
            {SensorPID, _} = spawn_monitor(sensor, sensorFunc, [self(), H]),
            start2(T, lists:append(TupleList, {H, SensorPID}))
        end.


watcher(List) ->

    receive
        {SensorPID, Measurement} ->
            {SensorPID, _} = spawn_monitor(sensor,sensorFunc, Argument_list),
        {'DOWN', _, _, SensorPID, "anamolous reading"} ->