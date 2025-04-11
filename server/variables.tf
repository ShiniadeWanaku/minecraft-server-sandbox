variable "subscription_id" {
  description = "ID de la suscripción de Azure"
  type        = string
}

variable "admin_password" {
  description = "Contraseña del usuario administrador de la VM"
  type        = string
  sensitive   = true
}