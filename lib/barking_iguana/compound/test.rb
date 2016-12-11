class Test
  attr_accessor :suite
  private :suite=

  attr_accessor :directory
  private :directory=

  include BarkingIguana::Logging::Helper
  include BarkingIguana::Benchmark

  def initialize suite, directory
    self.suite = suite
    self.directory = directory
  end

  def name
    directory.sub(suite.directory + '/', '').tr('/', ':')
  end

  def stages
    return [ TestStage.new(self, directory) ] if simple_test?
    Dir[directory + '/*'].select { |d| File.directory? d }.map { |s| TestStage.new self, File.basename(s) }
  end

  def simple_test?
    File.exists? "#{directory}/playbook.yml"
  end

  def run
    benchmark "test #{name}" do
      begin
        stages.each &:run
      ensure
        teardown
      end
    end
  end

  def teardown
    benchmark "#{name}: destroying all hosts" do
      host_manager.destroy_all
    end
  end

  def host_manager
    @host_manger ||= HostManager.new(stages.map(&:hosts).flatten.uniq { |h| h['uri'] })
  end
end
