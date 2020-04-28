require "helper"
require "fluent/plugin/in_azse.rb"

class AzseInputTest < Test::Unit::TestCase
  setup do
    Fluent::Test.setup
  end

  CONFIG = %[
    interval               1m
    tag_prefix             input.azse
  ]

  def create_driver(conf=CONFIG)
    Fluent::Test::Driver::Input.new(Fluent::AzseInput).configure(conf)
  end

  def shutdown_driver(driver)
    return unless driver.instance.instance_eval{ @thread }
    driver.instance.shutdown
    driver.instance.instance_eval{ @thread && @thread.join }
  end

  def test_configure
    d = create_driver
    assert_equal 'http://169.254.169.254/metadata/scheduledevents?api-version=2019-01-01', d.instance.endpoint
    assert_equal 60, d.instance.interval

    d = create_driver %[
      interval               20
      tag_prefix             input.azse
    ]
    assert_equal 'http://169.254.169.254/metadata/scheduledevents?api-version=2019-01-01', d.instance.endpoint
    assert_equal 20, d.instance.interval
    assert_equal 'input.azse', d.instance.tag_prefix
  end  
end