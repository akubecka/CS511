-module(main).
-compile(export_all).
-author("Alex Kubecka").

start () ->
    {ok , [ N ]} = io:fread("enter number of sensors > ", "~d") ,
    if N =< 1 ->
        io:fwrite("setup: range must be at least 2~n", []) ;
    true  ->
        Num_watchers = 1 + (N div  10) ,
        setup_loop(N, Num_watchers)
    end.

setup_loop(N, _) ->
    setup(N, 0 , []).

setup(N , ID, List) -> 
    case length(List) == 10 of
        true -> 
            spawn(watcher, start2, [List]),
            setup(N, ID, []);
        false ->
            case N == 0 of
                true -> 
                    spawn(watcher, start2, [List]);
                false -> 
                    setup(N-1, ID + 1, lists:append(List, [ID]))
            end
    end.

