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
