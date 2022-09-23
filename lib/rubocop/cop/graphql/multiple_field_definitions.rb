# frozen_string_literal: true

require "pry-byebug"
module RuboCop
  module Cop
    module GraphQL
      # This cop checks whether fields with multiple definitions are grouped together.
      # @example
      #   # good
      #
      #   class UserType < BaseType
      #     field :first_name, String, null: true
      #     field :first_name, Name, null: true
      #
      #     def first_name
      #       object.contact_data.first_name
      #     end
      #   end
      #
      #   # bad
      #
      #   class UserType < BaseType
      #     field :first_name, String, null: true
      #
      #     def first_name
      #       object.contact_data.first_name
      #     end
      #     field :first_name, Name, null: true
      #   end
      class MultipleFieldDefinitions < Base
        extend AutoCorrector
        include ConfigurableEnforcedStyle
        include RuboCop::GraphQL::NodePattern
        include RuboCop::Cop::RangeHelp
        include RuboCop::GraphQL::Heredoc

        def on_send(node)
          return unless field_definition?(node)

          field = RuboCop::GraphQL::Field.new(node)

          multiple_definitions = multiple_definitions(field)

          return if multiple_definitions.size == 1 || field.node != multiple_definitions.last.node

          if has_ungrouped_definitions?(multiple_definitions)
            add_offense(field.node, message: MULTIPLE_DEFINITIONS_MSG) do |corrector|
              group_multiple_definitions(corrector, multiple_definitions)
            end
          end
        end

        private

        MULTIPLE_DEFINITIONS_MSG = "Group multiple field definitions together."

        def multiple_definitions(field)
          fields = field.schema_member.body
                        .select { |node| field?(node) }
                        .map do |node|
                          f = field_definition_with_body?(node) ? node.children.first : node
                          RuboCop::GraphQL::Field.new(f)
                        end
          fields.select { |f| f.name == field.name }
        end

        def group_multiple_definitions(corrector, multiple_definitions)
          multiple_definitions.each_cons(2) do |first, second|
            next unless field_sibling_index(second) - field_sibling_index(first) > 1

            first = field_definition_with_body?(first.node.parent) ? first.node.parent : first.node
            second = field_definition_with_body?(second.node.parent) ? second.node.parent : second.node

            insert_new_field(corrector, first, second)
            remove_old_field(corrector, second)
          end
        end

        def insert_new_field(corrector, first, second)
          source_to_insert = "\n#{range_including_heredoc(second).source}"
          field_definition_range = range_including_heredoc(first)
          corrector.insert_after(field_definition_range, source_to_insert)
        end

        def remove_old_field(corrector, second)
          range_to_remove = range_with_surrounding_space(
            range: range_including_heredoc(second), side: :left
          )
          corrector.remove(range_to_remove)
        end

        def has_ungrouped_definitions?(multiple_definitions)
          sibling_indices = multiple_definitions.map do |field|
            field_sibling_index(field)
          end

          sibling_indices.each_cons(2).any? { |index1, index2| index2 - index1 > 1 }
        end

        def field_sibling_index(field)
          if field_definition_with_body?(field.parent)
            field.parent.sibling_index
          else
            field.sibling_index
          end
        end
      end
    end
  end
end
