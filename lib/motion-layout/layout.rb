module Motion
  class Layout

    def initialize(&block)
      @verticals = {}
      @horizontals = {}
      @metrics = {}

      yield self
      strain
    end

    def metrics(metrics)
      @metrics = Hash[metrics.keys.map(&:to_s).zip(metrics.values)]
    end

    def subviews(subviews)
      @subviews = Hash[subviews.keys.map(&:to_s).zip(subviews.values)]
    end

    def view(view)
      @view = view
    end

    def horizontal(format, *options)
      options = [:center_y] if options.empty?
      resolved_options = resolve_options(options)
      @horizontals[resolved_options] = (@horizontals[resolved_options] || []) << format
    end

    def vertical(format, *options)
      options = [:center_x] if options.empty?
      resolved_options = resolve_options(options)
      @verticals[resolved_options] = (@verticals[resolved_options] || []) << format
    end

    private

    def strain
      @subviews.values.each do |subview|
        subview.translatesAutoresizingMaskIntoConstraints = false
        @view.addSubview(subview) unless subview.superview
      end
      
      views = @subviews.merge("superview" => @view)

      constraints = []

      @verticals.each do |options, formats|
        constraints += formats.map do |format|
          NSLayoutConstraint.constraintsWithVisualFormat("V:#{format}", options:options, metrics:@metrics, views:views)
        end
      end

      @horizontals.each do |options, formats|
        constraints += formats.map do |format|
          NSLayoutConstraint.constraintsWithVisualFormat("H:#{format}", options:options, metrics:@metrics, views:views)
        end
      end

      @view.addConstraints(constraints.flatten)
    end

    def resolve_options(options)
      option_hash = {
        none: 0,
        left: NSLayoutFormatAlignAllLeft,
        right: NSLayoutFormatAlignAllRight,
        top: NSLayoutFormatAlignAllTop,
        bottom: NSLayoutFormatAlignAllBottom,
        leading: NSLayoutFormatAlignAllLeading,
        trailing: NSLayoutFormatAlignAllTrailing,
        center_x: NSLayoutFormatAlignAllCenterX,
        center_y: NSLayoutFormatAlignAllCenterY,
        baseline: NSLayoutFormatAlignAllBaseline
      }
      options.inject(0) do |combined_result, option|
        if option.kind_of?(Numeric)
          combined_result | option.to_i
        elsif constant = option_hash[option.to_s.downcase.to_sym]
          combined_result | constant
        else
          raise "invalid option: #{option.to_s.downcase}"
        end
      end
    end
  end
end
