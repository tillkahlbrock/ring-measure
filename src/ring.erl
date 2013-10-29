-module(ring).
-export([start/1]).

start(NumProcs) ->
	spawn(fun() -> run(NumProcs, self()) end).

run(0, Master) ->
	loop(Master);

run(NumProcs, Master) ->
	SuccessorPid = spawn(fun() -> run(NumProcs - 1, Master) end),
	loop(SuccessorPid).

loop(SuccessorPid) ->
	receive
		kill -> 
			SuccessorPid ! kill,
			io:format("I am dying...~n", []);
		Command -> 
			SuccessorPid ! Command,
			loop(SuccessorPid)
	end.

