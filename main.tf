# Configure the AWS Provider
provider "aws" {
    access_key = "${var.access_key}"
    secret_key = "${var.secret_key}"
    region = "${var.setregion}"
}

//SECURITY GROUP
resource "aws_security_group" "os_all_producers" {

  name = "os_consumer"
  vpc_id = "vpc-e6032a83"
  description = "Security group to allow all sources to intercommunicate and to talk out"


  ingress {
    from_port = "0"
    to_port = "0"
    protocol = "-1"
    self = true
    cidr_blocks = ["73.210.192.218/32"]
  }

    egress {
      from_port = 0
      to_port = 0
      protocol = "-1"
      cidr_blocks = ["0.0.0.0/0"]
  }

  tags {
    name = "os_all_producers"
  }
}

//S3BUCKET
//Create the bucket to hold software temp.  You will add the policy further down due to needing the IP address of the os_nexus1 instance
resource "aws_s3_bucket" "openshift_s3_bucket" {
  bucket = "openshifts3bucket"
}

//INSTANCE POLICY
//Creates the policy that will be attached to the ec2 assume role
resource "aws_iam_role_policy" "oss3_instance_policy" {
    name = "os_s3_policy"
    role = "${aws_iam_role.oss3_instance_role.id}"
    policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "Stmt1477509636623",
      "Action": "s3:*",
      "Effect": "Allow",
      "Resource": "arn:aws:s3:::openshifts3bucket/*"
    }
  ]
}
EOF
}

//INSTANCE ROLE
//Creates the role that will be assigned to the iam_instance_profile of the instance
resource "aws_iam_role" "oss3_instance_role" {
    name = "os_s3_role"
    assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

//INSTANCE PROFILE
//Creates the IAM instance profile that will be assigned to the ec2 server made of an instance policy attached to an sts allow role
resource "aws_iam_instance_profile" "oss3_profile" {
    name = "oss3_profile"
    roles = ["${aws_iam_role.oss3_instance_role.name}"]
}

//INSTANTIATION EC2
resource "aws_instance" "os_master" {
    ami = "ami-af4333cf"
    instance_type = "t2.medium"
    subnet_id = "subnet-49f27362"
    key_name = "ostempkey"
    count = "${var.master_count}"
    user_data = "${data.template_file.openshift_userdata.rendered}"
    vpc_security_group_ids = ["${aws_security_group.os_all_producers.id}"]
    iam_instance_profile = "${aws_iam_instance_profile.oss3_profile.id}"
    tags {
        Name = "os-master-${count.index}"
    }
}

//INSTANTIATION EC2
resource "aws_instance" "lb" {
    ami = "ami-af4333cf"
    instance_type = "t2.medium"
    subnet_id = "subnet-49f27362"
    key_name = "ostempkey"
    user_data = ""
    vpc_security_group_ids = ["${aws_security_group.os_all_producers.id}"]
    iam_instance_profile = "${aws_iam_instance_profile.oss3_profile.id}"
    tags {
        Name = "os-loadbalancer"
    }
}

//INSTANTIATION EC2
resource "aws_instance" "os_nodes" {
    ami = "ami-af4333cf"
    instance_type = "t2.medium"
    subnet_id = "subnet-49f27362"
    key_name = "ostempkey"
    count = "${var.nodes_count}"
    user_data = "${data.template_file.openshift_userdata.rendered}"
    vpc_security_group_ids = ["${aws_security_group.os_all_producers.id}"]
    iam_instance_profile = "${aws_iam_instance_profile.oss3_profile.id}"
    tags {
        Name = "os-master-${count.index}"
    }
}

data "template_file" "hosts" {
    template = "${file("./hosts.tpl")}"

    vars {
        MASTER1 = "${aws_instance.os_master.0.private_ip}"
        MASTER2 = "${aws_instance.os_master.1.private_ip}"
        LB1 = "${aws_instance.lb.private_ip}"
    }
}

data "template_file" "os_master_userdata" {
    template = "${file("./openshift_master.tpl")}"
}

data "template_file" "os_lb_userdata" {
    template = "${file("./openshift_lb.tpl")}"
}

data "template_file" "os_node_userdata" {
    template = "${file("./openshift_node.tpl")}"
}
