// Generated by CoffeeScript 1.3.3
(function() {
  var FOLLOWERS_LOW_LIMIT, TOKEN_EXPIRE_THRESHOLD, WEIBO_COOKIE_PATH, access_token, analyze, app_key, app_secret, async, get_weibo_cookie, http, https, lastTime, server, sqlite3, token_expire_time, token_gate_host, update_accesstoken, users, weibo_host_v1, weibo_host_v2;

  http = require('http');

  https = require('https');

  async = require('async');

  sqlite3 = require('sqlite3');

  weibo_host_v1 = "api.t.sina.com.cn";

  weibo_host_v2 = "api.weibo.com";

  token_gate_host = "open.weibo.com/tools/aj_apitest.php";

  app_key = "3805062853";

  app_secret = "3068b083821c6172522ad61d6bdd7b62";

  access_token = "2.00qE4goBVfeVJE7d6c1b66670jByjZ";

  FOLLOWERS_LOW_LIMIT = 500;

  TOKEN_EXPIRE_THRESHOLD = 10;

  WEIBO_COOKIE_PATH = "/Users/chenhao/Library/Application Support/Google/Chrome/Default/Cookies";

  token_expire_time = 0;

  lastTime = new Date().getTime();

  users = [];

  server = http.createServer(function(req, resp) {
    var client, keywords, options;
    keywords = require('url').parse(req.url, true)['query']['q'];
    console.log("Query keyword is " + keywords);
    if (keywords != null) {
      options = {
        host: weibo_host_v1,
        path: "/search.json?source=" + app_key + "&q=" + keywords
      };
      client = http.request(options, function(res) {
        var raw;
        res.setEncoding('utf8');
        raw = "";
        res.on('data', function(chunk) {
          return raw += chunk;
        });
        return res.on('end', function() {
          var content;
          content = JSON.parse(raw)['results'];
          if (content != null) {
            return update_accesstoken(function(err) {
              var q;
              if (!err) {
                q = async.queue(analyze, content.length);
                q.push(content);
                return q.drain = function() {
                  var data, weibo;
                  content = (function() {
                    var _i, _len, _results;
                    _results = [];
                    for (_i = 0, _len = content.length; _i < _len; _i++) {
                      weibo = content[_i];
                      if (weibo['user_followers_count'] >= FOLLOWERS_LOW_LIMIT) {
                        _results.push(weibo);
                      }
                    }
                    return _results;
                  })();
                  data = JSON.stringify({
                    'results': content
                  });
                  resp.writeHead(200, {
                    "Content-Type": "text/json"
                  });
                  resp.write(data, "utf8");
                  return resp.end();
                };
              }
            });
          }
        });
      });
      client.on('error', function(e) {
        return console.log("Request weibo with error " + e.message);
      });
      return client.end();
    }
  });

  server.listen(8000);

  get_weibo_cookie = function(callback) {
    var cookie, db;
    cookie = [];
    db = new sqlite3.Database(WEIBO_COOKIE_PATH);
    db.serialize(function() {
      return db.all("select host_key, path, secure, expires_utc, name, value from cookies where host_key='.weibo.com'", function(err, rows) {
        var row, _i, _len;
        if (!err) {
          for (_i = 0, _len = rows.length; _i < _len; _i++) {
            row = rows[_i];
            cookie.push(row.name + "=" + row.value);
          }
        }
        return callback(err, cookie.join(';'));
      });
    });
    return db.close();
  };

  update_accesstoken = function(callback) {
    var weibo_cookie;
    weibo_cookie = '';
    if (token_expire_time < TOKEN_EXPIRE_THRESHOLD) {
      return get_weibo_cookie(function(err, weibo_cookie) {
        var client, options;
        if (!err) {
          console.log("the weibo cookie is " + weibo_cookie);
          options = {
            host: token_gate_host,
            path: "?app_key=" + app_key + "&_t=0",
            method: "GET",
            headers: {
              Cookie: weibo_cookie,
              Referer: "http://open.weibo.com/tools/console"
            }
          };
          client = http.request(options, function(res) {
            var raw;
            res.setEncoding('utf8');
            raw = "";
            res.on('data', function(chunk) {
              return raw += chunk;
            });
            return res.on('end', function() {
              var data;
              data = JSON.parse(raw);
              if (data.token != null) {
                access_token = data.token;
                console.log("token refreshed..");
              }
              if (data.expires_in != null) {
                token_expire_time = data.expires_in;
              }
              return callback(true);
            });
          });
          return client.on('error', function(e) {
            return callback(false);
          });
        } else {
          return callback(false);
        }
      });
    } else {
      return callback(true);
    }
  };

  analyze = function(weibo, callback) {
    var client, list, options, user;
    list = (function() {
      var _i, _len, _results;
      _results = [];
      for (_i = 0, _len = users.length; _i < _len; _i++) {
        user = users[_i];
        if (user['id'] === weibo['from_user_id']) {
          _results.push(user);
        }
      }
      return _results;
    })();
    if (list.length === 0) {
      options = {
        host: weibo_host_v2,
        path: "/2/users/show.json?access_token=" + access_token + "&uid=" + weibo['from_user_id']
      };
      client = https.request(options, function(res) {
        var raw;
        res.setEncoding('utf8');
        raw = "";
        res.on('data', function(chunk) {
          return raw += chunk;
        });
        return res.on('end', function() {
          var data;
          data = JSON.parse(raw);
          if (data != null) {
            users.push(data);
            weibo['user_followers_count'] = data['followers_count'];
          }
          return callback(null);
        });
      });
      client.on('error', function(e) {
        weibo['user_followers_count'] = -1;
        console.log("Request weibo with error " + e.message);
        return callback(null);
      });
      return client.end();
    } else {
      weibo['user_followers_count'] = list[0]['followers_count'];
      return callback(null);
    }
  };

}).call(this);
