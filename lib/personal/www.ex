defmodule Personal.WWW do
  use Ace.HTTP.Service, port: 8080, cleartext: true
  use Raxx.Router

  section([], [
    {%{path: []}, Personal.WWW.HomePage},
    {%{method: :GET, path: ["pages", _url]}, Personal.WWW.Pages},
    {%{method: :POST, path: ["pastebin-api"]}, Personal.WWW.Pastebin},
    {%{method: :GET, path: ["pastebin", _url]}, Personal.WWW.Pastebin},
    {%{path: ["auth", "handshake"]}, Personal.WWW.AuthHandshake},
    {%{path: ["auth"]}, Personal.WWW.Auth},
    {_, Personal.WWW.NotFoundPage}
  ])

  @external_resource "lib/personal/public/main.css"
  @external_resource "lib/personal/public/auth.css"
  @external_resource "lib/personal/public/main.js"
  @external_resource "lib/personal/public/node_modules/argon2-browser/lib/argon2.js"
  @external_resource "lib/personal/public/auth.js"
  use Raxx.Static, "./public"
  use Raxx.Logger, level: :info
end
