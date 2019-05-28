defmodule Personal.WWW.Router do
    use Raxx.Router
    section([{Raxx.Logger, Raxx.Logger.setup(level: :info)}], [
        {%{path: []}, Personal.WWW.HomePage},
        {%{method: :GET, path: ["pages", _url]}, Personal.WWW.Pages},
        {%{method: :POST, path: ["pastebin-api"]}, Personal.WWW.PastebinApi},
        {%{method: :GET, path: ["pastebin", _url]}, Personal.WWW.Pastebin},
        {%{method: :POST, path: ["auth", "handshake"]}, Personal.WWW.AuthHandshake},
        {%{method: :GET, path: ["auth"]}, Personal.WWW.Auth},
        {%{method: :GET, path: ["paste", "new"]}, Personal.WWW.PasteEditor},
        {%{method: :POST, path: ["paste", "api"]}, Personal.WWW.PasteEditor},
        {_, Personal.WWW.NotFoundPage}
      ])
  end
  