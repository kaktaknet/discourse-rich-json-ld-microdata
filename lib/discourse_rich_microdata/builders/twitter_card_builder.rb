# frozen_string_literal: true

module DiscourseRichMicrodata
  module Builders
    class TwitterCardBuilder < BaseBuilder
      def build
        tags = base_twitter_tags

        case detect_page_type
        when :topic
          tags.merge!(topic_specific_tags)
        when :category
          tags.merge!(category_specific_tags)
        when :user
          tags.merge!(user_specific_tags)
        end

        render_tags(tags)
      end

      private

      def detect_page_type
        return :topic if data[:title] && data[:posts]
        return :category if data[:topic_count]
        return :user if data[:username]
        :default
      end

      def base_twitter_tags
        # Only unique tags - Discourse already generates twitter:title, twitter:description,
        # twitter:image, twitter:url. We only enhance the card type.
        {
          "twitter:card" => determine_card_type  # Enhanced: "summary_large_image" instead of "summary"
        }
      end

      def topic_specific_tags
        {
          "twitter:creator" => twitter_creator,
          "twitter:label1" => t('twitter_card.label_replies'),
          "twitter:data1" => (data[:posts_count] - 1).to_s,
          "twitter:label2" => t('twitter_card.label_author'),
          "twitter:data2" => data.dig(:author, :name)
        }
      end

      def category_specific_tags
        {
          "twitter:label1" => t('twitter_card.label_topics'),
          "twitter:data1" => data[:topic_count].to_s
        }
      end

      def user_specific_tags
        {
          "twitter:label1" => t('twitter_card.label_posts'),
          "twitter:data1" => data[:post_count].to_s,
          "twitter:label2" => t('twitter_card.label_karma'),
          "twitter:data2" => data[:likes_received].to_s
        }
      end

      def determine_card_type
        has_image? ? "summary_large_image" : "summary"
      end

      def has_image?
        image_url = twitter_image
        image_url.present? && image_url != base_url
      end

      def twitter_image
        case detect_page_type
        when :topic
          data[:image_url]
        when :user
          data[:avatar_url]
        else
          nil
        end
      end

      def twitter_site_handle
        handle = SiteSetting.rich_microdata_social_twitter
        return nil if handle.blank?

        handle.start_with?("@") ? handle : "@#{handle}"
      end

      def twitter_creator
        twitter_site_handle
      end

      def render_tags(tags_hash)
        html = []

        tags_hash.each do |name, content|
          next if content.nil? || (content.respond_to?(:empty?) && content.empty?)

          html << %(<meta name="#{escape_html(name)}" content="#{escape_html(content.to_s)}">)
        end

        html.join("\n")
      end
    end
  end
end
