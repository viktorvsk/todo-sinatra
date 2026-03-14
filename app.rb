require 'sinatra'
require 'sqlite3'

configure do
  set :bind, '0.0.0.0'
  set :port, ENV.fetch('PORT', 3000).to_i
end

def db
  @db ||= begin
    db = SQLite3::Database.new('todos.db')
    db.results_as_hash = true
    db.execute(<<~SQL)
      CREATE TABLE IF NOT EXISTS todos (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        done INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL DEFAULT (datetime('now'))
      )
    SQL
    db
  end
end

get '/' do
  @todos = db.execute('SELECT * FROM todos ORDER BY id DESC')
  erb :index
end

post '/todos' do
  title = params[:title].to_s.strip
  redirect '/' if title.empty?
  db.execute('INSERT INTO todos (title) VALUES (?)', [title])
  redirect '/'
end

post '/todos/:id/toggle' do
  db.execute('UPDATE todos SET done = 1 - done WHERE id = ?', [params[:id].to_i])
  redirect '/'
end

post '/todos/:id/delete' do
  db.execute('DELETE FROM todos WHERE id = ?', [params[:id].to_i])
  redirect '/'
end

__END__

@@index
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Todo App</title>
  <style>
    *, *::before, *::after { box-sizing: border-box; margin: 0; padding: 0; }
    body {
      font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif;
      background: #f0f2f5;
      min-height: 100vh;
      display: flex;
      align-items: flex-start;
      justify-content: center;
      padding: 40px 16px;
    }
    .container { width: 100%; max-width: 520px; }
    h1 { font-size: 2rem; color: #1a1a2e; margin-bottom: 24px; }
    .add-form { display: flex; gap: 8px; margin-bottom: 20px; }
    .add-form input {
      flex: 1; padding: 12px 16px;
      border: 2px solid #e0e0e0; border-radius: 8px;
      font-size: 15px; outline: none; background: white;
    }
    .add-form input:focus { border-color: #4f46e5; }
    .add-form button {
      padding: 12px 20px; background: #4f46e5; color: white;
      border: none; border-radius: 8px; font-size: 15px;
      font-weight: 600; cursor: pointer; white-space: nowrap;
    }
    .add-form button:hover { background: #4338ca; }
    .todo-list { list-style: none; }
    .todo-item {
      display: flex; align-items: center; gap: 10px;
      background: white; padding: 14px 16px; margin-bottom: 8px;
      border-radius: 8px; box-shadow: 0 1px 3px rgba(0,0,0,0.08);
    }
    .todo-item.done { opacity: 0.6; }
    .todo-title { flex: 1; font-size: 15px; color: #1a1a2e; }
    .todo-item.done .todo-title { text-decoration: line-through; color: #999; }
    .btn { padding: 6px 12px; border: none; border-radius: 5px; font-size: 13px; font-weight: 500; cursor: pointer; }
    .btn-toggle { background: #e8f5e9; color: #2e7d32; }
    .btn-toggle:hover { background: #c8e6c9; }
    .todo-item.done .btn-toggle { background: #fff3e0; color: #e65100; }
    .btn-delete { background: #fce4ec; color: #c62828; }
    .btn-delete:hover { background: #f8bbd0; }
    .empty { text-align: center; color: #999; padding: 48px 0; font-size: 15px; }
    form { margin: 0; }
  </style>
</head>
<body>
  <div class="container">
    <h1>Todos</h1>
    <form class="add-form" method="post" action="/todos">
      <input type="text" name="title" placeholder="What needs to be done?" autofocus required maxlength="200">
      <button type="submit">Add</button>
    </form>
    <ul class="todo-list">
      <% if @todos.empty? %>
        <p class="empty">No todos yet. Add one above!</p>
      <% else %>
        <% @todos.each do |todo| %>
          <li class="todo-item<%= ' done' if todo['done'] == 1 %>">
            <span class="todo-title"><%= todo['title'] %></span>
            <form method="post" action="/todos/<%= todo['id'] %>/toggle">
              <button class="btn btn-toggle" type="submit">
                <%= todo['done'] == 1 ? 'Undo' : 'Done' %>
              </button>
            </form>
            <form method="post" action="/todos/<%= todo['id'] %>/delete">
              <button class="btn btn-delete" type="submit">Delete</button>
            </form>
          </li>
        <% end %>
      <% end %>
    </ul>
  </div>
</body>
</html>
