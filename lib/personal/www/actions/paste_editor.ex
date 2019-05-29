defmodule Personal.WWW.PasteEditor do
  use Raxx.SimpleServer
  use Personal.WWW.EditorLayout, arguments: [:visit_type]

  @impl Raxx.SimpleServer
  def handle_request(request = %{method: :GET, path: [_, "new"]}, state) do
    if Personal.User.request_login?(request) do
      response(:ok)
      |> render(:new_paste)
    else
      Personal.WWW.NotFoundPage.handle_request(request, state)
    end
  end

  def handle_request(request = %{method: :POST, path: [_, "new"]}, state) do
    temp = Raxx.get_header(request, "cookie")

    cookies =
      if temp == nil do
        false
      else
        Cookie.parse(temp)
      end

    uuid = cookies["personal.uuid"]

    if Personal.User.request_login?(request) do
      {res, nonce} =
        request.body
        |> Base.decode64!()
        |> Personal.KeyService.open_box(uuid)

      {:ok, res} = Jason.decode(res)

      expire =
        if res["expire"] == 0 do
          :never
        else
          Time.add(Time.utc_now(), res["expire"], :minute)
        end

      password =
        if res["password"] == "" do
          nil
        else
          res["password"]
        end

      paste = Personal.Pastebin.new(res["title"], res["content"], expire, res["level"], res["editable"], password, res["language"])

      if res["title"] == "" or Personal.Pastebin.has_name?(res["title"]) do
        response(400)
        |> Raxx.set_header(
          "set-cookie",
          SetCookie.serialize(
            "personal.nonce",
            nonce,
            http_only: false
          )
        )
        |> Raxx.set_body("invalid title")
      else
        case Personal.Pastebin.add(paste) do
          :ok ->
            response(:ok)
            |> Raxx.set_header(
              "set-cookie",
              SetCookie.serialize(
                "personal.nonce",
                nonce,
                http_only: false
              )
            )
            |> Raxx.set_body("success")

          {:error, message} ->
            response(400)
            |> Raxx.set_header(
              "set-cookie",
              SetCookie.serialize(
                "personal.nonce",
                nonce,
                http_only: false
              )
            )
            |> Raxx.set_body(Kernel.inspect(message))
        end
      end
    else
      response(401)
    end
  end
end
