require 'tiny-presto/version'
require 'tiny-presto/cluster'

require 'singleton'
require 'presto-client'

module TinyPresto
  class TinyPresto
    include Singleton

    attr_reader :cluster, :client

    def initialize
      url = 'localhost'
      @cluster = Cluster.new(url)
      @cluster.run
      @client = Presto::Client.new(server: "#{url}:8080", catalog: 'memory', user: 'tiny-user', schema: 'default')
      loop do
        begin
          @client.run('show schemas')
          break
        rescue StandardError => _
          # Waiting for the cluster is launched
          sleep(1)
        end
      end
    end

    def stop
      @cluster.stop
    end
  end

  def self.run(sql)
    presto = TinyPresto.instance
    _, rows = presto.client.run(sql)
    rows
  end

  def self.verify(sql, expected_result)
    presto = TinyPresto.instance
    _, rows = presto.client.run(sql)
    rows == expected_result
  end

  def self.ensure_stop
    presto = TinyPresto.instance
    presto.stop
  end
end
