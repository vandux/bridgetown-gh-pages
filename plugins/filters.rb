class Filters < SiteBuilder
  def build
    liquid_filter "link_path" do |url|
      "#{config.base_path}#{url}"
    end
  end
end
