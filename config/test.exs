import Config

config :off_broadway_mqtt,
  telemetry_enabled: true,
  client_id_prefix: "test",
  telemetry_prefix: :test,
  dequeue_interval: 100,
  server_opts: [
    host: "localhost",
    port: 1883
  ]
