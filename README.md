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
bundle install
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

This will run the tests. If they all pass, then your environment is setup correctly.

Note: It is recommended to have GEOS installed and linked to RGeo. You can test this by running the following:

```
cd test/dummy
rails c

RGeo::Geos.supported?
# => true
```

## TODO

- ~~Memoize expensive functions within classes~~
- ~~Make star a parameter to getis-ord class~~
- Add examples to docs
- Create RDocs

## Future Work

#### General

- ~~Refactor stats to inherit an abstract class.~~
- Change WeightsMatrix class and Stat classes to utilize sparse matrix methods.

#### Weights

- Add Kernel based weighting.

#### Utils

- Rate smoothing
- Bayes smoothing

#### Local

- Join Count Statistic

### PPA

- Add descriptive stat methods for point clusters.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
