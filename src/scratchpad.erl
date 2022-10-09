%%%-------------------------------------------------------------------
%%% @author User
%%% @copyright (C) 2022, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 09. Oct 2022 12:21 PM
%%%-------------------------------------------------------------------
-module(scratchpad).
-author("User").

%% API
-export([start/0]).

start() ->
  ReplaceInit = fun() ->
    io:format("Hello") end,
  ReplaceInit().


