defmodule BattleSnakeServer.GameChannel do
  alias BattleSnake.{
    Snake,
    World,
  }
  alias BattleSnakeServer.{
    Game,
  }
  use BattleSnakeServer.Web, :channel

  def join("game:" <> game_id, payload, socket) do
    if authorized?(payload) do
      {:ok, socket}
    else
      {:error, %{reason: "unauthorized"}}
    end
  end

  # Channels can be used in a request/response fashion
  # by sending replies to requests from the client
  def handle_in("start", payload, socket) do
    "game:" <> id = socket.topic
    game = Game.get(id)

    spawn fn ->
      # HTTPoison.start

      world = game.world
      # |> World.init_food(4)
      # |> World.update_board

      draw = fn (socket) ->
        fn (world) ->
          html = Phoenix.View.render_to_string(
            BattleSnakeServer.PlayView,
            "board.html",
            world: world,
          )
          broadcast socket, "tick", %{html: html}
        end
      end

      # tick(world, world, draw.(socket))
    end

    {:reply, {:ok, payload}, socket}
  end

  def tick(%{"snakes" => []} = world, previous, draw) do
    # print previous
    # IO.puts "Game Over"
    :ok
  end

  def tick(world, previous, draw) do
    Process.sleep 50

    spawn_link fn ->
      draw.(world)
    end

    world
    |> update_in(["turn"], & &1 + 1)
    |> make_move
    |> World.step
    |> World.add_new_food
    |> World.update_board
    |> tick(world, draw)
  end

  def make_move world do
    moves = for snake <- world["snakes"] do
      name = snake["name"]
      # url = snake["url"]
      # body = "{}"
      # HTTPoison.post!(url, body)
      {name, "up"}
    end

    moves = Enum.into moves, %{}

    World.apply_moves(world, moves)
  end

  # It is also common to receive messages from the client and
  # broadcast to everyone in the current topic (game:lobby).
  def handle_in("tick", payload, socket) do
    broadcast socket, "tick", payload
    {:noreply, socket}
  end

  # Add authorization logic here as required.
  defp authorized?(_payload) do
    true
  end
end