defmodule Personal.WWW.Auth do
  use Raxx.SimpleServer
  use Personal.WWW.AuthLayout, arguments: [:info]
  @impl Raxx.SimpleServer

  def handle_request(request = %{method: :GET}, _state) do
    temp = Raxx.get_header(request, "cookie")

    cookies =
      if temp == nil do
        %{}
      else
        Cookie.parse(temp)
      end
    uuid = cookies["personal.uuid"]
    response(:ok) |> render( uuid != nil and  Personal.SessionAgent.check(uuid))
  end

  def handle_request(request = %{method: :POST}, _state) do
    case URI.decode_query(request.body) do
      %{"name" => name} ->
        greeting = "Hello, #{name}!"

        response(:ok)
        |> render(greeting)

      _ ->
        response(:bad_request)
        |> render("Bad Request")
    end
  end
end
