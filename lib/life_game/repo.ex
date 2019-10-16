defmodule LifeGame.Repo do
  use Ecto.Repo,
    otp_app: :life_game,
    adapter: Ecto.Adapters.Postgres
end
