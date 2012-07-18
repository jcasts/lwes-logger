require 'socket'
require 'logger'

require 'rubygems'
require 'lwes'
require 'uuid'

##
# Lwes based ruby logger for real-time logging.

class LwesLogger < Logger

  VERSION = '1.0.4'

  HOSTNAME = Socket.gethostname
  FORMAT   = "%s [%s#%d] %5s -- %s: %s\n"
  DATETIME_FORMAT = "%b %d %H:%M:%S"


  # The default event data to pass along with the lwes event.
  attr_reader :meta_event

  # The name of the event to emit all severity types to.
  # Will not emit to the full logs event if set to nil or false.
  # Defaults to "Full"
  attr_accessor :full_logs_event

  # Don't segregate by severity and only emit events to Namespace::Full.
  # Defaults to false.
  attr_accessor :full_logs_only

  # Base lwes namespace for events.
  attr_reader :namespace

  # The lwes event emitter.
  attr_reader :emitter

  # Format of the timestamp in the lwes events.
  # Note: If using a custom formatter, this property will only
  # apply to lwes events. Defaults to DATETIME_FORMAT.
  attr_accessor :datetime_format


  ##
  # Creates a new LwesLogger. Supports the following options:
  # :log_device:: Supports the same arguments as Logger.new - default: nil
  # :namespace::        Lwes root event namespace - default: "LwesLogger"
  # :datetime_format::  Timestamp format in lwes logs - default: DATETIME_FORMAT
  # :iface::            Forwarded to LWES::Event.new - default: "0.0.0.0"
  # :port::             Forwarded to LWES::Event.new - default: 12345
  # :heartbeat::        Forwarded to LWES::Event.new - default: 1
  # :ttl::              Forwarded to LWES::Event.new - default: 1


  def initialize ip_address, options={}
    args = [options[:log_device]].flatten
    super(*args)

    @meta_event = {
      :hostname => HOSTNAME,
      :pid      => $$.to_s
    }

    @datetime_format = options[:datetime_format] || DATETIME_FORMAT

    @full_logs_event = "Full"
    @full_logs_only  = false

    @formatter  = method(:call_format)
    @namespace  = camelize options[:namespace] || "LwesLogger"
    @emitter    = lwes_emitter ip_address, options
  end


  ##
  # Dump given message to the log device without any formatting.
  # Creates an LwesLogger::Any event.@options[:request].

  def << msg
    emit_log nil, msg
    super
  end


  ##
  # Log to both lwes and the log device, if given.

  def add severity, message=nil, progname=nil, &block
    return true if severity < @level

    emit_log severity, message, progname, &block
    super
  end

  alias log add


  ##
  # Emits an lwes logging event. Setting the data argument will
  # pass additional data to the emitted event.

  def emit_log severity, message=nil, progname=nil, data={}, &block
    event_hash = build_log_event severity, message, progname, data, &block

    dump_event = [@namespace, @full_logs_event].join("::")
    @emitter.emit dump_event, event_hash if @full_logs_event

    event_name = [@namespace, event_hash[:severity].capitalize].join("::")
    @emitter.emit event_name, event_hash unless @full_logs_only
  end


  ##
  # Creates an lwes event hash with log data.

  def build_log_event severity, message=nil, progname=nil, data={}, &block
    severity ||= UNKNOWN
    severity = format_severity(severity)

    progname ||= @progname
    message  ||= block.call if block_given?
    message  ||= progname

    event_id =
      "#{@namespace}::#{severity.capitalize}-" + UUID.generate

    event_hash = @meta_event.merge \
      :message   => message.to_s.gsub(/\e\[.*?m/, ''),
      :progname  => progname.to_s,
      :severity  => severity,
      :timestamp => Time.now.strftime(@datetime_format),
      :event_id  => event_id

    event_hash.merge! data

    event_hash.each do |key, val|
      val = val.call if Proc === val
      event_hash[key] = val.to_s
    end

    event_hash
  end


  ##
  # Set the emitter namespace.

  def namespace= str
    @namespace = camelize str
  end


  ##
  # Access the meta-event hash to set default values. If given a key and block,
  # the block will be run on every log output.

  def meta_event_attr key, value=nil, &block
    @meta_event[key] = value || (block if block_given?)
  end


  private


  def call_format severity, time, progname, message
    FORMAT % [
      HOSTNAME,
      time.strftime(@datetime_format),
      $$,
      severity,
      progname,
      message
    ]
  end


  def lwes_emitter ip_address, options={}
    options = {
      :address    => ip_address,
      :iface      => '0.0.0.0',
      :port       => 12345,
      :heartbeat  => 1,
      :ttl        => 1
    }.merge options

    LWES::Emitter.new options
  end


  def camelize string
    string.gsub(/(_|^)./i){|s| s[-1..-1].upcase}
  end
end
