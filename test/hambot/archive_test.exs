defmodule Hambot.ArchiveTest do
  use Hambot.DataCase

  describe "servers" do
    alias Hambot.Archive
    alias Hambot.Archive.Server

    import Hambot.DomainFixtures

    # @invalid_attrs %{}

    test "list_domains/0 returns all domains" do
      domain = domain_fixture()
      GenServer.cast(Server, :initialize_state)
      assert Server.list_domains() == [domain.domain]
    end

    test "subdomain is archived" do
      domain = domain_fixture(%{domain: "bleep.com"})
      GenServer.cast(Server, :initialize_state)
      assert Server.is_archive?(domain.domain)
      assert Archive.should_archive?("https://zeep.zop.bleep.com/zoop?zop=zeep")
      assert not Archive.should_archive?("https://espn.com/zoop?zop=zeep")
    end
  end
end
