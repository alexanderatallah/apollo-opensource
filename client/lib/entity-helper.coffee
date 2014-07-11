class @EntityHelper
  constructor: () ->
    @_entityLookupHandle = Deps.autorun =>
      highlightId = Session.get 'currentHighlightId'
      @lookupEntity(highlightId) if highlightId

  destroy: =>
    # We stop handles here and not just leave it to Deps.autorun to do it to cleanup in the right order
    @_entityLookupHandle?.stop()
    @_entityLookupHandle = null

  lookupEntity: (highlightId) =>
    Session.set 'entityLoading', true

    Meteor.call 'find-or-create-entity', highlightId, (error, entityId) =>
      Session.set 'entityLoading', false
      return Notify.meteorError error, true if error
      Session.set 'currentEntityId', entityId

  hasTextContent: (pageNumber) =>
    @_pages[pageNumber - 1]?.hasTextContent()

  getTextLayer: (pageNumber) =>
    @_pages[pageNumber - 1].$displayPage.find('.text-layer').get(0)

  extractText: (pageNumber) =>
    @_pages[pageNumber - 1].extractText()