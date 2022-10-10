-module(supervisorMod_bonus).
-author("lohit").
-export([startSupervisor/4]).

startSupervisor(TotalNodes, Topology, Algorithm, FailNodes) ->
  supervisorMod(TotalNodes, Topology, Algorithm, FailNodes).

%%%% --- Internal Function ---
supervisorMod(TotalNodes, Topology, Algorithm, FailNodes) ->

  case Topology of

    "FullNetwork" ->
      FullList = fillUpFullNetwork(Algorithm, TotalNodes, []),
      %%% io:format("Full List is ~p ~n ",[FullList]),

      %%% Fail (x) nodes
      UpdatedFullList = failXNodes(FullList, FailNodes),

      %%% io:format("Updated Length is ~p ~n",[length(UpdatedFullList)]),
      %%% timer:sleep(5000),

      {RealTime, _} = statistics(wall_clock),
      io:format("Current Start Real Time: ~p milliseconds ~n",[RealTime]),
      timer:sleep(5000),

      %%% Get a random ActorPid
      ActorPid = getAliveActorPid(UpdatedFullList),

      %%% Decide for Algorithm
      case Algorithm of

        "PushSum" ->
          ActorPid ! {fullNetwork, UpdatedFullList, 0, 0}

      end
  end.

%%% --- Full Network Topology, fill up Star Network
fillUpFullNetwork(_, 0, List) ->
  List;
fillUpFullNetwork(Algorithm, TotalNodes, List) ->
  case Algorithm of
    "PushSum" ->
      Current = TotalNodes,
      {ok, ActorPid} = pushSum_bonus:startLink(Current),
      fillUpFullNetwork(Algorithm, TotalNodes - 1, [ActorPid | List])
  end.


%%% Fail (x) nodes
failXNodes(FullList, 0) ->
  FullList;
failXNodes(FullList, FailNodes) ->
  %%% Get a random ActorPid
  Index = rand:uniform(length(FullList)),
  ActorPid = lists:nth(Index, FullList),
  exitProcess(ActorPid),
  %%% io:format("2. Actor Id ~p is alive ~p ~n ",[ActorPid,is_process_alive(ActorPid)]),

  %%% To make all the nodes converge, remove the ActorPid as soon as it dies from the list
  failXNodes((FullList--[ActorPid]), FailNodes - 1).


%%% get alive actor
getAliveActorPid(FullList) ->
  %%% Get a random ActorPid
  Index = rand:uniform(length(FullList)),
  ActorPid = lists:nth(Index, FullList),

  case is_process_alive(ActorPid) of
    true ->
      ActorPid;
    false ->
      getAliveActorPid(FullList)
  end.

exitProcess(ActorPid) ->
  ActorPid ! {exit,ActorPid}.
  %%% io:format("1. Actor Id ~p is alive ~p ~n ",[ActorPid,is_process_alive(ActorPid)]).