variable "setregion" {
	default = "us-west-2"
}

variable "vpcid" {
	default = "vpc-885374ed"
}

variable "aminumber" {
	default = "ami-d2c924b2"
}

variable "subnet" {
	default = "subnet-7d442724"
}

variable "bucket1"{
	default = "openshiftbucket001"
}

variable "master_count" {
	default = "1"
}

variable "nodes_count" {
	default = "2"
}

variable "master_instsize" {
	default = "t2.small"
}

variable "nodes_instsize" {
	default = "t2.small"
}

variable "lb_instsize" {
	default = "t2.small"
}