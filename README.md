# Compile and run options

We can run the Paxos system manually or by using the rules defined in the makefile
Namely the most useful are

make compile    - compile
make clean  - remove compiled code

make run    - run in single node
make run SERVERS=n CLIENTS=m CONFIG=p
                - run with different numbers of servers, clients and
                - version of configuration file, arguments are optional

make up     - make gen, then run in a docker network 
make up SERVERS=<n> CLIENTS=<m> CONFIG=<p>

make gen    - generate docker-compose.yml file
make down   - bring down docker network
make kill   - use instead of make down or if make down fails
make show   - list docker containers and networks

make ssh_up - run on real hosts via ssh (omitted)
make ssh_down   - kill nodes on real network (omitted)
make ssh_show   - show running nodes on real network (omitted)

There are further options in the makefile

# Testing
The arguments for the tests are set in the Makefile and are passed as command line arguments to the programs
(see: mke up SERVERS=<n> CLIENTS=<m> CONFIG=<p>)
Namely you can set
SERVERS = 3
number of servers
CLIENTS = 2
number of clients
CONFIG  = 1 
version of config to use, configs can be defined and modified in the configuration.ex file
An example configuration looks as follows:

'''
def version 1 do    # configuration 1
  %{
  debug_level:  0,  # debug level
  docker_delay: 5_000,  # time (ms) to wait for containers to start up

  max_requests: 500,    # max requests each client will make
  client_sleep: 5,  # time (ms) to sleep before sending new request
  client_stop:  10_000, # time (ms) to stop sending further requests
  n_accounts:   100,    # number of active bank accounts
  max_amount:   1000,   # max amount moved between accounts

  print_after:  1_000,  # print transaction log summary every print_after msecs

  window_size: 100 # For replicas: Max amount of more commands that are proposed than decided by the Synod protocol
  }
end
'''