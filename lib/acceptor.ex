defmodule Acceptor do


  def start config do
    next(config, 0, [] )
  end


  defp next config, ballot_num, accepted do

      receive do
      {:p1a, leader_id, b} ->
        {ballot_num, accepted} =
        if b > ballot_num do
          {b, accepted}
        else
          {ballot_num, accepted}
        end
      send leader_id, {:p1b, self(), ballot_num, accepted}
      next config, ballot_num, accepted

      {:p2a, leader_id, {b, s, c}} ->
        {ballot_num, accepted} =
        if b > ballot_num do
          {ballot_num, List.insert_at(accepted, {b, s, c}, 0)}
        else
          {ballot_num, accepted}
        end
        send leader_id, {:p2b, self(), ballot_num}
        next config, ballot_num, accepted

    end
  end
end
