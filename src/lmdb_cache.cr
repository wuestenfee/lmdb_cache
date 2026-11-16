require "cache"
require "lmdb"

module Cache
  struct LmdbStore(V) < Store(V)
    getter cache_path : String

    def initialize(@expires_in : Time::Span, @cache_path)
      Dir.mkdir_p cache_path

      @env = LMDB::Environment.new cache_path
      @db = @env.database
    end

    def all_keys : Set(String)
      transaction = @env.transaction @db, true

      result = Set(String).new @db.size
      @db.each_key { |key| result << key.as_str }

      transaction.commit

      result
    end

    private def write_impl(key : String, value : V, *, expires_in = @expires_in)
      @env.transaction @db do
        @db.put key, Entry(V).new(value, expires_in).to_yaml
      end
    end

    private def read_impl(key : String) : V?
      transaction = @env.transaction @db, true

      entry = @db.get?(key).try &.as_str

      transaction.commit

      return if entry.nil?

      entry = Entry(V).from_yaml entry

      if entry.expired?
        @env.transaction @db do
          @db.delete key
        end
      else
        return entry.value
      end

      nil
    end

    private def delete_impl(key : String) : Bool
      transaction = @env.transaction @db
      @db.delete key

      transaction.commit
      true
    rescue
      transaction.try &.commit
      false
    end

    private def exists_impl(key : String) : Bool
      transaction = @env.transaction @db, true

      raw_entry = @db.get?(key).try &.as_str

      transaction.commit

      return false if raw_entry.nil?

      entry = Entry(V).from_yaml raw_entry

      if entry.expired?
        @env.transaction do
          @db.delete key
        end

        false
      else
        true
      end
    end

    def clear
      @env.transaction do
        @db.clear
      end
    end

    def close
      @env.close
    end
  end
end
