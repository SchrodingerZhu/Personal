defmodule Personal.WWW.Pastebin do
  use Raxx.SimpleServer
  use Personal.WWW.PastebinLayout, arguments: [:state]

  @impl Raxx.SimpleServer
  def handle_request(request = %{method: :GET}, _state) do
    [_, subpath] = Map.get(request, :path)
    temp = Raxx.get_header(request, "cookie")

    cookies =
      if temp == nil do
        %{}
      else
        Cookie.parse(temp)
      end

    uuid = cookies["personal.uuid"]

    if not Personal.CacheAgent.Pastebin.has_url?(subpath) do
      Personal.WWW.NotFoundPage.handle_request(request, 404)
    else
      paste_id = Personal.CacheAgent.Pastebin.get_url(subpath)
      paste = Personal.CacheAgent.Pastebin.get_cache(paste_id)

      cond do
        paste.security_level == 0 ->
          response(:ok) |> render({:open, paste})

        uuid != nil and Personal.SessionAgent.check_login(uuid) ->
          response(:ok) |> render({:loged_in, paste})

        true ->
          response(:ok) |> render({:not_logedin})
      end
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
