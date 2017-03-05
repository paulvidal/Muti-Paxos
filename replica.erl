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
    {request, C} ->  % request from client
      New_slot_out = Slot_out,
      New_proposals = Proposals,
      New_decisions = Decisions,
      New_Requests = Requests ++ [C];

    {decision, S, C} ->  % decision from commander
      New_decisions = Decisions ++ [{S, C}],
      {New_proposals, New_Requests, New_slot_out} =
        decide(Database, Slot_out, New_decisions, New_decisions, Proposals, Requests)
  end,

  {Final_slot_in, Final_requests, Final_proposals} = propose_commands(
    Leaders, Slot_in, New_slot_out, New_Requests, New_proposals, New_decisions),

  next(Database, Leaders, Final_slot_in,
       New_slot_out, Final_requests, Final_proposals, New_decisions).

% PROPOSE commands for slots to the leaders
propose_commands(Leaders, Slot_in, Slot_out, Requests, Proposals, Decisions) ->
  Window = 5,
  propose(Leaders, Slot_in,
          Requests, Proposals, Decisions, Slot_out + Window - Slot_in).

propose(_, Slot_in, [], Proposals, _, _) -> {Slot_in, [], Proposals};
propose(_, Slot_in, Requests, Proposals, _,0) -> {Slot_in, Requests, Proposals};
propose(Leaders, Slot_in, [Command | Requests], Proposals, Decisions, Count) ->
  % Check if the slot is available by checking if there is no command for that
  % slot in the decision list
  case get_slot_command(Slot_in, Decisions) == none of

    true ->
      New_proposals = Proposals ++ [{Slot_in, Command}],
      [ Leader ! {propose, Slot_in, Command} || Leader <- Leaders];

    false ->
      New_proposals = Proposals
  end,

  propose(Leaders, Slot_in + 1, Requests, New_proposals, Decisions, Count - 1).

% DECIDES which commands should be executed and executes them
decide(_, Slot_out, [], _, Proposals, Requests) ->
  {Proposals, Requests, Slot_out};
decide(Database, Slot_out, [{Slot_out, Command} | _], All_decisions, Proposals, Requests) ->
  Proposed_command = get_slot_command(Slot_out, Proposals),

  case Proposed_command /= none of

    % Case where a command with Slot = Slot_out is in the Proposals list
    true ->
      New_proposals = lists:delete({Slot_out, Proposed_command}, Proposals),

      % If command is different from one which is going to be executed,
      % put it back in the Requests list, else ignore it
      case  Proposed_command /= Command of
        true ->
          New_requests = Requests ++ [Command];

        false ->
          New_requests = Requests
      end;

    % Case where no command with Slot = Slot_out in the Proposals list
    false ->
      New_proposals = Proposals,
      New_requests = Requests
  end,

  New_slot_out = perform(Database, Slot_out, lists:delete({Slot_out, Command}, All_decisions), Command),
  decide(Database, New_slot_out, All_decisions, All_decisions, New_proposals, New_requests);

decide(Database, Slot_out, [_ | Decisions], All_decisions, Proposals, Requests) ->
  decide(Database, Slot_out, Decisions, All_decisions, Proposals, Requests).

% PERFORM operation on database if action has not already executed
perform(Database, Slot_out, Decisions, {K, Cid, Op}) ->
  case has_been_executed(Decisions, Slot_out, {K, Cid, Op}) of

    false ->
      Database ! {execute, Op},
      K ! {response, Cid, ok};

    true -> skip
  end,

  Slot_out + 1.

% Get the given Command for a specific Slot from a list of pairs {Slot, Command}
get_slot_command(_, []) -> none;
get_slot_command(Slot, [{Slot, Command} | _]) -> Command;
get_slot_command(Slot, [_ | Proposals]) -> get_slot_command(Slot, Proposals).

% Check if a command already has been executed
has_been_executed([], _, _) -> false;
has_been_executed([ {Slot, Command_executed} | Decisions ], Slot_out, Command) ->

  if
    (Slot < Slot_out) and (Command_executed == Command) ->
      true;

    true ->
      has_been_executed(Decisions, Slot_out, Command)
  end.
