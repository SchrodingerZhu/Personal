defmodule Personal.User do
  use Memento.Table,
    attributes: [:id, :name, :password_hash, :email],
    index: [:name, :email],
    type: :ordered_set,
    autoincrement: true

  def new(name, password, email, input_type \\ :raw) do
    cond do
      !Regex.match?(~r/^[a-zA-Z0-9_-]+@[a-zA-Z0-9_-]+(.[a-zA-Z0-9_-]+)+$/, email) ->
        :invalid_email

      input_type == :raw ->
        hashed = Argon2.Base.hash_password(Personal.KeyService.raw_sha3(password), Argon2.gen_salt, [t_cost: 4, m_cost: 12])
        %Personal.User{name: name, password_hash: hashed, email: email}

      input_type == :sha3 ->
        hashed = Argon2.Base.hash_password(password, Argon2.gen_salt, [t_cost: 4, m_cost: 12])
        %Personal.User{name: name, password_hash: hashed, email: email}
    end
  end

  def add(user) do
    if !has_email?(user.email) and !has_user?(user.name) do
      case Personal.Database.insert(user) do
        {:ok, _} ->
          :ok

        info ->
          IO.puts(:stderr, "failed to add user")
          {:error, info}
      end
    else
      IO.puts(:stderr, "failed to add user, already exists")
      :error
    end
  end

  def has_user?(name) do
    case Personal.Database.find(Personal.User, {:==, :name, name}) do
      [] -> false
      _ -> true
    end
  end

  def has_email?(email) do
    case Personal.Database.find(Personal.User, {:==, :email, email}) do
      [] -> false
      _ -> true
    end
  end

  def check_hash(name, password) do
    case Personal.Database.find(Personal.User, {:==, :name, name}) do
      [user] ->
        case Argon2.check_pass(user, password) do
          {:ok, _} -> true
          _ -> false
        end

      _ ->
        false
    end
  end

  def get_hash(name) do
    case Personal.Database.find(Personal.User, {:==, :name, name}) do
      [user] ->
        user.password_hash

      _ ->
        nil
    end
  end

  def request_login?(request) do
    temp = Raxx.get_header(request, "cookie")

    cookies =
      if temp == nil do
        false
      else
        Cookie.parse(temp)
      end

    uuid = cookies["personal.uuid"]
    uuid != nil and Personal.SessionAgent.check(uuid) and Personal.SessionAgent.check_login(uuid)
  end
end
