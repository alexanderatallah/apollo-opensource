@generalQueryChangeLock = 0
@structuredQueryChangeLock = 0

@generalQueryChange = (newQuery) ->
  oldQuery = Session.get 'currentSearchQuery'
  if "#{ oldQuery }" is "#{ newQuery }" # Make sure we compare primitive strings
    return

  # We increase the counter to signal that general query invoked the change
  generalQueryChangeLock++
  Deps.afterFlush ->
    Meteor.setTimeout ->
      generalQueryChangeLock--
      assert generalQueryChangeLock >= 0
    , 100 # ms after the flush we unlock

  # TODO: Add fields from the sidebar
  Session.set 'currentSearchQuery', newQuery
  Session.set 'currentSearchLimit', INITIAL_SEARCH_LIMIT

@structuredQueryChange = (newQuerySerialized) ->
  oldQuery = Session.get 'currentSearchQuery'
  newQuery = serializedToQuery newQuerySerialized
  if "#{ oldQuery }" is "#{ newQuery }" # Make sure we compare primitive strings
    return

  # We increase the counter to signal that structured query invoked the change
  # structuredQueryChangeLock++
  # Deps.afterFlush ->
  #   Meteor.setTimeout ->
  #     structuredQueryChangeLock--
  #     assert structuredQueryChangeLock >= 0
  #   , 100 # ms after the flush we unlock

  Session.set 'currentSearchQuery', newQuery
  Session.set 'currentSearchLimit', INITIAL_SEARCH_LIMIT

Deps.autorun ->
  if !Session.get('searchAdvancedHasBeenToggled')
    if Session.get('currentSearchQuery')?.indexOf("find ") == 0
      Session.set 'searchAdvancedActive', true

Template.advancedSearch.created = ->
  @_searchQueryHandle = null
  @_dateRangeHandle = null

Template.advancedSearch.rendered = ->
  @_searchQueryHandle?.stop()
  @_searchQueryHandle = Deps.autorun =>
    # Sync query unless change happened because of this input field itself
    # unless structuredQueryChangeLock > 0
    serialized = queryToSerialized(Session.get 'currentSearchQuery')
    $(@findAll '#filterForFind').val(serialized.find)
    $(@findAll '#filterForContaining').val(serialized.containing) 

  @_dateRangeHandle?.stop()
  @_dateRangeHandle = Deps.autorun =>
    statistics = Statistics.documents.findOne {},
      fields:
        minPublicationDate: 1
        maxPublicationDate: 1

    $publicationDate = $(@findAll '#publication-date')
    $slider = $(@findAll '#date-range')

    unless statistics?.minPublicationDate and statistics?.maxPublicationDate
      $publicationDate.val('')
      $slider.slider('destroy') if $slider.data('ui-slider')
      return

    min = moment.utc(statistics.minPublicationDate).year()
    max = moment.utc(statistics.maxPublicationDate).year()

    [start, end] = $publicationDate.val().split(' - ') if $publicationDate.val()
    start = parseInt(start) or min
    end = parseInt(end) or max

    start = min if start < min
    end = max if end > max

    $slider.slider
      disabled: true # TODO: For now disabled
      range: true
      min: min
      max: max
      values: [start, end]
      step: 1
      slide: (event, ui) ->
        $publicationDate.val(ui.values[0] + ' - ' + ui.values[1])

    $publicationDate.val($slider.slider('values', 0) + ' - ' + $slider.slider('values', 1))

  $(@findAll '.chzn').chosen
    no_results_text: "No match"

Template.advancedSearch.destroyed = ->
  @_searchQueryHandle?.stop()
  @_searchQueryHandle = null
  @_dateRangeHandle?.stop()
  @_dateRangeHandle = null

Template.advancedSearch.isOpen = ->
  'open' if Session.get 'searchAdvancedActive'

serializeSearchForm = (template) ->
  find: $(template.findAll '#filterForFind').val()
  containing: $(template.findAll '#filterForContaining').val()

serializedToQuery = (s) ->
  "find " + s.find + " containing \"" + s.containing + "\""

queryToSerialized = (q) ->
  tokens = q.split(' ')
  if tokens[0] != "find"
    query = q
  else
    if tokens[1] == "containing"
      query = tokens.slice(2).join(' ')
    else if tokens[2] == "containing"
      type = tokens[1]
      query = tokens.slice(3).join(' ')

    query = query?.replace /"/g, ''
    
  find: type or "anything"
  containing: query

Template.advancedSearch.events =
  'blur #filterForContaining': (e, template) ->
    structuredQueryChange(serializeSearchForm template)
    return # Make sure CoffeeScript does not return anything

  'change #filterForContaining': (e, template) ->
    structuredQueryChange(serializeSearchForm template)
    return # Make sure CoffeeScript does not return anything

  'keyup #filterForContaining': (e, template) ->
    structuredQueryChange(serializeSearchForm template)
    return # Make sure CoffeeScript does not return anything

  'paste #filterForContaining': (e, template) ->
    structuredQueryChange(serializeSearchForm template)
    return # Make sure CoffeeScript does not return anything

  'cut #filterForContaining': (e, template) ->
    structuredQueryChange(serializeSearchForm template)
    return # Make sure CoffeeScript does not return anything

  'submit #sidebar-search': (e, template) ->
    e.preventDefault()
    structuredQueryChange(serializeSearchForm template)
    return # Make sure CoffeeScript does not return anything

  'change #filterForFind': (e, template) ->
    structuredQueryChange(serializeSearchForm template)
    return # Make sure CoffeeScript does not return anything
