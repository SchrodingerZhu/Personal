defmodule Personal.WWW.NotFoundPage do
  use Raxx.SimpleServer
  use Personal.WWW.Layout, arguments: []

  @impl Raxx.SimpleServer
  def handle_request(_request, _state) do
    response(:not_found)
    |> render()
  end
end
