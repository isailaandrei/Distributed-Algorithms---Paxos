defmodule Acceptor do


  def start config do
    IO.puts "SAL MAMA"
    next(config, 0, MapSet.new )
  end


  defp next config, ballot_num, accepted do
    ballot_num =
    receive do
      {:p1a, leader_id, b} ->
          if b > ballot_num do
            b
          end
        send leader_id, {:p1b, self(), ballot_num, accepted}
      {:p2a, leader_id, {b, s, c}} ->
        if b > ballot_num do
          MapSet.put(accepted, {b, s, c})
        end
        send leader_id, {:p2b, self(), ballot_num}
    end
    next config, ballot_num, accepted
  end
end
