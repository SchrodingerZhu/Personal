defmodule Personal.Database do
  @moduledoc """
    Basic ultilities About Mnesia
  """

  @spec init() :: :ok | :error
  def init() do
    nodes = [node()]
    Memento.stop()
    Memento.Schema.create(nodes)
    Memento.start()

    case {
      Memento.Table.create(Personal.Page, disc_copies: nodes),
      Memento.Table.create(Personal.Message, disc_copies: nodes),
      Memento.Table.create(Personal.User, disc_copies: nodes)
    } do
      {:ok, :ok, :ok} ->
        IO.puts("tables are successfully created.")

      message ->
        IO.puts(:stderr, "failed to create tables, the return message is")

        IO.puts(
          :stderr,
          message |> Kernel.inspect()
        )

        :error
    end
  end

  def insert(record) do
    operation = fn ->
      Memento.Query.write(record)
    end

    Memento.Transaction.execute(operation, 5)
  end

  def remove_id(type, id) do
    operation = fn ->
      Memento.Query.delete(type, id)
    end

    Memento.Transaction.execute(operation, 5)
  end

  def remove(record) do
    operation = fn ->
      Memento.Query.delete_record(record)
    end

    Memento.Transaction.execute(operation, 5)
  end

  def all(type) do
    {:ok, result} =
      Memento.transaction(fn ->
        Memento.Query.all(type)
      end)

    result
  end

  def get(type, id) do
    {:ok, result} =
      Memento.transaction(fn ->
        Memento.Query.read(type, id)
      end)

    result
  end

  def find(type, opt) do
    {:ok, result} =
      Memento.transaction(fn ->
        Memento.Query.select(type, opt)
      end)

    result
  end
end
