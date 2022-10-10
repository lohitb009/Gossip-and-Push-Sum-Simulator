-module(pushSum).
-author("lohit").

%% API
-export([startLink/1, main_loop/3]).

%%%% ==== Expose the API to client
startLink(Sum) ->
  ActorPid = spawn_link(?MODULE, main_loop, [Sum, 1, 0]),
  %%% io:format("ActorPID Started At : ~p~n",[ActorPid]),
  {ok, ActorPid}.

main_loop(Sum, Weight, Round) ->
  receive
    {fullNetwork, FullList, S, W} ->
      case length(FullList) of
        1 ->
          {RealTime, _} = statistics(wall_clock),
          io:format("Total Real Time at Event: ~p milliseconds ~n",[RealTime]),
          io:format("My Full Network Topology has converged .. :'( ~n");


        _ ->
          OldEstimate = Sum / Weight,
          NewEstimate = (Sum + S) / (Weight + W),

          if
            (OldEstimate - NewEstimate) < 0.0000000001 ->
              %%% Chk for rounds

              if
                Round =:= 2 ->
                  Idx = rand:uniform(length(FullList--[self()])),
                  ActorPid = lists:nth(Idx, FullList--[self()]),
                  ActorPid ! {fullNetwork, FullList--[self()], (Sum + S) / 2, (Weight + W) / 2},
                  {RealTime, _} = statistics(wall_clock),
                  io:format("Total Real Time at Event: ~p milliseconds ~n",[RealTime]),
                  io:format("ActorPid is done ~p ~n ", [self()]);

                true ->
                  %%              get neighbor index
                  Idx = rand:uniform(length(FullList--[self()])),
                  ActorPid = lists:nth(Idx, FullList--[self()]),
%%                  send msg to next node
                  ActorPid ! {fullNetwork, FullList, (Sum + S) / 2, (Weight + W) / 2},
                  {RealTime, _} = statistics(wall_clock),
                  io:format("Total Real Time at Event: ~p milliseconds ~n",[RealTime]),
                  main_loop((Sum + S) / 2, (Weight + W) / 2, Round + 1)
              end;

            true ->
%%              get neighbor index
              Idx = rand:uniform(length(FullList--[self()])),
              ActorPid = lists:nth(Idx, FullList--[self()]),
              %%                  send msg to next node
              ActorPid ! {fullNetwork, FullList, (Sum + S) / 2, (Weight + W) / 2},
              {RealTime, _} = statistics(wall_clock),
              io:format("Total Real Time at Event: ~p milliseconds ~n",[RealTime]),
              main_loop((Sum + S) / 2, (Weight + W) / 2, 0)
          end
      end;

    {line, FullList, Index, S, W, PrevIndex, SupervisorPid} ->
      case PrevIndex of
        false ->
          ok;
        _ ->
          PrevActorPid = lists:nth(PrevIndex, FullList),
          PrevActorPid ! {line, FullList, PrevIndex, 0, 0, false, SupervisorPid}
      end,
      io:format("Current Actor Pid is ~p ~n ", [self()]),

      OldEstimate = Sum / Weight,
      NewEstimate = (Sum + S) / (Weight + W),
      Neighbors = getNeighbors_line(Index, length(FullList), FullList),

      if
        (OldEstimate - NewEstimate) < 0.0000000001 ->
          %%% Chk for round condition
          case Round of
            2 ->
              case length(Neighbors) of
                0 ->
                  SupervisorPid ! {line_pushsum, FullList},
                  {RealTime, _} = statistics(wall_clock),
                  io:format("Total Real Time at Event: ~p milliseconds ~n",[RealTime]);
