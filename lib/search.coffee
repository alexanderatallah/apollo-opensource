@queryToSerialized = (q) ->
  return {} unless q
  tokens = q.split /\s+/
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

@serializedToQuery = (s) ->
  "find " + s.find + " containing \"" + s.containing + "\""