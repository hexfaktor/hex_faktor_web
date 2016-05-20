defmodule HexFaktor.Broadcast do
  @moduledoc """
  The Broadcast module is responsible for broadcasting messages to connected
  clients on the right channels.
  """

  alias HexFaktor.User

  def call(%User{id: id}, message, payload) do
    broadcast!("users:#{id}", message, payload)
  end

  @doc """
  Broadcasts a given `message` to the user with the given `user_id`.
  """
  def to_user(user_id, message, payload) do
    broadcast!("users:#{user_id}", message, payload)
  end

  @doc """
  Broadcasts a given `message` to everybody watching the project with
  the given `project_id`.
  """
  def to_project(project_id, message, payload) do
    broadcast!("projects:#{project_id}", message, payload)
  end

  defp broadcast!(room, message, payload) do
    HexFaktor.Endpoint.broadcast!(room, message, payload)
  end
end
