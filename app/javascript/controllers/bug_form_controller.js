import { Controller } from "@hotwired/stimulus"
import { t } from "i18n_helper"

export default class extends Controller {
  static targets = ["optionalFields", "toggleText"]

  toggle() {
    this.optionalFieldsTarget.classList.toggle("hidden")

    if (this.optionalFieldsTarget.classList.contains("hidden")) {
      this.toggleTextTarget.textContent = t("bug_form.detail_bug")
    } else {
      this.toggleTextTarget.textContent = t("bug_form.hide_details")
    }
  }
}
