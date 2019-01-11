defmodule SupervisorWorkshopTest do
  use ExUnit.Case

  # The Erlang VM when created, 30 years ago, set out to solve a single
  # problem. How do we write software that is fault tolerant? Another way to
  # ask the same question is: How do write software that is able to recover
  # itself when failure occurs?
  #
  # The answer to this is to write small applications that only do one things
  # (processes) and restart them quickly in the event of failure. There are
  # only a few primitives needed to accomplish this: processes and messages. We
  # covered alot about processes last time. The main thing we learned is
  # `spawn\1` and `spawn\3` will create a completely seperate application with
  # it's own stack and garbage collector and that application runs single
  # threaded. Because Erlangs VM handles pre-emptive scheduling of processes
  # for us we do not have to consider or thing about `locking` or `mutual
  # exclusions`, only that our new "application" runs eventually and
  # concurrently. We also discovered that thee applications (processes) can
  # send messages to each other via the `recieve\0` and `send\2` functions.

  test "review of processes" do
    stack_pid = Stack.new()

    Stack.push(stack_pid, :foo)
    Stack.push(stack_pid, :bar)

    assert Stack.pop(stack_pid) == :bar
  end

  # Now that we know how to start another process let's talk about exception handling.
  #
  # Currently when our stack encounters an error nothing happens. Meaning that
  # the process dies (no longer running). An exception happens but it is
  # contained in that process. The stack code above has a bug. If you pop the
  # stack and nothing is in the stack an exception is raised.

  test "processes are independent" do
    stack_pid = Stack.new()

    assert Stack.pop(stack_pid) == :error

    # the stack encountered an exception and died
    refute Process.alive?(stack_pid)
  end

  # Sometimes we want to be able to handle those exceptions and we can do this
  # through "linking". When a process is linked, the exceptions from that
  # process are recieved by the process that linked it. Linking our stack to
  # our test process would cause the test process to throw an exception. So we
  # can use it in addition to another technique call "trapping exits". Trapping
  # exit converts the external exceptions into messages that are added to the
  # trapping process's mailbox.

  test "linked processes" do
    stack_pid = Stack.new()
    Process.link(stack_pid)
    Process.flag(:trap_exit, true)

    Stack.pop(stack_pid)

    assert_received {:EXIT, ^stack_pid, _}
  end

  # Because a process can have an exception before linking occurs there is a
  # more atomic way to do this.

  test "atomic linked processes" do
    # trap exits first
    Process.flag(:trap_exit, true)

    # use spawn link to create process and link it at the same time
    stack_pid = spawn_link(Stack, :loop, [[]])

    Stack.pop(stack_pid)

    assert_received {:EXIT, ^stack_pid, _}
  end
end
