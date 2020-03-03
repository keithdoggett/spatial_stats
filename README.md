# SpatialStats

Short description and motivation.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'spatial_stats'
```

And then execute:

```bash
$ bundle
```

Or install it yourself as:

```bash
$ gem install spatial_stats
```

## Usage

How to use my plugin.

## Contributing

Once cloned, run the following commands to setup the test database.

```sh
cd ./spatial_stats
cd test/dummy
rake db:create
rake db:migrate
```

If you are getting an error, you may need to set the following environment variables.

```
$PGUSER # default "postgres"
$PGPASSWORD # default ""
$PGHOST # default "127.0.0.1"
$PGPORT # default "5432"
$PGDATABASE # default "spatial_stats_test"
```

If the dummy app is setup correctly, run the following:

```
cd ../..
rake
```

This will run the tests. If they all passed, then your environment is setup correctly.

## Future Work

- Add Kernel based weighting.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
