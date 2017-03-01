%%% Paul Vidal (pv14) and Saturnin Pugnet (sp5414)

-module(scout).
-import(utils, [compare/2]).
-export([start/3]).

start(Leader, Acceptors, Ballot_number) ->
  [Acceptor ! {p1a, self(), Ballot_number} || Acceptor <- Acceptors],
  next(Leader, Acceptors, Ballot_number, Acceptors, []).

next(Leader, Acceptors, Ballot_number, Wait_for, P_values) ->
  receive
    {p1b, Acceptor, Ballot, Accepted_values} ->
      case compare(Ballot, Ballot_number) == 0 of

        % Case where Ballot == Ballot_number
        true ->
          New_p_values = P_values ++ Accepted_values,
          New_wait_for = lists:delete(Acceptor, Wait_for),

          if
            length(New_wait_for) < (length(Acceptors) / 2) ->
              Leader ! {adopted, Ballot_number, New_p_values},
              exit(stop);

            true -> skip
         end,

         next(Leader, Acceptors, Ballot_number, New_wait_for, New_p_values);

         % Case where Ballot != Ballot_number
         false ->
           Leader ! {preempted, Ballot},
           exit(stop)
      end
  end.
