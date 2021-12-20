provider "aws" {
   # access_key = "${var.access_key}"
   # secret_key = "${var.secret_key}"
    region     = "${var.region}"
}
#*****************Data_Source************
data "aws_region" "current" {}
data "aws_vpcs" "my_vpcs" {}

data "aws_vpc" "default" {
  default = true
} 
data "aws_availability_zones" "working" {}

data "aws_subnet_ids" "my_subnets" {
vpc_id = "${data.aws_vpc.default.id}"
}
data "aws_security_groups" "my_groups" {
 filter {
    name   = "vpc-id"
   values = ["vpc-*"]
  }
}
# ****************Creating Security group
resource "aws_security_group" "web" {
  name = "DynSG"
  dynamic "ingress" {
    for_each = ["80", "443", "3306", "22"]
    content {
      from_port   = ingress.value
      to_port     = ingress.value
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name  = "mySGroup"
  }
}
resource "aws_security_group" "RDS_SG" {
  ingress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = ["${aws_security_group.web.id}"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "bd"
  }
}
# **************Creating RDS instance
resource "aws_db_instance" "mydb" {
  allocated_storage      = 10
  engine                 = "mysql"
  engine_version         = "5.7"
  instance_class         = "db.t2.micro"
  vpc_security_group_ids =["${aws_security_group.RDS_SG.id}"]
  name                   = "${var.database_name}"
  username               = "${var.database_user}"
  password               = "${var.database_password}"
 skip_final_snapshot    = true
}

data "template_file" "user_data" {
  template = "${file("${path.module}/user_data.tpl")}"
  vars = {
    db_username     ="${var.database_user}"
    db_RDS_endpoint ="${aws_db_instance.mydb.endpoint}"
    region_name     ="${data.aws_region.current.name}"
    region_descr    ="${data.aws_region.current.description}"
  }
  depends_on = [aws_db_instance.mydb]
}
#***************Create EC2 ( after RDS )
resource "aws_instance" "my_instance" {
  ami ="${var.ami}"
  instance_type ="${var.instance_type}"
  security_groups =["${aws_security_group.web.name}"]
  user_data = "${data.template_file.user_data.rendered}"
  key_name ="${var.key_name}"
  tags = {
    Name = "my_instance"
  }
  depends_on = [aws_db_instance.mydb]
  
  lifecycle {
    create_before_destroy = true
  }
}

#**************Outputs***************
output "rds_endpoint" {
    value = aws_db_instance.mydb.endpoint
}
output "aws_vpcs" {
  value = data.aws_vpcs.my_vpcs.ids
}
output "data_aws_availability_zones" {
  value = data.aws_availability_zones.working.names
}
output "data_aws_region_name" {
  value = data.aws_region.current.name
}
output "data_aws_region_description" {
  value = data.aws_region.current.description
}
output "instance_private_ip_addr" {
  value = aws_instance.my_instance.private_ip
}
output "instance_public_ip_addr" {
  value = aws_instance.my_instance.public_ip
}
output "security_group_web_id" {
  value = try(aws_security_group.web.id, "")
}
output "security_group_RDS_id" {
   value = try(aws_security_group.RDS_SG.id, "")
}
output "subnets_default_id" {
  value = data.aws_subnet_ids.my_subnets.ids
}  
output "default_vpc" {
  value = data.aws_vpc.default.id
} 
output "default_security_group_id" {
  value = data.aws_security_groups.my_groups
}
