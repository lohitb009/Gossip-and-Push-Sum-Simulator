-module(supervisorMod).
-author("lohit").
-export([startSupervisor/3]).

startSupervisor(TotalNodes,Topology,Algorithm) ->
  supervisorMod(TotalNodes,Topology,Algorithm).

%%%% --- Internal Function ---
supervisorMod(TotalNodes,Topology,Algorithm) ->
  {RealTime, _} = statistics(wall_clock),
  io:format("Total Real Time at Start: ~p milliseconds ~n",[RealTime]),
  io:format("Sleeping for 5 seconds. Please note above value. ~n"),
  timer:sleep(5000),
  case Topology of

    "Line"  ->
      LineList = fillUp1DList(Algorithm,TotalNodes,[]),

      %%% Get a random ActorPid
      Index = rand:uniform(TotalNodes),
      ActorPid = lists:nth(Index,LineList),

      %%% Decide for Algorithm
      case Algorithm of

        "Gossip"  ->
          ActorPid ! {line,TotalNodes,Index,LineList,self()},
          lineConvergenceOfNodes();

        "PushSum" ->
          ActorPid ! {line,LineList,Index,0,0,false,self()},
          lineConvergenceOfNodes()

      end;

    "2D"  ->
      SqareDim = math:ceil(math:sqrt(TotalNodes)),
      List_2D = fillUp2DList(Algorithm,SqareDim,SqareDim,[]),

      % Get a random ActorPid
      Index1 = rand:uniform(trunc(SqareDim)),
      Index2 = rand:uniform(trunc(SqareDim)),
      ActorPid = lists:nth(Index2,lists:nth(Index1,List_2D)),

      io:format("Dimensions of grid : ~p~n List_2d : ~p~n Random ActorPID Selected for start : ~p~n",[SqareDim, List_2D, ActorPid]),

      %%% Decide for Algorithm
      case Algorithm of

        "Gossip"  ->
          ActorPid ! {"2D", SqareDim, Index1, Index2 ,List_2D},
          gossip_started;

        "PushSum" ->
%%          pass
          ActorPid ! {"2D", SqareDim, Index1, Index2 ,List_2D, 0, 0, false, false},
          pushsum_started
      end;

    "FullNetwork" ->
      FullList = fillUpFullNetwork(Algorithm,TotalNodes,[]),
      %%% io:format("Full List is ~p ~n ",[FullList]),

      %%% Get a random ActorPid
      Index = rand:uniform(TotalNodes),
      ActorPid = lists:nth(Index,FullList),

      %%% Decide for Algorithm
      case Algorithm of

        "Gossip"  ->
          ActorPid ! {fullNetwork,FullList,false};

        "PushSum" ->
          ActorPid ! {fullNetwork,FullList,0,0}
      end;

    "Imperfect3D" ->
      SqareDim = math:ceil(math:sqrt(TotalNodes)),
      List_2D = fillUp2DList(Algorithm,SqareDim,SqareDim,[]),

      % Get a random ActorPid
      Index1 = rand:uniform(trunc(SqareDim)),
      Index2 = rand:uniform(trunc(SqareDim)),
      ActorPid = lists:nth(Index2,lists:nth(Index1,List_2D)),

      io:format("Dimensions of grid : ~p~n List_2d : ~p~n Random ActorPID Selected for start : ~p~n",[SqareDim, List_2D, ActorPid]),

      %%% Decide for Algorithm
      case Algorithm of

        "Gossip"  ->
          ActorPid ! {imp_3d, SqareDim, Index1, Index2 ,List_2D},
          gossip_started;

        "PushSum" ->
          ActorPid ! {imp_3d, SqareDim, Index1, Index2 ,List_2D, 0, 0, false, false},
          pushsum_started
      end
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
      Current = TotalNodes,
      {ok,ActorPid} = pushSum:startLink(Current),
      fillUp1DList(Algorithm,TotalNodes-1,[ActorPid|List])
  end.

%%% --- 2D Topology, fill up 2D Matrix
fillUp2DList(_,_,0.0,List) ->
  List;
fillUp2DList(Algorithm,SqareDim,Curr,List) ->
  EachRow = fillUpEach2DList(Algorithm,SqareDim,[]),
  fillUp2DList(Algorithm,SqareDim,Curr-1,[EachRow|List]).

fillUpEach2DList(_,0.0,List) ->
  List;
fillUpEach2DList(Algorithm,SqareDim,List) ->
  case Algorithm of
    "Gossip"->
      {ok,ActorPid} = gossip:startLink(),
      fillUpEach2DList(Algorithm,SqareDim-1,[ActorPid|List]);
    "PushSum" ->
      Current = SqareDim,
      {ok,ActorPid} = pushSum:startLink(Current),
      fillUpEach2DList(Algorithm,SqareDim-1,[ActorPid|List])
  end.

%%% --- Full Network Topology, fill up Star Network
fillUpFullNetwork(_,0,List) ->
  List;
fillUpFullNetwork(Algorithm,TotalNodes,List) ->
  case Algorithm of
    "Gossip"->
      {ok,ActorPid} = gossip:startLink(),
      fillUpFullNetwork(Algorithm,TotalNodes-1,[ActorPid|List]);
    "PushSum" ->
      Current = TotalNodes,
      {ok,ActorPid} = pushSum:startLink(Current),
      fillUpFullNetwork(Algorithm,TotalNodes-1,[ActorPid|List])
  end.


%%%% Supervisor receives line communication
lineConvergenceOfNodes() ->
  receive
    {line,UpdatedList} ->
      %%% chk the list and find the Alive Actors --- count to start from 1
      {Status,ActorPid,Index} = chkForAliveActors(length(UpdatedList),UpdatedList),
      case Status of
          fail ->
            io:format("Entire nodes in topology have converged ~n");
          ok ->
            %%% send the communication
            ActorPid ! {line,length(UpdatedList),Index,UpdatedList,self()},
            lineConvergenceOfNodes()
      end;

    {line_pushsum,UpdatedList} ->
       io:format("RECEIVE COMM ~n"),
      %%% chk the list and find the Alive Actors --- count to start from 1

      {Status,ActorPid,Index} = chkForAliveActors(length(UpdatedList),UpdatedList),

      case Status of
        fail ->
          io:format("Entire nodes in topology have converged ~n");

        ok ->
          %%% send the communication
          ActorPid ! {line, UpdatedList, Index, 0, 0, false, self()},
          lineConvergenceOfNodes()
      end
  end.

chkForAliveActors(0,_) ->
  {fail,"None","None"};
chkForAliveActors(Count,UpdatedList) ->
  ActorPid = lists:nth(Count, UpdatedList),
  case is_process_alive(ActorPid) of
    true  ->
      {ok,ActorPid,Count};
    false ->
      chkForAliveActors(Count-1,UpdatedList)
end.
