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

      assert Archive.list_domains(team) == [domain.domain]

      Archive.add_domain(team, "zzz.com")
      Archive.add_domain(team, "yyy.com")
      Archive.add_domain(team, "xxx.com")
      Archive.add_domain(team, "bbb.com")
      Archive.add_domain(team, "ccc.com")
      Archive.add_domain(team, "www.com")

      assert Archive.list_domains(team) == [
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

      assert length(Archive.archive_urls(team, ["https://zeep.zop.bleep.com/zoop?zop=zeep"])) == 1

      assert length(Archive.archive_urls(team, ["https://espn.com/zoop?zop=zeep"])) == 0

      arc1 = "https://zeep.zop.bleep.com/zoop?zop=zeep"
      arc2 = "https://zeep.zop.bleep.com/bop?zop=zeep"
      not_arc = "https://espn.com/zoop?zop=zeep"
      result = Archive.archive_urls(team, [arc1, arc2, not_arc])

      assert length(result) == 2

      assert {"https://archive.today/newest/https://zeep.zop.bleep.com/zoop", arc1} ==
               Enum.at(result, 0)

      assert {"https://archive.today/newest/https://zeep.zop.bleep.com/bop", arc2} ==
               Enum.at(result, 1)
    end

    test "dedupe" do
      team = team_fixture()

      {:ok, _} = Archive.add_domain(team, "xxx.com")
      assert length(Archive.list_domains(team)) == 1

      {:ok, _} = Archive.add_domain(team, "yyy.com")
      assert length(Archive.list_domains(team)) == 2

      {:ok, _} = Archive.add_domain(team, "zzz.com")
      assert length(Archive.list_domains(team)) == 3

      {:error, "domain is already added"} = Archive.add_domain(team, "xxx.com")
      assert length(Archive.list_domains(team)) == 3
    end
  end
end
