defmodule Personal.WWW.PastebinApi do
  use Raxx.SimpleServer

  @impl Raxx.SimpleServer
  def handle_request(request = %{method: :POST}, _state) do
    temp = Raxx.get_header(request, "cookie")

    cookies =
      if temp == nil do
        %{}
      else
        Cookie.parse(temp)
      end

    uuid = cookies["personal.uuid"]
    content = Jason.decode!(request.body)

    cond do
      content["name"] == nil or !Personal.CacheAgent.Pastebin.has_url?(content["name"]) ->
        response(:bad_request)

      !Personal.CacheAgent.Pastebin.is_open?(content["name"]) and
          (uuid == nil or !Personal.SessionAgent.check_login(uuid)) ->
        response(:unauthorized)
        |> Raxx.set_header("content-type", "application/json")
        |> Raxx.set_body(Jason.encode!(%{error: "please login first"}))

      true ->
        id = Personal.CacheAgent.Pastebin.get_url(content["name"])
        {box, nonce} = Personal.KeyService.seal_box(Personal.CacheAgent.Pastebin.get_cache(id).content, uuid)
        response(:ok)
        |> Raxx.set_header(
          "set-cookie",
          SetCookie.serialize("personal.nonce", nonce, http_only: false)
        )
        |> Raxx.set_header(
          "content-type", "application/json"
        )
        |> Raxx.set_body(
          Jason.encode!(%{box: Base.encode64(box)})
        )
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
