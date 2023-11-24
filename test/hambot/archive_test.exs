defmodule Hambot.ArchiveTest do
  use Hambot.DataCase

  describe "servers" do
    alias Hambot.Archive
    alias Hambot.Archive.Server

    import Hambot.DomainFixtures

    # @invalid_attrs %{}

    test "list_domains/0 returns all domains" do
      domain = domain_fixture(%{domain: "aaa.com"})
      GenServer.cast(Server, :initialize_state)
      assert Server.list_domains() == [domain.domain]

      Server.add_domain("zzz.com")
      Server.add_domain("yyy.com")
      Server.add_domain("xxx.com")
      Server.add_domain("bbb.com")
      Server.add_domain("ccc.com")
      Server.add_domain("www.com")

      assert Server.list_domains() == [
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
      domain = domain_fixture(%{domain: "bleep.com"})
      GenServer.cast(Server, :initialize_state)
      assert Server.is_archive?(domain.domain)
      assert Archive.should_archive?("https://zeep.zop.bleep.com/zoop?zop=zeep")
      assert not Archive.should_archive?("https://espn.com/zoop?zop=zeep")
    end
  end
end
