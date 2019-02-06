defmodule Personal.WWW do
  @external_resource "lib/personal/www/public/main.css"
  @external_resource "lib/personal/www/public/auth.css"
  @external_resource "lib/personal/www/public/main.js"
  @external_resource "lib/personal/www/public/node_modules/argon2-browser/lib/argon2.js"
  @external_resource "lib/personal/www/public/auth.js"
  @external_resource "lib/personal/www/public/sodium.min.js"
  @external_resource "lib/personal/www/public/node_modules/blueimp-md5/js/md5.min.js"
  @external_resource "lib/personal/www/public/node_modules/jquery/dist/jquery.min.js"
  @external_resource "lib/personal/www/public/pastebin.js"
  def child_spec([config, server_options]) do
    {:ok, port} = Keyword.fetch(server_options, :port)

    %{
      id: {__MODULE__, port},
      start: {__MODULE__, :start_link, [config, server_options]},
      type: :supervisor
    }
  end
  options = [source: Path.join(__DIR__, "www/public")]

  @static_setup (if(Mix.env() == :dev) do
                   options
                 else
                   Raxx.Static.setup(options)
                 end)

  def start_link(config, server_options) do
    stack =
      Raxx.Stack.new(
        [
          {Raxx.Static, @static_setup}
        ],
        {__MODULE__.Router, config}
      )

    Ace.HTTP.Service.start_link(stack, server_options)
  end



end
