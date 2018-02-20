  defmodule Commander do

  def start leader_id, acceptors, replicas,  {b, s, c} do

    for acceptor <- acceptors, do:
      send acceptor, {:p2a, self(), {b, s, c}}

    next leader_id, acceptors, acceptors, replicas, {b, s, c}
  end

  defp next leader_id, acceptors, waitfor, replicas, {b, s, c} do
    receive do
      {:p2b, acceptor, b_app} ->
        if b_app = b do
          MapSet.delete(waitfor, acceptor)
          if (length(waitfor) < length(acceptors) / 2) do
            for replica <- replicas, do:
              send replica, {:decision, s, c}
            Process.exit(0, :kill)
          end
        else
          send leader_id, {:preempted, b_app}
        end
    end
    next leader_id, acceptors, waitfor, replicas, {b, s, c}
  end
end
