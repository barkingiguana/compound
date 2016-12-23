class Vagrant
  attr_accessor :manager
  private :manager=, :manager

  attr_accessor :vagrant_file_template_path
  private :vagrant_file_template_path=, :vagrant_file_template_path

  attr_accessor :root
  private :root=, :root

  attr_accessor :environment
  private :environment=, :environment

  def initialize manager, options = {}
    self.manager = manager
    self.vagrant_file_template_path = options[:vagrant_file_template_path] || File.expand_path('../../../../resources/Vagrantfile.erb', __FILE__)
    self.root = options[:root] || Dir.pwd
    self.environment = options[:environment] || {}
  end

  include BarkingIguana::Logging::Helper
  include BarkingIguana::Benchmark

  {
    up: "",
    status: "",
    halt: "-f",
    destroy: "-f"
  }.each_pair do |command, always_args|
    define_method command do |*passed_args|
      logger.debug { "COMMAND: #{command.inspect}, PASSED_ARGS: #{passed_args.inspect}, ALWAYS_ARGS: #{always_args.inspect}" }
      merged_args = ([always_args] + passed_args).flatten.join(' ').strip
      logger.debug { "MERGED ARGS: #{merged_args.inspect}" }
      command_line = "/usr/local/bin/vagrant #{command} #{merged_args}".strip
      logger.debug { "COMMAND LINE: #{command_line.inspect}" }
      c = Mixlib::ShellOut.new command_line, cwd: root, env: environment, live_stream: logger
      benchmark "running command #{command_line.inspect} in #{root.inspect} with env #{environment.inspect}" do
        c.run_command
      end
      c.error!
      c.stdout
    end
  end

  def write_vagrant_file
    logger.debug { "Writing Vagrantfile to #{vagrant_file_path}" }
    File.open vagrant_file_path, 'w' do |f|
      f.puts vagrant_file_content
    end
  end

  def assign_ip_addresses
    hosts.each do |h|
      next if valid_ip_address? h.ip_address
      ip_address = next_available_ip_address
      logger.debug { "Assigning #{h.name} an IP address: #{ip_address}" }
      h.assign_ip_address ip_address
    end
  end

  def prepare
    assign_ip_addresses
    write_vagrant_file
  end

  def vagrant_file_content
    ERB.new(vagrant_file_template).result binding
  end

  def vagrant_file_template
    File.read vagrant_file_template_path
  end

  def vagrant_file_path
    File.join root, 'Vagrantfile'
  end

  def refresh_status
    current_status = status.split(/\n/)
    hosts.each do |host|
      current_status.each do |line|
        if line =~ /^#{host.name}\b/
          host.state = line.sub(host.name, '').sub('(virtualbox)', '').strip
        end
      end
    end
  end

  private

  def hosts
    manager.hosts
  end

  def next_available_ip_address
    unassigned_ip_addresses.shift
  end

  def valid_ip_address? ip_address
    ip_address =~ /^10\.8\./
  end

  def unassigned_ip_addresses
    @unassigned_ip_addresses ||= begin
      assignable_ip_addresses = (10..200).to_a.map { |dd| "10.8.42.#{dd}" }
      assigned_ip_addresses = hosts.map(&:ip_address)
      assignable_ip_addresses - assigned_ip_addresses
                                 end
  end
end
