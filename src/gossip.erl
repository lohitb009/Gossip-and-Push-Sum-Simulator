%%%-------------------------------------------------------------------
%%% @author lohit
%%% @copyright (C) 2022, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 28. Sep 2022 03:07 pm
%%%-------------------------------------------------------------------
-module(gossip).
-author("lohit").

%% API
-export([startLink/0]).
-export([main_loop/1]).

%%%% ==== Expose the API to client
startLink() ->
  ActorPid = spawn_link(?MODULE,main_loop,[0]),
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
               %%% Iteratively select the ActorPid from the line list
               %%% Select active neighbor
               io:format("Converged By Neighbors Death ~n");

            _ ->
              %%% Randomly select any neighbor from the list
              %%% Get a random ActorPid
              NeighborIndex = rand:uniform(length(Neighbors)),
              {Idx,ActorPid} = lists:nth(NeighborIndex,Neighbors),
              ActorPid ! {line,TotalNodes,Idx,LineList},
              main_loop(RumorCount+1)
          end
      end
  end.

%%% get the Neighbors
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