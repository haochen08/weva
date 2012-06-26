// Generated by CoffeeScript 1.3.3
(function() {
  var async, fs, process;

  async = require("async");

  fs = require("fs");

  process = function(fileinfo, callback) {
    return fs.readFile(fileinfo.fname, function(err, data) {
      if (!err) {
        fileinfo.fline = data.toString().split('\n').length;
      }
      return callback(null);
    });
  };

  fs.readdir('.', function(err, files) {
    var file, filelist, q;
    filelist = (function() {
      var _i, _len, _results;
      _results = [];
      for (_i = 0, _len = files.length; _i < _len; _i++) {
        file = files[_i];
        _results.push({
          'fname': file
        });
      }
      return _results;
    })();
    q = async.queue(process, filelist.length);
    q.push(filelist);
    return q.drain = function(err) {
      var fileinfo, _i, _len, _results;
      console.log('all processes finished');
      _results = [];
      for (_i = 0, _len = filelist.length; _i < _len; _i++) {
        fileinfo = filelist[_i];
        _results.push(console.log("file:" + fileinfo.fname + " line is " + fileinfo.fline));
      }
      return _results;
    };
  });

}).call(this);
