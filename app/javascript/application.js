// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
console.log("application.js loading...")
import "@hotwired/turbo-rails"
console.log("Turbo loaded")
import "controllers"
console.log("Controllers loaded")
import "bootstrap"
console.log("Bootstrap loaded")
