-module(ering).

-export([start/1, measure/2]).

-record(state, {controller, startTime, endTime}).

start(NumProcesses) ->
  MasterPid = spawn(fun() -> build_ring_master(NumProcesses, self()) end),
  MasterPid.

measure(MasterPid, Roundtrips) -> measure(MasterPid, Roundtrips, []).

measure(_MasterPid, 0, Result) ->
  io:format("Result: ~p~n", [lists:reverse(Result)]);

measure(MasterPid, Roundtrips, Result) ->
  NewResult = start_roundtrip(MasterPid),
  StartTime = NewResult#state.startTime,
  EndTime = NewResult#state.endTime,
  measure(MasterPid, Roundtrips - 1, [{StartTime, EndTime}|Result]).

start_roundtrip(MasterPid) ->
  MasterPid ! {self(), measure},
  receive
    {ok, Result} -> Result
  end.

build_ring_master(NumProcesses, Master) ->
  Successor = spawn(fun() -> build_ring(NumProcesses - 1, Master) end),
  receive_loop_master(Successor, #state{}).

build_ring(NumProcesses, Master) when NumProcesses =< 1 ->
  receive_loop(Master);

build_ring(NumProcesses, Master) ->
  Successor = spawn(fun() -> build_ring(NumProcesses - 1, Master) end),
  receive_loop(Successor).

receive_loop_master(Successor, State = #state{controller = ControllerPid}) ->
  receive
    kill ->
      Successor ! kill,
      io:format("I am dying... hardly....~n", []);
	{ControllerPid2, measure} ->
      NewStartTime = os:timestamp(),
	  Successor ! measure,
      receive_loop_master(Successor, State#state{startTime = NewStartTime, controller = ControllerPid2});
    measure ->
      EndTime = os:timestamp(),
      NewState = State#state{endTime = EndTime},
      ControllerPid ! {ok, NewState},
      receive_loop_master(Successor, NewState)
  end.

receive_loop(Successor) ->
  receive
    kill -> Successor ! kill, io:format("I am dying... hardly....~n", []);
    Command ->
      Successor ! Command,
      receive_loop(Successor)
  end.
