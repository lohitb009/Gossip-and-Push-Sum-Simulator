-module(gossip).
-author("lohit").
-export([startLink/0]).
-export([main_loop/1]).

%%%% ==== Expose the API to client
startLink() ->
  ActorPid = spawn_link(?MODULE,main_loop,[0]),
  %%% io:format("ActorPID Started At : ~p~n",[ActorPid]),
  {ok,ActorPid}.

%%% ==== Internal APIs not to be exposed
main_loop(RumorCount) ->
  receive
    {line,TotalNodes,Index,LineList} ->
      case RumorCount of
        10  ->
          io:format("Converged By Itself ~n"),
          Neighbors = getNeighbors(Index,TotalNodes,LineList),
          case length(Neighbors) of
            0 ->
              io:format("Can't route anywhere, all the neighbors are dead :'( ~n");
            1 ->
              {Idx,ActorPid} = lists:nth(1,Neighbors),
              ActorPid ! {line,TotalNodes,Idx,LineList};
            2 ->
              NeighborIndex = rand:uniform(length(Neighbors)),
              {Idx,ActorPid} = lists:nth(NeighborIndex,Neighbors),
              ActorPid ! {line,TotalNodes,Idx,LineList}
          end;

        _ ->
          %% These are all alive neighbors
          Neighbors = getNeighbors(Index,TotalNodes,LineList),
          case length(Neighbors) of
             0 ->
               %%% My both neighbors are dead, I am kind of dead as well
               io:format("Converged By Neighbors Death ~n");

            _ ->
              %%% Randomly select any neighbor from the list
              %%% Get a random ActorPid
              NeighborIndex = rand:uniform(length(Neighbors)),
              {Idx,ActorPid} = lists:nth(NeighborIndex,Neighbors),
              ActorPid ! {line,TotalNodes,Idx,LineList},
              main_loop(RumorCount+1)
          end
      end;
    {"2D",SquareDim,Index1, Index2 ,List_2D} ->
      case RumorCount of
        10  ->
          io:format("Current PID : ~p RumorCount : ~p ~n",[self(), RumorCount]),
          io:format("Converged By Itself ~n"),
          Neighbors = getNeighbors_2d(Index1, Index2, SquareDim,List_2D),
          case length(Neighbors) of
            0 ->
              io:format("Can't route anywhere, all the neighbors are dead :'( ~n");
            1 ->
              {[Idx1, Idx2],ActorPid} = lists:nth(1,Neighbors),
              ActorPid ! {"2D", SquareDim, Idx1, Idx2 ,List_2D};
            _ ->
              NeighborIndex = rand:uniform(length(Neighbors)),
              {[Idx1, Idx2],ActorPid} = lists:nth(NeighborIndex,Neighbors),
              ActorPid ! {"2D", SquareDim, Idx1, Idx2 ,List_2D}
          end;

        _ ->
          io:format("Current PID : ~p RumorCount : ~p ~n",[self(), RumorCount]),
          %% These are all alive neighbors
          Neighbors = getNeighbors_2d(Index1, Index2, SquareDim,List_2D),
          case length(Neighbors) of
            0 ->
              %%% My both neighbors are dead, I am kind of dead as well
              %%% Iteratively select the ActorPid from the line list
              %%% Select active neighbor
              io:format("Converged By Neighbors Death ~n");

            _ ->
              %%% Randomly select any neighbor from the list
              %%% Get a random ActorPid
              NeighborIndex = rand:uniform(length(Neighbors)),

              {[Idx1, Idx2],ActorPid} = lists:nth(NeighborIndex,Neighbors),
              ActorPid ! {"2D", SquareDim, Idx1, Idx2 ,List_2D},
              io:format("Current PID : ~p New RumorCount : ~p ~n",[self(), RumorCount+1]),
              main_loop(RumorCount+1)
          end
      end;

    {fullNetwork,FullList} ->
      case length(FullList) of
        1 ->
          io:format("My Full Network Topology has converged .. :'( ~n");

        _ ->
          case RumorCount of
            9  ->
%%          io:format("Received 10 msgs at ~p ~n",[self()]),
              Idx = rand:uniform(length(FullList--[self()])),
              ActorPid = lists:nth(Idx,FullList--[self()]),
              ActorPid ! {fullNetwork,FullList--[self()]},
              io:format("ActorPid is done ~p ~n ",[self()]);

            _ ->
              io:format("At ~p ~n ",[self()]),
              Idx = rand:uniform(length(FullList--[self()])),
              ActorPid = lists:nth(Idx,FullList--[self()]),
              ActorPid ! {fullNetwork,FullList},
              main_loop(RumorCount+1)
          end
      end;

