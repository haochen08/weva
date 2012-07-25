# -*- coding:utf-8 -*-
import cookielib, mechanize, urllib
def sqlite2cookie(filename):
    from pysqlite2 import dbapi2 as sqlite
    con = sqlite.connect(filename)
    cur = con.cursor()
    cur.execute("select host_key, path, secure, expires_utc, name, value from cookies where host_key='.weibo.com'")
    ftstr = ["FALSE","TRUE"]
    s = open("tp_cookie", "w")
    
    s.write("""\
 Netscape HTTP Cookie File
 http://www.netscape.com/newsref/std/cookie_spec.html
 This is a generated file!  Do not edit.
""")
    for item in cur.fetchall():
        s.write("%s\t%s\t%s\t%s\t%s\t%s\t%s\n" % (
            item[0], ftstr[item[0].startswith('.')], item[1],
            ftstr[item[2]], item[3], item[4], item[5]))
    s.close()
    cookie_jar = cookielib.MozillaCookieJar('tp_cookie')
    return cookie_jar
 
cookiejar = sqlite2cookie(r'/Users/chenhao/Library/Application Support/Google/Chrome/Default/Cookies')
br = mechanize.Browser()
# Browser options
br.set_cookiejar(cookiejar)
'''r = br.open('http://q.weibo.com/ajax/members/page',
                        urllib.urlencode({'page':str(page),'gid':gid}),
                        timeout=30).read()
'''
searchq = '韩寒' #文件开头用utf8（
r = br.open('http://s.weibo.com/weibo/' + urllib.quote(searchq)).read()
print r
