defmodule Personal.Utils.RbTree do
  defstruct root: :empty, size: 0
  @type t() :: %Personal.Utils.RbTree{root: Personal.Utils.RbTree.Node.tree(), size: integer}

  @spec is_empty?(t()) :: boolean
  def is_empty?(tree), do: Personal.Utils.RbTree.Node.is_empty?(tree.root)

  @spec size(t()) :: integer
  def size(tree), do: tree.size

  @spec insert(t(), any()) :: t()
  def insert(tree, x), do: %Personal.Utils.RbTree{root: Personal.Utils.RbTree.Node.insert(tree.root, x), size: tree.size + 1}

  @spec delete(t(), any()) :: t()
  def delete(tree, x), do: %Personal.Utils.RbTree{root: Personal.Utils.RbTree.Node.delete(tree.root, x), size: tree.size - 1}

  @spec min(t()) :: any()
  def min(tree), do: Personal.Utils.RbTree.Node.min(tree.root)

  @spec from_list(list()) :: t()
  def from_list(l) do
    %Personal.Utils.RbTree{root: Personal.Utils.RbTree.Node.from_list(l), size: Enum.count(l)}
  end

  @spec to_list(t()) :: list()
  def to_list(tree) do
    Personal.Utils.RbTree.Node.to_list(tree.root)
  end

  @spec new() :: t()
  def new(), do: __struct__()
end

defimpl Inspect, for: Personal.Utils.RbTree  do
  def inspect(tree, _opt) do
    "#RbTree<" <> Kernel.inspect(Personal.Utils.RbTree.to_list(tree)) <> ">"
  end
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
      true -> balance({color, l, k, make_insert(r, x)})
    end
  end

  @spec make_black_insert(tree()) :: tree()
  defp make_black_insert({:node, _, l, k, r}), do: {:node, :black, l, k, r}

  @spec make_black(tree()) :: tree()
  defp make_black({:node, :black, l, k, r}), do: {:node, :double_black, l, k, r}
  defp make_black({:node, _, l, k, r}), do: {:node, :black, l, k, r}
  defp make_black(:empty) do
    :bbempty
  end
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

  defp del(:empty, _), do: :empty

  defp del({:node, color, l, k, r}, x) do
    cond do
      x < k ->
        fix({color, del(l, x), k, r})

      x > k ->
        fix({color, l, k, del(r, x)})

      is_empty?(l) ->
        if color == :black do
          make_black(r)
        else
          r
        end

      is_empty?(r) ->
        if color == :black do
          make_black(l)
        else
          l
        end

      true ->
        temp = min(r)
        fix({color, l, temp, del(r, temp)})
    end
  end

  defp blacken_root({:node, _, l, k, r}), do: {:node, :black, l, k, r}
  defp blacken_root(_), do: :empty

  @spec delete(tree(), any()) :: tree()
  def delete(t, x), do: blacken_root(del(t, x))

  @spec tree_type(any()) :: {color(), tree(), any(), tree()}
  # type_spec helper
  defp tree_type(state), do: state

  @spec fix({color(), tree(), any(), tree()}) :: tree()
  defp fix(state) do
    {color, l, k, r} = state

    case tree_type({color, l, k, r}) do
      {color, {:node, :double_black, _, _, _}, x, {:node, :black, {:node, :red, b, y, c}, z, d}} ->
        {:node, color, {:node, :black, make_black(l), x, b}, y, {:node, :black, c, z, d}}

      {color, :bbempty, x, {:node, :black, {:node, :red, b, y, c}, z, d}} ->
        {:node, color, {:node, :black, :empty, x, b}, y, {:node, :black, c, z, d}}

      {color, {:node, :double_black, _, _, _}, x, {:node, :black, b, y, {:node, :red, c, z, d}}} ->
        {:node, color, {:node, :black, make_black(l), x, b}, y, {:node, :black, c, z, d}}

      {color, :bbempty, x, {:node, :black, b, y, {:node, :red, c, z, d}}} ->
        {:node, color, {:node, :black, :empty, x, b}, y, {:node, :black, c, z, d}}

      {color, {:node, :black, a, x, {:node, :red, b, y, c}}, z, {:node, :double_black, _, _, _}} ->
        {:node, color, {:node, :black, a, x, b}, y, {:node, :black, c, z, make_black(r)}}

      {color, {:node, :black, a, x, {:node, :red, b, y, c}}, z, :bbempty} ->
        {:node, color, {:node, :black, a, x, b}, y, {:node, :black, c, z, :empty}}

      {color, {:node, :black, {:node, :red, a, x, b}, y, c}, z, {:node, :double_black, _, _, _}} ->
        {:node, color, {:node, :black, a, x, b}, y, {:node, :black, c, z, make_black(r)}}

      {color, {:node, :black, {:node, :red, a, x, b}, y, c}, z, :bbempty} ->
        {:node, color, {:node, :black, a, x, b}, y, {:node, :black, c, z, :empty}}

      {:black, {:node, :double_black, _, _, _}, x, {:node, :red, b, y, c}} ->
        fix({:black, fix({:red, l, x, b}), y, c})

      {:black, :bbempty, x, {:node, :red, b, y, c}} ->
        fix({:black, fix({:red, l, x, b}), y, c})

      {:black, {:node, :red, a, x, b}, y, {:node, :double_black, _, _, _}} ->
        fix({:black, a, x, fix({:red, b, y, r})})

      {:black, {:node, :red, a, x, b}, y, :bbempty} ->
        fix({:black, a, x, fix({:red, b, y, r})})

      {color, {:node, :double_black, _, _, _}, x, {:node, :black, b, y, c}} ->
        make_black({:node, color, make_black(l), x, {:node, :red, b, y, c}})

      {color, :bbempty, x, {:node, :black, b, y, c}} ->
        make_black({:node, color, :empty, x, {:node, :red, b, y, c}})

      {color, {:node, :black, a, x, b}, y, {:node, :double_black, _, _, _}} ->
        make_black({:node, color, {:node, :red, a, x, b}, y, make_black(r)})

      {color, {:node, :black, a, x, b}, y, :bbempty} ->
        make_black({:node, color, {:node, :red, a, x, b}, y, :empty})

      _ ->
        {:node, color, l, k, r}
    end
  end

  @spec from_list(list()) :: tree()
  def from_list(l) do
    List.foldl(l, :empty, fn (x, y) -> insert(y, x) end)
  end

  @spec to_list(tree()) :: list()
  def to_list(:empty), do: []
  def to_list({:node, _, l, x, r}), do: to_list(l) ++ [x] ++ to_list(r)

end
