DEFAULT_TYPE = "anything"

@queryToSerialized = (q) ->
  return {} unless q
  q = q.trim().toLowerCase()
  tokens = q.split /\s+/
  if tokens[0] != "find"
    query = q
  else
    if tokens[1] == "containing"
      query = tokens.slice(2).join(' ')
    else if tokens[2] == "containing"
      type = tokens[1]
      type = type.capitalize() unless type == DEFAULT_TYPE
      query = tokens.slice(3).join(' ')
    else if not _.contains tokens, "containing"
      query = tokens.slice(1).join(' ')

    query = query?.replace /"/g, ''
    
  find: type or DEFAULT_TYPE
  containing: query

@serializedToQuery = (s) ->
  "find " + s.find + " containing \"" + s.containing + "\""