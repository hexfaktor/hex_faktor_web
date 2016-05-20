defmodule HexFaktor.Persistence.Notification do
  import Ecto.Query, only: [from: 2]

  alias HexFaktor.Repo
  alias HexFaktor.Notification

  def all_unseen_for(user, preload_list \\ []) do
    query = from r in Notification,
            where: r.user_id == ^user.id and is_nil(r.seen_at),
            select: r,
            preload: ^preload_list
    Repo.all(query)
  end

  def latest_for(user, limit, preload_list \\ []) do
    query = from r in Notification,
            where: r.user_id == ^user.id,
            order_by: [desc: :id],
            select: r,
            preload: ^preload_list,
            limit: ^limit
    Repo.all(query)
  end

  def all_unseen_for_branch(git_branch_id, preload_list \\ []) do
    query = from r in Notification,
            where: r.git_branch_id == ^git_branch_id and is_nil(r.seen_at),
            select: r,
            preload: ^preload_list
    Repo.all(query)
  end

  def mark_as_seen_for_user!(user) do
    query = from r in Notification,
            where: r.user_id == ^user.id and is_nil(r.seen_at)
    Repo.update_all(query, set: [seen_at: now])
  end

  def mark_as_seen_for_branch!(user, project_id, git_branch_id) do
    query = from r in Notification,
            where: r.user_id == ^user.id and r.project_id == ^project_id and
                    r.git_branch_id == ^git_branch_id and is_nil(r.seen_at)
    Repo.update_all(query, set: [seen_at: now])
  end

  def mark_as_email_sent_for_user!(user) do
    query = from r in Notification,
            where: r.user_id == ^user.id and is_nil(r.email_sent_at)
    Repo.update_all(query, set: [email_sent_at: now])
  end

  def mark_as_resolved_by_build_job!(ids, job_id) do
    query = from r in Notification,
            where: r.id in ^ids
    Repo.update_all(query, set: [seen_at: now, resolved_by_build_job_id: job_id])
  end

  def count_unseen_for(user_id) when is_integer(user_id) do
    query = from r in Notification,
            where: r.user_id == ^user_id and is_nil(r.seen_at),
            group_by: r.project_id,
            select: r.project_id
    query
    |> Repo.all
    |> Enum.count
  end
  def count_unseen_for(nil), do: nil
  def count_unseen_for(user), do: count_unseen_for(user.id)

  def find(id, preload_list \\ []) when is_list(preload_list) do
    query = from r in Notification,
            select: r,
            where: r.id == ^id,
            preload: ^preload_list
    Repo.one(query)
  end

  def ensure_for_deps_object(user_id, deps_object, reason_hash) do
    case find_by_user_id_and_reason_hash(user_id, reason_hash) do
      nil -> add_for_deps_object(user_id, deps_object, reason_hash)
      _val -> nil
    end
  end

  defp find_by_user_id_and_reason_hash(user_id, reason_hash) when is_binary(reason_hash) do
    query = from r in Notification,
            where: r.user_id == ^user_id and r.reason_hash == ^reason_hash,
            select: r
    Repo.one(query)
  end

  def find_unseen_and_unsent_for(user_ids, preload_list \\ []) do
    query = from r in Notification,
            where: r.user_id in ^user_ids and is_nil(r.seen_at) and is_nil(r.email_sent_at),
            select: r,
            preload: ^preload_list
    Repo.all(query)
  end

  defp add_for_deps_object(user_id, deps_object, reason_hash) do
    attributes = build_for_deps_object(user_id, deps_object, reason_hash)
    %Notification{}
    |> Notification.changeset(attributes)
    |> Repo.insert!
  end

  def build_for_deps_object(user_id, deps_object, reason_hash) do
    %{
      user_id: user_id,
      project_id: deps_object.project_id,
      git_branch_id: deps_object.git_branch_id,
      deps_object_id: deps_object.id,
      reason: "dep",
      reason_hash: reason_hash
    }
  end

  defp now do
    :calendar.universal_time
  end
end
