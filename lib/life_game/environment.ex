defmodule LifeGame.Environment do
  @moduledoc """
  `LifeGame.Environment` represents and environment or grid of cells in a game of life.
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
  Creates and returns a new `LifeGame.Environment` with the given width and height.
  """
  @spec new(non_neg_integer(), non_neg_integer(), list(cell()) | nil) :: Environment.t()
  def new(height, width, cells \\ []) do
    new_cells = Enum.reduce(cells, %{}, &Map.put(&2, &1, @alive))
    %Environment{cells: new_cells, height: height, width: width}
  end

  @doc """
  Evaluates the given `LifeGame.Environment` and returns the next iteration. It uses the rules
  at https://en.wikipedia.org/wiki/Conway%27s_Game_of_Life#Rules.
  """
  @spec tick(Environment.t()) :: Environment.t()
  def tick(%Environment{} = seed) do
    Enum.reduce(seed, seed, fn {cell, status}, environment ->
      case {status, neighbor_count(seed, cell)} do
        {@alive, count} when count < 2 -> put_status(environment, cell, @dead)
        {@alive, count} when count > 3 -> put_status(environment, cell, @dead)
        {@dead, count} when count == 3 -> put_status(environment, cell, @alive)
        {_status, _count} -> environment
      end
    end)
  end

  @doc """
  Returns the status for the given cell. Note: if a cell that is not valid for the given
  `LifeGame.Environment` is passed, this function will return `@dead`.
  """
  def get_status(%Environment{cells: cells}, cell) when is_cell(cell) do
    Map.get(cells, cell, @dead)
  end

  @doc """
  Updates the given cell with to the given status. If the cell is not in the `LifeGame.Environment`
  no update is made.
  """
  @spec put_status(Environment.t(), cell(), status()) :: Environment.t()
  def put_status(
        %Environment{height: height, width: width} = environment,
        {x, y} = cell,
        status
      )
      when is_status(status) and is_cell(cell) and (x < 0 or x >= width or y < 0 or y >= height) do
    environment
  end

  def put_status(
        %Environment{cells: cells} = environment,
        cell,
        status
      )
      when is_status(status) and is_cell(cell) do
    new_cells =
      case status do
        @dead -> Map.delete(cells, cell)
        @alive -> Map.put(cells, cell, @alive)
      end

    %{environment | cells: new_cells}
  end

  @doc """
  Returns the number of `@alive` neighbors the given cell has.
  """
  def neighbor_count(%Environment{} = environment, {x, y} = cell) when is_cell(cell) do
    [
      {x - 1, y},
      {x + 1, y},
      {x, y - 1},
      {x, y + 1},
      {x + 1, y + 1},
      {x + 1, y - 1},
      {x - 1, y + 1},
      {x - 1, y - 1}
    ]
    |> Enum.map(&get_status(environment, &1))
    |> Enum.sum()
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

  # Helper function to return the cell coordiantes and their status as a tuple
  defp cell_and_status(%Environment{height: height, width: width} = environment, index) do
    cell = {rem(index, width), div(index, height)}
    status = Environment.get_status(environment, cell)
    {cell, status}
  end
end
