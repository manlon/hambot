defmodule Hambot.ArchiveTest do
  use Hambot.DataCase

  describe "servers" do
    alias Hambot.Archive
    import Hambot.DomainFixtures
    import Hambot.TeamFixtures

    # @invalid_attrs %{}

    test "list_domains/1 returns all domains" do
      team = team_fixture()
      domain = domain_fixture(team, %{domain: "aaa.com"})

      assert Archive.list_domains(team.team_id) == [domain.domain]

      Archive.add_domain(team.team_id, "zzz.com")
      Archive.add_domain(team.team_id, "yyy.com")
      Archive.add_domain(team.team_id, "xxx.com")
      Archive.add_domain(team.team_id, "bbb.com")
      Archive.add_domain(team.team_id, "ccc.com")
      Archive.add_domain(team.team_id, "www.com")

      assert Archive.list_domains(team.team_id) == [
               "aaa.com",
               "bbb.com",
               "ccc.com",
               "www.com",
               "xxx.com",
               "yyy.com",
               "zzz.com"
             ]
    end

    test "subdomain is archived" do
      team = team_fixture()
      _domain = domain_fixture(team, %{domain: "bleep.com"})

      assert length(
               Archive.archive_urls(team.team_id, ["https://zeep.zop.bleep.com/zoop?zop=zeep"])
             ) == 1

      assert length(Archive.archive_urls(team.team_id, ["https://espn.com/zoop?zop=zeep"])) == 0
    end

    test "dedupe" do
      team = team_fixture()

      {:ok, _} = Archive.add_domain(team.team_id, "xxx.com")
      assert length(Archive.list_domains(team.team_id)) == 1

      {:ok, _} = Archive.add_domain(team.team_id, "yyy.com")
      assert length(Archive.list_domains(team.team_id)) == 2

      {:ok, _} = Archive.add_domain(team.team_id, "zzz.com")
      assert length(Archive.list_domains(team.team_id)) == 3

      {:error, "domain is already added"} = Archive.add_domain(team.team_id, "xxx.com")
      assert length(Archive.list_domains(team.team_id)) == 3
    end
  end
end
