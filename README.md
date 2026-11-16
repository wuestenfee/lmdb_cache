# lmdb_cache

A [cache](https://github.com/crystal-cache/cache)
store implementation that uses
[RomainFranceschini/crystal-lmdb](https://github.com/RomainFranceschini/crystal-lmdb)
as wrapper for [LMDB](https://symas.com/lmdb/).

## Installation

1. Add the dependency to your `shard.yml`:

   ```yaml
   dependencies:
     lmdb_cache:
       github: wuestenfee/lmdb_cache
   ```

2. Run `shards install`

3. Install [LMDB](https://symas.com/lmdb/) >= 0.9.23 on your system

## Usage

```crystal
require "lmdb_cache"
```

TODO: Write usage instructions here

## Development

TODO: Write development instructions here

## Contributing

1. Fork it (<https://github.com/wuestenfee/lmdb_cache/fork>)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## Contributors

- [wuestenfee](https://github.com/wuestenfee) - creator and maintainer
