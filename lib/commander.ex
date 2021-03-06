  defmodule Commander do

  def start leader_id, acceptors, replicas,  {b, s, c} do

    for acceptor <- acceptors, do:
      send acceptor, {:p2a, self(), {b, s, c}}

    next leader_id, acceptors, acceptors, replicas, {b, s, c}
  end

  defp next leader_id, acceptors, waitfor, replicas, {b, s, c} do
    receive do
      {:p2b, acceptor, b_app} ->
        if b_app == b do
          waitfor = MapSet.delete(waitfor, acceptor)
          if (MapSet.size(waitfor) < MapSet.size(acceptors) / 2) do
            for replica <- replicas, do:
              send replica, {:decision, s, c}
          else
            next leader_id, acceptors, waitfor, replicas, {b, s, c}
          end
        else
          send leader_id, {:preempted, b_app}
        end
    end
  end
end
