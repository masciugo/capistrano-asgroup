require 'rubygems'
require 'aws-sdk'
require 'capistrano'

module Capistrano
    class Asgroup
        # How this works
        #
        # This gem will fetch only running instances that have an autoscale tag name you specified
        # It will then reject the roles of :db and the :primary => true for all servers found but the first one
        # this is to make sure a single working task does not run in parallel
        #
        # you end up as if you defined the servers yourself like so:
        # server ip_address1, :app :db, :web, :primary => true
        # server ip_address2, :app, :web
        # server ip_address3, :app, :web
        def self.addInstances(which)
            if nil == fetch(:asgroup_use_private_ips)
              set :asgroup_use_private_ips, false
            end

            # WHY 2 CLIENTS ???
            @ec2_api = Aws::EC2::Client.new(
              access_key_id: fetch(:aws_access_key_id),
              secret_access_key: fetch(:aws_secret_access_key),
              region: fetch(:aws_region)
            )

            @as_api = Aws::AutoScaling::Client.new(region: fetch(:aws_region))

            # Get descriptions of all the Auto Scaling groups
            @autoScaleDesc = @as_api.describe_auto_scaling_groups

            @asGroupInstanceIds = Array.new()
            # Find the right Auto Scaling group
            @autoScaleDesc[:auto_scaling_groups].each do |asGroup|
                # Look for an exact name match or Cloud Formation style match (<cloud_formation_script>-<as_name>-<generated_id>)
                if asGroup[:auto_scaling_group_name] == which or asGroup[:auto_scaling_group_name].scan("#{}{which}").length > 0
                    # For each instance in the Auto Scale group
                    asGroup[:instances].each do |asInstance|
                        @asGroupInstanceIds.push(asInstance[:instance_id])
                    end
                end
            end

            # Get descriptions of all the EC2 instances
            @ec2DescInst = @ec2_api.describe_instances(instance_ids: @asGroupInstanceIds)

            # figure out the instance IP's
            server_as_db_defined = false
            @ec2DescInst[:reservations].each do |reservation| # RESERVATION IS ALWAYS 1???
                #remove instances that are either not in this asGroup or not in the "running" state # DOES THIS LOGIC FIT???
                reservation[:instances].delete_if{ |a| not @asGroupInstanceIds.include?(a[:instance_id]) or a[:state][:name] != "running" }.each do |instance|
                    puts "Found ASG #{which} Instance ID: #{instance[:instance_id]} in VPC: #{instance[:vpc_id]}"
                    options = {
                      user: fetch(:user),
                      roles: [:app, :web]
                    }
                    unless server_as_db_defined # ONLY THE FIRST SERVER RUN MIGRATION RIGHT???
                      server_as_db_defined = true
                      options[:roles] << :db
                      options[:primary] = true
                    end
                    ip = if true == fetch(:asgroup_use_private_ips) # WHAT'S THIS???
                        instance[:private_ip_address]
                    else
                        instance[:public_ip_address]
                    end
                    server ip, options
                    puts "Added server #{ip} with options #{options}"
                end
            end

       end
    end
end

