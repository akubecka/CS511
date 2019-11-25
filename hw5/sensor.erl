-module(hw5).
-compile(export_all).
-author("Alex Kubecka").

sensor(WatcherPID, SensorPID) ->
    Measurement = rand:uniform(11).

    if 
        Measurement == 11 -> exit("anamolous reading");
        true -> WatcherPID!{SensorPID, Measurement}
    end.

        Sleep_time = rand:uniform(10000),
        timer:sleep(Sleep_time)
    }