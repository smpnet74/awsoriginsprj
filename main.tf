# Configure the AWS Provider
provider "aws" {
    access_key = "${var.access_key}"
    secret_key = "${var.secret_key}"
    region = "${var.setregion}"
}

//SECURITY GROUP
resource "aws_security_group" "os_all_producers" {

  name = "os_consumer"
  vpc_id = "${var.vpcid}"
  description = "Security group to allow all sources to intercommunicate and to talk out"

  ingress {
    from_port = "0"
    to_port = "0"
    protocol = "-1"
    self = true
    cidr_blocks = ["73.210.192.27/32"]
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
  bucket = "${var.bucket1}"
  force_destroy = true
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
      "Resource": "arn:aws:s3:::${var.bucket1}/*"
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

//WRITE ANSIBLE HOSTS FILE TO S3
resource "aws_s3_bucket_object" "hostsobj" {
    bucket = "${var.bucket1}"
    key = "hosts"
    content = "${data.template_file.ansiblehosts.rendered}"
}

//WRITE OPENSHIFT STORAGE YAML FILE TO S3
resource "aws_s3_bucket_object" "osyamlobj" {
    bucket = "${var.bucket1}"
    key = "storage.yaml"
    content = "${data.template_file.persistantyaml.rendered}"
}

//USER CREATION
resource "aws_key_pair" "deployer" {
  key_name = "deployer-key" 
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC9nVOtCeQ8bCGJdyTmOVCtZU4Bh0xoc/lSKVDfmCQfDc5vtaYOVyfQPat0d4vZiBe6LLfEEy6qIxccBhSuczKgf4y8SVyfFs8x5UjD5fEP3j5bnAufi8P452vdd84z1GGr1DJeJKboolf7+4M+L6SpwB2mawbbF2rtFzah2eJE8YmV8JH6Kj88mP2AVFLFQo5FoEHZHb8rDJrKsyivj+VxxMtovAoERRurdpdIgR3AFHC3CPNqUoxGjZ9sAY2EeNwitJRXaDT16gxTnlIHZjTHSN1/DJEGq1U+36AP0CDyrtyPimc9wui3I2XRAehMK90rmf+ikb4WMl6M3v4CHwfj vagrant@vagrant-ubuntu-trusty-64"
}

//EFS FILESYSTEM

resource "aws_efs_file_system" "openshift_efs" {
  creation_token = "my-product123"
  performance_mode = "generalPurpose"
  tags {
    Name = "MyProduct123"
  }
}

resource "aws_efs_mount_target" "openshift_mount" {
  file_system_id = "${aws_efs_file_system.openshift_efs.id}"
  subnet_id = "${var.subnet}"
  security_groups = ["${aws_security_group.os_all_producers.id}"]
}


//INSTANTIATION EC2
resource "aws_instance" "os_master" {
    key_name = "deployer-key"
    ami = "${var.aminumber}"
    instance_type = "${var.master_instsize}"
    subnet_id = "${var.subnet}"
    key_name = "deployer-key"
    count = "${var.master_count}"
    user_data = "${data.template_file.os_master_userdata.rendered}"
    vpc_security_group_ids = ["${aws_security_group.os_all_producers.id}"]
    iam_instance_profile = "${aws_iam_instance_profile.oss3_profile.id}"
    tags {
        Name = "os-master-${count.index}"
    }
    root_block_device {
      delete_on_termination = true
    }
    ebs_block_device {
      device_name = "/dev/sdg"
      volume_size = 10  
      volume_type = "gp2"
      delete_on_termination = true
    }
}

//INSTANTIATION EC2
resource "aws_instance" "os_nodes" {
    key_name = "deployer-key"
    ami = "${var.aminumber}"
    instance_type = "${var.nodes_instsize}"
    subnet_id = "${var.subnet}"
    key_name = "deployer-key"
    count = "${var.nodes_count}"
    user_data = "${data.template_file.os_node_userdata.rendered}"
    vpc_security_group_ids = ["${aws_security_group.os_all_producers.id}"]
    iam_instance_profile = "${aws_iam_instance_profile.oss3_profile.id}"
    tags {
        Name = "os-node-${count.index}"
    }
    root_block_device {
      delete_on_termination = true
    }
    ebs_block_device {
      device_name = "/dev/sdg"
      volume_size = 10  
      volume_type = "gp2"
      delete_on_termination = true
  }
}

/*
//INSTANTIATION EC2
resource "aws_instance" "lb" {
    ami = "${var.aminumber}"
    instance_type = "${var.lb_instsize}"
    subnet_id = "${var.subnet}"
    key_name = "deployer-key"
    user_data = "${data.template_file.os_lb_userdata.rendered}"
    vpc_security_group_ids = ["${aws_security_group.os_all_producers.id}"]
    iam_instance_profile = "${aws_iam_instance_profile.oss3_profile.id}"
    root_block_device {
      delete_on_termination = true
    }
    tags {
        Name = "os-loadbalancer"
    }
}
*/
data "template_file" "ansiblehosts" {
    template = "${file("./hosts.tpl")}"

    vars {
        MASTER1 = "${aws_instance.os_master.0.public_dns}"
        MASTER2 = ""
        NODE1 = "${aws_instance.os_nodes.0.public_dns}"
        NODE2 = "${aws_instance.os_nodes.1.public_dns}"
        LB1 = ""
    }
}

data "template_file" "os_master_userdata" {
    template = "${file("./openshift_master.tpl")}"
    vars {
        BUCKET1 = "${var.bucket1}"
    }
}

data "template_file" "os_lb_userdata" {
    template = "${file("./openshift_lb.tpl")}"
}

data "template_file" "os_node_userdata" {
    template = "${file("./openshift_node.tpl")}"
    vars {
        BUCKET1 = "${var.bucket1}"
    }
}

data "template_file" "persistantyaml" {
    template = "${file("./persistant.tpl")}"
    vars {
        EFSHOSTNAME = "${aws_efs_mount_target.openshift_mount.dns_name}"
    }
}
