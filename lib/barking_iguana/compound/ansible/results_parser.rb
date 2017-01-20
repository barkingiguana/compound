module BarkingIguana
  module Compound
    module Ansible
      class ResultsParser
        attr_accessor :file
        private :file=, :file

        def initialize file
          self.file = file
        end

        def recap
          OpenStruct.new total_changes: total_changes
        end

        private

        def total_changes
          recap_text = File.read(file).split(/^PLAY RECAP \**$/)[-1].strip
          matches = recap_text.scan(/ changed=(\d+) /)
          matches[0].map(&:to_i).inject(&:+)
        end
      end
    end
  end
end
