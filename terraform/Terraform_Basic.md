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
###### 环境变量配置
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
##### terraform中代码区间的说明

* resource 指的是要创建什么资源，引用resource的输出，直接用resource.xxx就可以. 示例如下，引用name的时候需要指定 azurerm_resource_group.example_rg.name
```
resource "azurerm_resource_group" "example_rg" {
  name     = "example-rgname"
  location = "East US 2"
}
```
* data 指的是获取现有的配置的属性，引用data的输出，要使用data.xxx.xxx这种方式，示例如下，引用name的时候要指定 data.azurerm_ssh_public_key.pub_key.name
```
data "azurerm_ssh_public_key" "pub_key" {
    name = "alex"
    resource_group_name = "xiangliu_csa"
}
```


###### tf文件编写指南 
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
##### 创建多个资源

* 可以在resource里面使用count来进行计数，然后通过 ${count.index} 变量来获取每一次的count的索引(从0开始)。如果创建的多个资源之间有依赖关系，比如创建了2个网卡，需要将2个网卡绑定到2个VM上，那么 count要一致。
* 也可以使用for_each 来指定对应关系。比如上述的创建2个网卡，2个VM的例子，最佳做法是：将vm_name存成一个变量，然后创建网卡和虚拟机的时候，通过for_each(var.vm_name) 进行遍历，然后 name 则为 each.value。这样本身就有了对应关系。参考[示例](https://docs.rackspace.com/blog/create-a-vm-in-azure-by-using-terraform-with-for-loops/)脚本

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


##### 使用 count 创建多个同一Resource

[count](https://www.terraform.io/docs/configuration/resources.html#count-multiple-resource-instances-by-count) 比较适合于创建一样的多个资源，如果资源的部分参数不一样，可以用for each来创建.

示例：创建3个vpc，就在resource中指定 count=3即可。在tag命名的时候，count.index默认是从0开始，因此可以count.index+1来指定从1开始。
在output中，由于前面指定了count，有多个资源返回，可以用join Function将每一个vpc id通过逗号拼接起来。
使用[formatlist](https://www.terraform.io/docs/configuration/functions/formatlist.html)，则可以将返回的每一个vpc id在处理的时候，加上指定的字符串"the vpc id is:"

```
provider "aws" {
  profile = var.profile
  region = var.region
}

resource "aws_vpc" "terraform_vpc" {
  count =3
  cidr_block = "192.168.0.0/16"
  instance_tenancy = "default"

  tags = {
    Name = "terraform_vpc_${count.index + 1}"
  }
}


/*
output "vpc_id" {
  value = join(",",aws_vpc.terraform_vpc.*.id)
}
*/

output "vpc_id" {
  value = join("\n", formatlist("the vpc id is: %s",aws_vpc.terraform_vpc.*.id))
}

```

使用[for_each](https://www.terraform.io/docs/configuration/resources.html#for_each-multiple-resource-instances-defined-by-a-map-or-set-of-strings) 可以在创建每一个resource的时候，指定不同的参数，有关for_each，可以看这个blog: https://www.hashicorp.com/blog/hashicorp-terraform-0-12-preview-for-and-for-each/

示例
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
resource "aws_subnet" "public_subnets" {
  for_each = {
    "cn-north-1a" = 1 
    "cn-north-1b" = 2
  }
  vpc_id = aws_vpc.terraform_vpc.id
  availability_zone = each.key
  cidr_block = cidrsubnet(aws_vpc.terraform_vpc.cidr_block, 8, each.value)

  tags = {
    Name = "terraform_subnet_${each.value}"
  }
}
```


##### 跟VS Code集成
在VS Code中，可以搜索Terraform插件，能够实现编写tf文件的时候自动补全，且可以检查语法.
在使用的时候，遇到一些问题，比如v0.12.24的Terraform和VS Code Terraform 1.4.0 插件兼容有一些问题，无法直接识别 var.xxx 这种变量，要通过 ${"var.xxx"}的方式才能识别，但后者逐渐被Terraform淘汰。为解决这个问题，可以在VS code settigns.json中，启用 Terraform Language Server. 不过当前terraform index和 language server冲突，只建议启用一个，关闭 terraform index的话就无法自动补全了，这样做得不偿失，因此还是建议关闭 language server而启用index
```
    "terraform.languageServer": {
        "enabled": false,
        "args": []
    },
    "terraform.indexing": {
        "enabled": true,
        "liveIndexing": true
        }

```
