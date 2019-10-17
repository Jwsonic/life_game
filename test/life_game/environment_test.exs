defmodule LifeGame.EnvironmentTest do
  use ExUnit.Case, async: true

  alias LifeGame.Environment

  @env0 %Environment{cells: %{}, height: 5, width: 5}
  @env1 %Environment{cells: %{{0, 0} => 1}, height: 5, width: 5}

  @pending
  test "tick/1 produces correct results"

  test "put_status/3 correctly updates a cell"
end
