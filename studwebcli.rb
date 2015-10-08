#!/usr/bin/env ruby
require 'rubygems'
require 'bundler/setup'
require 'yaml'
require 'highline/import'
Bundler.require

@config = YAML.load_file 'config.yml'

require_relative 'studcli.rb'