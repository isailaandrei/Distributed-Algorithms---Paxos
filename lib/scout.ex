defmodule Scout do

  def start leader_id, acceptors, b do

    for acceptor <- acceptors, do:
      send acceptor, {:p1a, self(), b}

    next leader_id, acceptors, b, acceptors, MapSet.new
  end

  defp next leader_id, acceptors, b, waitfor, pvalues do
    receive do
      {:p1b, acceptor, b_app, response} ->
        if b_app = b do
          MapSet.put(pvalues, response)
          MapSet.delete(waitfor, acceptor)
          if (length(waitfor) < length(acceptors) / 2) do
            send acceptor, {:adopted, b, pvalues}
            Process.exit(0, :kill)
          end
        else
          send leader_id, {:preempted, b_app}
        end
    end
    next leader_id, acceptors, b, waitfor, pvalues
  end
end
