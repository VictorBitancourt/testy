module ApplicationHelper
  def icon_tag(name, size: nil, **options)
    css = class_names("icon icon--#{name}", { "icon--sm" => size == :sm, "icon--lg" => size == :lg }, options.delete(:class))
    tag.span class: css, aria: { hidden: true }, **options
  end

  # Button variant classes — 7 variants × 3 sizes
  def btn_classes(variant = :primary, size: :md)
    base = "inline-flex items-center justify-center gap-2 font-semibold rounded-lg transition cursor-pointer"

    sizes = {
      sm: "text-sm px-3 py-1.5",
      md: "px-5 py-2.5",
      lg: "px-8 py-3"
    }

    variants = {
      primary:   "bg-fz-blue-dark hover:bg-fz-blue-darker text-white shadow-lg",
      danger:    "bg-fz-red-dark hover:bg-fz-red-darker text-white shadow-lg",
      success:   "bg-fz-green-dark hover:bg-fz-green-darker text-white",
      ai:        "bg-fz-violet-dark hover:bg-fz-violet-darker text-white",
      secondary: "bg-surface-raised hover:bg-ink-lightest text-ink-dark",
      warning:   "bg-fz-yellow-medium hover:bg-fz-yellow-darker text-white",
      ghost:     "text-ink-dark hover:bg-white/5"
    }

    "#{base} #{sizes[size]} #{variants[variant]}"
  end

  # Status badge classes
  def badge_classes(variant)
    base = "inline-block text-xs font-bold px-2.5 py-1 rounded-full text-white"

    variants = {
      approved:    "bg-fz-green-dark",
      failed:      "bg-fz-red-dark",
      in_progress: "bg-fz-yellow-medium",
      not_started: "bg-fz-blue-dark",
      open:        "bg-fz-yellow-medium",
      resolved:    "bg-fz-green-dark",
      admin:       "bg-fz-violet-dark",
      user:        "bg-fz-blue-dark"
    }

    "#{base} #{variants[variant]}"
  end

  # Tag classes (for feature/cause/plan tags)
  def tag_classes(variant = :violet)
    base = "inline-block text-xs font-semibold px-2 py-0.5 rounded-full transition"

    variants = {
      violet:  "bg-fz-violet-darkest text-fz-violet-light hover:bg-fz-violet-darker",
      blue:    "bg-fz-blue-darkest text-fz-blue-light hover:bg-fz-blue-darker",
      red:     "bg-fz-red-darkest text-fz-red-light hover:bg-fz-red-darker"
    }

    "#{base} #{variants[variant]}"
  end
end
