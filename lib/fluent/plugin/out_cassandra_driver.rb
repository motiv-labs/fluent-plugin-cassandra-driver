require 'cassandra'
require 'msgpack'
require 'json'
require 'mutators/string_mutator'
require 'mutators/timeuuid_mutator'

module Fluent
  class CassandraCqlOutput < BufferedOutput
    Fluent::Plugin.register_output('cassandra_driver', self)

    config_param :hosts, :string
    config_param :keyspace, :string
    config_param :columnfamily, :string
    config_param :ttl, :integer, :default => 0
    config_param :schema, :string
    config_param :data_keys, :string

    # remove keys from the fluentd json event as they're processed
    # for individual columns?
    config_param :pop_data_keys, :bool, :default => true

    def session
      @session ||= get_session(self.hosts, self.keyspace)
    end

    def configure(conf)
      super

      # perform validations
      raise ConfigError, "'Hosts' is required by Cassandra output (ex: localhost, 127.0.0.1, ec2-54-242-141-252.compute-1.amazonaws.com" if self.hosts.nil?
      raise ConfigError, "'Keyspace' is required by Cassandra output (ex: FluentdLoggers)" if self.keyspace.nil?
      raise ConfigError, "'ColumnFamily' is required by Cassandra output (ex: events)" if self.columnfamily.nil?
      raise ConfigError, "'Schema' is required by Cassandra output (ex: id,ts,payload)" if self.schema.nil?
      raise ConfigError, "'Schema' must contain at least two column names (ex: id,ts,payload)" if self.schema.split(',').count < 2
      raise ConfigError, "'DataKeys' is required by Cassandra output (ex: tag,created_at,data)" if self.data_keys.nil?

      # convert schema from string to hash
      # NOTE: ok to use eval b/c this isn't this isn't a user
      #       supplied string
      self.schema = eval(self.schema)

      # convert data keys from string to array
      self.data_keys = self.data_keys.split(',')

      # split hosts to array
      self.hosts = self.hosts.split(',')
    end

    def start
      super
      session
    end

    def shutdown
      super
      @session.close if @session
    end

    def format(tag, time, record)
      record.to_msgpack
    end

    def write(chunk)
      chunk.msgpack_each { |record|
        $log.debug "Sending a new record to Cassandra: #{record.to_json}"

        values = build_insert_values_string(self.schema.keys, self.data_keys, record, self.pop_data_keys)

        cql = "INSERT INTO #{self.columnfamily} (#{self.schema.keys.join(',')}) VALUES (#{values}) USING TTL #{self.ttl}"

        begin
          @session.execute(cql)
        rescue Exception => e
          $log.error "Cannot send record to Cassandra: #{e.message}\nTrace: #{e.backtrace.to_s}"
        end
      }
    end

    private

    def get_session(hosts, keyspace)
      cluster = ::Cassandra.cluster(hosts: hosts)

      cluster.connect(keyspace)
    end

    def build_insert_values_string(schema_keys, data_keys, record, pop_data_keys)
      values = data_keys.map.with_index do |key, index|
        value = pop_data_keys ? record.delete(key) : record[key]
        type = self.schema[schema_keys[index]]

        case type
          when :string
            value = "'#{value}'"
          when 'timeuuid'
            value = Cassandra::Uuid::Generator.new.at(value).to_s
          else
        end

        value
      end

      # if we have one more schema key than data keys,
      # we can then infer that we should store the event
      # as a string representation of the corresponding
      # json object in the last schema column
      if schema_keys.count == data_keys.count + 1
        values << if record.count > 0
                    "'#{record.to_json}'"
                  else
                    # by this point, the extra schema column has been
                    # added to insert cql statement, so we must put
                    # something in it
                    # TODO: detect this scenario earlier and don't
                    #       specify the column name/value at all
                    #       when constructing the cql stmt
                    "''"
                  end
      end

      values.join(',')
    end
  end
end
