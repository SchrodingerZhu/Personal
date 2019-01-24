defmodule Personal.WWW.Auth do
  use Raxx.SimpleServer
  @impl Raxx.SimpleServer
  def handle_request(request = %{method: :GET, }, _) do
    cookie = Raxx.Session.SignedCookie.config(
      nonce: UUID.uuid4 |> to_charlist |> Enum.take(12) |> to_string,
      secret: UUID.uuid4 |> to_charlist |> Enum.take(32) |> to_string
    )
    x = response(:ok)
    |> Raxx.Session.SignedCookie.embed({:user, 25}, cookie)
    |> set_header("content-type", "application/json")
    x
  end

  def handle_request(request = %{method: :POST}, _state) do
    case URI.decode_query(request.body) do
    %{"type" => "auth", "name" => name, "password" => password} ->
        if Personal.User.check_hash(name, password) do
          response(:ok)
        else
          response(:error)
        end

    #     response(:ok)
    #     |> render(greeting)

    #   _ ->
    #     response(:bad_request)
    #     |> render("Bad Request")
    end
  end
end
