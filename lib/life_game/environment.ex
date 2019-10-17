defmodule LifeGame.Environment do
  @moduledoc """
  Environment represents and environment or grid of cells in a game of life.
  """
  defstruct cells: %{}, height: 0, width: 0

  alias __MODULE__

  @alive 1
  @dead 0

  @type t() :: %Environment{width: non_neg_integer(), height: non_neg_integer(), cells: map()}
  @type cell() :: {non_neg_integer(), non_neg_integer()}
  @type status() :: 1 | 0

  @doc """
  Creates and returns a new Environment with the given width and height.
  """
  @spec new(non_neg_integer(), non_neg_integer()) :: Environment.t()
  def new(width, height) do
    %Environment{width: width, height: height}
  end

  @doc """
  Evaluates the given `Environment` and returns the next iteration.
  """
  @spec tick(Environment.t()) :: Environment.t()
  def tick(seed)

  def tick(seed) do
    seed
  end

  def status_at(%Environment{cells: cells}, cell), do: Map.get(cells, cell, @dead)
end

defimpl Inspect, for: LifeGame.Environment do
  import Inspect.Algebra
  alias LifeGame.Environment

  def inspect(%Environment{width: width} = environment, opts) do
    environment
    |> Enum.map(&to_doc(&1, opts))
    |> Enum.chunk_every(width)
    |> Enum.intersperse(["\n"])
    |> Enum.concat()
    |> concat()
  end
end

defimpl Enumerable, for: LifeGame.Environment do
  alias LifeGame.Environment

  def count(%Environment{height: height, width: width}), do: {:ok, height * width}

  def member?(%Environment{height: height, width: width}, {x, y})
      when is_integer(x) and is_integer(y) do
    {:ok, x >= 0 and x < width and y >= 0 and y < height}
  end

  def member?(_environment, _cell), do: {:ok, false}

  # If this is the initial call, we need to keep track of our position
  def reduce(%Environment{} = environment, acc, fun) do
    reduce({environment, 0}, acc, fun)
  end

  # Always respect halt
  def reduce({%Environment{}, _index}, {:halt, acc}, _fun), do: {:halted, acc}

  # Always respect suspend
  def reduce({%Environment{}, _index} = position, {:suspend, acc}, fun) do
    {:suspended, acc, &reduce(position, &1, fun)}
  end

  # We're done when the index gets to height * width(past the last cell)
  def reduce({%Environment{height: height, width: width}, index}, {:cont, acc}, _fun)
      when height * width == index do
    {:done, acc}
  end

  # The actual reducer. Gets the cell and the status, then passes status to fun
  def reduce({environment, index}, {:cont, acc}, fun) do
    cell = build_cell(environment, index)
    status = Environment.status_at(environment, cell)
    reduce({environment, index + 1}, fun.(status, acc), fun)
  end

  def slice(%Environment{height: height, width: width} = environment) do
    slicer = fn start, length ->
      for index <- start..(start + length - 1) do
        cell = build_cell(environment, index)
        Environment.status_at(environment, cell)
      end
    end

    {:ok, height * width, slicer}
  end

  defp build_cell(%Environment{height: height, width: width}, index) do
    {rem(index, width), div(index, height)}
  end
end
