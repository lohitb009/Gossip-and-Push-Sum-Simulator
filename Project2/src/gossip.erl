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
%%    in case of line topology
    {line,TotalNodes,Index,LineList,SupervisorPid, PreviousIndex} ->
      case PreviousIndex of
        false ->
          ok;

        _ ->
          PreviousActorPid = lists:nth(PreviousIndex, LineList),
          PreviousActorPid ! {line, TotalNodes, PreviousIndex, LineList, SupervisorPid, false}
      end,

      case RumorCount of
        10  ->
          io:format("Converged By Itself ~n"),
%%          getting neighbours of node
          Neighbors = getNeighbors(Index,TotalNodes,LineList),
          case length(Neighbors) of
            0 ->
              {RealTime, _} = statistics(wall_clock),
              io:format("Total Real Time at Event: ~p milliseconds ~n",[RealTime]),
%%              io:format("Can't route anywhere, all the neighbors are dead :'( ~n"),
              %%% Give the control back to the parent
              SupervisorPid ! {line,LineList};
            1 ->
              {Idx,ActorPid} = lists:nth(1,Neighbors),
              {RealTime, _} = statistics(wall_clock),
              io:format("Total Real Time at Event: ~p milliseconds ~n",[RealTime]),
%%              sending message to next node
              ActorPid ! {line,TotalNodes,Idx,LineList,SupervisorPid, Index};
            2 ->
              NeighborIndex = rand:uniform(length(Neighbors)),
              {Idx,ActorPid} = lists:nth(NeighborIndex,Neighbors),
              {RealTime, _} = statistics(wall_clock),
              io:format("Total Real Time at Event: ~p milliseconds ~n",[RealTime]),
              %%              sending message to next node
              ActorPid ! {line,TotalNodes,Idx,LineList,SupervisorPid, Index}
          end;

        _ ->
          %% These are all alive neighbors
          %%          getting neighbours of node
          Neighbors = getNeighbors(Index,TotalNodes,LineList),
          case length(Neighbors) of
            0 ->
              %%% My both neighbors are dead, I am kind of dead as well
%%              io:format("Converged By Neighbors Death ~n"),
              %%% Give the control back to the parent
              {RealTime, _} = statistics(wall_clock),
              io:format("Total Real Time at Event: ~p milliseconds ~n",[RealTime]),
              SupervisorPid ! {line,LineList};

            _ ->
              %%% Randomly select any neighbor from the list
              %%% Get a random ActorPid
              NeighborIndex = rand:uniform(length(Neighbors)),
              {Idx,ActorPid} = lists:nth(NeighborIndex,Neighbors),
              {RealTime, _} = statistics(wall_clock),
              io:format("Total Real Time at Event: ~p milliseconds ~n",[RealTime]),
              ActorPid ! {line,TotalNodes,Idx,LineList,SupervisorPid, Index},
              main_loop(RumorCount+1)
          end
      end;

%%    2d topology
    {"2D",SquareDim,Index1, Index2 ,List_2D, PreviousIndex1, PreviousIndex2} ->
      case PreviousIndex1 of
        false ->
          ok;
        _ ->
          PreviousActorPid = lists:nth(PreviousIndex2, lists:nth(PreviousIndex1, List_2D)),
          PreviousActorPid ! {"2D", SquareDim, PreviousIndex1, PreviousIndex2, List_2D, false, false}
      end,

      case RumorCount of
        10  ->
          io:format("Converged By Itself ~n"),
          %%          getting neighbours of node
          Neighbors = getNeighbors_2d(Index1, Index2, SquareDim,List_2D),
          case length(Neighbors) of
            0 ->
              {RealTime, _} = statistics(wall_clock),
              io:format("Total Real Time at Event: ~p milliseconds ~n",[RealTime]);
%%              io:format("Can't route anywhere, all the neighbors are dead :'( ~n");
            1 ->
              {[Idx1, Idx2],ActorPid} = lists:nth(1,Neighbors),
              {RealTime, _} = statistics(wall_clock),
              io:format("Total Real Time at Event: ~p milliseconds ~n",[RealTime]),
%%              sending next message
              ActorPid ! {"2D", SquareDim, Idx1, Idx2 ,List_2D, Index1, Index2};
            _ ->
              NeighborIndex = rand:uniform(length(Neighbors)),
              {[Idx1, Idx2],ActorPid} = lists:nth(NeighborIndex,Neighbors),
              {RealTime, _} = statistics(wall_clock),
              io:format("Total Real Time at Event: ~p milliseconds ~n",[RealTime]),
              ActorPid ! {"2D", SquareDim, Idx1, Idx2 ,List_2D, Index1, Index2}
          end;

        _ ->
          %% These are all alive neighbors
          Neighbors = getNeighbors_2d(Index1, Index2, SquareDim,List_2D),
          case length(Neighbors) of
            0 ->

              %%% Iteratively select the ActorPid from the line list in next iteration
              %%% Select active neighbor
              {RealTime, _} = statistics(wall_clock),
              io:format("Total Real Time at Event: ~p milliseconds ~n",[RealTime]);
%%              io:format("Converged By Neighbors Death ~n");

            _ ->
              %%% Randomly select any neighbor from the list
              %%% Get a random ActorPid
              NeighborIndex = rand:uniform(length(Neighbors)),

              {[Idx1, Idx2],ActorPid} = lists:nth(NeighborIndex,Neighbors),
              {RealTime, _} = statistics(wall_clock),
              io:format("Total Real Time at Event: ~p milliseconds ~n",[RealTime]),
              ActorPid ! {"2D", SquareDim, Idx1, Idx2 ,List_2D, Index1, Index2},
