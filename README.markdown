## Introduction

LAST DISCLAIMER BY MASCIUGO:
THIS IS AN ADAPTATION OF [THIS PROJECT](https://github.com/teu/capistrano-asgroup) IN ORDER TO WORK LIKE
[THIS OTHER PROJECT](https://github.com/gtforge/capistrano-autoscale-deploy) WHICH, MOREVOER, WAS FOR CAPISTRANO 2 ONLY

capistrano-asgroup is a [Capistrano](https://github.com/capistrano/capistrano) plugin designed to simplify the
task of deploying to infrastructure hosted on [Amazon EC2](http://aws.amazon.com/ec2/). It was
completely inspired by the [capistrano-ec2group](https://github.com/logandk/capistrano-ec2group) and
[capistrano-ec2tag](https://github.com/douglasjarquin/capistrano-ec2tag) plugins, to which all credit is due.

Both of the prior plugins gave you "a way" to deploy using Capistrano to AWS Auto Scaling groups but both
required you to do so in a non-straightforward manner by putting your Auto Scaling group in its own
security group or by providing a unique tag for your Auto Scaling group.  This plugin simply takes the
name of the Auto Scaling group and uses that to find the Auto Scaling instances that it should deploy to.  It will
work with straight up hand created Auto Scaling groups (exact match of the AS group name).
### How this works
This gem will fetch only running instances that have an autoscale tag name you specified
It will then reject the roles `:db` and the `:primary => true` for all servers found but the first one
this is to make sure a single working task does not run in parallel
you end up as if you defined the servers yourself like so:

```ruby
server ip_address1, :app :db, :web, :primary => true
server ip_address2, :app, :web
server ip_address3, :app, :web
```

## Installation

### Set the Amazon AWS Credentials

In order for the plugin to list out the hostnames of your AWS Auto Scaling instances, it
will need access to the Amazon AWS API.  It is recommended to use IAM to create credentials
with limited capabilities for this type of purpose. Specify the following in your
Capistrano configuration:

You can use aws-sdk credentials described in [AWS docs](http://docs.aws.amazon.com/sdkforruby/api/index.html)
```ruby
set :aws_access_key_id, ENV['AWS_ACCESS_KEY_ID']
set :aws_secret_access_key, ENV['AWS_SECRET_ACCESS_KEY']
```

### Get the gem

The plugin is distributed as a Ruby gem.

**Ruby Gems**

```bash
gem install capistrano-asgroup
```

**Bundler**

Using [bundler](http://gembundler.com/)?

```bash
gem install bundler
```

Then add the following to your Gemfile:

```ruby
source 'http://rubygems.org'
gem 'capistrano-asgroup'
```

Install the gems in your manifest using:

```bash
bundle install
```

## Usage

### Configure Capistrano

Instead of manually defining the hostnames to deploy to like this:

```ruby
set :aws_region, 'eu-west-1' # set the region of AWS

set :aws_region, "us-west-1"
set :asgroup_use_private_ips, true
```

Simple do this where <my-autoscale-group-name> is the name of an autoscale group, with optional role:

```ruby
Capistrano::Asgroup.addInstances("<my-autoscale-group-name>")
```


```ruby
require 'capistrano/asgroup'

task :production do
  Asgroup.addInstances("my-asg-name")
  logger.info 'Deploying to the PRODUCTION environment!'
end
```

### Additional configuration

In order to deploy through a NAT instance in AWS VPC, you will need the instances private IP address instead of the DNS name

```ruby
set :asgroup_use_private_ips, true
```


## License

Originally developed by:
[Thomas Verbiscer](http://tom.verbiscer.com/), released under the MIT License
