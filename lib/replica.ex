defmodule Replica do

  def start  config, database, monitor do
    receive do
      {:bind, leaders} ->
        next config, database, monitor, leaders, 1, 1, MapSet.new, Map.new, Map.new, Map.new
    end
  end


  def next config, database, monitor, leaders, slot_in, slot_out, requests, proposals, decisions, performed do

    receive do
      {:client_request, c} ->
        requests = MapSet.put(requests, c)
        send monitor, {:client_request, config.server_num}
        {leaders, requests, proposals, slot_in} = propose(slot_in, slot_out, config, decisions, leaders, requests, proposals)
        next config, database, monitor, leaders, slot_in, slot_out, requests, proposals, decisions, performed

      {:decision, s, c} ->
        decisions = Map.put(decisions, s, c)
        performed = Map.put(performed, c, false)
        # Make function perform_all to simulate while loop.
        {database, requests, proposals, decisions, slot_out, performed} =
           perform_all(database, requests, proposals, decisions, slot_out, performed)

        {leaders, requests, proposals, slot_in} = propose(slot_in, slot_out, config, decisions, leaders, requests, proposals)
        next config, database, monitor, leaders, slot_in, slot_out, requests, proposals, decisions, performed
    end
  end

  def perform_all database, requests, proposals, decisions, slot_out, performed do
    {database, requests, proposals, decisions, slot_out, performed}=
    if Map.get(decisions, slot_out) do
      requests =
        if decisions[slot_out] != proposals[slot_out] do
          MapSet.put(requests, proposals[slot_out])
        else
          requests
        end
        proposals = Map.delete(proposals, proposals[slot_out])

        {slot_out, performed} = perform(database, decisions, slot_out, performed)
        perform_all database, requests, proposals, decisions, slot_out, performed
    else
      {database, requests, proposals, decisions, slot_out, performed}
    end
        {database, requests, proposals, decisions, slot_out, performed}

  end

    def perform database, decisions, slot_out, performed do
      {k, cid, op} = Map.get(decisions, slot_out)
      c = {k, cid, op}
      op_performed = performed[c]

      {slot_out, performed} =
      if !op_performed do
        send database, {:execute, op}
        send k, {:reply, cid, :ok}
        {slot_out + 1, Map.put(performed, c, true)}
      else
        {slot_out+1, performed}
      end
      {slot_out, performed}
    end


  def propose slot_in, slot_out, config, decisions, leaders, requests, proposals do
      if slot_in < slot_out + config.window && MapSet.size(requests) > 0 do
        c = Enum.at(requests, 0)
        {requests, proposals} =
          if !decisions[slot_in] do
            {MapSet.delete(requests, c),
              Map.put(decisions, slot_in, c)}
          else
            {requests, proposals}
          end
          for leader_id <- leaders, do:
            send leader_id, {:propose, slot_in, c}
          slot_in = slot_in + 1;
          propose(slot_in, slot_out, config, decisions, leaders, requests, proposals)
        else
          {leaders, requests, proposals, slot_in}
        end
  end
end
