# frozen_string_literal: true
module Dato
  module Local
    module FieldType
      class Link
        def self.parse(value, repo)
          repo.find(value)
        end
      end
    end
  end
end
