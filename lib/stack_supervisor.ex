defmodule StackSupervisor do
  # Client
  def start_link do
    spawn_link(__MODULE__, :init, [])
  end

  def start_stack(supervisor_pid, stack_name, initial_state \\ []) do
    send(supervisor_pid, {:start_stack, stack_name, initial_state})
  end

  def find(supervisor_pid, stack_name) do
    send(supervisor_pid, {:find, stack_name, self()})

    stack_pid =
      receive do
        {:found, stack_pid} -> stack_pid
      end

    if stack_pid do
      {:ok, stack_pid}
    else
      :error
    end
  end

  # Server
  def init do
    Process.flag(:trap_exit, true)
    loop(%{})
  end

  def loop(children) do
    loop(
      receive do
        {:start_stack, stack_name, initial_state} ->
          IO.inspect("start_stack: #{stack_name}")
          stack_pid = spawn_link(Stack, :loop, [initial_state])
          Map.put(children, stack_name, stack_pid)

        {:find, stack_name, sender} ->
          IO.inspect("find_stack: #{stack_name}")
          send(sender, {:found, children[stack_name]})
          children

        {:EXIT, dead_pid, _} ->
          stack_name = children |> Enum.find(fn {key, val} -> val == dead_pid end) |> elem(0)
          IO.inspect("restart_stack: #{stack_name}")
          start_stack(self(), stack_name)
          children
      end
    )
  end
end
