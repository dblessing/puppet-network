require 'ipaddr'

Puppet::Type.newtype(:network_rule) do
  @doc = "Manage non-volatile route configuration information"

  ensurable

  newparam(:name) do
    isnamevar
    desc "The name of the network rule"
  end

  newproperty(:network) do
    isrequired
    desc "The target network address"
    validate do |value|
      begin
        t = IPAddr.new(value) unless value == "default"
      rescue ArgumentError
        fail("Invalid value for network: #{value}")
      end
    end
  end

  newproperty(:selector) do
    isrequired
    desc "The rule selector"

    validate do |value|
      unless value.is_a?(Array)
        raise ArgumentError,
              "#{self.class} requires an array for the selector property"
      end

      # This is basic checking. Since multiple selector values can be entered
      # back-to-back, this is not fool-proof. However, it's a reasonable effort.
      value.each do |sel|
        unless sel =~ /^(not)?\s(from|to|tos|fwmark|dev|pref)\s/
          raise ArgumentError, 
                "#{self.class} selector requires valid rule selector " \
                "syntax for each value in the array. See `ip rule` man " \
                "pages for more information"
        end
      end
    end
  end

  newproperty(:action) do
    isrequired
    desc "The rule action"

    validate do |value|
      unless value.is_a?(Array)
        raise ArgumentError,
              "#{self.class} requires an array for the selector property"
      end

      # This is basic checking. Since multiple action values can be entered
      # back-to-back, this is not fool-proof. However, it's a reasonable effort.
      value.each do |sel|
        unless sel =~ /^(reject|prohibit|unreachable)?\s(table|realms|goto)\s/
          raise ArgumentError,
                "#{self.class} action requires valid rule action " \
                "syntax for each value in the array. See `ip rule` man " \
                "pages for more information"
        end
      end
  end
end
