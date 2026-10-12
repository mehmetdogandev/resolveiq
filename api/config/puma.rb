# Puma configuration. Render injects PORT; locally the API runs on 3001.
threads_count = ENV.fetch("RAILS_MAX_THREADS", 3)
threads threads_count, threads_count

port ENV.fetch("PORT", 3001)

workers ENV.fetch("WEB_CONCURRENCY", 0).to_i

plugin :tmp_restart

pidfile ENV["PIDFILE"] if ENV["PIDFILE"]
