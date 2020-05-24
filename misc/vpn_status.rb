#!/usr/local/bin/ruby
# coding: UTF-8
require 'net/http'
require 'json'

servers = ['172.16.21.17','172.16.21.18']


@c = Hash.new
@count = 0
servers.each do |sc|
  @c[sc]= IO.popen("echo load-stats | nc -w 1 #{sc} 7505 | tail -1 | cut -d',' -f1 | cut -d'=' -f2").gets
  @c[sc] = @c[sc].sub("\n",'')
  @count = @count + @c[sc].to_i
end


file = File.open('/usr/local/www/vpn/index.html', 'w')
file.write('
<HTML>
<HEAD>
<meta http-equiv="Content-Type" content="text/html; charset=utf-8">
<meta http-equiv="refresh" content="60">
<TITLE>VPN Статус</TITLE>
</HEAD>
<body>
<h5>Список сотрудников подключенных к VPN (обновляется один раз в минуту)</h><br>')
file.write("Обновленно: #{Time.now}<br>")
file.write("Всего подключено: #{@count}<br>")

@count = 0
servers.each do |s|
 p s
 p @c["#{s}"]
 file.write("Сервер: #{s}<br>")
 file.write("Подключений: " + @c["#{s}"].to_s + "")
 file.write('<table><tr><td>Логин</td><td>ФИО</td><td>Депапртамент</td></tr>')
 clients = IO.popen("echo status 3 | nc -w 1 #{s} 7505 | awk '{print $13}' | grep ^\[1-9]",'r')
 clients.each do |c|
   #@count = @count +1
   c = c.sub("\n",'')
   p c
   uri = URI("http://wiki.company.local/us/index.php?jid=#{c}&type=json")
   res = Net::HTTP.get_response(uri)
   if res.body.size > 4
     data = JSON.parse(res.body)
     file.write("<tr><td>#{data['employees_login']}</td><td>#{data['employees_name']}</td><td>#{data['subdivision_full_name']}</td></tr>")
  else
    file.write("<tr><td>#{c}</td><td>Не определенно</td><td>Не определенно</td></tr>")
  end
 end
 file.write('</table>')
end

file.write("</BODY></HTML>")
file.close
