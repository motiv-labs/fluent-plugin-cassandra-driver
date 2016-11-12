# Cassandra plugin for Fluentd

Cassandra output plugin for Fluentd.

Implemented using the Datastax Ruby Driver for Apache Cassandra gem and targets [CQL3](https://docs.datastax.com/en/cql/3.3/)
and Cassandra 1.2 - 3.x

# Installation

via RubyGems

    fluent-gem install fluent-plugin-cassandra-driver
    td-agent-gem install fluent-plugin-cassandra-driver

# Quick Start

## Cassandra Configuration
    # Create keyspace (via CQL)
      CREATE KEYSPACE metrics WITH strategy_class='org.apache.cassandra.locator.SimpleStrategy' AND strategy_options:replication_factor=1;

    # Create table (column family)
      CREATE TABLE logs (id varchar, timestamp timestamp, json text, PRIMARY KEY (id, timestamp)) WITH CLUSTERING ORDER BY (timestamp DESC);

## Fluentd.conf Configuration
    <match cassandra.**>
      type cassandra_driver      # fluent output plugin file name (sans fluent_plugin_ prefix)
      hosts 127.0.0.1            # comma delimited string of hosts
      keyspace metrics           # cassandra keyspace
      columnfamily logs          # cassandra column family
      ttl 60                     # cassandra ttl (optional, default is 0)
      schema                     # cassandra column family schema (see example below)
      pop_data_keys              # pop values from the fluentd hash when storing it as json (optional, default is true)
      json_column json           # column where store all remaining data from fluentd (optional)
    </match>
    
### Schema example
    # hash of hashes :column_damily_key => {:fluentd_record_key => :type_from_list}
    '{:id => {:id => nil}, :timestamp => {:timestamp => :time}}'
    
Available mappings:
* :integer
* :string
* :timeuuid
* :time
    
All nil types will be recognized as string.
    
# Tests

TODO
