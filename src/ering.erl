-module(ering).

-export([start/1, measure/2]).

start(NumProcesses) ->
  MasterPid = spawn(fun() -> build_ring_master(NumProcesses, self()) end),
  MasterPid.

measure(MasterPid, Roundtrips) -> measure(MasterPid, Roundtrips, []).

measure(_MasterPid, 0, Result) -> Result;

measure(MasterPid, Roundtrips, Result) ->
  NewResult = start_roundtrip(MasterPid),
  measure(MasterPid, Roundtrips - 1, [NewResult|Result]).

start_roundtrip(MasterPid) -> MasterPid ! {first, measure}.

build_ring_master(NumProcesses, Master) ->
  Successor = spawn(fun() -> build_ring(NumProcesses - 1, Master) end),
  receive_loop_master(Successor, {0,0}).

build_ring(NumProcesses, Master) when NumProcesses =< 1 ->
  receive_loop(Master);

build_ring(NumProcesses, Master) ->
  Successor = spawn(fun() -> build_ring(NumProcesses - 1, Master) end),
  receive_loop(Successor).

receive_loop_master(Successor, Result = {StartTime, _EndTime}) ->
  receive
    kill -> Successor ! kill, io:format("I am dying... hardly....~n", []);
	{first, Command} ->
      NewStartTime = 1,
	  Successor ! Command,
      receive_loop_master(Successor, {NewStartTime, 0});
    Command ->
      EndTime = 5,
      io:format("Got: ~p~n", [Command]),
      receive_loop_master(Successor, {StartTime, EndTime})
  end,
  Result.

receive_loop(Successor) ->
  receive
    kill -> Successor ! kill, io:format("I am dying... hardly....~n", []);
    Command ->
      Successor ! Command,
      io:format("Sent: ~p~n", [Command]),
      receive_loop(Successor)
  end.
