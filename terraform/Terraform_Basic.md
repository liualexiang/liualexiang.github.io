#### Terraform 初步学习手册
##### 下载安装Terraform
[Terraform](https://www.terraform.io/downloads.html) 为一个二进制文件，只要下载下来放到PATH路径下即可使用.

Terraform基本使用：
在下载好tf文件之后，直接执行下面的命令即可部署，如果在当前路径下有多个tf文件，则按照字母顺序执行

```
terraform init
terraform apply

terraform destroy //删除terraform资源
```

##### Terraform 的基本配置
Terraform可以配置环境变量，也可以不配置。如果配置环境变量的话，可以将环境变量保存到variables.tf这个文件中。变量可以指定不同的数据类型，比如list，set, map等格式，详情参考： https://www.terraform.io/docs/configuration/variables.html

示例配置文件
```
variable "region" {
    default = "cn-north-1"
}

variable "profile" {
    default = "default"
}
```

以与AWS集成为例，通过provider来指定云厂商
```
provider "aws" {
  profile = "default"
  region = "cn-north-1"
}
```

在使用环境变量的情况下，则写为
```
provider "aws" {
  profile = var.profile
  region = var.region
}
```

对于以前版本的terraform ()，也可以这么写，现已不推荐
```
provider "aws" {
  profile = "${var.profile}"
  region = "${var.region}"
}
```

##### 将结果通过output打印出来
如果想要获得resource执行的结果，那么可以通过output进行打印，下面是一个示例，打印出新建的VPC的ID

```
provider "aws" {
  profile = var.profile
  region = var.region
}

resource "aws_vpc" "terraform_vpc" {
  cidr_block = "192.168.0.0/16"
  instance_tenancy = "default"

  tags = {
    Name = "terraform_vpc"
  }
}

output "vpc_id" {
  value = aws_vpc.terraform_vpc.id
}
```

##### 示例：使用terraform创建一个VPC，子网，IGW，子网路由，以及EC2，EC2指定一个额外的EBS卷以及UseData.

有关跟AWS集成，参考： https://www.terraform.io/docs/providers/aws/index.html
很多资源都有Data Sources和Resources，其中Data Sources指的是获取当前的配置信息，如获取AMI的ID，获取现有VPC ID和Subnet ID等，Resources指的是创建新的资源，如创建VPC和创建Subnet


```
provider "aws" {
  profile = "default"
  region = "cn-north-1"
}

resource "aws_vpc" "terraform_vpc" {
  cidr_block = "192.168.0.0/16"
  instance_tenancy = "default"

  tags = {
    Name = "terraform_vpc"
  }
}

resource "aws_subnet" "public_subnet_01" {
  vpc_id = "${aws_vpc.terraform_vpc.id}"
  availability_zone = "cn-north-1a"
  cidr_block = "${cidrsubnet(aws_vpc.terraform_vpc.cidr_block, 4, 1)}"
}

resource "aws_internet_gateway" "igw" {
  vpc_id="${aws_vpc.terraform_vpc.id}"
  
  tags = {
    Name = "terraform_igw"
  }
}

resource "aws_route_table" "public" {
  vpc_id = "${aws_vpc.terraform_vpc.id}"
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.igw.id}"
  }
  tags = {
    Name = "terraform_public"
  }
}

resource "aws_route_table_association" "pub" {
  subnet_id = "${aws_subnet.public_subnet_01.id}"
  route_table_id = "${aws_route_table.public.id}"
}

data "aws_ami" "amzn2" {
  most_recent = true
  owners = ["amazon"]
  filter {
    name = "name"
    values = ["amzn2-ami-hvm-2.0.20200304.0-x86_64-gp2"]
  }
}

resource "aws_instance" "terraform_test" {
  ami = "${data.aws_ami.amzn2.id}"
  instance_type = "t2.micro"
  subnet_id = "${aws_subnet.public_subnet_01.id}"
  ebs_block_device {
    volume_type="gp2"
    volume_size = "500"
    device_name = "/dev/xvdf"
  }
  key_name = "BJSAWS"
  user_data = "touch /home/ec2-user/testfile_by_terraform"
  
  disable_api_termination = false

  tags = {
    Name = "terraform_instance"
  }
}

```


##### 跟VS Code集成
在VS Code中，可以搜索Terraform插件，能够实现编写tf文件的时候自动补全，且可以检查语法.