defmodule Leader do

  def start config do
    receive do

      {:bind, acceptors, replicas} ->
        scout = spawn Scout, :start, [self(), acceptors, {0, self()}]
        next acceptors, replicas, {0, self()}, false, Map.new
    end
  end


  defp next acceptors, replicas, ballot_num, active, proposals do
    receive do

      {:propose, s, c} ->
        if (proposals[s] == nil || proposals[s] == c) do
            Map.put(proposals, s, c)
          if active do
            spawn(Commander, :start, [self(), acceptors, replicas, {ballot_num, s, c}])
          end
        end
        next acceptors, replicas, ballot_num, active, proposals


      {:adopted, ballot_num, pvals} ->
        proposals = rightjoin proposals, pvals
        for {s, c} <- proposals, do:
         spawn Commander, :start, [self(), acceptors, replicas, {ballot_num, s, c}]
        active = true
        next acceptors, replicas, ballot_num, active, proposals


        {:preempted, b={r_app, leader_id_app}} ->
          {ballot_num, active} =
            if b > ballot_num do
              spawn Scout, :start, [self(), acceptors, {r_app + 1, self()}]
              {{r_app + 1, self()}, false}
            else
              {ballot_num, active}
            end
          next acceptors, replicas, ballot_num, active, proposals
    end
  end



  def pmax pvals do
    pvals = Enum.sort_by(pvals, fn {b, s, c} -> b end)
    res = Map.new(for {b, s, c} <- pvals, do: {s, c})
    res
  end

  def rightjoin proposals, pvals do
    pvals = pmax pvals
    res = Map.new(Map.to_list(pvals) ++
  Enum.filter(proposals, fn {s, c} -> !Map.has_key?(pvals, s) end))
    res
  end


end
