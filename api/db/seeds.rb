# Idempotent synthetic demo data. Safe to run on every deploy.
puts DemoSeed.run!.to_json
