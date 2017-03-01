%%% Paul Vidal (pv14) and Saturnin Pugnet (sp5414)

-module(commander).
-import(utils, [compare/2]).
-export([start/4]).

start(Leader, Acceptors, Replicas, P_value) ->
  [ Acceptor ! {p2a, self(), P_value} || Acceptor <- Acceptors],
  next(Leader, Acceptors, Replicas, P_value, Acceptors).

next(Leader, Acceptors, Replicas, {Ballot_number, Slot , Command}, Wait_for) ->
  receive
    {p2b, Acceptor, Ballot} ->
      if
        % Case where Ballot == Ballot_number
        compare(Ballot, Ballot_number) == 0 ->
          New_wait_for = lists:delete(Acceptor, Wait_for),

          if
            length(New_wait_for) < (length(Acceptors) / 2) ->
              [ Replica ! {decision, Slot, Command} || Replica <- Replicas],
              exit(stop);

            true -> skip
         end,

         next(Leader, Acceptors, Ballot_number, New_wait_for, New_p_values);

         % Case where Ballot != Ballot_number
         true ->
           Leader ! {preempted, Ballot},
           exit(stop)
      end,
  end
