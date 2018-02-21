defmodule Scout do

  def start leader_id, acceptors, b do

    for acceptor <- acceptors, do:
      send acceptor, {:p1a, self(), b}

    next leader_id, acceptors, b, acceptors, MapSet.new
  end

  defp next leader_id, acceptors, b, waitfor, pvalues do
    receive do
      {:p1b, acceptor, b_app, r} ->
        {pvalues, waitfor} =
        if b_app = b do
          p = MapSet.union(pvalues, r)
          w = MapSet.delete(waitfor, acceptor)
          if (MapSet.size(waitfor) < MapSet.size(acceptors) / 2) do
            send leader_id, {:adopted, b, pvalues}
          end
          {p, w}
        else
          send leader_id, {:preempted, b_app}
          {pvalues, waitfor}
        end
        next leader_id, acceptors, b, waitfor, pvalues
    end
  end
end
