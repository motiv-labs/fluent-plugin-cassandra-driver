module CassandraDriver
  class StringMutator
    def mutate(value)
      "'#{value}'"
    end
  end
end