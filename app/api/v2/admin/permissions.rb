# frozen_string_literal: true

module API
  module V2
    module Admin
      # Admin functionality over permissions table
      class Permissions < Grape::API
        resource :permissions do
          helpers do
            def validate_params!(params)
              unless %w(get post delete put head patch all).include?(params[:verb].downcase)
                error!({ errors: ['admin.permissions.invalid_verb'] }, 422)
              end

              error!({ errors: ['admin.permissions.invalid_action'] }, 422) unless %w(accept drop audit).include?(params[:action].downcase)
            end
          end

          desc 'Returns array of permissions as paginated collection',
          security: [{ "BearerToken": [] }],
          failure: [
            { code: 401, message: 'Invalid bearer token' }
          ]
          params do
            optional :page,
                     type: { value: Integer, message: 'admin.user.non_integer_page' },
                     values: { value: -> (p){ p.try(:positive?) }, message: 'admin.user.non_positive_page'},
                     default: 1,
                     desc: 'Page number (defaults to 1).'
            optional :limit,
                     type: { value: Integer, message: 'admin.user.non_integer_limit' },
                     values: { value: 1..100, message: 'admin.user.invalid_limit' },
                     default: 100,
                     desc: 'Number of users per page (defaults to 100, maximum is 100).'
          end
          get do
            Permission.all.tap { |q| present paginate(q) }
          end

          desc 'Create permission',
          security: [{ "BearerToken": [] }],
          failure: [
            { code: 401, message: 'Invalid bearer token' }
          ]
          params do
            requires :role,
                     type: String,
                     allow_blank: false
            requires :verb,
                     type: String,
                     allow_blank: false
            requires :path,
                     type: String,
                     allow_blank: false
            requires :action,
                     type: String,
                     allow_blank: false
          end
          post do
            validate_params!(params)

            declared_params = declared(params, include_missing: false)

            error!({ errors: ['admin.permission.role_doesnt_exist'] }, 422) if Permission.where(role: params[:role]).empty?

            permission = Permission.new(declared_params)

            code_error!(permission.errors.details, 422) unless permission.save

            # clear cached permissions, so they will be freshly refetched on the next call to /auth
            Rails.cache.delete('permissions')
            status 200
          end

          desc 'Deletes permission',
          security: [{ "BearerToken": [] }],
          failure: [
            { code: 401, message: 'Invalid bearer token' }
          ]
          params do
            requires :id,
                     type: Integer,
                     allow_blank: false,
                     desc: 'permission id'
          end
          delete do
            target_permission = Permission.find_by(id: params[:id])

            error!({ errors: ['admin.permission.doesnt_exist'] }, 404) if target_permission.nil?

            target_permission.destroy
            # clear cached permissions, so they will be freshly refetched on the next call to /auth
            Rails.cache.delete('permissions')

            status 200
          end

          desc 'Update Permission',
          security: [{ "BearerToken": [] }],
          failure: [
            { code: 401, message: 'Invalid bearer token' }
          ]
          params do
            requires :id,
                     type: Integer,
                     allow_blank: false,
                     desc: 'Permission id'
            optional :role,
                     type: String,
                     allow_blank: false,
                     desc: 'permission field - role'
            optional :verb,
                     type: String,
                     allow_blank: false,
                     desc: 'permission field - request verb'
            optional :path,
                     type: String,
                     allow_blank: false,
                     desc: 'permission field - request path'
            optional :action,
                     type: String,
                     allow_blank: false
          end
          put do
            target_permission = Permission.find_by(id: params[:id])
            error!({ errors: ['admin.permission.doesnt_exist'] }, 404) if target_permission.nil?

            unless target_permission.update(declared(params, include_missing: false))
              code_error!(target_permission.errors.details, 422)
            end
            # clear cached permissions, so they will be freshly refetched on the next call to /auth
            Rails.cache.delete('permissions')

            status 200
          end
        end
      end
    end
  end
end
