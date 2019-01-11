defmodule Stack do
  @moduledoc """
  This module represents a stack
  """

  ## Client implmentation
  def new do
    # `spawn\3` this creates a new process (application) with it's own stack and garbage collector
    # NOTE: used so often it's also called spawn mfa (module, function, arguments)
    spawn(__MODULE__, :loop, [[]])
  end

  def push(pid, val) do
    # `send\2` sends a message to another process
    send(pid, {:push, val})
    :ok
  end

  def pop(pid) do
    # send pop to other application
    send(pid, {:pop, self()})

    # `receive\0` blocks until a message is in the mailbox 
    # wait for other application to send the answer back
    receive do
      {:pop, val} -> val
    after
      10 -> :error
    end
  end

  ## Server implementation
  def loop(state) do
    new_state =
      receive do
        {:push, val} ->
          [val | state]

        {:pop, sender} ->
          [val | rest_of_stack] = state
          send(sender, {:pop, val})
          rest_of_stack
      end

    loop(new_state)
  end
end
