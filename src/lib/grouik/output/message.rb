# frozen_string_literal: true

# Copyright (C) 2017 Dimitri Arrigoni <dimitri@arrigoni.me>
# License GPLv3+: GNU GPL version 3 or later
# <http://www.gnu.org/licenses/gpl.html>.
# This is free software: you are free to change and redistribute it.
# There is NO WARRANTY, to the extent permitted by law.

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
