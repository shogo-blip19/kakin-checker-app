import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="step"
export default class extends Controller {
  static targets = ["panel"]
  static values = {index: Number}

  next() {
    this.indexValue = this.indexValue + 1 
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
