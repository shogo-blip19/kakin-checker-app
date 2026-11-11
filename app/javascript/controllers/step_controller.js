import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="step"
export default class extends Controller {
  static targets = ["panel", "subtitle", "form", "amount"]
  static values = { index: Number }

  next() {
    if (this.currentPanelIsValid()) {
      this.indexValue = this.indexValue + 1
    }
  }

  back() {
    this.indexValue = this.indexValue - 1
  }



  indexValueChanged() {
    this.showCurrentPanel()
    this.updateSubtitle()
  }

  showCurrentPanel() {
    this.panelTargets.forEach((panel, index) => {
      panel.classList.toggle("hidden", index !== this.indexValue)
    })
  }

  updateSubtitle() {
    const panel = this.panelTargets[this.indexValue]
    if (!panel) return

    const total = this.panelTargets.length
    this.subtitleTarget.textContent = `Step ${this.indexValue + 1}/${total} - ${panel.dataset.stepTitle}`
  }

  currentPanelIsValid() {
    const currentPanel = this.panelTargets[this.indexValue]
    const inputs = currentPanel.querySelectorAll("input")
    for (const input of inputs) {
      if (!input.checkValidity()) {
        input.reportValidity()
        return false
      }
    }
    return true
  }


}
