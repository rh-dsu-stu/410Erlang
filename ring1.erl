% shell starts a ring of Processes processes, the shell process is included in the ring
% as well making this a ring of Processes + 1 processes.
% This is a bit broken, I had a very tough time.

-module(ring1).
-export([start/3, ring/3, create_processes/4]).

create_processes(Previous, 0, Laps, Token) ->
  Previous ! {new, self()},
  ring(Previous, Laps, Token);

% creates the processes
create_processes(Previous, Processes, Laps, Token) ->
  %creates the processes and links them to the first process
  % make this distributed by adding a node argument to spawn_link
  spawn_link(ring1, create_processes, [self(), Processes-1, Laps, Token]),
  ring(Previous, Laps, Token).

% undef because there is not a previous node
% there are three versions of ring to accommodate various conditions
% the first process does not know who it will receive from so Previous is undefined.
ring(undef, Laps, Token) ->
  receive
    {new, From} ->
      From ! Token,
       %io:format("Process ~w sent ~w to Process ~w~n", [self(), Token, From]),
       %io:format("Lap ~w~n", [Laps]),
      ring(From, Laps-1, Token)
  end;

% when laps is 0 the shell process will send stop around the ring
ring(Previous, 0, _) ->
  receive
    % _ is used because the first process will receive the token and then send stop
    % _ allows for this
    Token ->
      %io:format("Process ~w received ~w~n", [self(), Token]),
      % sends stop from process to process
      Previous ! stop
     % io:format("Process ~w sent to Process ~w~n", [self(), Previous])
  end;

% where all the other sending/receiving takes place
ring(Previous, Laps, Token) ->
  receive
    % for the first receive
    {new, From} ->
      Previous ! {new, From},
      ring(Previous, Laps, Token);
    Token ->
      %io:format("Process ~w received ~w~n", [self(), Token]),
      Previous ! Token,
        %io:format("Process ~w sent ~w to Process ~w~n", [self(), Token, Previous]),
        %io:format("Lap ~w~n", [Laps-1]),
      ring(Previous, Laps-1, Token)
  end.

% exported function to start the ring and timer and then stop the timer.
start(Laps, Processes, Token) ->
  % starts the clocks, runtime is cpu runtime
  % wall_clock is actual time
  statistics(runtime),
  statistics(wall_clock),

  % program begins
  create_processes(undef, Processes, Laps, Token),

  % tuples storing the times
  {_, Time1} = statistics(runtime),
  {_, Time2} = statistics(wall_clock),

  % microsecond conversion
  T1 = Time1 * 1000,
  T2 = Time2 * 1000,
  io:format("Runtime = ~p microseconds ~nRealtime = ~p microseconds~n", [T1, T2]).


