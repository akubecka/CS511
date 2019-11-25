-module(hw5).
-compile(export_all).
-author("Alex Kubecka").

watcher() ->
    receive
        {SensorPID, Measurement} ->
    spawn_monitor(Module,Function,Argument_list).