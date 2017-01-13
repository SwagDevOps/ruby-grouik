# frozen_string_literal: true

# Provide a wrapper over ``Rainbow``
class Grouik::Output::Message
  attr_reader :stream
  attr_accessor :content

  def initialize(stream = STDOUT, content = nil)
    @stream = stream
    self.content = content
  end

  def content=(content)
    @content = content.to_s
  end

  # @todo Catch ``NoMethodError`` or similar error
  # @return [self]
  def output(type)
    stream.puts self.format_as(type)
    self
  end

  class << self
    # @return [self]
    def output(stream, type, message)
      self.new(stream, content).output(type)
    end
  end

  # @param [Hash]
  # @return [Rainbow::Presenter, Rainbow::NullPresenter]
  def format_as(type)
    {
      success: colorizable.background(:green).color(:black),
      failure: colorizable.background(:red).color(:black),
    }.fetch(type.to_sym)
  end

  # Denote output is colorizable (``tty?``)
  def colorizable?
    stream.tty?
  end

  # @return [Rainbow::Presenter, Rainbow::NullPresenter]
  def colorizable
    require 'rainbow'
    return Rainbow::Wrapper.new(colorizable?).wrap(content)
  end
end
