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
      end
  end.