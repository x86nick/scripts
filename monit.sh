apt-get install monit

/etc/monit/conf.d


check host localhost with address 0.0.0.0
   start program = "/etc/init.d/my-service start"
   stop program = "/etc/init.d/my-service stop"
if failed url http://0.0.0.0:7070/seriveurl
   alert mail@domain.com
if failed url http://0.0.0.0:7070/hubspot
then restart



in monitrc

#
set httpd port 2812 and
    use address localhost
    allow localhost
