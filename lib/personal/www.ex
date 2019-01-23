defmodule Personal.WWW do
  use Ace.HTTP.Service, port: 8080, cleartext: true
  use Raxx.Router

  section([], [
    {%{ path: []}, Personal.WWW.HomePage},
    {%{method: :GET, path: ["pages", _url]}, Personal.WWW.Pages},
    {%{path: ["api", "auth"]}, Personal.WWW.Auth},
    {_, Personal.WWW.NotFoundPage}
  ])

  @external_resource "lib/personal/public/main.css"
  @external_resource "lib/personal/public/main.js"
  use Raxx.Static, "./public"
  use Raxx.Logger, level: :info
end
