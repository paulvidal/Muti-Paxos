%%% Paul Vidal (pv14) and Saturnin Pugnet (sp5414)

-module(acceptor).
-import(utils, [compare/2]).
-export([start/0]).

start() ->
  next(0, []).

next(Ballot_number, Accepted) ->

  receive
    {p1a, Leader, Ballot} ->
      if compare(Ballot, Ballot_number) > 0 -> New_ballot_number = Ballot;
         true -> New_ballot_number = Ballot_number
      end,

      Leader ! {p1b, self(), New_ballot_number, Accepted},
      next(New_ballot_number, Accepted);

    {p2a, Leader, {Ballot, Slot, Command}} ->
      if compare(Ballot, Ballot_number) == 0 ->
        New_accepted = Accepted ++ {Ballot, Slot, Command};
        true -> New_accepted = Accepeted
      end,

      Leader ! {p2b, self(), Ballot_number},
      next(Ballot_number, New_accepted)
  end.
