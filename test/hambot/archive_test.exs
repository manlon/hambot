defmodule Hambot.ArchiveTest do
  use Hambot.DataCase

  describe "servers" do
    alias Hambot.Archive.Server

    import Hambot.DomainFixtures

    # @invalid_attrs %{}

    test "list_domains/0 returns all domains" do
      domain = domain_fixture()
      GenServer.cast(Server, :initialize_state)
      assert Server.list_domains() == [domain.domain]
    end
  end
end
