# EC 130903 - removed @user_class, displays whodunnit as is
module RailsAdmin
  module Extensions
    module PaperTrail
      class VersionProxy
        def initialize(version, user_class = nil)
          @version = version
        end

        def message
          @message = @version.event
          @version.respond_to?(:changeset) ? @message + " [" + @version.changeset.to_a.collect {|c| c[0] + " = " + c[1][1].to_s}.join(", ") + "]" : @message
        end

        def created_at
          @version.created_at
        end

        def table
          @version.item_type
        end

        def username
					@version.whodunnit
        end

        def item
          @version.item_id
        end
      end

      class AuditingAdapter
        COLUMN_MAPPING = {
          :table => :item_type,
          :username => :whodunnit,
          :item => :item_id,
          :created_at => :created_at,
          :message => :event
        }

        def initialize(controller, user_class = nil)
          raise "PaperTrail not found" unless defined?(PaperTrail)
          @controller = controller
        end

        def latest
          ::Version.limit(100).map{|version| VersionProxy.new(version)}
        end

        def delete_object(object, model, user)
          # do nothing
        end

        def update_object(object, model, user, changes)
          # do nothing
        end

        def create_object(object, abstract_model, user)
          # do nothing
        end

        def listing_for_model(model, query, sort, sort_reverse, all, page, per_page = (RailsAdmin::Config.default_items_per_page || 20))
          if sort.present?
            sort = COLUMN_MAPPING[sort.to_sym]
          else
            sort = :created_at
            sort_reverse = "true"
          end
          versions = ::Version.where :item_type => model.model.name
          versions = versions.where("event LIKE ?", "%#{query}%") if query.present?
          versions = versions.order(sort_reverse == "true" ? "#{sort} DESC" : sort)
          versions = all ? versions : versions.send(Kaminari.config.page_method_name, page.presence || "1").per(per_page)
          versions.map{|version| VersionProxy.new(version)}
        end

        def listing_for_object(model, object, query, sort, sort_reverse, all, page, per_page = (RailsAdmin::Config.default_items_per_page || 20))
          if sort.present?
            sort = COLUMN_MAPPING[sort.to_sym]
          else
            sort = :created_at
            sort_reverse = "true"
          end
          versions = ::Version.where :item_type => model.model.name, :item_id => object.id
          versions = versions.where("event LIKE ?", "%#{query}%") if query.present?
          versions = versions.order(sort_reverse == "true" ? "#{sort} DESC" : sort)
          versions = all ? versions : versions.send(Kaminari.config.page_method_name, page.presence || "1").per(per_page)
          versions.map{|version| VersionProxy.new(version)}
        end
      end
    end
  end
end
