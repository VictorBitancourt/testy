module ApplicationHelper
  def icon_tag(name, size: nil, **options)
    css = class_names("icon icon--#{name}", { "icon--sm" => size == :sm, "icon--lg" => size == :lg }, options.delete(:class))
    tag.span class: css, aria: { hidden: true }, **options
  end

  def btn_classes(variant = :primary, size: :md)
    classes = [ "btn", "btn--#{variant}" ]
    classes << "btn--#{size}" unless size == :md
    classes.join(" ")
  end

  def badge_classes(variant)
    "badge badge--#{variant}"
  end

  def tag_classes(variant = :violet)
    "tag tag--#{variant}"
  end
end
