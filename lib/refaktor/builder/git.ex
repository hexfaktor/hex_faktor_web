defmodule Refaktor.Builder.Git do
  defmodule RepoInfo do
    defstruct url:       nil,
              branch:    nil,
              revision:  nil,
              revisions: nil,
              tag:       nil,
              dir:       nil
  end

  alias Refaktor.Docker

  @default_system_opts [stderr_to_stdout: true]
  @git_image "faktor-git"
  @job_mount_dir "/job"
  @code_dirname Application.get_env :hex_faktor, :code_dirname
  @code_clone_dir Path.join(@job_mount_dir, @code_dirname)
  @depth 1

  @doc """
  Clones a Git repo into the given `dir`.
  """
  def clone(repo_url, job_dir, opts \\ []) do
    File.mkdir_p(job_dir)

    volume_opts = ["-v", "#{job_dir}:#{@job_mount_dir}"]
    cmd = ["git"] ++ git_cmd_opts(repo_url, @code_clone_dir, opts)

    case Docker.run(@git_image, cmd, volume_opts) do
      {:ok, _} ->
        {:ok, info(repo_url, Path.join(job_dir, @code_dirname))}
      val ->
        val
    end
  end

  defp git_cmd_opts(repo_url, dir, opts) do
    cmd_opts = ["clone", repo_url, dir, "--depth=#{@depth}"]
    if opts[:branch] do
      cmd_opts = cmd_opts ++ ["--branch=#{opts[:branch]}"]
    end
    cmd_opts
  end

  defp info(url, dir) do
    %RepoInfo{
      dir: dir,
      url: url,
      branch: branch(dir),
      revision: revision(dir),
      revisions: revisions_back(dir, @depth),
    }
  end

  # Returns the name of the current branch.
  defp branch(dir) do
    git_output(dir, ["rev-parse", "--abbrev-ref", "HEAD"])
  end

  # Returns the SHA1 of the current revision.
  defp revision(dir) do
    git_output(dir, ["rev-parse", "HEAD"])
    |> revision_info
  end

  # Returns the SHA1 of the current last `count` revisions.
  defp revisions_back(dir, count) do
    0..count-1
    |> Enum.map(fn(nr) ->
        git_output(dir, ["rev-parse", "HEAD" <> String.duplicate("^", nr)])
        |> revision_info
      end)
    |> Enum.reject(&is_nil/1)
  end

  defp revision_info("fatal: " <> _), do: nil
  defp revision_info(sha1) do
    %{sha1: sha1}
  end

  defp git_output(dir, cmd_opts) do
    case System.cmd("git", cmd_opts, [cd: dir] ++ @default_system_opts) do
      {output, 0} -> String.strip(output)
      {output, _} -> String.strip(output)
    end
  end
end
