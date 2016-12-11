class HostManager
  attr_accessor :hosts
  private :hosts=, :hosts

  include BarkingIguana::Logging::Helper
  include BarkingIguana::Benchmark

  def initialize hosts = []
    self.hosts = hosts
    if hosts.any? { |h| h['uri'] !~ /^10\.8\./ }
      raise "Your hosts must be in the 10.8/16 CIDR to be managed by me"
    end
    write_file
  end

  def write_file
    logger.debug { "Writing Vagrantfile to #{vagrant_file_path}" }
    File.open vagrant_file_path, 'w' do |f|
      f.puts vagrant_file_content
    end
  end

  def destroy_all
    destroy *hosts.map { |h| h['name'] }
  end

  def vagrant_file_content
    ERB.new(File.read("test/templates/Vagrantfile.erb")).result __binding__
  end

  def vagrant_file_path
    File.join root, 'Vagrantfile'
  end

  def root
    @root ||= Dir.pwd
  end

  def active
    all.select { |h| h['state'] == 'running' }
  end

  def all
    refresh_status
    hosts
  end

  def refresh_status
    benchmark "refreshing host status" do
      status = vagrant.status.split(/\n/)
      hosts.each do |host|
        status.each do |line|
          if line =~ /^#{host['name']}\b/
            host['state'] = line.sub(host['name'], '').sub('(virtualbox)', '').strip
          end
        end
      end
    end
  end

  {
    launch: "up",
    shutdown: "halt",
    destroy: "destroy",
  }.each do |interface, command|
    define_method interface do |*host_names|
      if host_names.empty?
        logger.debug { "Not running anything because the hosts list is empty" }
      else
        host_names.sort!
        benchmark "running #{interface} for #{host_names.join(', ')}" do
          vagrant.public_send command, *host_names
        end
      end
    end
  end

  def find_by_name name
    all.detect { |h| h['name'] == name }
  end

  def vagrant
    @vagrant ||= Vagrant.new(vagrant_file_path)
  end
end
