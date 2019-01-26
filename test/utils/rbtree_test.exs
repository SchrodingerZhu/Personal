defmodule RbTreeTest do
  use ExUnit.Case

  def gen_data(max \\ 10_000, num \\ 10_100) do
    Enum.take_random(0..max, num)
  end

  test "rb_tree_basic_property" do
    data = gen_data()
    sorted_data = data |> Enum.sort()

    assert(
      sorted_data ==
        Personal.Utils.RbTree.from_list(data)
        |> Personal.Utils.RbTree.to_list()
    )
  end

  test "rb_tree_deletion" do
    data = gen_data() |> Enum.sort() |> Enum.uniq()
    rbtree = Personal.Utils.RbTree.from_list(data)
    to_delete = data |> Enum.take_random(1_000)
    x = Enum.reduce(to_delete, rbtree, fn x, tree -> Personal.Utils.RbTree.delete(tree, x) end)
    assert(x |> Personal.Utils.RbTree.to_list() == data -- to_delete)
  end
end
