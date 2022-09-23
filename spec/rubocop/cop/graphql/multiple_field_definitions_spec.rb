# frozen_string_literal: true

RSpec.describe RuboCop::Cop::GraphQL::MultipleFieldDefinitions, :config do
  context "when a field has multiple definitions" do
    it "not register an offense when grouped" do
      expect_no_offenses(<<~RUBY)
        class UserType < BaseType
          field :image_url, String, null: true
          field :image_url, String, null: false do
            argument :width, Integer, required: false
            argument :height, Integer, required: false
          end

          field :first_name, String, null: false
        end
      RUBY
    end

    it "register an offense when ungrouped" do
      expect_offense(<<~RUBY)
        class UserType < BaseType
          field :image_url, String, null: true

          field :first_name, String, null: false

          field :image_url, String, null: false
          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Group multiple field definitions together.
        end
      RUBY

      expect_correction(<<~RUBY)
        class UserType < BaseType
          field :image_url, String, null: true
          field :image_url, String, null: false

          field :first_name, String, null: false
        end
      RUBY
    end

    it "register an offense when ungrouped and field definition has a body" do
      expect_offense(<<~RUBY)
        class UserType < BaseType
          field :image_url, String, null: true

          field :first_name, String, null: false

          field :image_url, String, null: false do
          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Group multiple field definitions together.
            argument :width, Integer, required: false
            argument :height, Integer, required: false
          end
        end
      RUBY

      expect_correction(<<~RUBY)
        class UserType < BaseType
          field :image_url, String, null: true
          field :image_url, String, null: false do
            argument :width, Integer, required: false
            argument :height, Integer, required: false
          end

          field :first_name, String, null: false
        end
      RUBY
    end

    context "when field has a heredoc description" do
      it "not registers an offense when grouped together" do
        expect_no_offenses(<<~RUBY)
          class UserType < BaseType
            field :first_name, String, null: true, description: <<~DESC
              First Name.
            DESC

            field :first_name, String, null: false, description: <<~DESC
              First Name.
            DESC

            def first_name
              object.contact_data.first_name
            end
          end
        RUBY
      end

      it "registers an offense when ungrouped" do
        expect_offense(<<~RUBY)
          class UserType < BaseType
            field :first_name, String, null: true, description: <<~DESC
              First Name.
            DESC

            def first_name
              object.contact_data.first_name
            end

            field :first_name, String, null: false, description: <<~DESC
              First Name.
            DESC

            field :first_name, String, null: false, description: "First Name."
            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Group multiple field definitions together.
          end
        RUBY

        expect_correction(<<~RUBY)
          class UserType < BaseType
            field :first_name, String, null: true, description: <<~DESC
              First Name.
            DESC
            field :first_name, String, null: false, description: <<~DESC
              First Name.
            DESC
            field :first_name, String, null: false, description: "First Name."

            def first_name
              object.contact_data.first_name
            end
          end
        RUBY
      end
    end
  end
end
