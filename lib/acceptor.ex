defmodule Acceptor do


  def start config do
    next config, 0, MapSet.new
  end


  defp next config, ballot_num, accepted do

      receive do
        {:p1a, leader_id, b} ->
          ballot_num =
          if b > ballot_num do
            b
          else
            ballot_num
          end
        send leader_id, {:p1b, self(), ballot_num, accepted}
        next config, ballot_num, accepted

        {:p2a, leader_id, {b, s, c}} ->
          accepted =
          if b == ballot_num do
            MapSet.put(accepted, {b, s, c})
          else
            accepted
          end
          send leader_id, {:p2b, self(), ballot_num}
          next config, ballot_num, accepted

    end
  end
end
