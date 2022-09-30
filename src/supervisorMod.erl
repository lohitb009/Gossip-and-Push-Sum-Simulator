%%%-------------------------------------------------------------------
%%% @author lohit
%%% @copyright (C) 2022, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 28. Sep 2022 03:27 pm
%%%-------------------------------------------------------------------
-module(supervisorMod).
-author("lohit").

%% API
-export([startSupervisor/3]).

startSupervisor(TotalNodes,Topology,Algorithm) ->
    supervisorMod(TotalNodes,Topology,Algorithm).

%%%% --- Internal Function ---
supervisorMod(TotalNodes,Topology,Algorithm) ->
  case Topology of

    "Line"  ->
      LineList = fillUp1DList(Algorithm,TotalNodes,[]),

      %%% Get a random ActorPid
      Index = rand:uniform(TotalNodes),
      ActorPid = lists:nth(Index,LineList),

      %%% Decide for Algorithm
      case Algorithm of

        "Gossip"  ->
          ActorPid ! {line,TotalNodes,Index,LineList};

        "PushSum" ->
          pass

      end;

    "2D"  ->
        pass;

    "FullNetwork" ->
        pass;

    "Imperfect2D" ->
        pass
  end.

%%% --- Line Topology, fill up 1D List
fillUp1DList(_,0,List) ->
  List;
fillUp1DList(Algorithm,TotalNodes,List) ->
  case Algorithm of
    "Gossip"->
        {ok,ActorPid} = gossip:startLink(),
        fillUp1DList(Algorithm,TotalNodes-1,[ActorPid|List]);
    "PushSum" ->
        pass
  end.