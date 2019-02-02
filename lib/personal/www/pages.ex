defmodule Personal.WWW.Pages do
  use Raxx.SimpleServer
  use Personal.WWW.Layout, arguments: [:page]

  @impl Raxx.SimpleServer
  def handle_request(request = %{method: :GET}, _state) do
    [_, subpath] = Map.get(request,:path)
    if Personal.CacheAgent.Url.has?(subpath) do
      res = response(:ok)
      page_id  = Personal.CacheAgent.Url.get(subpath)
      page = Personal.CacheAgent.Page.get(page_id)
      render(res, page)
    else
      Personal.WWW.NotFoundPage.handle_request(request, 404)
    end
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
