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

  
    def handle_request(request = %{method: :POST, path: [_, "api"]}, state) do
      temp = Raxx.get_header(request, "cookie")

      cookies =
        if temp == nil do
          false
        else
          Cookie.parse(temp)
        end

      uuid = cookies["personal.uuid"]
      if Personal.User.request_login?(request) do
        
        {res, nonce} = request.body
          |> Base.decode64!()
          |> Personal.KeyService.open_box(uuid)
        {:ok, res} = Jason.decode(res)
        IO.inspect(res)
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
      else
        Personal.WWW.NotFoundPage.handle_request(request, state)
      end
    end
  end
  