require 'cassandra'

module CassandraDriver
  class TimeuuidMutator
    @generator = Cassandra::Uuid::Generator.new

    def mutate(value)
      @generator.at(value).to_s
    end
  end
end