defmodule Scout do

  def start leader_id, acceptors, b do

    for acceptor <- acceptors, do:
      send acceptor, {:p1a, self(), b}

    next leader_id, acceptors, b, acceptors, []
  end

  defp next leader_id, acceptors, b, waitfor, pvalues do
    receive do
      {:p1b, acceptor, b_app, response} ->
        {pvalues, waitfor} =
        if b_app = b do
          {List.insert_at(pvalues, response, 0),
          List.delete(waitfor, acceptor)}
          if (length(waitfor) < length(acceptors) / 2) do
            send leader_id, {:adopted, b, pvalues}
            Process.exit(0, :kill)
          end
        else
          {pvalues, waitfor}
          send leader_id, {:preempted, b_app}
        end
        next leader_id, acceptors, b, waitfor, pvalues
    end
  end
end
