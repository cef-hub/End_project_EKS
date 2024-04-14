variable "necessity_db" {
  description = "do we need a database"
  type        = string
  default     = "no"  
}

variable "necessity_eks" {
  description = "do we need a EKS cluster"
  type        = string
  default     = "no"  
}

variable "instance_class" {
  description = "db class instance"
  type        = string
}

variable "cidr_block" {
  description = "cidr_block IP range"
  type        = string
}

variable "cidr_block_pr1" {
  description = "cidr_block IP range"
  type        = string
}

variable "cidr_block_pr2" {
  description = "cidr_block IP range"
  type        = string
}

variable "cidr_block_pb1" {
  description = "cidr_block IP range"
  type        = string
}

variable "cidr_block_pb2" {
  description = "cidr_block IP range"
  type        = string
}

variable "description" {
  description = "description"
  type        = string
  default = "dev.skruhlik.pass"
}

variable "managedby" {
  description = "control application"
  type        = string
  default = "Terraform"
}

variable "instance_type" {
  description = "ec2 instance_type"
  type        = string
}