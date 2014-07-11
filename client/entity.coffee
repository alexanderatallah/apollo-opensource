Template.entityDetail.loading = ->
  Session.get('entityLoading') and Session.get('currentHighlightId')

Template.entityDetail.notFound = ->
  !Session.get('currentEntityId') and !Session.get('entityLoading') and Session.get('currentHighlightId')

Template.entityDetail.entity = ->
  Entity.documents.findOne Session.get 'currentEntityId'