variable "location" {
  description = "The Azure Region in which all resources should be created."
  type        = string
  default     = "East US"
}

variable "AKSCluster" {
  description = "The name of the Azure Kubernetes Service (AKS) cluster."
  type        = string
  default     = "KS-aks-cluster"
}

variable "vnet_address_space" {
  description = "The address space used by the Virtual Network."
  type        = list(string)
  default     = ["10.0.0.0/16"]
}

variable "private_subnet_prefixes" {
  description = "The address prefixes used for the private subnets."
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "public_subnet_prefixes" {
  description = "The address prefixes used for the public subnets."
  type        = list(string)
  default     = ["10.0.3.0/24", "10.0.4.0/24"]
}

