defmodule Personal.WWW.AuthHandshake do
  use Raxx.SimpleServer
  @impl Raxx.SimpleServer
  def handle_request(request = %{method: :GET, }, _) do
    nonce = UUID.uuid4 |> to_charlist |> Enum.take(24) |> to_string
    secret = UUID.uuid4 |> to_charlist |> Enum.take(32) |> to_string
    start = {{2012, 9, 29}, {15, 32, 10}}
    response(:ok)
    |> Raxx.set_header(
      "set-cookie",
      SetCookie.serialize(
        "raxx.session",
        Base.encode64("nonce="<>nonce <> "***" <>"key=" <> secret),
        %{
          max_age: 60,
          universal_time: start,
          path: "/",
          http_only: false,
          host_only: false
        }
      )
    )
    |> Raxx.set_body(
      "{\"hi\": \"123\"}"
    )
  end

  def handle_request(request = %{method: :POST}, _state) do
    #IO.inspect(Jason.decode!(request.body))
    IO.inspect(Jason.decode!(request.body))
    case Jason.decode!(request.body) do
    %{"request" => "login", "id" => id, "box" => box} ->
        cond do
          !Personal.SessionAgent.check(id) ->
            response(:bad_request)

          Personal.SessionAgent.check_login(id) ->
            IO.puts("y")
            response(:bad_request)

          true ->
            {code, nonce} = Personal.KeyService.compare_boxedkey(box, id)
            if code do
              temp =
              Personal.SessionAgent.get(id)
              |> Personal.Session.update_login
              |> Personal.Session.update_time

              Personal.SessionAgent.update(id, temp)
            end
            response(:ok)
            |> Raxx.set_header(
              "content-type", "application/json"
            )
            |> Raxx.set_body(
              Jason.encode!(%{nonce: nonce})
            )
        end
    %{"username" => username, "public_key" => public} ->
        if Personal.User.has_user?(username) do
          id = Personal.KeyService.gen_uuid
          nonce =Personal.KeyService.gen_nonce()
          session = Personal.Session.new(id, Base.decode64!(nonce), Base.decode64!(public), username)
          Personal.SessionAgent.put_new(session)
          response(:ok)
          |> Raxx.set_header(
            "content-type", "application/json"
          )
          |> Raxx.set_body(
            Jason.encode!(%{nonce: nonce, id: id, public_key: System.get_env("auth_public")})
          )
        else
          response(:bad_request)
        end


    %{"request" => "new_nonce", "id" => id} ->
      if Personal.SessionAgent.check(id) do
        #nonce = Personal.KeyService.gen_nonce()
        session = Personal.SessionAgent.get(id)
        #Personal.SessionAgent.update(id, Personal.Session.update_nonce(session, nonce))
        response(:ok)
        |> Raxx.set_header(
            "content-type", "application/json"
          )
        |> Raxx.set_body(
          Jason.encode!(%{nonce: session.nonce |> Base.encode64()})
        )
      else
        response(:bad_request)
      end

    _ ->
      response(:bad_request)
    end
  end
end
