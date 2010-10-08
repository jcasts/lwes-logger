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
  end


  def teardown
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


  def test_namespace=
    @logger.namespace = "test_namespace"
    assert_equal "TestNamespace", @logger.namespace
  end
end