%%          io:format("Received a msg at ~p ~n",[self()]),
%%          %%% Randomly select any neighbor and continue
%%          ActorPid = getNeighbors_fullNetwork(0, length(FullList--[self()]), FullList--[self()]),
%%          ActorPid ! {fullNetwork, length(FullList), FullList},
%%          io:format("Actor pidd selected : ~p ~n",[ActorPid]),
%%          main_loop(RumorCount+1)
%%          case Idx of
%%            -1  ->
%%              io:format("More than 98% nodes call have converged, THE END..~n");
%%            _   ->
%%              ActorPid ! {fullNetwork, TotalNodes, FullList},
%%              main_loop(RumorCount+1)
%%          end
%%      end;
    {imp_3d, SquareDim,Index1, Index2 ,List_2D} ->
      case RumorCount of
        10  ->
          io:format("Current PID : ~p RumorCount : ~p ~n",[self(), RumorCount]),
          io:format("Converged By Itself ~n"),
          Neighbors = getNeighbors_i3d(Index1, Index2, SquareDim,List_2D),
          case length(Neighbors) of
            0 ->
              io:format("Can't route anywhere, all the neighbors are dead :'( ~n");
            1 ->
              {[Idx1, Idx2],ActorPid} = lists:nth(1,Neighbors),
              ActorPid ! {imp_3d, SquareDim, Idx1, Idx2 ,List_2D};
            _ ->
              NeighborIndex = rand:uniform(length(Neighbors)),
              {[Idx1, Idx2],ActorPid} = lists:nth(NeighborIndex,Neighbors),
              ActorPid ! {imp_3d, SquareDim, Idx1, Idx2 ,List_2D}
          end;

        _ ->
          io:format("Current PID : ~p RumorCount : ~p ~n",[self(), RumorCount]),
          %% These are all alive neighbors
          Neighbors = getNeighbors_2d(Index1, Index2, SquareDim,List_2D),
          case length(Neighbors) of
            0 ->
              %%% My both neighbors are dead, I am kind of dead as well
              %%% Iteratively select the ActorPid from the line list
              %%% Select active neighbor
              io:format("Converged By Neighbors Death ~n");

            _ ->
              %%% Randomly select any neighbor from the list
              %%% Get a random ActorPid
              NeighborIndex = rand:uniform(length(Neighbors)),

              {[Idx1, Idx2],ActorPid} = lists:nth(NeighborIndex,Neighbors),
              ActorPid ! {"2D", SquareDim, Idx1, Idx2 ,List_2D},
              io:format("Current PID : ~p New RumorCount : ~p ~n",[self(), RumorCount+1]),
              main_loop(RumorCount+1)
          end
      end
  end.

%%% get the Neighbors for Line Topology
getNeighbors(Index,TotalNodes,LineList) ->
  NeighborsList = forLoop(Index,1,[-1,1],[],LineList,TotalNodes),
  NeighborsList.

forLoop(CurrIndex,Itr,DirMatrix,NeighborsList,LineList,TotalNodes) ->
  if
    %%% Itr is out of bounds
    Itr > length(DirMatrix)->
      NeighborsList;

    true ->
      TempIndex = CurrIndex + lists:nth(Itr,DirMatrix),
      if
        %%% If condition is true
        TempIndex > 0 andalso TempIndex < (TotalNodes+1) ->
          ActorPid = lists:nth(TempIndex,LineList),
          case is_process_alive(ActorPid) of
            true  ->
              forLoop(CurrIndex,Itr+1,DirMatrix,[{TempIndex,ActorPid}|NeighborsList],LineList,TotalNodes);
            false ->
              forLoop(CurrIndex,Itr+1,DirMatrix,NeighborsList,LineList,TotalNodes)
          end;
        %%% else case for the condition
        true ->
          forLoop(CurrIndex,Itr+1,DirMatrix,NeighborsList,LineList,TotalNodes)
      end
  end.

%%% get the Neighbors for 2D Topology
getNeighbors_2d(Index1, Index2, SquareDim,List_2D) ->
  NeighborsList = forLoop_2d(Index1, Index2,1,[[-1,0],[1,0],[0,1],[0,-1]],[],List_2D,SquareDim),
  NeighborsList.

