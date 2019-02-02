defmodule Personal.WWW.PastebinApi do
  use Raxx.SimpleServer

  @impl Raxx.SimpleServer
  def handle_request(request = %{method: :POST}, _state) do
  end



  # def handle_request(request = %{method: :POST}, _state) do
  #   case URI.decode_query(request.body) do
  #     %{"name" => name} ->
  #       greeting = "Hello, #{name}!"

  #       response(:ok)
  #       |> render(greeting)

  #     _ ->
  #       response(:bad_request)
  #       |> render("Bad Request")
  #   end
  # end
end
