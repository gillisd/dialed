# frozen_string_literal: true

module Dialed
  module HTTP
    class ProxyUri < SimpleDelegator
      using Dialed::Refinements::Presence

      def self.parse(string)
        new(Addressable::URI.parse(string))
      end

      def initialize(uri = Addressable::URI.parse('http://invalid.invalid'))
        super
      end

      def infer_scheme_if_missing!
        self.scheme ||= 'http'
      end

      def valid?
        host.present? &&
          port.present? &&
          scheme.present?
      end
    end
  end
end
