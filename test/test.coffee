async = require "async"
fs = require "fs"
process = (fileinfo, callback) ->
  fs.readFile fileinfo.fname, (err, data) ->
    if !err
      fileinfo.fline = data.toString().split('\n').length
    callback null
    
  
fs.readdir '.', (err, files) ->
  filelist = ('fname':file for file in files)
  q = async.queue(process, filelist.length)
  q.push filelist
  q.drain = (err) ->
    console.log('all processes finished')
    for fileinfo in filelist
      console.log "file:"+fileinfo.fname+" line is "+fileinfo.fline 
