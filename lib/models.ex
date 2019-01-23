defmodule Personal.Page do
  use Memento.Table,
    attributes: [:id, :title, :content, :status, :is_markdown, :url],
    index: [:title],
    type: :ordered_set,
    autoincrement: true

  def new(title, content, status, is_markdown, url) do
    %Personal.Page{title: title, content: content, status: status, is_markdown: is_markdown, url: url}
  end

  def add(page) do
    if Personal.CacheAgent.Url.has?(page.url) do
      :url_collision
    else
      case Personal.Database.insert(page) do
        {:ok, _} -> :ok
        info -> {:insertion_error, info}
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
