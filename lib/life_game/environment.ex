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

  defguardp is_cell(cell)
            when is_tuple(cell) and
                   cell |> elem(0) |> is_integer() and
                   cell |> elem(1) |> is_integer()

  defguardp is_status(status) when status in [@alive, @dead]

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
  def tick(seed) do
    Enum.reduce(seed, seed, fn {{cell, status}, environment} ->
      # TODO: start here
      environment
    end)
  end

  def get_status(%Environment{cells: cells}, cell) when is_cell(cell) do
    Map.get(cells, cell, @dead)
  end

  def put_status(%Environment{cells: cells} = environment, cell, status)
      when is_cell(cell) and is_status(status) do
    %{environment | cells: Map.put(cells, cell, status)}
  end
end

defimpl Inspect, for: LifeGame.Environment do
  import Inspect.Algebra
  alias LifeGame.Environment

  def inspect(%Environment{width: width} = environment, opts) do
    environment
    |> Enum.map(fn {_cell, status} -> to_doc(status, opts) end)
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
    cas = cell_and_status(environment, index)
    reduce({environment, index + 1}, fun.(cas, acc), fun)
  end

  def slice(%Environment{height: height, width: width} = environment) do
    slicer = fn start, length ->
      for index <- start..(start + length - 1) do
        cell_and_status(environment, index)
      end
    end

    {:ok, height * width, slicer}
  end

  defp cell_and_status(%Environment{height: height, width: width} = environment, index) do
    cell = {rem(index, width), div(index, height)}
    status = Environment.get_status(environment, cell)
    {cell, status}
  end
end
