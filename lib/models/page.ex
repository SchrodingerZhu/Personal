defmodule Personal.Page do
  use Memento.Table,
    attributes: [:id, :title, :content, :is_open, :is_markdown, :url],
    index: [:title],
    type: :ordered_set,
    autoincrement: true

  def new(title, content, is_open, is_markdown, url) do
    %Personal.Page{
      title: title,
      content: content,
      is_open: is_open,
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
