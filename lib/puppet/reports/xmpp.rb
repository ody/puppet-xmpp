require 'puppet'
require 'yaml'

begin
  require 'xmpp4r/client'
  include Jabber
rescue LoadError => e
  Puppet.info "You need the `xmpp4r` gem to use the XMPP report"
end

Puppet::Reports.register_report(:xmpp) do

  configfile = File.join([File.dirname(Puppet.settings[:config]), "xmpp.yaml"])
  raise(Puppet::ParseError, "XMPP report config file #{configfile} not readable") unless File.exist?(configfile)
  config = YAML.load_file(configfile)
  XMPP_JID = config[:xmpp_jid]
  XMPP_PASSWORD = config[:xmpp_password]
  XMPP_TARGET = config[:xmpp_target]

  desc <<-DESC
  Send notification of failed reports to an XMPP user.
  DESC

  def process
    if self.status == 'failed'
      Puppet.debug "Sending status for #{self.host} to XMMP user #{XMPP_TARGET}"
      jid = JID::new(XMPP_JID)
      cl = Client::new(jid)
      cl.connect
      cl.auth(XMPP_PASSWORD)
      body = "Puppet run for #{self.host} #{self.status} at #{Time.now.asctime}"
      m = Message::new(XMPP_TARGET, body).set_type(:normal).set_id('1').set_subject("Puppet run failed!")
      cl.send m
    end
  end
end
