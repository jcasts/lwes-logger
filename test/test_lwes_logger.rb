require "rubygems"
require "test/unit"
require "tmpdir"
require "lwes_logger"
require "flexmock/test_unit"

class TestLwesLogger < Test::Unit::TestCase

  def setup
    @tmpdir = File.join Dir.tmpdir, "lwes_logger_tests_#{$$}"
    FileUtils.mkdir_p @tmpdir

    @emitter_hash = {
      :address    => "127.0.0.1",
      :iface      => '0.0.0.0',
      :port       => 12345,
      :heartbeat  => 1,
      :ttl        => 1
    }

    @mock_emitter = flexmock LWES::Emitter.new(@emitter_hash)

    @lwes_emitter_class = flexmock LWES::Emitter
    @lwes_emitter_class.should_receive(:new).
      with(@emitter_hash).and_return(@mock_emitter)

    @logger = LwesLogger.new "127.0.0.1"

    @time = Time.now
    flexmock(Time).should_receive(:now).and_return(@time)

    flexmock(UUIDTools::UUID).should_receive(:timestamp_create).
      and_return("uuid_timestamp")
  end


  def teardown
    @mock_emitter.reset_emitted if @mock_emitter.respond_to? :reset_emitted
    FileUtils.rm_rf @tmpdir
  end


  def test_init
    logger = LwesLogger.new "127.0.0.1"

    assert LWES::Emitter === logger.emitter
    assert_equal "Full", logger.full_logs_event
    assert_equal false, logger.full_logs_only
    assert_equal "LwesLogger", logger.namespace
    assert_nil logger.instance_variable_get("@logdev")
  end


  def test_init_log_device
    log_device = ["#{@tmpdir}/test.log", 10, 10241024]

    @lwes_emitter_class.should_receive(:new).
      with(@emitter_hash.merge(:log_device => log_device)
      ).and_return(@mock_emitter)

    logger = LwesLogger.new "127.0.0.1", :log_device => log_device

    logdev = logger.instance_variable_get("@logdev")

    assert Logger::LogDevice === logdev
    assert_equal "#{@tmpdir}/test.log", logdev.filename
    assert_equal 10, logdev.instance_variable_get("@shift_age")
    assert_equal 10241024, logdev.instance_variable_get("@shift_size")
  end


  def test_init_log_device_io
    logfile = File.open("#{@tmpdir}/test.log", "w+")

    @lwes_emitter_class.should_receive(:new).
      with(@emitter_hash.merge(:log_device => logfile)
      ).and_return(@mock_emitter)

    logger = LwesLogger.new "127.0.0.1", :log_device => logfile
    logdev = logger.instance_variable_get("@logdev")

    assert_equal logfile, logdev.instance_variable_get("@dev")
    logfile.close
  end


  def test_init_emitter_options
    @lwes_emitter_class.should_receive(:new).with({
      :address    => "0.0.0.0",
      :iface      => "244.0.0.1",
      :port       => 54321,
      :heartbeat  => 5,
      :ttl        => 30
    }).at_least.once

    LwesLogger.new "0.0.0.0",
      :iface      => "244.0.0.1",
      :port       => 54321,
      :heartbeat  => 5,
      :ttl        => 30
  end


  def test_init_namespace
    @lwes_emitter_class.should_receive(:new).and_return @mock_emitter

    logger = LwesLogger.new "127.0.0.1", :namespace => "test_namespace"
    assert_equal "TestNamespace", logger.namespace
  end


  def test_append
    event_hash = @logger.build_log_event nil, "test log"

    log_device = StringIO.new("")

    @lwes_emitter_class.should_receive(:new).
      with(@emitter_hash.merge(:log_device => log_device)).
      and_return(@mock_emitter)

    add_emit_hooks @mock_emitter
    logger = LwesLogger.new "127.0.0.1", :log_device => log_device

    logger << "test log"

    assert_equal 2, @mock_emitter.emitted.length
    assert_equal ["LwesLogger::Full", event_hash], @mock_emitter.emitted[0]
    assert_equal ["LwesLogger::Any", event_hash], @mock_emitter.emitted[1]

    log_device.rewind
    assert_equal "test log", log_device.read
  end


  def test_add
    event_hash = @logger.build_log_event Logger::DEBUG, "test log"

    log_device = StringIO.new("")

    @lwes_emitter_class.should_receive(:new).
      with(@emitter_hash.merge(:log_device => log_device)).
      and_return(@mock_emitter)

    add_emit_hooks @mock_emitter
    logger = LwesLogger.new "127.0.0.1", :log_device => log_device

    logger.add Logger::DEBUG, "test log"
    args = [logger.send(:format_severity, Logger::DEBUG),
            @time, nil, "test log"]

    log_line = logger.send :format_message, *args

    assert_equal 2, @mock_emitter.emitted.length
    assert_equal ["LwesLogger::Full", event_hash], @mock_emitter.emitted[0]
    assert_equal ["LwesLogger::Debug", event_hash], @mock_emitter.emitted[1]

    log_device.rewind
    assert_equal log_line, log_device.read
  end


  def test_namespace=
    @logger.namespace = "test_namespace"
    assert_equal "TestNamespace", @logger.namespace
  end


  def test_build_log_event
    hash = @logger.build_log_event Logger::DEBUG,
                                   "log message",
                                   "log prog",
                                   :extra_data => "data"

    assert_equal({
      :extra_data => "data",
      :message    => "log message",
      :progname   => "log prog",
      :timestamp  => @time.strftime("%b %d %H:%M:%S"),
      :severity   => "DEBUG",
      :event_id   => "LwesLogger::Debug-uuid_timestamp",
      :hostname   => Socket.gethostname,
      :pid        => $$.to_s
    }, hash)
  end


  def test_build_log_event_overrides
    hash = @logger.build_log_event Logger::DEBUG,
                                   "log message",
                                   "log prog",
                                   :message => "overriden",
                                   :pid     => 0

    assert_equal "0", hash[:pid]
    assert_equal "overriden", hash[:message]
  end


  def test_build_log_event_message
    hash = @logger.build_log_event Logger::DEBUG, "log message", "log prog" do
             "msg from block"
           end
    assert_equal "log message", hash[:message]

    hash = @logger.build_log_event Logger::DEBUG, nil, "log prog" do
             "msg from block"
           end
    assert_equal "msg from block", hash[:message]

    hash = @logger.build_log_event Logger::DEBUG, nil, "log prog"
    assert_equal "log prog", hash[:message]
  end


  def test_build_log_event_severity
    hash = @logger.build_log_event nil
    assert_equal "ANY", hash[:severity]
  end


  def test_build_log_event_progname
    @logger.instance_variable_set("@progname", "inst progname")
    hash = @logger.build_log_event Logger::DEBUG
    assert_equal "inst progname", hash[:progname]
  end


  def test_build_log_event_proc_data
    @logger.meta_event_attr :test1 do
      "value1"
    end

    block = lambda{:value2}
    hash = @logger.build_log_event nil, nil, nil, :test2 => block

    assert_equal "value1", hash[:test1]
    assert_equal "value2", hash[:test2]
  end


  def test_emit_log
    event_hash = @logger.build_log_event Logger::DEBUG, "log msg"

    @mock_emitter.should_receive(:emit).with "LwesLogger::Full", event_hash
    @mock_emitter.should_receive(:emit).with "LwesLogger::Debug", event_hash

    @logger.emit_log Logger::DEBUG, "log msg"
  end


  def test_emit_log_full_only
    @logger.full_logs_only = true
    event_hash = @logger.build_log_event Logger::DEBUG, "log msg"

    add_emit_hooks @mock_emitter
    @logger.emit_log Logger::DEBUG, "log msg"

    assert_equal 1, @mock_emitter.emitted.length
    assert_equal ["LwesLogger::Full", event_hash], @mock_emitter.emitted.first
  end


  def test_emit_log_severity_only
    @logger.full_logs_event = false
    event_hash = @logger.build_log_event Logger::DEBUG, "log msg"

    add_emit_hooks @mock_emitter
    @logger.emit_log Logger::DEBUG, "log msg"

    assert_equal 1, @mock_emitter.emitted.length
    assert_equal ["LwesLogger::Debug", event_hash], @mock_emitter.emitted.first
  end


  def test_meta_event_attr
    @logger.meta_event_attr :test1, "value1"

    @logger.meta_event_attr :test2 do
      "value2"
    end

    @logger.meta_event_attr :test3, "value3" do
      "not this value!"
    end

    assert_equal "value1", @logger.meta_event[:test1]
    assert_equal "value2", @logger.meta_event[:test2].call
    assert_equal "value3", @logger.meta_event[:test3]
  end


  def test_call_format
    time = Time.now
    timestamp = time.strftime("%b %d %H:%M:%S")

    host = Socket.gethostname
    sev  = "ERROR"
    prog = "prog"
    msg  = "message"

    results = @logger.send(:call_format, sev, time, prog, msg)
    expected = "#{host} [#{timestamp}##{$$}] #{sev} -- #{prog}: #{msg}\n"

    assert_equal expected, results
  end


  def test_camelize
    assert_equal "TestThing",  @logger.send(:camelize, "test_thing")
    assert_equal "Test-thing", @logger.send(:camelize, "test-thing")
    assert_equal "Test-Thing", @logger.send(:camelize, "Test-_thing")
    assert_equal "Test_thing", @logger.send(:camelize, "test__thing")
    assert_equal "TESTTHING",  @logger.send(:camelize, "TEST_THING")
    assert_equal "TestThing",  @logger.send(:camelize, "TestThing")
  end


  private

  def add_emit_hooks emitter
    emitter.instance_eval do
      undef emit
      def emit *args
        @emitted ||= []
        @emitted << args
      end

      undef emitted if defined?(emitted)
      def emitted
        @emitted
      end

      undef reset_emitted if defined?(reset_emitted)
      def reset_emitted
        @emitted = []
      end

    end
  end
end
