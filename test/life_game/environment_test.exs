defmodule LifeGame.EnvironmentTest do
  use ExUnit.Case, async: true

  alias LifeGame.Environment

  @env0 Environment.new(5, 5)
  @env1 Environment.new(5, 5, [{0, 0}])

  @glider_frames [
    Environment.new(5, 5, [{0, 2}, {1, 3}, {2, 1}, {2, 2}, {2, 3}]),
    Environment.new(5, 5, [{1, 1}, {1, 3}, {2, 2}, {2, 3}, {3, 2}]),
    Environment.new(5, 5, [{1, 3}, {2, 1}, {2, 3}, {3, 2}, {3, 3}]),
    Environment.new(5, 5, [{1, 2}, {2, 3}, {2, 4}, {3, 2}, {3, 3}]),
    Environment.new(5, 5, [{1, 3}, {2, 4}, {3, 2}, {3, 3}, {3, 4}])
  ]

  test "tick/1 produces correct results" do
    assert Environment.tick(@env1) == @env0

    1..(length(@glider_frames) - 2)
    |> Enum.each(fn index ->
      frame = Enum.at(@glider_frames, index)
      next_index = rem(index + 1, length(@glider_frames))
      next_frame = Enum.at(@glider_frames, next_index)

      # We do equals on the index as to make this easier to debug
      assert {index, Environment.tick(frame)} == {index, next_frame}
    end)
  end

  test "put_status/3 correctly updates a cell" do
    assert Environment.put_status(@env0, {0, 0}, 1) == @env1
    assert Environment.put_status(@env0, {0, 0}, 0) == @env0

    assert @glider_frames
           |> Enum.at(0)
           |> Environment.put_status({0, 2}, 0)
           |> Environment.put_status({2, 1}, 0)
           |> Environment.put_status({1, 1}, 1)
           |> Environment.put_status({3, 2}, 1) == Enum.at(@glider_frames, 1)
  end

  test "neighbor_count/2 returns the correct count" do
    frame = Enum.at(@glider_frames, 0)

    assert Environment.neighbor_count(frame, {0, 2}) == 1
    assert Environment.neighbor_count(frame, {1, 3}) == 3
    assert Environment.neighbor_count(frame, {2, 1}) == 1
    assert Environment.neighbor_count(frame, {2, 2}) == 3
    assert Environment.neighbor_count(frame, {2, 3}) == 2

    frame = Enum.at(@glider_frames, 1)

    assert Environment.neighbor_count(frame, {1, 1}) == 1
    assert Environment.neighbor_count(frame, {1, 3}) == 2
    assert Environment.neighbor_count(frame, {2, 2}) == 4
    assert Environment.neighbor_count(frame, {2, 3}) == 3
    assert Environment.neighbor_count(frame, {3, 2}) == 2
  end
end
