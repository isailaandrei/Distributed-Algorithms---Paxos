defmodule Scout do

  def start leader_id, acceptors, b do

    for acceptor <- acceptors, do:
      send acceptor, {:p1a, self(), b}

    next leader_id, acceptors, b, acceptors, MapSet.new
  end

  defp next leader_id, acceptors, b, waitfor, pvalues do
    receive do
      {:p1b, acceptor, b_app, r} ->
        if b_app == b do
          pvalues = MapSet.union(pvalues, r)
          waitfor = MapSet.delete(waitfor, acceptor)
          if (MapSet.size(waitfor) < MapSet.size(acceptors) / 2) do
            send leader_id, {:adopted, b, pvalues}
          else
            next leader_id, acceptors, b, waitfor, pvalues
          end
        else
          send leader_id, {:preempted, b_app}
        end
    end
  end
end
