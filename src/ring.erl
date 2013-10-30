-module(ring).
-export([start/1]).

start(NumProcs) ->
	Master = self(),
	FirstChild = spawn(fun() -> run(NumProcs - 1, Master) end),
	Master ! kill,
	loop(FirstChild, NumProcs - 1).

run(0, Master) ->
	loop(Master, 0);

run(NumProcs, Master) ->
	SuccessorPid = spawn(fun() -> run(NumProcs - 1, Master) end),
	loop(SuccessorPid, NumProcs - 1).

loop(SuccessorPid, Num) ->
	receive
		kill -> 
			SuccessorPid ! kill,
			io:format("I (~p) am dying...~n", [Num]);
		Command -> 
			SuccessorPid ! Command,
			loop(SuccessorPid, Num)
	end.

