class @Annotation extends ReadAccessDocument
  # access: 0 (private, ACCESS.PRIVATE), 1 (public, ACCESS.PUBLIC)
  # readPersons: if private access, list of persons who have read permissions
  # readGroups: if private access, list of groups who have read permissions
  # maintainerPersons: list of persons who have maintainer permissions
  # maintainerGroups: list of groups who have maintainer permissions
  # adminPersons: list of persons who have admin permissions
  # adminGroups: list of groups who have admin permissions
  # createdAt: timestamp when document was created
  # updatedAt: timestamp of this version
  # lastActivity: time of the last annotation activity (commenting)
  # author:
  #   _id: person id
  #   slug
  #   givenName
  #   familyName
  #   gravatarHash
  #   user
  #     username
  # body: in HTML
  # publication:
  #   _id: publication's id
  # references: made in the body of annotation or comments
  #   highlights: list of
  #     _id
  #   annotations: list of
  #     _id
  #   publications: list of
  #     _id
  #     slug
  #     title
  #   persons: list of
  #     _id
  #     slug
  #     givenName
  #     familyName
  #     gravatarHash
  #     user
  #       username
  #   groups: list of
  #     _id
  #     slug
  #     name
  #   tags: list of
  #     _id
  #     name: ISO 639-1 dictionary
  #     slug: ISO 639-1 dictionary
  #   collections: list of
  #     _id
  #     slug
  #     name
  #   comments: list of
  #     _id
  #   urls: list of
  #     _id
  #     url
  # tags: list of
  #   tag:
  #     _id
  #     name: ISO 639-1 dictionary
  #     slug: ISO 639-1 dictionary
  # referencingAnnotations: list of (reverse field from Annotation.references.annotations)
  #   _id: annotation id
  # license: license information, if known
  # inside: list of groups this annotations was made/shared inside
  #   _id
  #   slug
  #   name
  # local (client only): if it exists this is just a temporary annotation on the client side, 1 (automatically created, LOCAL.AUTOMATIC), 2 (user changed the content, LOCAL.CHANGED)
  # editing (client only): is this annotation being edited

  @Meta
    name: 'Annotation'
    fields: =>
      maintainerPersons: [@ReferenceField Person, ['slug', 'givenName', 'familyName', 'gravatarHash', 'user.username']]
      maintainerGroups: [@ReferenceField Group, ['slug', 'name']]
      adminPersons: [@ReferenceField Person, ['slug', 'givenName', 'familyName', 'gravatarHash', 'user.username']]
      adminGroups: [@ReferenceField Group, ['slug', 'name']]
      author: @ReferenceField Person, ['slug', 'givenName', 'familyName', 'gravatarHash', 'user.username']
      publication: @ReferenceField Publication, [], true, 'annotations'
      references:
        highlights: [@ReferenceField Highlight, [], true, 'referencingAnnotations']
        annotations: [@ReferenceField 'self', [], true, 'referencingAnnotations']
        publications: [@ReferenceField Publication, ['slug', 'title'], true, 'referencingAnnotations']
        persons: [@ReferenceField Person, ['slug', 'givenName', 'familyName', 'gravatarHash', 'user.username'], true, 'referencingAnnotations']
        groups: [@ReferenceField Group, ['slug', 'name'], true, 'referencingAnnotations']
        # TODO: Are we sure that we want a reverse field for tags? This could become a huge list for popular tags.
        tags: [@ReferenceField Tag, ['name', 'slug'], true, 'referencingAnnotations']
        collections: [@ReferenceField Collection, ['slug', 'name'], true, 'referencingAnnotations']
        # TODO: Are we sure that we want a reverse field for urls? This could become a huge list for popular urls.
        comments: [@ReferenceField Comment, [], true, 'referencingAnnotations']
        urls: [@ReferenceField Url, ['url'], true, 'referencingAnnotations']
      tags: [
        tag: @ReferenceField Tag, ['name', 'slug']
      ]
      inside: [@ReferenceField Group, ['slug', 'name']]
    # We do not see referencing something as an event which should update lastActivity of a referenced document.
    # Additionally, we update lastActivity when there is a constructive change, like adding to a group, and not when
    # document is being removed. When value changes we update just the related lastActivity of a new value, not old one.
    triggers: =>
      updatedAt: UpdatedAtTrigger ['author._id', 'body', 'publication._id', 'tags.tag._id', 'license', 'inside._id']
      personLastActivity: RelatedLastActivityTrigger Person, ['author._id'], (doc, oldDoc) -> doc.author?._id
      publicationLastActivity: RelatedLastActivityTrigger Publication, ['publication._id'], (doc, oldDoc) -> doc.publication?._id
      tagsLastActivity: RelatedLastActivityTrigger Tag, ['tags.tag._id'], (doc, oldDoc) ->
        newTags = (tag.tag._id for tag in doc.tags or [])
        oldTags = (tag.tag._id for tag in oldDoc.tags or [])
        _.difference newTags, oldTags
      groupsLastActivity: RelatedLastActivityTrigger Group, ['inside._id'], (doc, oldDoc) ->
        newGroups = (group._id for group in doc.inside or [])
        oldGroups = (group._id for group in oldDoc.inside or [])
        _.difference newGroups, oldGroups

  _hasMaintainerAccess: (person) =>
    # User has to be logged in
    return unless person?._id

    # TODO: Implement karma points for public documents

    return true if @author._id is person._id

    return true if person._id in _.pluck @maintainerPersons, '_id'

    personGroups = _.pluck person.inGroups, '_id'
    documentGroups = _.pluck @maintainerGroups, '_id'

    return true if _.intersection(personGroups, documentGroups).length

  @_requireMaintainerAccessConditions: (person) ->
    return [] unless person?._id

    [
      'author._id': person._id
    ,
      'maintainerPersons._id': person._id
    ,
      'maintainerGroups._id':
        $in: _.pluck person.inGroups, '_id'
    ]

  _hasAdminAccess: (person) =>
    # User has to be logged in
    return unless person?._id

    # TODO: Implement karma points for public documents

    return true if person._id in _.pluck @adminPersons, '_id'

    personGroups = _.pluck person.inGroups, '_id'
    documentGroups = _.pluck @adminGroups, '_id'

    return true if _.intersection(personGroups, documentGroups).length

  @_requireAdminAccessConditions: (person) ->
    return [] unless person?._id

    [
      'adminPersons._id': person._id
    ,
      'adminGroups._id':
        $in: _.pluck person.inGroups, '_id'
    ]

  @defaultAccess: ->
    @ACCESS.PRIVATE

  @applyDefaultAccess: (personId, document) ->
    document = super

    if personId and personId not in _.pluck document.adminPersons, '_id'
      document.adminPersons ?= []
      document.adminPersons.push
        _id: personId
    if document.author?._id and document.author._id not in _.pluck document.adminPersons, '_id'
      document.adminPersons ?= []
      document.adminPersons.push
        _id: document.author._id

    document