%%                  io:format("Converged ~n");


                _ ->
                  %%              get neighbor index
                  NeighborIdx = rand:uniform(length(Neighbors)),
                  {Idx, ActorPid} = lists:nth(NeighborIdx, Neighbors),
                  ActorPid ! {line, FullList, Idx, (Sum + S) / 2, (Weight + W) / 2, Index, SupervisorPid},
                  {RealTime, _} = statistics(wall_clock),
                  io:format("Total Real Time at Event: ~p milliseconds ~n",[RealTime]),
                  io:format("ActorPid is done ~p ~n ", [self()])
              end;

            _ ->
              case length(Neighbors) of
                0 ->
                  SupervisorPid ! {line_pushsum, FullList},
                  {RealTime, _} = statistics(wall_clock),
                  io:format("Total Real Time at Event: ~p milliseconds ~n",[RealTime]);
%%                  io:format("No neighbors ~n");
%%                  main_loop((Sum+S)/2, (Weight+W)/2, Round+1)
                %%              get neighbor index
                _ -> NeighborIdx = rand:uniform(length(Neighbors)),
                  {Idx, ActorPid} = lists:nth(NeighborIdx, Neighbors),
                  ActorPid ! {line, FullList, Idx, (Sum + S) / 2, (Weight + W) / 2, Index, SupervisorPid},
%%            io:format("ActorPid is done ~p ~n ",[self()]),
                  {RealTime, _} = statistics(wall_clock),
                  io:format("Total Real Time at Event: ~p milliseconds ~n",[RealTime]),
                  main_loop((Sum + S) / 2, (Weight + W) / 2, Round + 1)
              end

          end;

        true ->
          case length(Neighbors) of
            0 ->
              SupervisorPid ! {line_pushsum, FullList},
              {RealTime, _} = statistics(wall_clock),
              io:format("Total Real Time at Event: ~p milliseconds ~n",[RealTime]);
%%              io:format("No neighbors ~n");

            _ ->
              %%              get neighbor index
              NeighborIdx = rand:uniform(length(Neighbors)),
              {Idx, ActorPid} = lists:nth(NeighborIdx, Neighbors),
              ActorPid ! {line, FullList, Idx, (Sum + S) / 2, (Weight + W) / 2, Index, SupervisorPid},
%%        io:format("ActorPid is done ~p ~n ",[self()]),
              {RealTime, _} = statistics(wall_clock),
              io:format("Total Real Time at Event: ~p milliseconds ~n",[RealTime]),
              main_loop((Sum + S) / 2, (Weight + W) / 2, 0)
          end
      end;


    {"2D", SquareDim, Index1, Index2, List_2D, S, W, PreviousIndex1, PreviousIndex2} ->

      case PreviousIndex1 of
        false -> ok;
        _ ->
          PreviousActorPid = lists:nth(PreviousIndex2, lists:nth(PreviousIndex1, List_2D)),
          PreviousActorPid ! {"2D", SquareDim, PreviousIndex1, PreviousIndex2, List_2D, 0, 0, false, false}
      end,

      Neighbors = getNeighbors_2d(Index1, Index2, SquareDim, List_2D),
      case length(Neighbors) of
        0 ->
          {RealTime, _} = statistics(wall_clock),
          io:format("Total Real Time at Event: ~p milliseconds ~n",[RealTime]);
%%          io:format("My 2d Topology has converged ..  ~n");

        _ ->
          {RealTime1, _} = statistics(wall_clock),
          io:format("Total Real Time at Event: ~p milliseconds ~n",[RealTime1]),
          OldEstimate = Sum / Weight,
          NewEstimate = (Sum + S) / (Weight + W),

          if
            (OldEstimate - NewEstimate) < 0.0000000001 ->
              %%% Chk for rounds

              if
                Round =:= 2 ->
                  case length(Neighbors) of
                    0 ->
                      {RealTime, _} = statistics(wall_clock),
                      io:format("Total Real Time at Event: ~p milliseconds ~n",[RealTime]);
