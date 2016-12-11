module BarkingIguana
  module Compound
    module Ansible
      class InventoryParser
        def self.get_variables(host, group_idx, hosts=nil)
          vars = {}
          p = self.get_properties

          # roles default
          p[group_idx]['roles'].each do |role|
            vars = load_vars_file(vars ,"roles/#{role}/defaults/main.yml")
          end

          # all group
          vars = load_vars_file(vars ,'group_vars/all', true)

          # each group vars
          if p[group_idx].has_key?('group')
            vars = load_vars_file(vars ,"group_vars/#{p[group_idx]['group']}", true)
          end

          # each host vars
          vars = load_vars_file(vars ,"host_vars/#{host}", true)

          # site vars
          if p[group_idx].has_key?('vars')
            vars = merge_variables(vars, p[group_idx]['vars'])
          end

          # roles vars
          p[group_idx]['roles'].each do |role|
            vars = load_vars_file(vars ,"roles/#{role}/vars/main.yml")
          end

          # multiple host and children dependencies group vars
          unless hosts.nil? || p[group_idx]["hosts_childrens"].nil?
            hosts_childrens = p[group_idx]["hosts_childrens"]
            next_find_target = hosts
            while(!next_find_target.nil? && hosts_childrens.size > 0)
              vars = load_vars_file(vars ,"group_vars/#{next_find_target}", true)
              group_vars_file = find_group_vars_file(hosts_childrens,next_find_target)
              next_find_target = group_vars_file
              hosts_childrens.delete(group_vars_file)
            end
          end

          return vars

        end

        # param  hash   {"server"=>["192.168.0.103"], "databases"=>["192.168.0.104"], "pg:children"=>["server", "databases"]}
        # param  search ":children"
        # param  k      "pg:children"
        # return {"server"=>["192.168.0.103"], "databases"=>["192.168.0.104"], "pg"=>["192.168.0.103", "192.168.0.104"]}
        def self.get_parent(hash,search,k)
          k_parent = k.gsub(search,'')
          arry = Array.new
          hash["#{k}"].each{|group|
            next if hash["#{group}"].nil?
            arry = arry + hash["#{group}"]
          }
          h = Hash.new
          h["#{k_parent}"] = arry
          return h
        end

        def self.load_targets(file)

          f = File.open(file).read
          groups = Hash.new
          group = ''
          hosts = Hash.new
          hosts.default = Hash.new
          f.each_line{|line|
            line = line.chomp
            # skip
            next if line.start_with?('#') #comment
            next if line.empty? == true   #null

            # get group
            if line.start_with?('[') && line.end_with?(']')
              group = line.gsub('[','').gsub(']','')
              groups["#{group}"] = Array.new
              next
            end

            # get host
            host_name = line.split[0]
            if group.empty? == false
              if groups.has_key?(line)
                groups["#{group}"] << line
                next
              elsif host_name.include?("[") && host_name.include?("]")
                # www[01:50].example.com
                # db-[a:f].example.com
                hostlist_expression(line,":").each{|h|
                  host = hosts[h.split[0]]
                  groups["#{group}"] << get_inventory_param(h).merge(host)
                }
                next
              else
                # 1つのみ、かつ:を含まない場合
                # 192.168.0.1
                # 192.168.0.1 ansible_ssh_host=127.0.0.1 ...
                host = hosts[host_name]
                groups["#{group}"] << get_inventory_param(line).merge(host)
                next
              end
            else
              if host_name.include?("[") && host_name.include?("]")
                hostlist_expression(line, ":").each{|h|
                  hosts[h.split[0]] = get_inventory_param(h)
                }
              else
                hosts[host_name] = get_inventory_param(line)
              end
            end
          }

          # parse children [group:children]
          search = Regexp.new(":children".to_s)
          groups.keys.each{|k|
            unless (k =~ search).nil?
              # get group parent & merge parent
              groups.merge!(get_parent(groups,search,k))
              # delete group children
              if groups.has_key?("#{k}") && groups.has_key?("#{k.gsub(search,'')}")
                groups.delete("#{k}")
              end
            end
          }
          return groups
        end

        # param ansible_ssh_port=22
        # return: hash
        def self.get_inventory_param(line)
          host = Hash.new
          # 初期値
          host['name'] = line
          host['port'] = 22
          if line.include?(":") # 192.168.0.1:22
            host['uri']  = line.split(":")[0]
            host['port'] = line.split(":")[1].to_i
            return host
          end
          # 192.168.0.1 ansible_ssh_port=22
          line.split.each{|v|
            unless v.include?("=")
              host['uri'] = v
            else
              key,value = v.split("=")
              host['port'] = value.to_i if key == "ansible_ssh_port" or key == "ansible_port"
              host['private_key'] = value if key == "ansible_ssh_private_key_file"
              host['user'] = value if key == "ansible_ssh_user" or key == "ansible_user"
              host['uri'] = value if key == "ansible_ssh_host" or key == "ansible_host"
              host['pass'] = value if key == "ansible_ssh_pass"
              host['connection'] = value if key == "ansible_connection"
            end
          }
          return host
        end
      end
    end
  end
end
