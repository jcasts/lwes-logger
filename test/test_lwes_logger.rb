require "rubygems"
require "test/unit"
require "tmpdir"
require "lwes_logger"
require "flexmock/test_unit"

class TestLwesLogger < Test::Unit::TestCase

  def setup
    @tmpdir = File.join Dir.tmpdir, "lwes_logger_tests_#{$$}"
    FileUtils.mkdir_p @tmpdir

    @mock_emitter = flexmock LWES::Emitter.new(
      :address    => "127.0.0.1",
      :iface      => '0.0.0.0',
      :port       => 12345,
      :heartbeat  => 1,
      :ttl        => 1
    )

    @lwes_emitter_class = flexmock LWES::Emitter
    @lwes_emitter_class.should_receive(:new).and_return(@mock_emitter)
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
    logger = LwesLogger.new "127.0.0.1",
      :log_device => ["#{@tmpdir}/test.log", 10, 10241024]
    logdev = logger.instance_variable_get("@logdev")

    assert Logger::LogDevice === logdev
    assert_equal "#{@tmpdir}/test.log", logdev.filename
    assert_equal 10, logdev.instance_variable_get("@shift_age")
    assert_equal 10241024, logdev.instance_variable_get("@shift_size")
  end


  def test_init_log_device_io
    logfile = File.open("#{@tmpdir}/test.log", "w+")

    logger = LwesLogger.new "127.0.0.1", :log_device => logfile
    logdev = logger.instance_variable_get("@logdev")

    assert_equal logfile, logdev.instance_variable_get("@dev")
    logfile.close
  end

end
