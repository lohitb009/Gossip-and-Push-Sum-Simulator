%%%-------------------------------------------------------------------
%%% @author User
%%% @copyright (C) 2022, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 09. Oct 2022 12:21 PM
%%%-------------------------------------------------------------------
-module(scratchpad).
-author("User").

%% API
-export([start/0]).

start() ->
  ReplaceInit = fun() ->
    io:format("Hello") end,
  ReplaceInit().

io:format("Reached : ~p ~n",[self()]),
Index = string:str(FullList, [self()]),
case length(FullList) of
1 ->
io:format("My Line Topology has converged .. :'( ~n");

_ ->
OldEstimate = Sum/Weight,
NewEstimate = (Sum+S)/(Weight+W),

if
(OldEstimate-NewEstimate) < 0.0000000001 ->
%%% Chk for rounds

if
Round =:= 2->
Neighbors = getNeighbors_line(Index,length(FullList),FullList),
Idx = rand:uniform(length(Neighbors)),
{_,ActorPid} = lists:nth(Idx,Neighbors),
ActorPid ! {line,FullList--[self()],(Sum+S)/2,(Weight+W)/2},
io:format("Round is ~p , sent msg to : ~p ~n",[Round+1,ActorPid]),
io:format("ActorPid is done ~p ~n ",[self()]);

true ->
Neighbors = getNeighbors_line(Index,length(FullList),FullList),
Idx = rand:uniform(length(Neighbors)),
{_,ActorPid} = lists:nth(Idx,Neighbors),
ActorPid ! {line,FullList,(Sum+S)/2,(Weight+W)/2},
io:format("Round is ~p , sent msg to : ~p ~n",[Round+1,ActorPid]),
main_loop((Sum+S)/2, (Weight+W)/2, Round+1)
end;

true ->
Neighbors = getNeighbors_line(Index,length(FullList),FullList),
Idx = rand:uniform(length(Neighbors)),
{_,ActorPid} = lists:nth(Idx,Neighbors),
ActorPid ! {line,FullList,(Sum+S)/2,(Weight+W)/2},
io:format("Round is ~p , sent msg to : ~p ~n",[Round+1,ActorPid]),
main_loop((Sum+S)/2, (Weight+W)/2, 0)
end
end;



  -----


io:format("____START____~n PID: ~p ~n Round: ~p ~n S: ~p ~n W: ~p ~n",[self(),Round,Sum+S,Weight+W]),

Index = string:str(FullList, [self()]),
case Round of
2 ->
%%          io:format("Round is currently 2 at : ~p ~n",[self()]),
Neighbors = getNeighbors_line(Index,length(FullList),FullList),

case length(Neighbors) of
0 ->
io:format("All the neighbors are dead at :~p~n",[self()]),
io:format("____END____~n PID: ~p ~n Round: ~p ~n S: ~p ~n W: ~p ~n",[self(),Round,Sum+S,Weight+W]);

_ ->
Idx = rand:uniform(length(Neighbors)),
{_,ActorPid} = lists:nth(Idx,Neighbors),
ActorPid ! {line,FullList--[self()], (Sum+S)/2,(Weight+W)/2, SupPID, self()},
io:format("Round is ~p at ~p , sent msg to : ~p ~n",[Round+1,self(),ActorPid]),
io:format("____END____~n PID: ~p ~n Round: ~p ~n S: ~p ~n W: ~p ~n",[self(),Round,(Sum+S)/2,(Weight+W)/2])
end;

_ ->
Neighbors = getNeighbors_line(Index,length(FullList),FullList),

case length(Neighbors) of
0 ->
io:format("All the neighbors are dead at :~p~n",[self()]),

io:format("____END____~n PID: ~p ~n Round: ~p ~n S: ~p ~n W: ~p ~n",[self(),Round,(Sum+S),(Weight+W)]),
main_loop((Sum+S), (Weight+W), 0);
%%            SupPID ! {pushSum_Line,FullList};
_ ->
Idx = rand:uniform(length(Neighbors)),
{_,ActorPid} = lists:nth(Idx,Neighbors),
ActorPid ! {line,FullList--[self()],(Sum+S)/2,(Weight+W)/2, SupPID, self()},
io:format("Round is ~p at ~p , sent msg to : ~p ~n",[Round+1,self(),ActorPid]),
io:format("____END____~n PID: ~p ~n Round: ~p ~n S: ~p ~n W: ~p ~n",[self(),Round,(Sum+S)/2,(Weight+W)/2]),
main_loop((Sum+S)/2, (Weight+W)/2, 0)
end
end;

