class @Entity extends AccessDocument
  # createdAt: timestamp when document was created
  # updatedAt: timestamp of this version
  # author:
  #   _id: author's person id
  #   slug: author's person id
  #   givenName
  #   familyName
  #   gravatarHash
  #   user
  #     username
  # name: unique name of this entity
  # highlights: list of highlights
  #   _id: highlight id
  # description: string description

  @Meta
    name: 'Entity'
    fields: =>
      author: @ReferenceField Person, ['slug', 'givenName', 'familyName', 'gravatarHash', 'user.username']
      highlights: [@ReferenceField Highlight, ['quote', 'publication._id'], true, 'referencingEntities']
    triggers: =>
      updatedAt: UpdatedAtTrigger ['author._id', 'publication._id', 'quote', 'target']

  hasReadAccess: (person) =>
    throw new Error "Not needed, entities are public for now"

  @requireReadAccessSelector: (person, selector) ->
    throw new Error "Not needed, entities are public for now"

  @readAccessPersonFields: ->
    throw new Error "Not needed, entities are public for now"

  @readAccessSelfFields: ->
    throw new Error "Not needed, entities are public for now"

  _hasMaintainerAccess: (person) =>
    # User has to be logged in
    return unless person?._id

    return true if @author._id is person._id

  @_requireMaintainerAccessConditions: (person) ->
    return [] unless person?._id

    [
      'author._id': person._id
    ]

  @maintainerAccessPersonFields: ->
    super

  @maintainerAccessSelfFields: ->
    fields = super
    _.extend fields,
      author: 1

  hasAdminAccess: (person) =>
    throw new Error "Not implemented"

  @requireAdminAccessSelector: (person, selector) ->
    throw new Error "Not implemented"
