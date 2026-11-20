import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="amount"
export default class extends Controller {
  static targets = ["input"]

  set(event) {
    this.inputTarget.value = event.params.yen
    this.inputTarget.focus()
  }
}