%%              io:format("Current PID : ~p New RumorCount : ~p ~n",[self(), RumorCount+1]),
              main_loop(RumorCount+1)
          end
      end;

    {fullNetwork,FullList,PrevActorPid} ->
      io:format("Full list len : ~p ~n",[length(FullList)]),
%%      implementing acknowledge protocol as discussed in readme
      case PrevActorPid of
        false ->
          ok;

        _ ->
          PrevActorPid ! {fullNetwork,FullList,false}
      end,

      case length(FullList) of
        1 ->
          {RealTime, _} = statistics(wall_clock),
          io:format("Total Real Time at Event: ~p milliseconds ~n",[RealTime]),
          io:format("My Full Network Topology has converged .. :'( ~n");

        _ ->
%%          checking rumorcount
          case RumorCount of
            9  ->

              Idx = rand:uniform(length(FullList--[self()])),
              ActorPid = lists:nth(Idx,FullList--[self()]),
              ActorPid ! {fullNetwork,FullList--[self()]},
              {RealTime, _} = statistics(wall_clock),
              io:format("Total Real Time at Event: ~p milliseconds ~n",[RealTime]),
              io:format("ActorPid is done ~p ~n ",[self()]);

            _ ->
              io:format("At ~p ~n ",[self()]),
              Idx = rand:uniform(length(FullList--[self()])),
              ActorPid = lists:nth(Idx,FullList--[self()]),
              ActorPid ! {fullNetwork,FullList,self()},
              {RealTime, _} = statistics(wall_clock),
              io:format("Total Real Time at Event: ~p milliseconds ~n",[RealTime]),
              main_loop(RumorCount+1)
          end
      end;

    {imp_3d, SquareDim, Index1, Index2, List_2D, PrevIndex1, PrevIndex2} ->

      case PrevIndex1 of

        false ->
          ok;

        _ ->
          PrevActorPid = lists:nth(PrevIndex2, lists:nth(PrevIndex1, List_2D)),
          PrevActorPid ! {imp_3d, SquareDim, PrevIndex1, PrevIndex2, List_2D, false, false}
      end,

      case RumorCount of
        10  ->
%%          io:format("Current PID : ~p RumorCount : ~p ~n",[self(), RumorCount]),
          io:format("Converged By Itself ~n"),
          Neighbors = getNeighbors_i3d(Index1, Index2, SquareDim,List_2D),
          case length(Neighbors) of
            0 ->
              {RealTime, _} = statistics(wall_clock),
              io:format("Total Real Time at Event: ~p milliseconds ~n",[RealTime]);
%%              io:format("Can't route anywhere, all the neighbors are dead :'( ~n");
            1 ->
              {[Idx1, Idx2],ActorPid} = lists:nth(1,Neighbors),
              {RealTime, _} = statistics(wall_clock),
              io:format("Total Real Time at Event: ~p milliseconds ~n",[RealTime]),
              ActorPid ! {imp_3d, SquareDim, Idx1, Idx2 ,List_2D, Index1, Index2};
            _ ->
              NeighborIndex = rand:uniform(length(Neighbors)),
              {[Idx1, Idx2],ActorPid} = lists:nth(NeighborIndex,Neighbors),
              {RealTime, _} = statistics(wall_clock),
              io:format("Total Real Time at Event: ~p milliseconds ~n",[RealTime]),
              ActorPid ! {imp_3d, SquareDim, Idx1, Idx2 ,List_2D, Index1, Index2}
          end;

        _ ->
%%          io:format("Current PID : ~p RumorCount : ~p ~n",[self(), RumorCount]),
          %% These are all alive neighbors
          Neighbors = getNeighbors_2d(Index1, Index2, SquareDim,List_2D),
          case length(Neighbors) of
            0 ->
              %%% My both neighbors are dead, I am kind of dead as well
              %%% Iteratively select the ActorPid from the line list in next iteration
              %%% Select active neighbor
              {RealTime, _} = statistics(wall_clock),
              io:format("Total Real Time at Event: ~p milliseconds ~n",[RealTime]);
%%              io:format("Converged By Neighbors Death ~n");

            _ ->
              %%% Randomly select any neighbor from the list
              %%% Get a random ActorPid
              NeighborIndex = rand:uniform(length(Neighbors)),

              {[Idx1, Idx2],ActorPid} = lists:nth(NeighborIndex,Neighbors),
              {RealTime, _} = statistics(wall_clock),
%%              io:format("Current PID : ~p New RumorCount : ~p ~n",[self(), RumorCount+1]),
              io:format("Total Real Time at Event: ~p milliseconds ~n",[RealTime]),
              ActorPid ! {imp_3d, SquareDim, Idx1, Idx2 ,List_2D, Index1, Index2},
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
  NeighborsList = forLoop_2d(Index1, Index2,1,[[-1,0],[1,0],[0,1],[0,-1], [-1, 1], [-1, -1], [1, 1], [1, -1]],[],List_2D,SquareDim),
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


%%for imperfect 3d
addRandomNeighbour(Index1, Index2, SquareDim, List_2D) ->
  R1 = rand:uniform(length(List_2D)),
  R2 = rand:uniform(length(List_2D)),
  if
    ( (R1 == (Index1+1)) or (R1 == (Index1-1)) or (R2 == (Index2+1)) or (R2 == (Index2-1)) or (R1 < 1) or (R1 > SquareDim) or (R2 < 1) or (R2 > SquareDim) ) ->
      addRandomNeighbour(Index1, Index2, SquareDim, List_2D);
    true ->
      ActorPid = lists:nth(R2, lists:nth(R1,List_2D)),
      {[R1, R2],ActorPid}
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
