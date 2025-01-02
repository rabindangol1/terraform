provider "aws" {
  region     = "us-east-1"
}

variable "root_ssh_pub_key" {
  type = string
  default = ""
}
variable "deployer_ssh_pub_key" {
  type = string
  default = ""
}

data "template_file" "init_script" {
  template = file("init_script.sh") 
}

resource "aws_key_pair" "deployer_root_key" {
  key_name = "deployer_root_key_mainnet"
  public_key = file("~/.ssh/id_rsa.pub")
  
}

data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}


resource "aws_instance" "web" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t3.medium" 
  key_name      = "deployer_root_key_mainnet"
  count= 3

  root_block_device {
    volume_size           = 25
  }

  tags = {
    Name = "node-${count.index +1}"
    Project = "IBC"
  }

  user_data = data.template_file.init_script.rendered
}

output "instance_private_ip" {
 value =[for i in aws_instance.web : i.private_ip ]
}
output "instance_public_ip" {
 value =[for i in aws_instance.web : i.public_ip ]

}
