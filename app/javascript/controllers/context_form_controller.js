import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="context-form"
export default class extends Controller {
  static targets = ["providerSelect", "apiSelect", "modelSelect"]
  static values = {
    providerApis: Object,
    providerModels: Object
  }

  connect() {
    // Initialize on page load
    this.updateApiOptions()
    this.updateModelOptions()
  }

  // Called when provider changes
  providerChanged(event) {
    this.updateApiOptions()
    this.updateModelOptions()
  }

  // Update API dropdown based on selected provider
  updateApiOptions() {
    const provider = this.providerSelectTarget.value
    const apiSelect = this.apiSelectTarget
    const currentValue = apiSelect.value
    
    // Get available APIs for this provider
    const apis = this.providerApisValue[provider] || []
    
    // Clear existing options
    apiSelect.innerHTML = ""
    
    // Add new options
    apis.forEach(api => {
      const option = document.createElement("option")
      option.value = api.value
      option.textContent = api.label
      option.selected = (api.value === currentValue)
      apiSelect.appendChild(option)
    })
    
    // If current value is not available, select first option
    if (!apis.find(api => api.value === currentValue) && apis.length > 0) {
      apiSelect.value = apis[0].value
    }
  }

  // Update model dropdown based on selected provider
  updateModelOptions() {
    const provider = this.providerSelectTarget.value
    const modelSelect = this.modelSelectTarget
    const currentValue = modelSelect.value
    
    // Get available models for this provider
    const models = this.providerModelsValue[provider] || []
    
    // Clear existing options
    modelSelect.innerHTML = ""
    
    // Add new options
    models.forEach(model => {
      const option = document.createElement("option")
      option.value = model.value
      option.textContent = model.label
      option.selected = (model.value === currentValue)
      modelSelect.appendChild(option)
    })
    
    // If current value is not available, select first option
    if (!models.find(model => model.value === currentValue) && models.length > 0) {
      modelSelect.value = models[0].value
    }
  }
}

