require '/opt/postal/vendor/bundle/ruby/2.4.0/gems/socksify-1.7.1/lib/socksify'

class Net::SMTP::Response
  def message
    @string
  end
end

class Net::SMTP
  attr_accessor :source_address

  def secure_socket?
    @socket.is_a?(OpenSSL::SSL::SSLSocket)
  end

  #
  # We had an issue where a message was sent to a server and was greylisted. It returned
  # a Net::SMTPUnknownError error. We then tried to send another message on the same
  # connection after running `rset` the next message didn't raise any exceptions because
  # net/smtp returns a '200 dummy reply code' and doesn't raise any exceptions.
  #
  def rset
    @error_occurred = false
    getok('RSET')
  end

  def rset_errors
    @error_occurred = false
  end

  private

  def tcp_socket(address, port)
    if ENV['PROXY_ENABLED'] == 'true' 
      if (ENV['PROXY_LOCAL_SMTP'] || 'localhost').include? address
        log "Local SMTP #{address} identified. Bypass SMTP proxy."
      else
        TCPSocket::socks_server = "127.0.0.1"
        TCPSocket::socks_port = 1080
      end
    end
    TCPSocket.open(address, port, self.source_address)
  end
end