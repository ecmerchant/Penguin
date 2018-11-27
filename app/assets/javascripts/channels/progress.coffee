App.progress = App.cable.subscriptions.create "ProgressChannel",
  connected: ->
    # Called when the subscription is ready for use on the server
    @install()
    @show()

  disconnected: ->
    # Called when the subscription has been terminated by the server

  received: (data) ->
    # Called when there's incoming data on the websocket for this channel
    $('.progress-percentage').text("#{data.percent}%")
    $('progress').prop('value', data.percent)

  show: ->
    @perform('show', progress_id: 1)

  install: ->
    $(document).on('page:change', -> App.progress.show())
