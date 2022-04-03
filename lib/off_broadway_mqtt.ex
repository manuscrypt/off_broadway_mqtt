defmodule OffBroadway.MQTT do
  @moduledoc """
  A broadway producer for MQTT topic subscriptions.
  """

  alias Broadway.Message
  alias OffBroadway.MQTT.Config

  @type topic :: binary
  @type qos :: 0 | 1 | 2
  @type subscription :: {topic, qos}
  @type queue_name :: GenServer.name() | {:via, Registry, {atom, topic}}
  @type config :: Config.t()

  defmacro __using__(_) do
    quote do
      use Broadway

      import OffBroadway.MQTT

      alias Broadway.Message
      alias OffBroadway.MQTT.Producer
    end
  end

  @doc """
  Adds the second argument as error to one or many message(s).
  """
  @spec fail_msg([Message.t()], Exception.t()) :: [Message.t()]
  @spec fail_msg(Message.t(), Exception.t()) :: Message.t()
  def fail_msg(messages, exception) when is_list(messages) do
    messages |> Enum.map(&fail_msg(&1, exception))
  end

  def fail_msg(message, exception),
    do: message |> Message.failed(exception)

  def unique_client_id do
    default_config() |> unique_client_id()
  end

  @doc """
  Utility function to build a for the running application unique client id that
  can be used when connecting with the broker.

  This ensures that multiple clients from the same application don't kick each
  other from the broker in case the broker does not allow multiple connections
  with the same clent id.
  """
  @spec unique_client_id(config) :: String.t()
  def unique_client_id(%{client_id_prefix: prefix}) do
    random = [:positive] |> System.unique_integer() |> to_string
    prefix <> "_" <> random
  end

  @spec unique_client_id(config) :: String.t()
  def unique_client_id(%{client_id: prefix}) do
    prefix
  end

  @doc """
  Returns the name for the queue belonging to the given topic.
  """
  @spec queue_name(topic) :: {:via, Registry, {atom, topic}}
  def queue_name(topic) do
    Config.new_from_app_config() |> queue_name(topic)
  end

  @doc """
  Returns the name for the queue belonging to the given topic.
  """
  @spec queue_name(config, topic) :: {:via, Registry, {atom, topic}}
  def queue_name(%{queue_registry: registry}, topic) when is_binary(topic) do
    {:via, Registry, {registry, topic}}
  end

  @doc """
  Returns the topic name from a `t:queue_name/0`.
  """
  @spec topic_from_queue_name(queue_name) :: topic
  def topic_from_queue_name({:via, _, {_, topic}}), do: topic

  @doc """
  Returns the runtime configuration for OffBroadway.MQTT.

  See `f:OffBroadway.MQTT.Config.new/1` for more details.
  """
  @spec config(Config.options()) :: config
  def config(config_opts \\ []) when is_list(config_opts),
    do: Config.new(config_opts)

  @doc """
  Returns the runtime configuration for OffBroadway.MQTT with the configured
  application defaults.

  See `f:OffBroadway.MQTT.Config.new_from_app_config/1` for more details.
  """
  @spec default_config(Config.options()) :: config
  def default_config(config_opts \\ []) when is_list(config_opts),
    do: Config.new_from_app_config(config_opts)
end
