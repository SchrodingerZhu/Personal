defmodule Personal.WWW.AUth do
  use Raxx.SimpleServer
  @impl Raxx.SimpleServer
  # def handle_request(request = %{method: :GET}, _state) do
  #   # [_, subpath] = Map.get(request,:path)
  #   # if Personal.CacheAgent.Url.has?(subpath) do
  #   #   res = response(:ok)
  #   #   page_id  = Personal.CacheAgent.Url.get(subpath)
  #   #   page = Personal.CacheAgent.Page.get(page_id)
  #   #   json(res, page)
  #   # else
  #   #   Personal.WWW.NotFoundPage.handle_request(request, 404)
  #   # end
  # end

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
