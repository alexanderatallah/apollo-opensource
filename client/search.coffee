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

@structuredQueryChange = (newQuery) ->
  oldQuery = Session.get 'currentSearchQuery'
  if "#{ oldQuery }" is "#{ newQuery.general }" # Make sure we compare primitive strings
    return

  # We increase the counter to signal that structured query invoked the change
  structuredQueryChangeLock++
  Deps.afterFlush ->
    Meteor.setTimeout ->
      structuredQueryChangeLock--
      assert structuredQueryChangeLock >= 0
    , 100 # ms after the flush we unlock

  # TODO: Add other fields from the sidebar
  Session.set 'currentSearchQuery', newQuery.general
  Session.set 'currentSearchLimit', INITIAL_SEARCH_LIMIT

Deps.autorun ->
  if !Session.get('searchAdvancedHasBeenToggled')
    if Session.get('currentSearchQuery').toLowerCase().indexOf(" where ") > -1
      Session.set 'searchAdvancedActive', true

Template.advancedSearch.created = ->
  @_searchQueryHandle = null
  @_dateRangeHandle = null

Template.advancedSearch.rendered = ->
  @_searchQueryHandle?.stop()
  @_searchQueryHandle = Deps.autorun =>
    # Sync input field unless change happened because of this input field itself
    $(@findAll '#general').val(Session.get 'currentSearchQuery') unless structuredQueryChangeLock > 0

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
    no_results_text: "No tag match"

Template.advancedSearch.destroyed = ->
  @_searchQueryHandle?.stop()
  @_searchQueryHandle = null
  @_dateRangeHandle?.stop()
  @_dateRangeHandle = null

Template.advancedSearch.isOpen = ->
  'open' if Session.get 'searchAdvancedActive'

interpretedIntoQuery = (template) ->
  # TODO: Add other fields as well
  general: $(template.findAll '#general').val()

Template.advancedSearch.events =
  'blur #general': (e, template) ->
    structuredQueryChange(interpretedIntoQuery template)
    return # Make sure CoffeeScript does not return anything

  'change #general': (e, template) ->
    structuredQueryChange(interpretedIntoQuery template)
    return # Make sure CoffeeScript does not return anything

  'keyup #general': (e, template) ->
    structuredQueryChange(interpretedIntoQuery template)
    return # Make sure CoffeeScript does not return anything

  'paste #general': (e, template) ->
    structuredQueryChange(interpretedIntoQuery template)
    return # Make sure CoffeeScript does not return anything

  'cut #general': (e, template) ->
    structuredQueryChange(interpretedIntoQuery template)
    return # Make sure CoffeeScript does not return anything

  'submit #sidebar-search': (e, template) ->
    e.preventDefault()
    structuredQueryChange(interpretedIntoQuery template)
    return # Make sure CoffeeScript does not return anything
