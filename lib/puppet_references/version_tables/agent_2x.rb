require 'puppet_references'

module PuppetReferences
  module VersionTables
    class Agent2x < PuppetReferences::VersionTables::AgentTables
      def initialize(agent_data)
        super
        @file = '_agent2.x.html'
        @versions = @agent_data.keys.select{|v| v =~ /^2\./}.sort.reverse
      end
    end
  end
end