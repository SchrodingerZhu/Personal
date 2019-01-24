defmodule Personal.Utils.RbTree do

end
defmodule Personal.Utils.RbTree.Node do

@type color() :: :red | :black | :double_black
@type rbnode() :: {:node, color(), tree(), any(), tree()}
@type empty() :: :empty
@type bbempty() :: :bbempty
@type tree() :: empty() | bbempty() | rbnode()

  # min element
  @spec min(tree()) :: any()
  def min(:empty), do: nil
  def min(:bbempty), do: nil
  def min({:node, _, :empty, x, _}), do: x
  def min({:node, _, l, _, _}), do: min(l)

  @spec is_empty?(tree()) :: boolean()
  def is_empty?(:empty), do: true
  def is_empty?(_), do: false

  @spec insert(tree(), any()) :: tree()
  def insert(t, x) do
    make_black_insert(make_insert(t, x))
  end

  @spec make_insert(tree(), any()) :: tree()
  defp make_insert(:empty, x), do: {:node, :red, :empty, x, :empty}
  defp make_insert({:node, color, l, k, r}, x) do
    cond do
      x < k -> balance({color, make_insert(l, x), k, r})
      true  -> balance({color, l, k, make_insert(r, x)})
    end
  end

  @spec make_black_insert(tree()) :: tree()
  defp make_black_insert({:node, _, l, k, r}), do: {:node, :black, l, k, r}

  @spec make_black(tree()) :: tree()
  defp make_black(:empty) do
    :bbempty
  end
  defp make_black({:node, :black, l, k, r}), do: {:node, :double_black, l, k, r}
  defp make_black({:node, _, l, k, r}), do: {:node, :black, l, k, r}
  defp make_black(t), do: t

  @spec balance({color(), tree(), any(), tree()}) :: tree()
  def balance({:black, {:node, :red, {:node, :red, a, x, b}, y, c}, z, d}),
    do: {:node, :red, {:node, :black, a, x, b}, y, {:node, :black, c, z, d}}
  def balance({:black, {:node, :red, a, x, {:node, :red, b, y, c}}, z, d}),
    do: {:node, :red, {:node, :black, a, x, b}, y, {:node, :black, c, z, d}}
  def balance({:black, a, x, {:node, :red, b, y, {:node, :red, c, z, d}}}),
    do: {:node, :red, {:node, :black, a, x, b}, y, {:node, :black, c, z, d}}
  def balance({:black, a, x, {:node, :red, {:node, :red, b, y, c}, z, d}}),
    do: {:node, :red, {:node, :black, a, x, b}, y, {:node, :black, c, z, d}}
  def balance({color, l, k, r}), do: {:node, color, l, k, r}



end
