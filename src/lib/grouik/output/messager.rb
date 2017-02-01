# frozen_string_literal: true

# Provide a wrapper over ``Rainbow``
class Grouik::Output::Messager
  attr_accessor :stream
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

    # Defines available formats
    #
    # @return [Hash]
    def formats
      {
        status_success: {
          background: :green,
          color: :black
        },
        status_failure: {
          background: :red,
          color: :black},
      }
    end
  end

  # @param type [Symbol|String]
  # @return [Rainbow::Presenter, Rainbow::NullPresenter]
  def format_as(type)
    colorize(self.class.formats[type.to_sym])
  end

  # Denote output is colorizable (``tty?``)
  def colorizable?
    stream.tty?
  end

  protected

  # @return [Rainbow::Presenter, Rainbow::NullPresenter]
  def colorizable
    require 'rainbow'

    Rainbow.enabled = colorizable?
    return Rainbow::Wrapper.new(colorizable?).wrap(content)
  end

  def colorize(format = {})
    colorizable = self.colorizable.clone
    format.to_h.each { |k, v| colorizable = colorizable.public_send(k, v) }

    colorizable
  end
end
