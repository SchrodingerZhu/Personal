defmodule Personal.Session do
  defstruct cookie: nil, user: nil, last_active: nil
  def new(cookie, user) do
    %Personal.Session{cookie: cookie, user: user, last_active: Time.utc_now}
  end
  def update(session) do

  end
end
defmodule Personal.SessionAgent do

end
