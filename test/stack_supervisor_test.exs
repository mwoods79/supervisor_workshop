defmodule StackSupervisorTest do
  use ExUnit.Case

  test "smoke" do
    sup = StackSupervisor.start_link()
    StackSupervisor.start_stack(sup, "MyStack")
    {:ok, stack_pid} = StackSupervisor.find(sup, "MyStack")

    Stack.pop(stack_pid)

    refute Process.alive?(stack_pid)

    {:ok, stack_pid} = StackSupervisor.find(sup, "MyStack")

    Stack.push(stack_pid, "foo")
    assert Stack.pop(stack_pid) == "foo"
  end
end
