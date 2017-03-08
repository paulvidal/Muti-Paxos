%%% Paul Vidal (pv14) and Saturnin Pugnet (sp5414)

%%% distributed algorithms, n.dulay 27 feb 17
%%% coursework 2, paxos made moderately complex

-module(system).
-export([start/1]).

start([Arg1, Arg2, Arg3, Arg4 | _]) ->
  {N_servers, _}  = string:to_integer(atom_to_list(Arg1)),
  {N_clients, _}  = string:to_integer(atom_to_list(Arg2)),
  {N_accounts, _} = string:to_integer(atom_to_list(Arg3)),
  Max_amount = 1000,

   %  Milli-seconds for Simulation
  {End_after, _}  = string:to_integer(atom_to_list(Arg4)),

  _Servers = [ spawn(server, start, [self(), N_accounts, End_after])
    || _ <- lists:seq(1, N_servers) ],

  Components = [ receive {config, R, A, L} -> {R, A, L} end
    || _ <- lists:seq(1, N_servers) ],

  {Replicas, Acceptors, Leaders} = lists:unzip3(Components),

  [ Replica ! {bind, Leaders} || Replica <- Replicas ],
  [ Leader  ! {bind, Acceptors, Replicas} || Leader <- Leaders ],

  _Clients = [ spawn(client, start,
               [Replicas, N_accounts, Max_amount, End_after])
    || _ <- lists:seq(1, N_clients) ],

  done.
