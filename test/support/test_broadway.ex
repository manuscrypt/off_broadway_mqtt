defmodule OffBroadway.MQTT.TestBroadway do
  @moduledoc false

  use OffBroadway.MQTT

  def start_link(config, opts) do
    test_pid = self()
    topic = Keyword.fetch!(opts, :topic)
    name = Keyword.fetch!(opts, :name)

    batch_fun =
      opts[:batch_fun] ||
        fn msgs ->
          send(test_pid, {:batch_fun, msgs})
          msgs
        end

    process_fun =
      opts[:process_fun] ||
        fn msg ->
          send(test_pid, {:process_fun, msg})
          msg
        end

    producer_opts =
      opts
      |> Keyword.fetch!(:producer_opts)
      |> Keyword.put_new(:sub_ack, test_pid)

    producer_opts = [config, {:subscription, {topic, 0}}] ++ producer_opts

    Broadway.start_link(__MODULE__,
      name: name,
      producer: [
        module: {Producer, producer_opts}
      ],
      processors: [default: [concurrency: 1]],
      batchers: [
        default: [concurrency: 1, batch_size: 10]
      ],
      context: %{
        process_fun: process_fun,
        batch_fun: batch_fun
      }
    )
  end

  @impl true
  def handle_message(_processor_name, message, %{
        process_fun: process_fun
      }) do
    message
    |> Message.update_data(process_fun)
  rescue
    e -> fail_msg(message, e)
  end

  @impl true
  def handle_batch(_batcher, messages, _batch_info, %{
        batch_fun: batch_fun
      }) do
    batch_fun.(messages)
  rescue
    e -> fail_msg(messages, e)
  end
end
