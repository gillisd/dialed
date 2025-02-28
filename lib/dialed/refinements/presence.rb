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
      end

      refine String do
        def present?
          !nil? && !empty?
        end
      end

      refine Integer do
        def present?
          !nil?
        end
      end

      refine Array do
        import_methods PresenceMethods
      end

      refine Hash do
        import_methods PresenceMethods
      end

      refine Symbol do
        def present?
          !nil? && !empty?
        end
      end
    end
  end
end