%%                      io:format("No neighbors");
                    _ ->
                      {RealTime, _} = statistics(wall_clock),
                      io:format("Total Real Time at Event: ~p milliseconds ~n",[RealTime]),
                      %%              get neighbor index
                      Idx = rand:uniform(length(Neighbors)),
                      {[NextIdx1, NextIdx2], ActorPid} = lists:nth(Idx, Neighbors),
%%                      io:format("Round is ~p , sent msg to : ~p ~n", [Round + 1, ActorPid]),

                      io:format("ActorPid is done ~p ~n ", [self()]),
                      ActorPid ! {"2D", SquareDim, NextIdx1, NextIdx2, List_2D, (Sum + S) / 2, (Weight + W) / 2, Index1, Index2}
                  end;

                true ->
                  case length(Neighbors) of
                    0 ->
                      {RealTime, _} = statistics(wall_clock),
                      io:format("Total Real Time at Event: ~p milliseconds ~n",[RealTime]);
%%                      io:format("No neighbors");
                    _ ->

                      Idx = rand:uniform(length(Neighbors)),
                      {[NextIdx1, NextIdx2], ActorPid} = lists:nth(Idx, Neighbors),
                      ActorPid ! {"2D", SquareDim, NextIdx1, NextIdx2, List_2D, (Sum + S) / 2, (Weight + W) / 2, Index1, Index2},
%%                      io:format("Round is ~p , sent msg to : ~p ~n", [Round + 1, ActorPid]),
                      {RealTime, _} = statistics(wall_clock),
                      io:format("Total Real Time at Event: ~p milliseconds ~n",[RealTime]),
                      main_loop((Sum + S) / 2, (Weight + W) / 2, Round + 1)
                  end
              end;

            true ->
              case length(Neighbors) of
                0 ->
                  {RealTime, _} = statistics(wall_clock),
                  io:format("Total Real Time at Event: ~p milliseconds ~n",[RealTime]);
%%                  io:format("No neighbors");
                _ ->
                  %%              get neighbor index
                  Idx = rand:uniform(length(Neighbors)),
                  {[NextIdx1, NextIdx2], ActorPid} = lists:nth(Idx, Neighbors),
                  ActorPid ! {"2D", SquareDim, NextIdx1, NextIdx2, List_2D, (Sum + S) / 2, (Weight + W) / 2, Index1, Index2},
%%                  io:format("Round is ~p , sent msg to : ~p ~n", [0, ActorPid]),
                  {RealTime, _} = statistics(wall_clock),
                  io:format("Total Real Time at Event: ~p milliseconds ~n",[RealTime]),
                  main_loop((Sum + S) / 2, (Weight + W) / 2, 0)
              end
          end
      end;

    {imp_3d, SquareDim, Index1, Index2, List_2D, S, W, PreviousIndex1, PreviousIndex2} ->
      case PreviousIndex1 of
        false -> ok;
        _ ->
          PreviousActorPid = lists:nth(PreviousIndex2, lists:nth(PreviousIndex1, List_2D)),
          PreviousActorPid ! {imp_3d, SquareDim, PreviousIndex1, PreviousIndex2, List_2D, 0, 0, false, false}
      end,

      Neighbors = getNeighbors_i3d(Index1, Index2, SquareDim, List_2D),
      case length(Neighbors) of
        0 ->
          {RealTime, _} = statistics(wall_clock),
          io:format("Total Real Time at Event: ~p milliseconds ~n",[RealTime]),
          io:format("My 2d Topology has converged .. :'( ~n");

        _ ->
          OldEstimate = Sum / Weight,
          NewEstimate = (Sum + S) / (Weight + W),

          if
            (OldEstimate - NewEstimate) < 0.0000000001 ->
              %%% Chk for rounds

              if
                Round =:= 2 ->
                  case length(Neighbors) of
                    0 -> {RealTime, _} = statistics(wall_clock),
                      io:format("Total Real Time at Event: ~p milliseconds ~n",[RealTime]);
%%                      io:format("No Neighbours");
                    _ -> Idx = rand:uniform(length(Neighbors)),
                      {[NextIdx1, NextIdx2], ActorPid} = lists:nth(Idx, Neighbors),
