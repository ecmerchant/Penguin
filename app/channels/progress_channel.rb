class ProgressChannel < ApplicationCable::Channel
  def subscribed
    # stream_from "some_channel"
  end

  def unsubscribed
    # Any cleanup needed when channel is unsubscribed
  end

  def show(data)
    stream_from("progress:#{data['progress_id'].to_i}")
  end
end
