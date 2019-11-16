-module(server).

-export([start_server/0]).

-include_lib("./defs.hrl").

-spec start_server() -> _.
-spec loop(_State) -> _.
-spec do_join(_ChatName, _ClientPID, _Ref, _State) -> _.
-spec do_leave(_ChatName, _ClientPID, _Ref, _State) -> _.
-spec do_new_nick(_State, _Ref, _ClientPID, _NewNick) -> _.
-spec do_client_quit(_State, _Ref, _ClientPID) -> _NewState.

start_server() ->
    catch(unregister(server)),
    register(server, self()),
    case whereis(testsuite) of
	undefined -> ok;
	TestSuitePID -> TestSuitePID!{server_up, self()}
    end,
    loop(
      #serv_st{
	 nicks = maps:new(), %% nickname map. client_pid => "nickname"
	 registrations = maps:new(), %% registration map. "chat_name" => [client_pids]
	 chatrooms = maps:new() %% chatroom map. "chat_name" => chat_pid
	}
     ).

loop(State) ->
    receive 
	%% initial connection
	{ClientPID, connect, ClientNick} ->
	    NewState =
		#serv_st{
		   nicks = maps:put(ClientPID, ClientNick, State#serv_st.nicks),
		   registrations = State#serv_st.registrations,
		   chatrooms = State#serv_st.chatrooms
		  },
	    loop(NewState);
	%% client requests to join a chat
	{ClientPID, Ref, join, ChatName} ->
	    NewState = do_join(ChatName, ClientPID, Ref, State),
	    loop(NewState);
	%% client requests to join a chat
	{ClientPID, Ref, leave, ChatName} ->
	    NewState = do_leave(ChatName, ClientPID, Ref, State),
	    loop(NewState);
	%% client requests to register a new nickname
	{ClientPID, Ref, nick, NewNick} ->
	    NewState = do_new_nick(State, Ref, ClientPID, NewNick),
	    loop(NewState);
	%% client requests to quit
	{ClientPID, Ref, quit} ->
	    NewState = do_client_quit(State, Ref, ClientPID),
	    loop(NewState);
	{TEST_PID, get_state} ->
	    TEST_PID!{get_state, State},
	    loop(State)
    end.

%% executes join protocol from server perspective
do_join(ChatName, ClientPID, Ref, State) ->
	case maps:find(ChatName, State#serv_st.chatrooms) of
		error -> %%Chatroom does not already exist
			ChatPID = spawn(chatroom, start_chatroom, [ChatName]),
			ClientNick = maps:find(ClientPID, State#serv_st.nicks),	
			ChatPID!{self(), Ref, register, ClientPID, ClientNick},
			State#serv_st{registrations = maps:put(ChatName, [ClientPID], State#serv_st.registrations), chatrooms = maps:put(ChatName, ChatPID, State#serv_st.chatrooms)};
		{ok, Value} -> %%Chatroom exists
			ClientNick = maps:find(ClientPID, State#serv_st.nicks),
			Value!{self(), Ref, register, ClientPID, ClientNick},
			State#serv_st{registrations = maps:update(ChatName, lists:append([ClientPID], maps:get(ChatName, State#serv_st.registrations)), State#serv_st.registrations)}
	end.

%% executes leave protocol from server perspective
do_leave(ChatName, ClientPID, Ref, State) ->
	ChatPID = maps:get(ChatName, State#serv_st.chatrooms),
	Updated = State#serv_st{registrations = maps:update(ChatName, lists:delete([ClientPID], maps:get(ChatName, State#serv_st.registrations)), State#serv_st.registrations)},
	ChatPID!{self(), Ref, unregister, ClientPID},
	ClientPID!{self(), Ref, ack_leave},
	Updated.


%% executes new nickname protocol from server perspective
do_new_nick(State, Ref, ClientPID, NewNick) ->
    io:format("Server NewNick"),
	case lists:member(NewNick, maps:values(State#serv_st.nicks)) of
		false -> %%Nickname not already used
			io:format("false Server NewNick"),
			Updated = State#serv_st{nicks = maps:update(ClientPID, NewNick, State#serv_st.nicks)},
			Fun = fun(K,V,Chats) ->
				case lists:member(ClientPID, V) of
					true ->
						lists:append([K], Chats);
					false ->
						Chats
					end
				end,
				ListOfChats = maps:fold(Fun, [], Updated#serv_st.registrations),
				io:format(" mid false Server NewNick"),
			lists:foreach(fun(X) ->
				maps:get(X, Updated#serv_st.chatrooms)!{self(), Ref, update_nick, ClientPID, NewNick}
				end,
				ListOfChats),
			ClientPID!{self(), Ref, ok_nick},
			io:format(" end false Server NewNick"),
			Updated;
		true ->
			io:format("true Server NewNick"),
			ClientPID!{self(), Ref, err_nick_used},
			State
	end.

%% executes client quit protocol from server perspective
do_client_quit(State, Ref, ClientPID) ->
	Updated1 = State#serv_st{nicks = maps:remove(ClientPID, State#serv_st.nicks)},
	Fun = fun(K,V,Chats) ->
		case lists:member(ClientPID, V) of
			true ->
				lists:append([K], Chats);
			false ->
				Chats
			end
		end,
	ListOfChats = maps:fold(Fun, [], Updated1#serv_st.registrations),
	lists:foreach(fun(X) ->
		maps:get(X, Updated1#serv_st.chatrooms)!{self(), Ref, unregister, ClientPID}
		end,
		ListOfChats),
		NewRegMap = maps:fold(fun(K,V,Map)->
			case lists:member(ClientPID,V) of
				true->
					maps:update(K, lists:delete(ClientPID, V), Map);
				false ->
					ok
				end
			end,
			Temp,
			Temp),
	Updated2 = Updated1#serv_st{registrations = NewRegMap},
	ClientPID!{self(), Ref, ack_quit},
	Updated2.