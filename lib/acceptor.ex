defmodule Acceptor do

  def start config do
    # Define falsity ballot number as {-1, -1}
    next {-1, -1}, Map.new
  end

  # Main loop for Acceptor 
  defp next ballot_num, accepted do
    receive do
      {:p1a, l, b} ->
        ballot_num = 
          if b > ballot_num do
            b
          else
            ballot_num
          end
        send l, {:p1b, self(), ballot_num, MapSet.new(Map.values(accepted))}
        next ballot_num, accepted

      {:p2a, l, {b, s, c}} ->
        accepted = 
          if ballot_num == b do
            Map.put(accepted, s, {b, s, c})
          else
            accepted
          end
        send l, {:p2b, self(), ballot_num}
        next ballot_num, accepted
    end
  end
end