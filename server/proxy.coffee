#TODO
# 1. handle token expiration
# 2. error handling
http = require 'http'
https = require 'https'
async = require 'async'
weibo_host_v1 = "api.t.sina.com.cn"  #http, for weibo search API
weibo_host_v2 = "api.weibo.com" #https, for other APIs
app_key = "3805062853"
access_token = "2.00qE4goBVfeVJE7d6c1b66670jByjZ"
FOLLOWERS_LOW_LIMIT = 500
users = []

server = http.createServer (req, resp) ->
  keywords = require('url').parse(req.url, true)['query']['q']
  console.log "Query keyword is "+keywords
  if keywords?
    options = 
      host: weibo_host_v1
      path: "/search.json?source="+app_key+"&q="+keywords
    client = http.request options, (res) ->
      res.setEncoding 'utf8'
      raw = ""
      res.on 'data', (chunk) ->
        raw += chunk
      res.on 'end',  ->
        content = JSON.parse(raw)['results']
        if content?
          q = async.queue analyze, content.length
          q.push content
          q.drain = ->
            content = (weibo for weibo in content when weibo['user_followers_count'] >= FOLLOWERS_LOW_LIMIT)
            data = JSON.stringify('results': content)
            resp.writeHead 200, 
              "Content-Type": "text/json"
            resp.write data, "utf8"
            resp.end()

    client.on 'error', (e) ->
      console.log "Request weibo with error "+e.message
    client.end()  

server.listen 8000
 
# add user information to the weibo
analyze = (weibo, callback) ->
  list = (user for user in users when user['id'] is weibo['from_user_id'])
  if list.length is 0
    options = 
      host: weibo_host_v2
      path: "/2/users/show.json?access_token="+access_token+"&uid="+weibo['from_user_id']
    client = https.request options, (res) ->
      res.setEncoding 'utf8'
      raw = ""
      res.on 'data', (chunk) ->
        raw += chunk
      res.on 'end', ->
        data = JSON.parse(raw)
        if data?
          users.push(data)
          weibo['user_followers_count'] = data['followers_count']
        callback null  
    client.on 'error', (e) ->
      weibo['user_followers_count'] = -1
      console.log "Request weibo with error "+e.message
      callback null
    client.end()
  else
    weibo['user_followers_count'] = list[0]['followers_count']
    callback null
      
    
                     
          
  
  
