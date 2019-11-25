-module(hw5).
-compile(export_all).
-author("Alex Kubecka").

start () ->
    {ok , [ N ]} = io:fread("enter  number  of sensors > ", "~d") ,
    if N =< 1 ->
        io:fwrite("setup: range  must be at  least  2~n", []) ;
    true  ->
        Num_watchers = 1 + (N div  10) ,
        setup_loop(N, Num_watchers)
    end.

setup_loop(0, )