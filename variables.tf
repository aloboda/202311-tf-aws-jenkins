variable "profile" {
  type    = string
  default = "default"

}

variable "region-master" {
  type    = string
  default = "us-east-1"
}

variable "region-worker" {
  type    = string
  default = "us-west-2"
}

variable "external_ip" {
  type        = string
  default     = "0.0.0.0/0"
  description = "External IP"
}

variable "instance_type" {
  type    = string
  default = "t2.micro"
}
variable "workers-count" {
  type    = number
  default = 1
}
variable "app-port" {
  type    = number
  default = 80
}