%%% Paul Vidal (pv14) and Saturnin Pugnet (sp5414)

-module(leader).
-import(utils, [compare/2]).
-export([start/2]).

start(Acceptors, Replicas) ->
  next(Acceptors, Replicas, {0, self()}, false, []).

next(Acceptors, Replicas, Ballot_number, Active, Proposals) ->
  receive
    {propose, Slot, Command} ->
      if
        not is_proposed(Slot, Proposals) ->
          New_proposals = Proposals ++ {Slot, Command},

          if
            Active ->
              spawn(commander, start,
                [self(), Acceptors, Replicas, {Ballot_number, Slot, Command}]);
            true -> skip
          end;

        true ->
          New_proposals = Proposals

      end,

      next(Acceptors, Replicas, Ballot_number, Active, New_proposals);

    {adopted, Ballot, P_values} ->
      P_max = p_max(P_values),
      New_proposals = update_proposals(Proposals, P_max),
      [ spawn(commander, start,
              [self(), Acceptors, Replicas, {Ballot, Slot, Command}])
        || {Slot, Command} <- New_proposals],

      next(Acceptors, Replicas, Ballot_number, true, New_proposals);

    {preempted, Ballot} ->
      if
        compare(Ballot, Ballot_number) > 0 ->
          New_active = false,
          {Num, _} = Ballot,
          New_ballot_number = {Num + 1, self()},
          spawn(scout, start, [self(), Acceptors, Ballot_number]);

        true ->
          New_ballot_number = Ballot_number,
          New_active = true
      end,

      next(Acceptors, Replicas, New_ballot_number, New_active, Proposals)
  end.

% Check if a slot is proposed
is_proposed(_, []) -> false;
is_proposed(Slot, [{Slot, _} | _]) -> true;
is_proposed(Slot, [_ | Proposals]) -> is_proposed(S, Proposals).

% Determine for each slot the command corresponding the maximum ballot
p_max(P_values) -> p_max(P_values, maps:new()).
p_max([], Max_ballot_for_slots) -> maps:to_list(Max_ballot_for_slots);
p_max([{Ballot, Slot, Command} | P_values], Max_ballot_for_slots) ->
  {Current_max_ballot, _, _} = maps:get(Slot, Max_ballot_for_slots),

  if
    Current_max_ballot < Ballot -> New_max_ballot_for_slot
      = maps:put(Slot, {Ballot, Slot, Command}, Max_ballot_for_slots);

    true -> New_max_ballot_for_slot = Max_ballot_for_slot

  end,

  p_max(P_values, New_max_ballot_for_slot).

% Returns the elements in the list Y and the elements of X that are not in Y
update_proposals(X, Y) -> sets:to_list(sets:from_list(X ++ Y)).
