terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 3.0"
    }
  }
}

# Configure the AWS Provider
provider "aws" {
  access_key = var.accessID
  secret_key = var.secretkey
  region = "us-east-1"
}

# Create a VPC
resource "aws_key_pair" "ram_aws" {
  key_name   = "ram_aws"
  public_key = file(var.jenkins)
}
output "AWS_Link" {
  //value = concat([aws_instance.ubuntu.public_dns,""],[":8080/spring-mvc-example",""])
  value=format("Access the AWS hosted app from here: %s%s", aws_instance.ram_aws.public_dns, ":8080/PersistentWebApp")
}
resource "aws_instance" "ram_aws" {
  key_name      = aws_key_pair.ram_aws.key_name
  ami           = "ami-047a51fa27710816e"
  instance_type = "t2.micro"

  tags = {
    Name = "ram_aws"
  }

  /*vpc_security_group_ids = [
    aws_security_group.vib_aws.id
  ]*/

  connection {
    type        = "ssh"
    user        = "ec2-user"
    private_key = file(var.jenkins_pem)
    host        = self.public_ip
  }


  user_data = <<-EOF
  #!bin/bash
  sudo amazon-linux-extras install tomcat8.5
  sudo systemctl enable tomcat
  sudo systemctl start tomcat
  cd /usr/share/tomcat/webapps/
  sudo cp /tmp/PersistentWebApp.war /usr/share/tomcat/webapps/PersistentWebApp.war
  EOF

  provisioner "file" {
    source      = "/var/lib/jenkins/workspace/assignment2/target/PersistentWebApp.war"
    destination = "/tmp/PersistentWebApp.war"
    connection {
      type        = "ssh"
      user        = "ec2-user"
      private_key = file(var.jenkins_pem)
      host        = self.public_ip
    }
  }

}

variable "accessID" {
  type = string
}

variable "secretkey" {
  type = string
}

variable "jenkins" {
  type = string
}


variable "jenkins_pem" {
  type = string
}