# frozen_string_literal: true

# Copyright 2019 Tristan Robert

# This file is part of ForemanFogProxmox.

# ForemanFogProxmox is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.

# ForemanFogProxmox is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.

# You should have received a copy of the GNU General Public License
# along with ForemanFogProxmox. If not, see <http://www.gnu.org/licenses/>.

module ForemanFogProxmox
    module ProxmoxComputeAttributes

        def host_compute_attrs(host)
            super.tap do |_attrs|
              ostype = host.compute_attributes['config_attributes']['ostype']
              type = host.compute_attributes['type']
              case type
              when 'lxc'
                host.compute_attributes['config_attributes'].store('hostname', host.name)
              when 'qemu'
                raise ::Foreman::Exception, format(_('Operating system family %<type>s is not consistent with %<ostype>s'), type: host.operatingsystem.type, ostype: ostype) unless compute_os_types(host).include?(ostype)
              end
            end
          end
      
          def vm_compute_attributes(vm)
            vm_attrs = {}
            if vm.respond_to?(:config)
              vm_attrs = vm_attrs.merge(vmid: vm.identity, node_id: vm.node_id, type: vm.type)
              if vm.config.respond_to?(:disks)
                vm_attrs[:volumes_attributes] = Hash[vm.config.disks.each_with_index.map { |disk, idx| [idx.to_s, disk.attributes] }]
              end
              if vm.config.respond_to?(:interfaces)
                vm_attrs[:interfaces_attributes] = Hash[vm.config.interfaces.each_with_index.map { |interface, idx| [idx.to_s, interface.attributes] }]
              end
              vm_attrs[:config_attributes] = vm.config.attributes.reject { |key, value| [:disks, :interfaces, :vmid, :node_id, :node, :type].include?(key) || !vm.config.respond_to?(key) || ForemanFogProxmox::Value.empty?(value.to_s) || Fog::Proxmox::DiskHelper.disk?(key.to_s) || Fog::Proxmox::NicHelper.nic?(key.to_s) }
            end
            vm_attrs
          end 

    end

end