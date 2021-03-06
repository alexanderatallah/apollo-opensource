# Used for global variable assignments in local scopes
root = @

searchLimitIncreasing = false

currentSearchQueryCount = ->
  (Session.get('currentSearchQueryCountPublications') or 0) + (Session.get('currentSearchQueryCountPersons') or 0)

Deps.autorun ->
  # Every time search query is changed, we reset counts
  # (We don't want to reset counts on currentSearchLimit change)
  Session.get 'currentSearchQuery'
  Session.set 'currentSearchQueryCountPublications', 0
  Session.set 'currentSearchQueryCountPersons', 0

  searchLimitIncreasing = false

Deps.autorun ->
  Session.set 'currentSearchQueryReady', false
  if Session.get('currentSearchLimit') and Session.get('currentSearchQuery')
    Session.set 'currentSearchQueryLoading', true
    Meteor.subscribe 'search-results', Session.get('currentSearchQuery'), Session.get('currentSearchLimit'),
      onReady: ->
        Session.set 'currentSearchQueryReady', true
        Session.set 'currentSearchQueryLoading', false
      onError: ->
        # TODO: Should we display some error?
        Session.set 'currentSearchQueryLoading', false
    # TODO: replace with Entity search results, Alex's temp
    Meteor.subscribe 'highlights'
  else
    Session.set 'currentSearchQueryLoading', false

Deps.autorun ->
  if Session.get 'searchActive'
    Meteor.subscribe 'statistics'

Template.results.created = ->
  $(window).on 'scroll.results', ->
    if $(document).height() - $(window).scrollTop() <= 2 * $(window).height()
      increaseSearchLimit 10

    return # Make sure CoffeeScript does not return anything

Template.results.rendered = ->
  if Session.get 'currentSearchQueryReady'
    searchLimitIncreasing = false
    # Trigger scrolling to automatically start loading more results until whole screen is filled
    $(window).trigger('scroll')

Template.results.destroyed = ->
  $(window).off '.results'

Template.results.events =
  'mouseenter .result-item': (e, template) ->
    $(template.findAll '.result-item.hover').removeClass('hover')
    $(e.target).addClass('hover')
    Session.set 'currentFocusedResult', $(e.target).find('.title a').text()

increaseSearchLimit = (pageSize) ->
  if searchLimitIncreasing
    return
  if Session.get('currentSearchLimit') < currentSearchQueryCount()
    searchLimitIncreasing = true
    Session.set 'currentSearchLimit', (Session.get('currentSearchLimit') or 0) + pageSize

Template.results.publications = ->
  if not Session.get('currentSearchLimit') or not Session.get('currentSearchQuery')
    return

  searchResult = SearchResult.documents.findOne
    name: 'search-results'
    query: Session.get 'currentSearchQuery'

  return if not searchResult

  Session.set 'currentSearchQueryCountPublications', searchResult.countPublications
  Session.set 'currentSearchQueryCountPersons', searchResult.countPersons

  Publication.documents.find
    'searchResult._id': searchResult._id
  ,
    sort: [
      ['searchResult.order', 'asc']
    ]
    limit: Session.get 'currentSearchLimit'

Template.resultsCount.publications = ->
  Session.get 'currentSearchQueryCountPublications'

Template.resultsCount.persons = ->
  Session.get 'currentSearchQueryCountPersons'

Template.results.noResults = ->
  Session.get('currentSearchQueryReady') and not currentSearchQueryCount()

Template.sidebar.entity = ->
  Session.get('currentFocusedResult')

Template.sidebar.documents = ->
  # TODO: not Session.get('currentSearchLimit') or ...
  if not Session.get('currentSearchQuery')
    return

  # searchResult = SearchResult.documents.findOne
  #   name: 'search-entities'
  #   query: Session.get 'currentSearchQuery'

  # return if not searchResult

  # Session.set 'currentSearchQueryCountEntities', searchResult.countHighlights

  # TODO: Alex, use real fulltext search
  # Highlight.documents.find
  #   quote: new RegExp Session.get('currentSearchQuery'), 'i'
    # limit: Session.get 'currentSearchLimit'

Template.resultsLoad.loading = ->
  Session.get('currentSearchQueryLoading')

Template.resultsLoad.more = ->
  Session.get('currentSearchQueryReady') and Session.get('currentSearchLimit') < currentSearchQueryCount()

Template.resultsLoad.events =
  'click .load-more': (e, template) ->
    e.preventDefault()
    searchLimitIncreasing = false # We want to force loading more in every case
    increaseSearchLimit 10

    return # Make sure CoffeeScript does not return anything

Template.resultsSearchInvitation.searchInvitation = ->
  not Session.get('currentSearchQuery')

Template.publicationSearchResult.events =
  'click .preview-link': (e, template) ->
    e.preventDefault()

    if template._publicationHandle
      # We ignore the click if handle is not yet ready
      $(template.findAll '.abstract').slideToggle('fast') if template._publicationHandle.ready()
    else
      template._publicationHandle = Meteor.subscribe 'publications-by-id', @_id, =>
        Deps.afterFlush =>
          $(template.findAll '.abstract').slideToggle('fast')

    return # Make sure CoffeeScript does not return anything

Template.publicationSearchResult.created = ->
  @_publicationHandle = null

Template.publicationSearchResult.rendered = ->
  $(@findAll '.scrubber').iscrubber()

Template.publicationSearchResult.destroyed = ->
  @_publicationHandle?.stop()
  @_publicationHandle = null

Template.publicationSearchResultTitle[method] = Template.publicationMetaMenuTitle[method] for method in ['created', 'rendered', 'destroyed']

Template.publicationSearchResultThumbnail.events
  'click li': (e, template) ->
    root.startViewerOnPage = @page
    # TODO: Change when you are able to access parent context directly with Meteor
    publication = @publication
    Meteor.Router.toNew Meteor.Router.publicationPath publication._id, publication.slug

Template.accessIcon.iconName = ->
  switch @access
    when Publication.ACCESS.OPEN then 'icon-public'
    when Publication.ACCESS.CLOSED then 'icon-closed'
    when Publication.ACCESS.PRIVATE then 'icon-private'
    else assert false

# We do not want location to be updated for every key press, because this really makes browser history hard to navigate
# TODO: This might make currentSearchQuery be overriden with old value if it happens that exactly after 500 ms user again presses a key, but location is changed to old value which sets currentSearchQuery and thus input field back to old value
updateSearchLocation = _.debounce (query) ->
  Meteor.Router.toNew Meteor.Router.searchPath query
, 500

Deps.autorun ->
  if Session.get 'searchActive'
    updateSearchLocation Session.get 'currentSearchQuery'
