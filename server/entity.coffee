# natural = Natural

class @Entity extends Entity
  @Meta
    name: 'Entity'
    replaceParent: true

  # A set of fields which are public and can be published to the client
  @PUBLISH_FIELDS: ->
    fields: {} # All

Meteor.methods
  'create-entity': (highlightId) ->
    check highlightId, DocumentId

    person = Meteor.person()
    throw new Meteor.Error 401, "User not signed in." unless person

    # TODO: Check whether target conforms to schema
    # TODO: Check the target (try to apply it on the server)

    highlight = Highlight.documents.findOne highlightId
    throw new Meteor.Error 400, "Invalid highlight." unless highlight

    createdAt = moment.utc().toDate()
    entity =
      createdAt: createdAt
      updatedAt: createdAt
      author:
        _id: Meteor.personId()
      name: highlight.quote
      highlights: [
        _id: highlightId
      ]

    entity = Entity.applyDefaultAccess person._id, entity

    Entity.documents.insert entity

  'find-or-create-entity': (highlightId) ->
    check highlightId, DocumentId

    entity = Entity.documents.findOne
      "highlights._id": highlightId

    return entity._id if entity

    Meteor.call 'create-entity', highlightId

Meteor.publish 'entities', ->
  Entity.documents.find {}, Entity.PUBLISH_FIELDS()
