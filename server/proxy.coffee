#TODO
# 1. handle token expiration
# 2. error handling
http = require 'http'
https = require 'https'
async = require 'async'
sqlite3 = require 'sqlite3'
weibo_host_v1 = "api.t.sina.com.cn"  #http, for weibo search API
weibo_host_v2 = "api.weibo.com" #https, for other APIs
token_gate_host = "open.weibo.com"
app_key = "3805062853"
app_secret="3068b083821c6172522ad61d6bdd7b62"
access_token = "2.00qE4goBVfeVJE7d6c1b66670jByjZ"
FOLLOWERS_LOW_LIMIT = 500
TOKEN_EXPIRE_THRESHOLD = 10
WEIBO_COOKIE_PATH = "/Users/chenhao/Library/Application Support/Google/Chrome/Default/Cookies"

token_expire_time = 0;
lastTime = new Date().getTime()
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
          update_accesstoken (err) ->
            if !err
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

get_weibo_cookie = (callback) ->
  cookie = []
  db = new sqlite3.Database(WEIBO_COOKIE_PATH)
  db.serialize ->
    db.all "select host_key, path, secure, expires_utc, name, value from cookies where host_key='.weibo.com'", (err, rows) ->
      if !err
        cookie.push row.name + "=" + row.value for row in rows
      callback err, cookie.join ';'

  db.close()
  
   
update_accesstoken = (callback) ->
  #token_expire_time -= ((new Date().getTime()) - lastTime.getTime()) / 1000
  weibo_cookie = ''
  if token_expire_time < TOKEN_EXPIRE_THRESHOLD
    get_weibo_cookie (err, weibo_cookie) ->
      if !err
        console.log "the weibo cookie is "+weibo_cookie
        options = 
          host: token_gate_host
          path: "/tools/aj_apitest.php?appkey="+app_key
          method: "GET"
          #headers: 
           # 'Cookie': weibo_cookie
        console.log options   
        client = http.request options, (res) ->
          res.setEncoding 'utf8'
          raw = ""
          res.on 'data', (chunk) ->
            raw += chunk
            console.log "Get data"+chunk
          res.on 'end', ->
            console.log "parse token finished.."
            data = JSON.parse(raw)
            if data.token?
              access_token = data.token
              console.log "token refreshed with "+access_token
            if data.expires_in?
              token_expire_time = data.expires_in
            callback true
        client.on 'error', (e) ->
          callback false
      else
        callback false
  else
    callback true
          
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
      
    
                     
          
  
  
