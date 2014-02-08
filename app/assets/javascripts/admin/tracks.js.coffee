TracklistEditor =
  init: ->
    table = $('.tracks_table')
    @dom =
      table: table.find('tbody')
      add_track: table.find('a[data-action=add_track]')
      add_text: table.find('a[data-action=add_text]')
      upload: $('#upload_from_csv')
    @dom.add_track.on('click', => @addTrackRow())
    @dom.add_text.on('click', => @addTextRow())
    @dom.table.delegate('a[data-action=remove_row]', 'click', @removeRow.bind(@ ))
    @dom.upload.on('change', @onCSVUpload.bind(@))

  addTrackRow: (start_time='', track='', artist='', album='', label='') ->
    html = "<tr>
              <td><input type='text' value='#{start_time}' name='tracklist[tracks][][start_time]' /></td>
              <td><input type='text' value='#{track}' name='tracklist[tracks][][track]' /></td>
              <td><input type='text' value='#{artist}' name='tracklist[tracks][][artist]' /></td>
              <td><input type='text' value='#{album}' name='tracklist[tracks][][album]' /></td>
              <td><input type='text' value='#{label}' name='tracklist[tracks][][label]' /></td>
              <td><a class='button' data-action='remove_row'>Remove</a></td>
            </tr>"
    tr = $(html).appendTo(@dom.table)

  addTextRow: ->
    html = "<tr>
              <td colspan='5'><input type='text' name='tracklist[tracks][][freetext]' /></td>
              <td><a class='button' data-action='remove_row'>Remove</a></td>
            </tr>"
    tr = $(html).appendTo(@dom.table)

  removeRow: (e) ->
    tgt = $(e.target)
    tr = tgt.parents('tr')
    tr.remove()

  onCSVUpload: (e) ->
    file = e.target.files[0]
    return unless file.type is 'text/csv'
    reader = new FileReader()
    reader.onload = (evt) =>
      lines = evt.target.result.split("\n")
      for line in lines
        parts = line.split(',')
        track = parts[0]
        artist = parts[1]
        album = parts[2]
        label = parts[3]
        @addTrackRow('', track, artist, album, label)
    reader.readAsText(file)
    e.target.value = null


@TracklistEditor = TracklistEditor