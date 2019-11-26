-module(sensor).
-compile(export_all).
-author("Alex Kubecka").

sensorFunc(WatcherPID, SensorID) ->
    Measurement = rand:uniform(11).
    case Measurement == 11 of 
        true -> exit("anamolous reading");
        false -> WatcherPID!{SensorID, Measurement}
    end,
    Sleep_time = rand:uniform(10000),
    timer:sleep(Sleep_time),
    sensorFunc(WatcherPID, SensorID).
