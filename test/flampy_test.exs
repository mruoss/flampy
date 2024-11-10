defmodule FlampyTest do
  use ExUnit.Case
  doctest Flampy

  test "greets the world" do
    assert Flampy.hello() == :world
  end
end
