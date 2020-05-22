## Contributing

Once cloned, run the following commands to setup the test database.

```bash
cd ./spatial_stats
bundle install
cd test/dummy
rake db:create
rake db:migrate
```

If you are getting an error, you may need to set the following environment variables.

```bash
$PGUSER # default "postgres"
$PGPASSWORD # default ""
$PGHOST # default "127.0.0.1"
$PGPORT # default "5432"
$PGDATABASE # default "spatial_stats_test"
```

If the dummy app is setup correctly, run the following:

```bash
cd ../..
rake
```

This will run the tests. If they all pass, then your environment is setup correctly.

Note: It is recommended to have GEOS installed and linked to RGeo. You can test this by running the following:

```bash
cd test/dummy
rails c

RGeo::Geos.supported?
# => true
```

Please submit PRs with a description of the problem, the solution and link any issues that it closes.
