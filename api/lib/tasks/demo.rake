namespace :demo do
  desc "Wipe all data and rebuild the synthetic demo dataset"
  task reset: :environment do
    puts DemoSeed.reset!.to_json
  end
end
