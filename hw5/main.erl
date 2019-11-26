-module(main).
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

%%subtract 10 everytime
%then create a range w/ complicated math so ids are unique

setup_loop(N, Num_watchers) ->
    setup(N, Num_watchers, 0 , []).

setup(N ,Num_watchers, ID, List) -> %maybe remove watcher
    case lists:length(List) == 10 of
        true -> 
            spawn(watcher, start, List),
            setup(N, Num_watchers-1, ID, []);
        false ->
            case N == 0 of
                true -> spawn(watcher, start, List);
                false -> setup(N-1, Num_watchers, ID + 1, lists:append(List, [ID])) %%++
            end,
    end.