%%                      io:format("Round is ~p , sent msg to : ~p ~n", [Round + 1, ActorPid]),
                      io:format("ActorPid is done ~p ~n ", [self()]),
                      {RealTime, _} = statistics(wall_clock),
                      io:format("Total Real Time at Event: ~p milliseconds ~n",[RealTime]),
                      ActorPid ! {imp_3d, SquareDim, NextIdx1, NextIdx2, List_2D, (Sum + S) / 2, (Weight + W) / 2, Index1, Index2}
                  end;

                true ->
                  case length(Neighbors) of
                    0 ->
                      {RealTime, _} = statistics(wall_clock),
                      io:format("Total Real Time at Event: ~p milliseconds ~n",[RealTime]);
%%                      io:format("No Neighbours");
                    _ ->
                      Idx = rand:uniform(length(Neighbors)),
                      {[NextIdx1, NextIdx2], ActorPid} = lists:nth(Idx, Neighbors),
                      ActorPid ! {imp_3d, SquareDim, NextIdx1, NextIdx2, List_2D, (Sum + S) / 2, (Weight + W) / 2, Index1, Index2},
%%                      io:format("Round is ~p , sent msg to : ~p ~n", [Round + 1, ActorPid]),
                      {RealTime, _} = statistics(wall_clock),
                      io:format("Total Real Time at Event: ~p milliseconds ~n",[RealTime]),
                      main_loop((Sum + S) / 2, (Weight + W) / 2, Round + 1)
                  end
              end;

            true ->
              case length(Neighbors) of
                0 ->
                  {RealTime, _} = statistics(wall_clock),
                  io:format("Total Real Time at Event: ~p milliseconds ~n",[RealTime]);
%%                  io:format("No Neighbours");
                _ ->
                  Idx = rand:uniform(length(Neighbors)),
                  {[NextIdx1, NextIdx2], ActorPid} = lists:nth(Idx, Neighbors),
                  ActorPid ! {imp_3d, SquareDim, NextIdx1, NextIdx2, List_2D, (Sum + S) / 2, (Weight + W) / 2, Index1, Index2},
%%                  io:format("Round is ~p , sent msg to : ~p ~n", [0, ActorPid]),
                  {RealTime, _} = statistics(wall_clock),
                  io:format("Total Real Time at Event: ~p milliseconds ~n",[RealTime]),
                  main_loop((Sum + S) / 2, (Weight + W) / 2, 0)
              end
          end
      end
  end.


getNeighbors_line(Index, TotalNodes, LineList) ->
  NeighborsList = forLoop(Index, 1, [-1, 1], [], LineList, TotalNodes),
  NeighborsList.

forLoop(CurrIndex, Itr, DirMatrix, NeighborsList, LineList, TotalNodes) ->
  if
  %%% Itr is out of bounds
    Itr > length(DirMatrix) ->
      NeighborsList;

    true ->
      TempIndex = CurrIndex + lists:nth(Itr, DirMatrix),
      if
      %%% If condition is true
        TempIndex > 0 andalso TempIndex < (TotalNodes + 1) ->
          ActorPid = lists:nth(TempIndex, LineList),
          case is_process_alive(ActorPid) of
            true ->
              forLoop(CurrIndex, Itr + 1, DirMatrix, [{TempIndex, ActorPid} | NeighborsList], LineList, TotalNodes);
            false ->
              forLoop(CurrIndex, Itr + 1, DirMatrix, NeighborsList, LineList, TotalNodes)
          end;
      %%% else case for the condition
        true ->
          forLoop(CurrIndex, Itr + 1, DirMatrix, NeighborsList, LineList, TotalNodes)
      end
  end.

getNeighbors_2d(Index1, Index2, SquareDim, List_2D) ->
  NeighborsList = forLoop_2d(Index1, Index2, 1, [[-1, 0], [1, 0], [0, 1], [0, -1]], [], List_2D, SquareDim),
  NeighborsList.

