# frozen_string_literal: true

# Describe a message (sent on a IO as STDOUT/STDERR)
class Grouik::Output::Message
  attr_accessor :content
  attr_accessor :type
  attr_accessor :stream

  def initialize
    yield self if block_given?
  end

  # @param content [String]
  def content=(content)
    @content = content.to_s.empty? ? nil : content.to_s
  end

  # @param stream [IO]
  def stream=(stream)
    @stream = stream.clone
  end

  # @return [IO]
  def stream
    @stream || STDOUT.clone
  end

  # @raise [RuntimeError]
  # @return [self]
  def send
    attrs = [:stream, :content, :type]
    attrs.each do |attr|
      raise 'attributes %s must be set' % attrs if public_send(attr).nil?
    end

    messager_class.new(stream, content.to_s).output(type)
    self
  end

  protected

  # @return [Grouik::Output::Messager]
  def messager_class
    require '%s/messager' % __dir__

    Grouik::Output::Messager
  end
end
