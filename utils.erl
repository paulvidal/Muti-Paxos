%%% Paul Vidal (pv14) and Saturnin Pugnet (sp5414)

-module(utils).
-export([compare/2]).

compare({Num1, LeaderId1}, {Num2, LeaderId2}) ->
  if
    Num1 > Num2 -> 1;
    Num1 < Num 2 -> -1;
    LeaderId1 > LeaderId2 -> 1;
    LeaderId1 < LeaderId2 -> -1;
    true -> 0
  end.
