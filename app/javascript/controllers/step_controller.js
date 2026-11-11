import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="step"
export default class extends Controller {
  static targets = ["panel"]
  static values = {index: Number}

  next() {
    if (this.currentPanelIsValid()) {
      this.indexValue = this.indexValue + 1
    }
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

  back() {
    this.indexValue = this.indexValue - 1
  }


  indexValueChanged() {
    this.panelTargets.forEach((panel, index) => {
      if (index === this.indexValue) {
        panel.classList.remove("hidden")
      } else {
        panel.classList.add("hidden")
      }
    })
  } 

}
