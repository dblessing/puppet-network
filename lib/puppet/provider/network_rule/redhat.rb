require 'ipaddr'
require 'puppetx/filemapper'

Puppet::Type.type(:network_rule).provide(:redhat) do
  # RHEL network_rule provider.
  #
  # This provider uses the filemapper mixin to map the rules file to a
  # collection of network_rule providers, and back.

  include PuppetX::FileMapper

  desc "RHEL style rules provider"

  confine    :osfamily => :redhat
  defaultfor :osfamily => :redhat

  has_feature :provider_option

  def select_file
    "/etc/sysconfig/network-scripts/rule-#{@resource[:interface]}"
  end

  def self.target_files
    Dir["/etc/sysconfig/network-scripts/rule-*"]
  end

  def self.parse_file(filename, contents)
    rules = []

    lines = contents.split("\n")
    lines.each do |line|
      # Strip off any trailing comments
      line.sub!(/#.*$/, '')

      if line =~ /^\s*#|^\s*$/
        # Ignore comments and blank lines
        next
      end

      new_rule = {}

      # Try to piece things back together based on value.
      new_rule[:selector] = line.split(/\s(table|prohibit|reject|unreachable|realms|goto)/)[0]
      new_rule[:name] = "Rule #{new_rule[:selector]}"
      line.slice!(new_rule[:selector])
      new_rule[:action] = line.strip
      new_rule[:interface] = filename.dup # Because apparently filename is frozen
      new_rule[:interface].slice!(/.+rule-/)

      rules << new_rule
    end

    rules
  end

  # Generate an array of sections
  def self.format_file(filename, providers)
    contents = []
    contents << header
    # Build rules
    providers.sort_by(&:name).each do |provider|
      [:action, :selector].each do |prop|
        raise Puppet::Error, "#{provider.name} does not have a #{prop}." if provider.send(prop).nil?
      end
      contents << "#{provider.selector} #{provider.action}\n"
    end
    contents.join
  end

  def self.header
    str = <<-HEADER
# HEADER: This file is is being managed by puppet. Changes to
# HEADER: rules that are not being managed by puppet will persist;
# HEADER: however changes to rules that are being managed by puppet will
# HEADER: be overwritten. In addition, file order is NOT guaranteed.
# HEADER: Last generated at: #{Time.now}
HEADER
    str
  end
end
