class @Url extends Document
  # createdAt: timestamp when document was created
  # updatedAt: timestamp of this version
  # lastActivity: time of the last url activity (for now same as updatedAt)
  # url: URL where document is pointing at
  # referencingAnnotations: list of (reverse field from Annotation.references.urls)
  #   _id: annotation id

  @Meta
    name: 'Url'
    triggers: =>
      updatedAt: UpdatedAtTrigger ['url']
