defmodule Personal.Page do
  use Memento.Table,
    attributes: [:id, :title, :content, :status, :is_markdown, :url],
    index: [:title],
    type: :ordered_set,
    autoincrement: true

  def new(title, content, status, is_markdown, url) do
    %Personal.Page{
      title: title,
      content: content,
      status: status,
      is_markdown: is_markdown,
      url: url
    }
  end

  def add(page) do
    if Personal.CacheAgent.Url.has?(page.url) do
      :url_collision
    else
      case Personal.Database.insert(page) do
        {:ok, res} ->
          Personal.CacheAgent.Url.put_new(res.url, res.id)
          :ok

        info ->
          {:insertion_error, info}
      end
    end
  end
end

defmodule Personal.Message do
  use Memento.Table,
    attributes: [:id, :title, :content, :page, :status, :email, :author, :date],
    index: [:title],
    type: :ordered_set,
    autoincrement: true

  def new(title, content, page, status, email, author) do
    if Regex.match?(~r/^[a-zA-Z0-9_-]+@[a-zA-Z0-9_-]+(.[a-zA-Z0-9_-]+)+$/, email) do
      %Personal.Message{
        title: title,
        content: content,
        status: status,
        email: email,
        page: page,
        author: author,
        date: Time.utc_now()
      }
    else
      IO.puts(:stderr, "wrong email!")
      :wrong_email
    end
  end
end

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
        hashed = Comeonin.Argon2.add_hash(Personal.KeyService.raw_md5(password))
        %Personal.User{name: name, password_hash: hashed.password_hash, email: email}

      input_type == :md5 ->
        hashed = Comeonin.Argon2.add_hash(password)
        %Personal.User{name: name, password_hash: hashed.password_hash, email: email}
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
        case Comeonin.Argon2.check_pass(user, password) do
          {:ok, _} -> true
          _ -> false
        end

      _ ->
        false
    end
  end
end
