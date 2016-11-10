# Cassandra plugin for Fluentd

Cassandra output plugin for Fluentd.

Implemented using the Datastax Ruby Driver for Apache Cassandra gem and targets [CQL3](https://docs.datastax.com/en/cql/3.3/)
and Cassandra 1.2 - 3.x

# Installation

via RubyGems

    fluent-gem install fluent-plugin-cassandra-driver

# Quick Start

## Cassandra Configuration
    # create keyspace (via CQL)
      CREATE KEYSPACE \"metrics\" WITH strategy_class='org.apache.cassandra.locator.SimpleStrategy' AND strategy_options:replication_factor=1;

    # create table (column family)
      CREATE TABLE logs (id varchar, ts bigint, payload text, PRIMARY KEY (id, ts)) WITH CLUSTERING ORDER BY (ts DESC);

    # NOTE: schema definition should match that specified in the Fluentd.conf configuration file (see below)

## Fluentd.conf Configuration
    <match cassandra.**>
      type cassandra_driver      # fluent output plugin file name (sans fluent_plugin_ prefix)
      hosts 127.0.0.1            # comma delimited string of hosts
      keyspace metrics           # cassandra keyspace
      columnfamily logs          # cassandra column family
      ttl 60                     # cassandra ttl *optional => default is 0*
      schema                     # cassandra column family schema *hash where keys => column names and values => data types* for example: {:id => :string}
      data_keys                  # comma delimited string of the fluentd hash's keys
      pop_data_keys              # keep or pop key/values from the fluentd hash when storing it as json
    </match>
    
# Tests

TODO
