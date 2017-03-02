%%% Paul Vidal (pv14) and Saturnin Pugnet (sp5414)

-module(acceptor).
-import(utils, [compare/2]).
-export([start/0]).

start() ->
  Starting_ballot_number = {-1, 0},
  next(Starting_ballot_number, []).

next(Ballot_number, Accepted) ->

  receive
    {p1a, Leader, Ballot} ->
      case compare(Ballot, Ballot_number) > 0 of
        true -> New_ballot_number = Ballot;
        false -> New_ballot_number = Ballot_number
      end,

      Leader ! {p1b, self(), New_ballot_number, Accepted},
      next(New_ballot_number, Accepted);

    {p2a, Leader, {Ballot, Slot, Command}} ->
      case compare(Ballot, Ballot_number) == 0 of
        true -> New_accepted = Accepted ++ [{Ballot, Slot, Command}];
        false -> New_accepted = Accepted
      end,

      Leader ! {p2b, self(), Ballot_number},
      next(Ballot_number, New_accepted)
  end.
