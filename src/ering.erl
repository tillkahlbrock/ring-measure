-module(ering).
-export([start/1, start_measure/2, measure/2]).
-record(state, {controller, startTime, endTime}).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% API
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
start_measure(NumProcesses, Roundtrips) ->
  MasterPid = start(NumProcesses),
  measure(MasterPid, Roundtrips).

start(NumProcesses) ->
  MasterPid = spawn(fun() -> build_ring_master(NumProcesses, self()) end),
  MasterPid.

measure(MasterPid, Roundtrips) -> measure(MasterPid, Roundtrips, []).

measure(_MasterPid, 0, Result) -> Result;

measure(MasterPid, Roundtrips, Result) ->
  NewResult = start_roundtrip(MasterPid),
  StartTime = NewResult#state.startTime,
  EndTime = NewResult#state.endTime,
  measure(MasterPid, Roundtrips - 1, [{StartTime, EndTime}|Result]).


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Helper
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
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

receive_loop_master(Successor, State) ->
  receive
    kill ->
      Successor ! kill,
      io:format("I am dying... hardly....~n", []);
	{ControllerPid, measure} ->
      NewStartTime = os:timestamp(),
	  Successor ! measure,
      receive_loop_master(Successor, State#state{startTime = NewStartTime, controller = ControllerPid});
    measure ->
      EndTime = os:timestamp(),
      NewState = State#state{endTime = EndTime},
      State#state.controller ! {ok, NewState},
      receive_loop_master(Successor, NewState)
  end.

receive_loop(Successor) ->
  receive
    kill -> Successor ! kill, io:format("I am dying... hardly....~n", []);
    measure ->
      Successor ! measure,
      receive_loop(Successor)
  end.
