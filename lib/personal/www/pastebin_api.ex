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
    IO.inspect(content)

    cond do
      content["name"] == nil or !Personal.CacheAgent.Pastebin.has_url?(content["name"]) ->
        response(:bad_request)

      !Personal.CacheAgent.Pastebin.is_open?(content["name"]) and
          (uuid == nil or !Personal.SessionAgent.check_login(uuid)) ->
        response(:unauthorized)
        |> Raxx.set_header("content-type", "application/json")
        |> Raxx.set_body(Jason.encode!(%{error: "please login first"}))

      true ->
        case content do
          %{"request" => "get_box", "name" => _name, "id" => id} ->
            {box, nonce} =
              Personal.KeyService.seal_box(
                Personal.CacheAgent.Pastebin.get_cache(id).content,
                uuid
              )

            response(:ok)
            |> Raxx.set_header(
              "set-cookie",
              SetCookie.serialize("personal.nonce", nonce, http_only: false)
            )
            |> Raxx.set_header(
              "content-type",
              "application/json"
            )
            |> Raxx.set_body(Jason.encode!(%{box: Base.encode64(box)}))

          %{"request" => "open_submit", "id" => id, "name" => _name, "new_content" => new_content} ->
            new_paste =
              id
              |> Personal.CacheAgent.Pastebin.get_cache()
              |> Map.update!(:content, fn _ -> new_content end)

            if new_paste.can_edit and new_paste.is_open do
              Personal.Pastebin.update(new_paste)
              response(:ok)
            else
              response(:bad_request)
            end

          %{
            "request" => "boxed_submit",
            "id" => id,
            "name" => _name,
            "boxed_new_content" => boxed_new_content
          } ->
            {new_content, nonce} = Personal.KeyService.open_box(Base.decode64!(boxed_new_content), uuid)

            new_paste =
              id
              |> Personal.CacheAgent.Pastebin.get_cache()
              |> Map.update!(:content, fn _ -> new_content end)

            if new_paste.can_edit and !new_paste.is_open do
              Personal.Pastebin.update(new_paste)

              response(:ok)
              |> Raxx.set_header(
                "set-cookie",
                SetCookie.serialize("personal.nonce", nonce, http_only: false)
              )
            else
              response(:bad_request)
              |> Raxx.set_header(
                "set-cookie",
                SetCookie.serialize("personal.nonce", nonce, http_only: false)
              )
            end
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
