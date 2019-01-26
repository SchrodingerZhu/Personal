defmodule Personal.WWW.AuthHandshake do
  use Raxx.SimpleServer
  @impl Raxx.SimpleServer
  def handle_request(request = %{method: :GET, }, _) do
    nonce = UUID.uuid4 |> to_charlist |> Enum.take(24) |> to_string
    secret = UUID.uuid4 |> to_charlist |> Enum.take(32) |> to_string
    start = {{2012, 9, 29}, {15, 32, 10}}
    response(:ok)
    |> Raxx.set_header(
      "set-cookie",
      SetCookie.serialize(
        "raxx.session",
        Base.encode64("nonce="<>nonce <> "***" <>"key=" <> secret),
        %{
          max_age: 60,
          universal_time: start,
          path: "/",
          http_only: false,
          host_only: false
        }
      )
    )
    |> Raxx.set_body(
      "{\"hi\": \"123\"}"
    )
  end

  def handle_request(request = %{method: :POST}, _state) do
    case URI.decode_query(request.body) do
    %{"username" => username, "public_key" => public} ->
        id = UUID.uuid4 |> Base.encode64
        response(:ok)
        |> Raxx.set_header(
          "set_cookie",
          SetCookie.sertialize(
            "raxx.session",
            id
          )
        )

    %{"request" => "new_nonce", "id" => id} ->
      nonce = %{nonce: UUID.uuid4 |> Base.encode64 |> Enum.take(24)}
      response(:ok)
      |> Raxx.set_header(
        "content-type",
        "application/json"
      )
      |> Raxx.set_body(
        Jason.encode(nonce)
      )
    #     |> render(greeting)

    _ ->
      response(:bad_request)
    end
  end
end