forLoop_2d(Index1, Index2, Itr, DirMatrix, NeighborsList, List_2D, SquareDim) ->
  if
  %%% Itr is out of bounds
    Itr > length(DirMatrix) ->
      NeighborsList;

    true ->
      TempIndex1 = Index1 + lists:nth(1, lists:nth(Itr, DirMatrix)),
      TempIndex2 = Index2 + lists:nth(2, lists:nth(Itr, DirMatrix)),
      if
      %%% If condition is true
        TempIndex1 > 0 andalso TempIndex1 =< SquareDim andalso TempIndex2 > 0 andalso TempIndex2 =< SquareDim ->
          ActorPid = lists:nth(TempIndex2, lists:nth(TempIndex1, List_2D)),
          case is_process_alive(ActorPid) of
            true ->
              forLoop_2d(Index1, Index2, Itr + 1, DirMatrix, [{[TempIndex1, TempIndex2], ActorPid} | NeighborsList], List_2D, SquareDim);
            false ->
              forLoop_2d(Index1, Index2, Itr + 1, DirMatrix, NeighborsList, List_2D, SquareDim)
          end;
      %%% else case for the condition
        true ->
          forLoop_2d(Index1, Index2, Itr + 1, DirMatrix, NeighborsList, List_2D, SquareDim)
      end
  end.

getNeighbors_i3d(Index1, Index2, SquareDim, List_2D) ->
  NeighborsList = forLoop_i3d(Index1, Index2, 1, [[-1, 0], [1, 0], [0, 1], [0, -1], [1, 1], [-1, -1], [1, -1], [-1, 1]], [], List_2D, SquareDim),
  RandomPID = addRandomNeighbour(Index1, Index2, SquareDim, List_2D),
  [RandomPID | NeighborsList].

addRandomNeighbour(Index1, Index2, SquareDim, List_2D) ->
  R1 = rand:uniform(length(List_2D)),
  R2 = rand:uniform(length(List_2D)),
  if
    ((R1 == (Index1 + 1)) or (R1 == (Index1 - 1)) or (R2 == (Index2 + 1)) or (R2 == (Index2 - 1)) or (R1 < 1) or (R1 > SquareDim) or (R2 < 1) or (R2 > SquareDim)) ->
      addRandomNeighbour(Index1, Index2, SquareDim, List_2D);
    true ->
      ActorPid = lists:nth(R2, lists:nth(R1, List_2D)),
      {[R1, R2], ActorPid}
  end.

forLoop_i3d(Index1, Index2, Itr, DirMatrix, NeighborsList, List_2D, SquareDim) ->
  if
  %%% Itr is out of bounds
    Itr > length(DirMatrix) ->
      NeighborsList;

    true ->
      TempIndex1 = Index1 + lists:nth(1, lists:nth(Itr, DirMatrix)),
      TempIndex2 = Index2 + lists:nth(2, lists:nth(Itr, DirMatrix)),
      if
      %%% If condition is true
        TempIndex1 > 0 andalso TempIndex1 =< SquareDim andalso TempIndex2 > 0 andalso TempIndex2 =< SquareDim ->
          ActorPid = lists:nth(TempIndex2, lists:nth(TempIndex1, List_2D)),
          case is_process_alive(ActorPid) of
            true ->
              forLoop_i3d(Index1, Index2, Itr + 1, DirMatrix, [{[TempIndex1, TempIndex2], ActorPid} | NeighborsList], List_2D, SquareDim);
            false ->
              forLoop_i3d(Index1, Index2, Itr + 1, DirMatrix, NeighborsList, List_2D, SquareDim)
          end;
      %%% else case for the condition
        true ->
          forLoop_i3d(Index1, Index2, Itr + 1, DirMatrix, NeighborsList, List_2D, SquareDim)
      end
  end.