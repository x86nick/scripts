import json
import socket
from urllib2 import urlopen

#def lambda_handler(event, context):
    # TODO implement
    
    #url = 'https://www.google.com/'
    #response = urlopen( url)
    #req = urllib.request.Request(url,timeout=1000)
    #response = urllib.request.urlopen(req)
    #code = response.getcode()
    
import socket
import sys

def lambda_handler(event, context):
  # Create a TCP/IP socket
  sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
  sock.settimeout(5)
  #url="google.com"

  print socket.gethostbyname(url)
  
  # Connect the socket to the port where the server is listening
  server_address = (url, 443)
  print >>sys.stderr, 'connecting to %s port %s' % server_address
  sock.connect(server_address)
  print(sock)
  
  request_header = 'GET /status HTTP/1.0\r\n\r\n'
  sock.send(request_header)

  response = ''
  while True:
    recv = sock.recv(1024)
    if not recv:
        break
    response += recv 

  print response
  
  print sock.getpeername()[0]


  sock.close()  