forLoop_2d(Index1, Index2, Itr,DirMatrix,NeighborsList,List_2D,SquareDim) ->
  if
  %%% Itr is out of bounds
    Itr > length(DirMatrix)->
      NeighborsList;

    true ->
      TempIndex1 = Index1 + lists:nth(1,lists:nth(Itr,DirMatrix)),
      TempIndex2 = Index2 + lists:nth(2,lists:nth(Itr,DirMatrix)),
      if
      %%% If condition is true
        TempIndex1 > 0 andalso TempIndex1 =< SquareDim andalso TempIndex2 > 0 andalso TempIndex2 =< SquareDim ->
          ActorPid = lists:nth(TempIndex2, lists:nth(TempIndex1,List_2D)),
          case is_process_alive(ActorPid) of
            true  ->
              forLoop_2d(Index1, Index2, Itr+1,DirMatrix,[{[TempIndex1, TempIndex2],ActorPid}|NeighborsList],List_2D,SquareDim);
            false ->
              forLoop_2d(Index1, Index2, Itr+1,DirMatrix,NeighborsList,List_2D,SquareDim)
          end;
      %%% else case for the condition
        true ->
          forLoop_2d(Index1, Index2, Itr+1,DirMatrix,NeighborsList,List_2D,SquareDim)
      end
  end.

getNeighbors_i3d(Index1, Index2, SquareDim,List_2D) ->
  NeighborsList = forLoop_i3d(Index1, Index2,1,[[-1,0],[1,0],[0,1],[0,-1],[1,1],[-1,-1],[1,-1],[-1,1]],[],List_2D,SquareDim),
  RandomPID = addRandomNeighbour(Index1, Index2, SquareDim, List_2D),
  [RandomPID | NeighborsList].
%%  NeighborsList.

%%% get the Neighbors for imperfect 3d Topology
%%forLoop_i3d(Index1, Index2, SquareDim,List_2D) ->
%%  NeighborsList = forLoop_i3d(Index1, Index2,1,[[-1,0],[1,0],[0,1],[0,-1]],[],List_2D,SquareDim),

%%  while()
%%  RanIdx1 = rand:uniform(length(List_2D)),
%%  RanIdx2 = rand:uniform(length(List_2D)),


addRandomNeighbour(Index1, Index2, SquareDim, List_2D) ->
  R1 = rand:uniform(length(List_2D)),
  R2 = rand:uniform(length(List_2D)),
  if
    ( (R1 == (Index1+1)) or (R1 == (Index1-1)) or (R2 == (Index2+1)) or (R2 == (Index2-1)) or (R1 < 1) or (R1 > SquareDim) or (R2 < 1) or (R2 > SquareDim) ) ->
      addRandomNeighbour(Index1, Index2, SquareDim, List_2D);
    true ->
      ActorPid = lists:nth(R2, lists:nth(R1,List_2D)),
      ActorPid
  end.

forLoop_i3d(Index1, Index2, Itr,DirMatrix,NeighborsList,List_2D,SquareDim) ->
  if
  %%% Itr is out of bounds
    Itr > length(DirMatrix)->
      NeighborsList;

    true ->
      TempIndex1 = Index1 + lists:nth(1,lists:nth(Itr,DirMatrix)),
      TempIndex2 = Index2 + lists:nth(2,lists:nth(Itr,DirMatrix)),
      if
      %%% If condition is true
        TempIndex1 > 0 andalso TempIndex1 =< SquareDim andalso TempIndex2 > 0 andalso TempIndex2 =< SquareDim ->
          ActorPid = lists:nth(TempIndex2, lists:nth(TempIndex1,List_2D)),
          case is_process_alive(ActorPid) of
            true  ->
              forLoop_i3d(Index1, Index2, Itr+1,DirMatrix,[{[TempIndex1, TempIndex2],ActorPid}|NeighborsList],List_2D,SquareDim);
            false ->
              forLoop_i3d(Index1, Index2, Itr+1,DirMatrix,NeighborsList,List_2D,SquareDim)
          end;
      %%% else case for the condition
        true ->
          forLoop_i3d(Index1, Index2, Itr+1,DirMatrix,NeighborsList,List_2D,SquareDim)
      end
  end.

%%% Randomly select the neighbor for Full Network
getNeighbors_fullNetwork(Count,TotalNodes,FullList) ->

  %%% Get a random ActorPid
  Index = rand:uniform(TotalNodes),
  ActorPid = lists:nth(Index,FullList),
  ActorPid.
%%  case is_process_alive(ActorPid) of
%%    true  ->
%%      %%% io:format("Returning Tuple Pair ~p ~n",[{Index,ActorPid}]),
%%      {Index,ActorPid};
%%
%%    _ ->
%%      if
%%        ((Count/TotalNodes)*100) < 98 ->
%%          getNeighbors_fullNetwork(Count+1,TotalNodes,FullList);
%%        true ->
%%          {-1, "None"}
%%      end
%%  end.