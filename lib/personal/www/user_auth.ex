defmodule Personal.WWW.AuthHandshake do
  use Raxx.SimpleServer
  @impl Raxx.SimpleServer
  def handle_request(request = %{method: :POST}, _state) do
    # IO.inspect(Jason.decode!(request.body))
    temp = Raxx.get_header(request, "cookie")

    cookies =
      if temp == nil do
        %{}
      else
        Cookie.parse(temp)
      end

    case Jason.decode!(request.body) do
      %{"request" => "check"} ->
        session = Personal.SessionAgent.get(cookies["personal.uuid"])
        if session == nil do
          response(:bad_request)
        else
          argon2 = Personal.User.get_hash(session.username)
          response(:ok)
          |> Raxx.set_header("content-type", "application/json")
          |> Raxx.set_body(
            Jason.encode!(
              %{argon2: argon2}
            )
          )
        end

      %{"request" => "clear"} ->
        Personal.SessionAgent.drop(cookies["personal.uuid"])

        response(:ok)
        |> Raxx.set_header(
          "set-cookie",
          SetCookie.expire("personal.uuid")
        )
        |> Map.update!(
          :headers,
          fn x ->
            [
              {
                "set-cookie",
                SetCookie.expire(
                  "personal.server_pub",
                  http_only: false
                )
              }
              | x
            ]
          end
        )
        |> Map.update!(
          :headers,
          fn x ->
            [
              {
                "set-cookie",
                SetCookie.expire(
                  "personal.nonce",
                  http_only: false
                )
              }
              | x
            ]
          end
        )
        |> Raxx.set_header(
          "content-type",
          "application/json"
        )
        |> Raxx.set_body(Jason.encode!(%{logout: true}))

      %{"request" => "logout"} ->
        cond do
          !Personal.SessionAgent.check(cookies["personal.uuid"]) ->
            response(:bad_request)

          !Personal.SessionAgent.check_login(cookies["personal.uuid"]) ->
            response(:bad_request)

          true ->
            Personal.SessionAgent.drop(cookies["personal.uuid"])

            response(:ok)
            |> Raxx.set_header(
              "set-cookie",
              SetCookie.expire("personal.uuid")
            )
            |> Map.update!(
              :headers,
              fn x ->
                [
                  {
                    "set-cookie",
                    SetCookie.expire(
                      "personal.server_pub",
                      http_only: false
                    )
                  }
                  | x
                ]
              end
            )
            |> Map.update!(
              :headers,
              fn x ->
                [
                  {
                    "set-cookie",
                    SetCookie.expire(
                      "personal.nonce",
                      http_only: false
                    )
                  }
                  | x
                ]
              end
            )
            |> Raxx.set_header(
              "content-type",
              "application/json"
            )
            |> Raxx.set_body(Jason.encode!(%{logout: true}))
        end

      %{"request" => "login", "box" => box} ->
        cond do
          cookies["personal.uuid"] == nil ->
            response(:bad_request)

          !Personal.SessionAgent.check(cookies["personal.uuid"]) ->
            response(:bad_request)

          Personal.SessionAgent.check_login(cookies["personal.uuid"]) ->
            response(:bad_request)

          true ->
            {code, nonce} = Personal.KeyService.compare_boxedkey(box, cookies["personal.uuid"])

            if code do
              temp =
                Personal.SessionAgent.get(cookies["personal.uuid"])
                |> Personal.Session.update_login()
                |> Personal.Session.update_time()

              Personal.SessionAgent.update(cookies["personal.uuid"], temp)

              response(:ok)
              |> Raxx.set_header(
                "content-type",
                "application/json"
              )
              |> Raxx.set_header(
                "set-cookie",
                SetCookie.serialize(
                  "personal.nonce",
                  nonce,
                  http_only: false
                )
              )
              |> Raxx.set_body(Jason.encode!(%{login: true}))
            else
              response(:bad_request)
              |> Raxx.set_header(
                "set-cookie",
                SetCookie.serialize(
                  "personal.nonce",
                  nonce,
                  http_only: false
                )
              )
              |> Raxx.set_body(Jason.encode!(%{login: false}))
            end
        end

      %{"username" => username, "public_key" => public} ->
        cond do
          cookies["personal.uuid"] != nil and
              Personal.SessionAgent.check_login(cookies["personal.uuid"]) ->
            response(:bad_request)

          Personal.User.has_user?(username) ->
            id = Personal.KeyService.gen_uuid()
            nonce = Personal.KeyService.gen_nonce()

            session =
              Personal.Session.new(id, Base.decode64!(nonce), Base.decode64!(public), username)

            Personal.SessionAgent.put_new(session)

            x =
              response(:ok)
              |> Raxx.set_header(
                "content-type",
                "application/json"
              )
              |> Raxx.set_body(Jason.encode!(%{build_session: true}))
              |> Raxx.set_header(
                "set-cookie",
                SetCookie.serialize(
                  "personal.uuid",
                  id,
                  max_age: 1800
                )
              )
              |> Map.update!(
                :headers,
                fn x ->
                  [
                    {
                      "set-cookie",
                      SetCookie.serialize(
                        "personal.nonce",
                        nonce,
                        http_only: false,
                        max_age: 1800
                      )
                    }
                    | x
                  ]
                end
              )
              |> Map.update!(
                :headers,
                fn x ->
                  [
                    {
                      "set-cookie",
                      SetCookie.serialize(
                        "personal.server_pub",
                        System.get_env("auth_public"),
                        http_only: false,
                        max_age: 1800
                      )
                    }
                    | x
                  ]
                end
              )

            IO.inspect(x)
            x

          true ->
            response(:bad_request)
        end

      _ ->
        response(:bad_request)
    end
  end
end
