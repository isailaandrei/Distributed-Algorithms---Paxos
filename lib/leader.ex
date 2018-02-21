defmodule Leader do

  def start config, monitor do
    receive do
      {:bind, acceptors, replicas} ->
        ballot_num  = {0, self()}
        spawn_send_scout acceptors, ballot_num, config, monitor
        next acceptors, replicas, {0, self()}, false, Map.new, config, monitor
    end
  end


  defp next acceptors, replicas, ballot_num, active, proposals, config, monitor do
    receive do

      {:propose, s, c} ->
        proposals =
          if (proposals[s] == nil || proposals[s] == c) do
            if active do
              spawn_send_commander acceptors, replicas, {ballot_num, s, c}, config, monitor
            end
            Map.put(proposals, s, c)
          else
            proposals
          end
        next acceptors, replicas, ballot_num, active, proposals, config, monitor


      {:adopted, ballot_num, pvals} ->
        proposals = rightjoin proposals, pvals
        for {s, c} <- proposals, do:
         spawn_send_commander acceptors, replicas, {ballot_num, s, c}, config, monitor
        active = true
        next acceptors, replicas, ballot_num, active, proposals, config, monitor


        {:preempted, b={r_app, _}} ->
          {ballot_num, active} =
            if b > ballot_num do
              spawn_send_scout acceptors, {r_app + 1, self()}, config, monitor
              {{r_app + 1, self()}, false}
            else
              {ballot_num, active}
            end
          next acceptors, replicas, ballot_num, active, proposals, config, monitor
    end
  end



  def pmax pvals do
    pvals = Enum.sort_by(pvals, fn {b, _, _} -> b end)
    res = Map.new(for {_, s, c} <- pvals, do: {s, c})
    res
  end

  def rightjoin proposals, pvals do
    pvals = pmax pvals
    res = Map.new(Map.to_list(pvals) ++
  Enum.filter(proposals, fn {s, _} -> !Map.has_key?(pvals, s) end))
    res
  end

  def spawn_send_scout acceptors, ballot_num, config, monitor  do
    spawn Scout, :start, [self(), acceptors, ballot_num]
    send monitor, {:add_scout, config.server_num}
  end

  def spawn_send_commander acceptors, replicas, pvalue, config, monitor do
    spawn Commander, :start, [self(), acceptors, replicas, pvalue]
    send monitor, {:add_commander, config.server_num}
  end


end
