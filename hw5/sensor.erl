-module(hw5).
-compile(export_all).
-author("Alex Kubecka").

sensor(WatcherPID, SensorPID) ->
    Measurement = rand:uniform(11).
    case Measurement == 11 of 
        true -> exit("anamolous reading");
        false -> WatcherPID!{SensorPID, Measurement}
    end,
    Sleep_time = rand:uniform(10000),
    timer:sleep(Sleep_time),
    sensor(WatcherPID, SensorPID).
