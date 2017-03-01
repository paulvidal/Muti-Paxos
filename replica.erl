%%% Paul Vidal (pv14) and Saturnin Pugnet (sp5414)

%%% distributed algorithms, n.dulay 27 feb 17
%%% coursework 2, paxos made moderately complex

-module(replica).
-export([start/1]).

start(Database) ->
  receive
    {bind, Leaders} ->
       next(Database, Leaders, 1, 1, [], [], [])
  end.

next(Database, Leaders, Slot_in, Slot_out, Requests, Proposals, Decisions) ->
  receive
    {request, C} ->      % request from client
      New_slot_out = Slot_out,
      New_proposals = Proposals,
      New_decisions = Decisions,
      New_Request = Requests ++ [C];

    {decision, S, C} ->  % decision from commander
      New_decisions = Decisions ++ [{S, C}];
      {New_proposals, New_requests, New_slot_out} =
        decide (Database, Slot_out, New_decisions, Proposals, Requests)
  end,

  {Final_slot_in, Final_requests, Final_proposals}
    = propose(Leaders, Slot_in, New_slot_out, New_Request, New_proposals, New_decisions),

  next(Database, Leaders,
       Final_slot_in, New_slot_out, Final_requests, Final_proposals, New_decisions).

% PROPOSE commands for slots
propose(Leaders, Slot_in, Slot_out, Requests, Proposals, Decisions) ->
  WINDOW = 5,
  propose(Leaders, Slot_in,
          Requests, Proposals, Decisions, Slot_out + Window - Slot_in).

propose(_, Slot_in, [], Proposals, _, _) -> {Slot_in, [], Proposals}.
propose(_, Slot_in, Requests, Proposals, _,0) -> {Slot_in, Requests, Proposals}.
propose(Leaders, Slot_in, [Command | Requests], Proposals, Decisions, Count) ->
  if
    get_slot_command(Slot_in, Decisions) != none ->
      New_proposals = Proposals ++ [{Slot_in, Command}],
      [ Leader ! {propose, {Slot_in, Command}} || Leader <- Leaders];

    true ->
      New_proposals = Proposals
  end,

  propose(Leaders, Slot_in + 1, Requests, Proposals, Decisions, Count - 1).

% DECIDE and EXECUTES requests
decide(Database, Slot_out, [], Proposals, Requests) ->
  {Proposals, Requests, Slot_out}.
decide(Database, Slot_out, [{_, Command} | Decisions], Proposals, Requests) ->
  Command_executed = get_slot_command(Slot_out, Proposals),
  if
    Command_executed != none ->
      New_proposals = lists:delete({Slot_out, Command_executed}, Proposals),

      if
        Command_executed != Command ->
          New_requests = Requests ++ [Command];

        true ->
          New_requests = Requests
      end;

    true ->
      New_proposals = Proposals,
      New_requests = Requests
  end,

  New_slot_out = perform(Database, Slot_out, Decisions, Command),
  decide(Database, New_slot_out, Decisions, New_proposals, New_requests).

% PERFORM operation on database
perform(Database, Slot_out, Decisions, {K, Cid, Op}) ->
  if
    not has_been_executed(Decisions, Slot_out, {K, Cid, Op}) ->
      Database ! {execute, Op},
      K ! {response, Cid, ok}

    true -> skip
  end,

  Slot_out + 1.

% Get the given Command for a specific slot
get_slot_command(Slot, []) -> none;
get_slot_command(Slot, [{Slot, Command} | Proposals]) -> Command;
get_slot_command(Slot, [_ | Proposals]) -> get_slot_command(Slot, Proposals).

% Check if a command already has been executed
has_been_executed([], Slot_out, Command) -> false;
has_been_executed([ {Slot, Command_executed} | Decisions ], Slot_out, Command) ->
  if
    Slot < Slot_out and Command_executed == Command -> true,

    true -> has_been_executed(Decisions, Slot_out, Command)
  end.
