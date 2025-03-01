module Dialed
  module Refinements
    module PresenceMethods
      def present?
        !nil? && !empty?
      end

      def presence
        self if present?
      end
    end

    module Presence
      refine NilClass do
        def present?
          false
        end

        def presence
          nil
        end
      end

      refine String do
        def present?
          !nil? && !empty?
        end

        def presence
          self if present?
        end
      end

      refine Integer do
        def present?
          !nil?
        end
      end

      refine Array do
        def present?
          !nil? && !empty?
        end

        def presence
          self if present?
        end
      end

      refine Hash do
        def present?
          !nil? && !empty?
        end

        def presence
          self if present?
        end
      end

      refine Symbol do
        def present?
          !nil? && !empty?
        end

        def presence
          self if present?
        end
      end
    end
  end
end
