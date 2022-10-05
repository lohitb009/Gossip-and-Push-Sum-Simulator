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

    {fullNetwork,TotalNodes,FullList,S,W} ->

      OldEstimate = Sum/Weight,
      NewEstimate = (Sum+S)/(Weight+W),

      %% io:format("ActorPid is ~p ~n",[self()]),
      %% io:format("Delta is ~p ~n",[OldEstimate-NewEstimate]),

      if
        (OldEstimate-NewEstimate) < 0.01 ->
          %%% Randomly select an index
          {Idx,ActorPid} = getNeighbors_fullNetwork(0,TotalNodes,FullList),

          case Idx of
            -1  ->
              io:format("More than 98% nodes call have converged, THE END..~n");

            _   ->
              if
                Round =:= 3 ->
                  %%% This ActorPid will converge
                  %%% Send the message to the random index
                  %%% io:format("Current process-id ~p is dead :( ~n",[self()]),

                  if
                    ActorPid =:= self() ->
                      %%% Randomly select an index
                      {NewIdx,NewActorPid} = getNeighbors_fullNetwork(0,TotalNodes,FullList),
                      case NewIdx of
                        -1  ->
                          io:format("More than 98% nodes call have converged, THE END..~n");
                        _ ->
                          NewActorPid ! {fullNetwork,TotalNodes,FullList,(Sum+S)/2,(Weight+W)/2}
                      end;

                    true ->
                        ActorPid ! {fullNetwork,TotalNodes,FullList,(Sum+S)/2,(Weight+W)/2}

                  end;

                true ->
                  %%% Send the message to the random index
                  ActorPid ! {fullNetwork,TotalNodes,FullList,(Sum+S)/2,(Weight+W)/2},
                  %%% Recursively call itself
                  main_loop((Sum+S)/2, (Weight+W)/2, Round+1)
              end
          end;

        true ->
          %%% Randomly select an index
          {Idx,ActorPid} = getNeighbors_fullNetwork(0,TotalNodes,FullList),
          case Idx of
            -1  ->
              io:format("More than 98% nodes call have converged, THE END..~n");

            _   ->
              if
                ActorPid =:= self() ->
                  %%% Randomly select an index
                  {NewIdx,NewActorPid} = getNeighbors_fullNetwork(0,TotalNodes,FullList),
                  case NewIdx of
                    -1  ->
                      io:format("More than 98% nodes call have converged, THE END..~n");
                    _ ->
                      NewActorPid ! {fullNetwork,TotalNodes,FullList,(Sum+S)/2,(Weight+W)/2},
                      %%% Recursively call itself
                      main_loop((Sum+S)/2, (Weight+W)/2, Round+1)
                  end;
                true ->
                  %%% Send the message to the random index
                  ActorPid ! {fullNetwork,TotalNodes,FullList,(Sum+S)/2,(Weight+W)/2},
                  %%% Recursively call itself
                  main_loop((Sum+S)/2, (Weight+W)/2, Round+1)
              end
          end
      end
  end.

%%% Randomly select the neighbor for Full Network
getNeighbors_fullNetwork(Count,TotalNodes,FullList) ->

  %%% Get a random ActorPid
  Index = rand:uniform(TotalNodes),
  ActorPid = lists:nth(Index,FullList),

  case is_process_alive(ActorPid) of
    true  ->
      %% io:format("Returning Tuple Pair ~p ~n",[{Index,ActorPid}]),
      {Index,ActorPid};

    _ ->
      if
        ((Count/TotalNodes)*100) < 98 ->
          getNeighbors_fullNetwork(Count+1,TotalNodes,FullList);
        true ->
          {-1, "None"}
      end
  end.