require "./spec_helper"

# Originally copied from https://github.com/crystal-cache/cache/blob/main/spec/file_store_spec.cr

# The MIT License (MIT)

# Copyright (c) 2018-2026 Anton Maminov

# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:

# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.

# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.

describe Cache do
  context Cache::LmdbStore do
    cache_path = "#{__DIR__}/cache"

    Spec.after_each do
      FileUtils.rm_rf(cache_path)
    end

    it "initialize" do
      store = Cache::LmdbStore(String).new(expires_in: 12.hours, cache_path: cache_path)

      store.should be_a(Cache::Store(String))
      store.cache_path.should end_with("/spec/cache")
      store.close
    end

    it "write to cache first time" do
      store = Cache::LmdbStore(String).new(12.hours, cache_path: cache_path)

      value = store.fetch("foo") { "bar" }
      value.should eq("bar")

      store.close
    end

    it "fetch from cache" do
      store = Cache::LmdbStore(String).new(12.hours, cache_path: cache_path)

      value = store.fetch("foo") { "bar" }
      value.should eq("bar")

      value = store.fetch("foo") { "baz" }
      value.should eq("bar")

      store.close
    end

    it "fetch from cache with generic types values" do
      store = Cache::LmdbStore(String | Int32).new(expires_in: 12.hours, cache_path: cache_path)

      value = store.fetch("string") { "bar" }
      value.should eq("bar")

      value = store.fetch("integer") { 13 }
      value.should eq(13)

      store.close
    end

    it "fetch from cache with false values" do
      store = Cache::LmdbStore(String | Bool).new(expires_in: 12.hours, cache_path: cache_path)

      value = store.fetch("foo") { false }
      value.should be_false

      value = store.fetch("foo") { "bar" }
      value.should be_false
    end

    it "don't fetch from cache if expired" do
      freeze do |time|
        store = Cache::LmdbStore(String).new(1.seconds, cache_path: cache_path)

        value = store.fetch("foo") { "bar" }
        value.should eq("bar")

        Timecop.travel(time + 2.seconds)

        value = store.fetch("foo") { "baz" }
        value.should eq("baz")
      end
    end

    it "fetch with expires_in from cache" do
      freeze do |time|
        store = Cache::LmdbStore(String).new(1.seconds, cache_path: cache_path)

        value = store.fetch("foo", expires_in: 1.hours) { "bar" }
        value.should eq("bar")

        Timecop.travel(time + 2.seconds)

        value = store.fetch("foo") { "baz" }
        value.should eq("bar")
      end
    end

    it "don't fetch with expires_in from cache if expires" do
      freeze do |time|
        store = Cache::LmdbStore(String).new(12.hours, cache_path: cache_path)

        value = store.fetch("foo", expires_in: 1.seconds) { "bar" }
        value.should eq("bar")

        Timecop.travel(time + 2.seconds)

        value = store.fetch("foo") { "baz" }
        value.should eq("baz")
      end
    end

    it "write" do
      store = Cache::LmdbStore(String).new(12.hours, cache_path: cache_path)
      store.write("foo", "bar", expires_in: 1.minute).should eq("bar")

      value = store.fetch("foo") { "baz" }
      value.should eq("bar")
    end

    it "read" do
      store = Cache::LmdbStore(String).new(12.hours, cache_path: cache_path)
      store.write("foo", "bar")

      value = store.read("foo")
      value.should eq("bar")
    end

    it "read nil if key does not exists" do
      store = Cache::LmdbStore(String).new(expires_in: 12.hours, cache_path: cache_path)

      value = store.read("foo")
      value.should be_nil
    end

    it "fetch without block" do
      store = Cache::LmdbStore(String).new(expires_in: 12.hours, cache_path: cache_path)
      store.write("foo", "bar")

      value = store.fetch("foo")
      value.should eq("bar")
    end

    it "set a custom expires_in value for one entry on write" do
      freeze do |time|
        store = Cache::LmdbStore(String).new(12.hours, cache_path: cache_path)
        store.write("foo", "bar", expires_in: 1.second)

        Timecop.travel(time + 2.seconds)

        store.all_keys.size.should eq(1)

        value = store.read("foo")
        value.should be_nil

        store.all_keys.should be_empty
      end
    end

    it "delete from cache" do
      store = Cache::LmdbStore(String).new(12.hours, cache_path: cache_path)

      value = store.fetch("foo") { "bar" }
      value.should eq("bar")
      store.all_keys.size.should eq(1)

      result = store.delete("foo")
      result.should be_true

      value = store.read("foo")
      value.should be_nil
      store.all_keys.should be_empty
    end

    it "returns false when deleting a missing key" do
      store = Cache::LmdbStore(String).new(12.hours, cache_path: cache_path)

      store.delete("missing").should be_false
    end

    it "deletes all items from the cache" do
      store = Cache::LmdbStore(String).new(12.hours, cache_path: cache_path)

      value = store.fetch("foo") { "bar" }
      value.should eq("bar")
      store.all_keys.size.should eq(1)

      store.clear

      store.all_keys.should be_empty
    end

    it "clears an empty cache" do
      store = Cache::LmdbStore(String).new(12.hours, cache_path: cache_path)

      store.clear
    end

    it "#exists?" do
      store = Cache::LmdbStore(String).new(12.hours, cache_path: cache_path)

      store.write("foo", "bar")

      store.exists?("foo").should be_true
      store.exists?("foz").should be_false
    end

    it "#exists? expires" do
      freeze do |time|
        store = Cache::LmdbStore(String).new(1.second, cache_path: cache_path)

        store.write("foo", "bar")

        Timecop.travel(time + 2.seconds)

        store.exists?("foo").should be_false
      end
    end

    it "#increment" do
      store = Cache::LmdbStore(Int32).new(12.hours, cache_path: cache_path)

      store.write("num", 1)
      store.increment("num", 1).should eq(2)

      value = store.read("num")

      value.should eq(2)
    end

    it "#decrement" do
      store = Cache::LmdbStore(Int32).new(12.hours, cache_path: cache_path)

      store.write("num", 2)
      store.decrement("num", 1).should eq(1)

      value = store.read("num")

      value.should eq(1)
    end

    it "#increment returns nil for missing and non-integer values" do
      store = Cache::LmdbStore(String | Int32).new(expires_in: 12.hours, cache_path: cache_path)

      store.increment("missing", 1).should be_nil
      store.write("string", "value")
      store.increment("string", 1).should be_nil
    end
  end
end
