-module(ering).

-export([start/1, measure/2, rpc/2]).

start(NumProcesses) ->
  MasterPid = spawn(fun() -> build_ring_master(NumProcesses, self()) end),
  MasterPid.

measure(_Message, _Times) -> ok.

rpc(MasterPid, Command) -> MasterPid ! {first, Command}.

build_ring_master(NumProcesses, Master) ->
  Successor = spawn(fun() -> build_ring(NumProcesses - 1, Master) end),
  receive_loop_master(Successor).

build_ring(NumProcesses, Master) when NumProcesses =< 1 ->
  receive_loop(Master);

build_ring(NumProcesses, Master) ->
  Successor = spawn(fun() -> build_ring(NumProcesses - 1, Master) end),
  receive_loop(Successor).

receive_loop_master(Successor) ->
  receive
    kill -> Successor ! kill, io:format("I am dying... hardly....~n", []);
	{first, Command} -> Successor ! Command;
    Command ->
      io:format("Got: ~p~n", [Command]),
      receive_loop(Successor)
  end.

receive_loop(Successor) ->
  receive
    kill -> Successor ! kill, io:format("I am dying... hardly....~n", []);
    Command ->
      Successor ! Command,
      io:format("Sent: ~p~n", [Command]),
      receive_loop(Successor)
  end.
