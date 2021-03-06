Rule = GSS.Rule

class StyleSheet extends GSS.EventTrigger
  
  isScoped: false        
  
  ###    
  el:  Node
  engine:     Engine
  rules:      []
  isScoped:   Boolean  
  ###  
  constructor: (o = {}) ->  
    super
    
    for key, val of o
      @[key] = val  
    
    if !@engine then throw new Error "StyleSheet needs engine"
      
    @engine.addStyleSheet @
    
    GSS.styleSheets.push @
    
    @isRemote = false
    @remoteSourceText = null
    if @el
      tagName = @el.tagName
      if tagName is "LINK"
        @isRemote = true    
        
    @rules = []
    if o.rules      
      @addRules o.rules
    
    @loadIfNeeded()
    
    return @      
    
  addRules: (rules) ->
    @setNeedsInstall true
    for r in rules
      r.parent = @
      r.styleSheet = @      
      r.engine = @engine
      rule = new GSS.Rule r
      @rules.push rule
  
  # Load
  # ---------------------------------------------
  
  isLoading: false
  
  needsLoad: true  
  
  reload: ->
    @destroyRules()
    @_load()
  
  loadIfNeeded: () ->
    if @needsLoad
      @needsLoad = false
      @_load()
    @
  
  _load: ->    
    if @isRemote
      @_loadRemote()
    else if @el
      @_loadInline()
  
  _loadInline: ->
    #@destroyRules()
    @addRules GSS.get.readAST @el
  
  _loadRemote: () ->
    if @remoteSourceText
      return @addRules GSS.compile @remoteSourceText
    url = @el.getAttribute('href')
    if !url then return null
    req = new XMLHttpRequest    
    req.onreadystatechange = () =>
      return unless req.readyState is 4
      return unless req.status is 200
      @remoteSourceText = req.responseText.trim()
      @addRules GSS.compile @remoteSourceText
      @isLoading = false
      @trigger 'loaded'
    @isLoading = true
    req.open 'GET', url, true
    req.send null
  
  
  # Install
  # ---------------------------------------------
    
  needsInstall: false # flagged in @addRules
  
  setNeedsInstall: (bool) ->
    if bool
      @engine.setNeedsUpdate true
      @needsInstall = true
    else      
      @needsInstall = false
    
  install: ->
    if @needsInstall
      @setNeedsInstall false
      @_install()     
  
  reinstall: () ->
    @_install()
  
  _install: ->
    for rule in @rules
      rule.install()  
  
  reset: ->
    @setNeedsInstall true
    for rule in @rules
      rule.reset()
  
  # Destruction
  # ---------------------------------------------
  
  destroyRules: ->
    for rule in @rules
      rule.destroy()
    @rules = []
  
  destroy: () ->
    i = @engine.styleSheets.indexOf @
    @engine.styleSheets.splice i, 1
    
    i = GSS.styleSheets.indexOf @
    GSS.styleSheets.splice i, 1
    
    #...
  
  isRemoved: ->
    if @el and !document.body.contains(@el) and !document.head.contains(@el)
      return true
    return false
  
  
  # CSS dumping
  # ----------------------------------------
  
  needsDumpCSS: false
  
  setNeedsDumpCSS: (bool) ->
    # generally called by child rules
    if bool
      @engine.setNeedsDumpCSS true
      @needsDumpCSS = true
    else
      @needsDumpCSS = false
    
  
  dumpCSSIfNeeded: ->
    if @needsDumpCSS
      #@needsDumpCSS = false
      @dumpCSS()
    
  dumpCSS: ->
    css = ""
    for rule in @rules
      ruleCSS = rule.dumpCSS()
      css = css + ruleCSS if ruleCSS
    return css

StyleSheet.fromNode = (node) ->
  if node.gssStyleSheet then return node.gssStyleSheet
  #if !GSS.get.isStyleNode(node) then return null    
    
  engine = GSS(scope: GSS.get.scopeForStyleNode(node))  
  
  sheet = new GSS.StyleSheet {
    el: node
    engine: engine
    engineId: engine.id
  }
  node.gssStyleSheet = sheet
  return sheet




class StyleSheet.Collection
  
  constructor: ->
    collection = []
    for key, val of @
      collection[key] = val
    return collection
    
  install: ->
    for sheet in @
      sheet.install()
    @
  
  find: () ->
    nodes = document.querySelectorAll '[type="text/gss"], [type="text/gss-ast"]'
    for node in nodes
      sheet = GSS.StyleSheet.fromNode node
    @
  
  findAllRemoved: ->
    removed = []
    for sheet in @
      if sheet.isRemoved() then removed.push sheet
    return removed
    


GSS.StyleSheet = StyleSheet

GSS.styleSheets = new GSS.StyleSheet.Collection()

module.exports = StyleSheet
