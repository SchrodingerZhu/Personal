defmodule Personal.KeyService do
  def gen_uuid() do
    UUID.uuid4()
  end

  def gen_nonce() do
    UUID.uuid4 |> Base.encode64 |> to_charlist() |> Enum.take(24) |> to_string()
  end
end
