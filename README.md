# Viproxy

EventMachine Proxy DSL for writing high-performance transparent / intercepting proxies in Ruby.

# Original Project is em-proxy of Ilya Grigorik
- EngineYard tutorial: [Load testing your environment using em-proxy](http://docs.engineyard.com/em-proxy.html)
- [Slides from RailsConf 2009](http://bit.ly/D7oWB)
- [GoGaRuCo notes & Slides](http://www.igvita.com/2009/04/20/ruby-proxies-for-scale-and-monitoring/)
[![Build Status](https://travis-ci.org/igrigorik/em-proxy.png?branch=master)](https://travis-ci.org/igrigorik/em-proxy)

# Modified Project is viproxy of Fatih Ozavci

## Getting started

    $> ruby bin/viproxy
    Usage: viproxy [options]
    -l, --listen [PORT]              Port to listen on
    -d, --duplex [host:port, ...]    List of backends to duplex data to
    -r, --relay [hostname:port]      Relay endpoint: hostname:port
    -s, --socket [filename]          Relay endpoint: unix filename
    -z, --ssl                        Run in SSL mode
    -c, --sslcert [filename]         SSL certificate file (PEM)
    -f, --logfile [filename]         Log file
    -p, --regexfile [filename]       Replacement file
    -v, --verbose                    Run in debug mode

    $> ruby bin/viproxy -l 8080 -z -c cert.crt -f /tmp/x.log -v -d 127.0.0.1:8081 -r 127.0.0.1:8083

The above will start viproxy on port 8080, relay and respond with data from port 8083, and also (optional) duplicate all traffic to ports 8081 (and discard their responses).


## License

The MIT License - Copyright (c) 2010 Ilya Grigorik
