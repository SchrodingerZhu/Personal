defmodule Personal.Application do
  @moduledoc false

  use Application

  def start(_type, _args) do
    config = %{}
    cleartext_options = [port: port(), cleartext: true]

    secure_options = [
      port: secure_port(),
      cleartext: false,
      certfile: certificate_path(),
      keyfile: certificate_key_path()
    ]

    children = [
      Supervisor.child_spec({Personal.WWW, [config, cleartext_options]}, id: :www_cleartext),
      Supervisor.child_spec({Personal.WWW, [config, secure_options]}, id: :www_secure),
      Supervisor.child_spec({Personal.CacheAgent, []}, id: :cache_agent),
      Supervisor.child_spec({Personal.SessionAgent, []}, id: :session_agent)
    ]

    {pri, pub} = Kcl.generate_key_pair()
    System.put_env("auth_public", pub |> Base.encode64())
    System.put_env("auth_private", pri |> Base.encode64())

    opts = [strategy: :one_for_one, name: Personal.Supervisor]
    Supervisor.start_link(children, opts)
    receive do
      
    end
  end

  defp port() do
    with raw when is_binary(raw) <- System.get_env("PORT"), {port, ""} = Integer.parse(raw) do
      port
    else
      _ -> 8080
    end
  end

  defp secure_port() do
    with raw when is_binary(raw) <- System.get_env("SECURE_PORT"),
         {secure_port, ""} = Integer.parse(raw) do
      secure_port
    else
      _ -> 8443
    end
  end

  defp certificate_path() do
    Application.app_dir(:personal, "priv/localhost/certificate.pem")
  end

  defp certificate_key_path() do
    Application.app_dir(:personal, "priv/localhost/certificate_key.pem")
  end
end
