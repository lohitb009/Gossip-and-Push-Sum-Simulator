-module(pushSum).
-author("lohit").

%% API
-export([startLink/1, main_loop/3]).

%%%% ==== Expose the API to client
startLink(Sum) ->
  ActorPid = spawn_link(?MODULE,main_loop,[Sum,1,0]),
  %%% io:format("ActorPID Started At : ~p~n",[ActorPid]),
  {ok,ActorPid}.

main_loop(Sum,Weight,Round) ->
  receive
    {fullNetwork,FullList,S,W} ->
      case length(FullList) of
        1 ->
           io:format("My Full Network Topology has converged .. :'( ~n");

        _ ->
           OldEstimate = Sum/Weight,
           NewEstimate = (Sum+S)/(Weight+W),

           if
             (OldEstimate-NewEstimate) < 0.0000000001 ->
               %%% Chk for rounds

               if
                 Round =:= 2->
                   Idx = rand:uniform(length(FullList--[self()])),
                   ActorPid = lists:nth(Idx,FullList--[self()]),
                   ActorPid ! {fullNetwork,FullList--[self()],(Sum+S)/2,(Weight+W)/2},
                   io:format("ActorPid is done ~p ~n ",[self()]);

                 true ->
                   Idx = rand:uniform(length(FullList--[self()])),
                   ActorPid = lists:nth(Idx,FullList--[self()]),
                   ActorPid ! {fullNetwork,FullList,(Sum+S)/2,(Weight+W)/2},
                   main_loop((Sum+S)/2, (Weight+W)/2, Round+1)
               end;

             true ->
               Idx = rand:uniform(length(FullList--[self()])),
               ActorPid = lists:nth(Idx,FullList--[self()]),
               ActorPid ! {fullNetwork,FullList,(Sum+S)/2,(Weight+W)/2},
               main_loop((Sum+S)/2, (Weight+W)/2, Round)
           end
      end;

    {line,FullList,S,W} ->
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
              main_loop((Sum+S)/2, (Weight+W)/2, Round)
          end
      end;

    {"2D",SquareDim,Index1, Index2 ,List_2D, S,W} ->
      io:format("Reached : ~p ~n",[self()]),
%%      Index = string:str(FullList, [self()]),
      Neighbors = getNeighbors_2d(Index1, Index2, SquareDim,List_2D),
      case length(Neighbors) of
        0 ->
          io:format("My 2d Topology has converged .. :'( ~n");

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
              main_loop((Sum+S)/2, (Weight+W)/2, Round)
          end
      end


  end.


getNeighbors_line(Index,TotalNodes,LineList) ->
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