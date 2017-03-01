%%% Paul Vidal (pv14) and Saturnin Pugnet (sp5414)

-module(commander).
-import(utils, [compare/2]).
-export([start/4]).

start(Leader, Acceptors, Replicas, P_value) ->
  [ Acceptor ! {p2a, self(), P_value} || Acceptor <- Acceptors],
  next(Leader, Acceptors, Replicas, P_value, Acceptors).

next(Leader, Acceptors, Replicas, {Ballot_number, Slot, Command}, Wait_for) ->
  receive
    {p2b, Acceptor, Ballot} ->
      case compare(Ballot, Ballot_number) == 0  of
        % Case where Ballot == Ballot_number
        true ->
          New_wait_for = lists:delete(Acceptor, Wait_for),

          if
            length(New_wait_for) < (length(Acceptors) / 2) ->
              [ Replica ! {decision, Slot, Command} || Replica <- Replicas],
              exit(stop);

            true -> skip
          end,

          next(Leader, Acceptors, Replicas,
               {Ballot_number, Slot, Command}, New_wait_for);

        % Case where Ballot != Ballot_number
        false ->
          Leader ! {preempted, Ballot},
          exit(stop)
      end
  end.
