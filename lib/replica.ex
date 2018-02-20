defmodule Replica do

  def start database, monitor, config do
    receive do
      {:bind, leaders} ->
        next config, database, monitor, leaders, 1, 1, MapSet.new, Map.new, Map.new
    end
  end


  def next config, database, monitor, leaders, slot_in, slot_out, requests, proposals, decisions do

    receive do
      {:request, c} ->
        requests = MapSet.put(requests, c)
        {leaders, requests, proposals, slot_in} = propose(slot_in, slot_out, config, decisions, leaders, requests, proposals)
        next config, database, monitor, leaders, slot_in, slot_out, requests, proposals, decisions

      {:decision, s, c} ->
        decisions = Map.put(decisions, s, c)
        # Make function perform_all to simulate while loop.
        {database, requests, proposals, decisions, slot_out} = perform_all(database, requests, proposals, decisions, slot_out)

        {leaders, requests, proposals, slot_in} = propose(slot_in, slot_out, config, decisions, leaders, requests, proposals)
        next config, database, monitor, leaders, slot_in, slot_out, requests, proposals, decisions
    end
  end

  def perform_all database, requests, proposals, decisions, slot_out do

  end

  def propose slot_in, slot_out, config, decisions, leaders, requests, proposals do

  end
end
