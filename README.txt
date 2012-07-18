= lwes-logger

* http://yaks.me/lwes-logger

== DESCRIPTION:

Lwes based ruby logger for real-time logging.

== FEATURES:

* Send logging udp events with lwes.

* Optionally also log to a local file.

== SYNOPSIS:

  require 'lwes_logger'

  logger = LwesLogger.new '127.0.0.1',
            :log_device => "optional_backup_logfile.logs"

  logger.namespace = "MyApp::Logs"

  logger.meta_event.merge! :app_name => "myapp",
                           :user     => `whoami`

  logger.debug "This is a debug log event"
  logger.error "OH NOES!"

Will produce logs in the optional_backup_logfile.logs file and will
generate the following Lwes events:

  System::Startup[3]
  {
    SenderPort = 64885;
    ReceiptTime = 1286495516997;
    SenderIP = 127.0.0.1;
  }
  MyApp::Logs::Full[12]
  {
    SenderPort = 64885;
    message = This is a debug log event;
    progname = This is a debug log event;
    event_id = MyApp::Logs::Debug-3bd9c9d2-d272-11df-b9a6-00254bfffeb1;
    app_name = myapp;
    user = system_user;
    ReceiptTime = 1286495519612;
    SenderIP = 127.0.0.1;
    timestamp = Oct 07 16:51:59;
    hostname = example.com;
    severity = DEBUG;
    pid = 70884;
  }
  MyApp::Logs::Debug[12]
  {
    SenderPort = 64885;
    message = This is a debug log event;
    progname = This is a debug log event;
    event_id = MyApp::Logs::Debug-3bd9c9d2-d272-11df-b9a6-00254bfffeb1;
    app_name = myapp;
    user = system_user;
    ReceiptTime = 1286495519612;
    SenderIP = 127.0.0.1;
    timestamp = Oct 07 16:51:59;
    hostname = example.com;
    severity = DEBUG;
    pid = 70884;
  }
  MyApp::Logs::Full[12]
  {
    SenderPort = 64885;
    message = OH NOES!;
    progname = OH NOES!;
    event_id = MyApp::Logs::Error-3a38b5f6-d273-11df-b9a6-00254bfffeb1;
    app_name = myapp;
    user = system_user;
    ReceiptTime = 1286495519612;
    SenderIP = 127.0.0.1;
    timestamp = Oct 07 16:51:59;
    hostname = example.com;
    severity = ERROR;
    pid = 70884;
  }
  MyApp::Logs::Error[12]
  {
    SenderPort = 64885;
    message = OH NOES!;
    progname = OH NOES!;
    event_id = MyApp::Logs::Error-3a38b5f6-d273-11df-b9a6-00254bfffeb1;
    app_name = myapp;
    user = system_user;
    ReceiptTime = 1286495519612;
    SenderIP = 127.0.0.1;
    timestamp = Oct 07 16:51:59;
    hostname = example.com;
    severity = ERROR;
    pid = 70884;
  }
  System::Shutdown[7]
  {
    freq = 145;
    SenderPort = 64885;
    seq = 0;
    ReceiptTime = 1286495661890;
    total = 0;
    SenderIP = 127.0.0.1;
    count = 0;
  }

Notice that for convenience, logs events are broadcast to both the Full and
Severity (e.g. Debug) events. You can change the name of the full logs by
setting the full_logs_event attribute to a string, or turn full logs off
completely by setting it to false:

  logger.full_logs_event = "OtherFullLogs"
  logger.full_logs_event = false

Alternatively, if you'd rather only have full logs you can assign the
full_logs_only attribute:

  logger.full_logs_only = true

== REQUIREMENTS:

* lwes gem

* uuidtools gem

== INSTALL:

* sudo gem install lwes-logger

== LICENSE:

(The MIT License)

Copyright (c) 2010 Jeremie Castagna

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
'Software'), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED 'AS IS', WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
