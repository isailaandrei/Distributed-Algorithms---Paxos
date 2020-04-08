defmodule Leader do

  def start config, monitor do
    receive do
      {:bind, acceptors, replicas} ->
        ballot_num = {0, self()}
        spawn Scout, :start, [self(), acceptors, ballot_num, monitor, config]
        next acceptors, replicas, ballot_num, false, MapSet.new, config, nil, monitor
    end
  end

  # Main loop of Leader
  defp next acceptors, replicas, ballot_num, active, proposals, config, monitoring_leader, monitor do
    receive do
      {:propose, s, c} ->
        if !Enum.find(proposals, fn p -> match?({^s ,_}, p) end) do
          proposals = MapSet.put(proposals, {s, c})
          if active do
            spawn Commander, :start, [self(), acceptors, replicas, {ballot_num, s, c}, monitor, config]
          # monitoring_leader is the one that preempted this current leader
          # even if the monitoring_leader is not active, we are using
          # an "ancestor" reasoning, i.e. the monitoring_leader was
          # eventually preempted by someone else, whom he will forward
          # the message to
          # Uncomment the code below for collocation
          #else
          #  if monitoring_leader do
          #    send monitoring_leader, {:propose, s, c}
          #  end
          end
        end
        next acceptors, replicas, ballot_num, active, proposals, config, monitoring_leader, monitor

      {:adopted, ^ballot_num, pvals} ->
        proposals = update(proposals, pmax pvals)
        for {s, c} <- proposals do
          spawn Commander, :start, [self(), acceptors, replicas, {ballot_num, s, c}, monitor, config]
        end
        active = true
        next acceptors, replicas, ballot_num, active, proposals, config, monitoring_leader, monitor

      {:preempted, {r, leader}} ->
        if config.debug_level == 1 do
          IO.puts "DEBUG ACTIVE: Ping-pong -- ballot number: #{inspect ballot_num}, pid: #{inspect self()}"
        end
        if {r, leader} > ballot_num do
          active = false
          ballot_num = {r + 1, self()}
          # Ping Pong if you spawn the scout immediately
          # Thus, introduce a bit of asymmetry to resolve the livelock
          Process.sleep(:rand.uniform(1000))
          spawn Scout, :start, [self(), acceptors, ballot_num, monitor, config]
        end
        # For collocation we need to store the leader who preempted this one
        # monitoring_leader = leader
        next acceptors, replicas, ballot_num, active, proposals, config, monitoring_leader, monitor
    end
  end

  defp pmax pvals do
    MapSet.new(for {b, s, c} <- pvals, Enum.all?(pvals, fn {b_prime, s_prime, _} -> s != s_prime or b_prime <= b end), do: {b, s, c})
  end

  # The update function applies to two sets of proposals.
  # Returns the elements of y as well as the elements
  # of x that are not in y.
  # Warning: this is not union! When talking about
  # elements of y, we refer to fst p, where p is a
  # pair in y
  defp update(x, y) do
    res = MapSet.new(for {s, elem} <- x, !Enum.find(y, fn p -> match?({^s, _}, p) end), do: {s, elem})
    MapSet.union(res, MapSet.new(y))
  end

end