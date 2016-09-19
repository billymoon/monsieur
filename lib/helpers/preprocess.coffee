_ = require 'lodash'
fs = require 'fs'
path = require 'path'
illiterate = require 'illiterate'

module.exports = (app)->
  
  virtuallyIlliterate = {}
  
  app.hooks.pathserver.push (data)->
    
    app.server.use (req, res, next)->
      
      fallthrough = true
      
      _.each _.keys(app.handlers), (item, index)->
        
        ## TODO: safe alternative to `req._parsedUrl`
        replaced_path = req._parsedUrl.pathname.replace new RegExp("^\/?#{data.myurl}"), ""
        m = replaced_path.match new RegExp "^/?(.+)\\.#{app.handlers[item]?.chain}$"
        literate_path = "#{replaced_path}.md".replace(/^\//,'')
        compilable_path = !!m and "#{m[1]}.#{item}"
        literate_compilable_path = !!m and "#{m[1]}.#{item}.md"
        literate = null
        raw = null
        checkpath = (path_to_check)-> fs.existsSync path.resolve path.join data.mypath, path_to_check
        
        if !!fallthrough and (
            (checkpath(literate_path) and literate = true and raw = true) or
            !!m and (checkpath(compilable_path) or (checkpath(literate_compilable_path) and literate = true))
          )
          
          fallthrough = false
          currentpath = if !!raw then literate_path else if literate then literate_compilable_path else compilable_path
          currentpath = path.join data.mypath, currentpath
          str = fs.readFileSync(path.resolve currentpath).toString 'UTF-8'
          
          if !!literate
            illiterated = illiterate str
            _.each illiterated, (item)->
              virtuallyIlliterate[path.normalize(path.join(path.dirname(req._parsedUrl.pathname), item.filename))] = item.content
            str = illiterated.default
          
          if not raw then str = app.handlers[item].process str, path.resolve currentpath
          # process str with beforesend hooks
          for cb in app.hooks.beforesend
            str = cb str, req, app.program
          
          if !!literate and !!raw
            part = path.extname(replaced_path).replace(/^\./, '')
            ## TODO: perhaps use filetype for mime instead of plain ... #{part or 'plain'}"
            literate_mime = if app.mimes[part] then app.mimes[part] else "text/plain"
          
          res.set 'Content-Type', if !!literate_mime then "#{literate_mime}; charset=utf-8" else if !!raw then "text/#{item}; charset=utf-8" else "#{app.mimes[app.handlers[item]?.chain]}; charset=utf-8"
          res.set 'Content-Length', Buffer.byteLength(str, 'utf-8')
          res.end str
      
      if !!fallthrough && !!virtuallyIlliterate[path.normalize(req._parsedUrl.pathname)]

        fallthrough = false
        
        res.set 'Content-Type', "#{app.mimes[path.extname(req._parsedUrl.pathname).slice(1)] || 'text/' + path.extname(req._parsedUrl.pathname).slice(1)}; charset=utf-8"
        res.set 'Content-Length', Buffer.byteLength(virtuallyIlliterate[path.normalize(req._parsedUrl.pathname)], 'utf-8')
        res.end virtuallyIlliterate[path.normalize(req._parsedUrl.pathname)]

      next() if fallthrough