variable "management_group_name" {
  description = " Management group where the baseline is defined and assigned "
  type        = string
  default     = "mg-hp-guardrails-lab"
}

variable "storage_public_network_effect" {
  description = "Enforcement effect for control C-02."
  type        = string
  default     = "Audit"

  validation {
    condition = contains(
      ["Audit", "Deny", "Disabled"],
      var.storage_public_network_effect
    )
    error_message = "The effect must be Audit, Deny or Disabled"
  }
}