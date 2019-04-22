# clamav-client - ClamAV client
# Copyright (C) 2014 Franck Verrot <franck@verrot.fr>

# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.

# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

require 'test_helper'

describe "ClamAV::Client Integration Tests" do
  describe "default new line delimiter" do
    let(:client) { ClamAV::Client.new }

    describe "any callable" do
      it "can be used" do
        assert client.execute(lambda { |conn| true })
      end
    end

    describe "ping" do
      let(:ping_command) { ClamAV::Commands::PingCommand.new }

      it "can be sent" do
        assert client.execute(ping_command)
      end

      it "can be sent multiple times" do
        assert client.execute(ping_command)
        assert client.execute(ping_command)
      end

      it 'can be used as #ping' do
        assert_equal client.execute(ping_command), client.ping
      end
    end

    describe "scan" do
      let(:base_path) { File.expand_path('../../../../', __FILE__) }

      it "can be started" do
        dir = File.join(base_path, 'test/fixtures')
        results = client.execute(ClamAV::Commands::ScanCommand.new(dir))

        expected_results = {
          "#{base_path}/test/fixtures/clamavtest.gz"  => ClamAV::VirusResponse,
          "#{base_path}/test/fixtures/clamavtest.txt" => ClamAV::VirusResponse,
          "#{base_path}/test/fixtures/clamavtest.zip" => ClamAV::VirusResponse,
          "#{base_path}/test/fixtures/innocent.txt"   => ClamAV::SuccessResponse
        }

        results.each do |result|
          expected_result = expected_results[result.file]
          assert_equal expected_result, result.class
        end
      end
    end

    describe "instream" do
      let(:dir) { File.expand_path('../../../../test/fixtures', __FILE__) }

      it "can recognize a sane file" do
        command = build_command_for_file('innocent.txt')
        client.execute(command).must_equal ClamAV::SuccessResponse.new("stream")
      end

      it "can recognize an infected file" do
        command = build_command_for_file('clamavtest.txt')
        client.execute(command).must_equal ClamAV::VirusResponse.new("stream", "ClamAV-Test-Signature")
      end

      def build_command_for_file(file)
        io = File.open(File.join(dir, file))
        ClamAV::Commands::InstreamCommand.new(io)
      end
    end
  end
end
