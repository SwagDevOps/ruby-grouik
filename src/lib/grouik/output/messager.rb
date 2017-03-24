# frozen_string_literal: true

# Copyright (C) 2017 Dimitri Arrigoni <dimitri@arrigoni.me>
# License GPLv3+: GNU GPL version 3 or later
# <http://www.gnu.org/licenses/gpl.html>.
# This is free software: you are free to change and redistribute it.
# There is NO WARRANTY, to the extent permitted by law.

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
    def output(stream, type)
      self.new(stream, content).output(type)
    end

    # Defines available formats
    #
    # @return [Hash]
    def formats
      {
        status_success: {
          background: :green,
          color: :black,
        },
        status_failure: {
          background: :red,
          color: :black,
        },
        error: {
          color: :red,
        }
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

  # Get a colorizable (almost a wrapper over ``Rainbow``) content instance
  #
  # @return [Rainbow::Presenter, Rainbow::NullPresenter]
  def colorizable
    require 'rainbow'

    Rainbow.enabled = colorizable?
    Rainbow::Wrapper.new(colorizable?).wrap(content)
  end

  def colorize(format = {})
    colorizable = self.colorizable.clone
    format.to_h.each { |k, v| colorizable = colorizable.public_send(k, v) }

    colorizable
  end
end
