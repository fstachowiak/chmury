//określa platformę na której będzie tworzona infrastruktura i region
provider "aws" {
	region = "us-east-1"
}


//Tworzy VPC z określonym zakresem adresów IP, włącza obsługę DNS i hostów DNS
resource "aws_vpc" "mainvpc" {
	cidr_block = "10.0.0.0/16"
	enable_dns_support = true
	enable_dns_hostnames = true
}

//Tworzy podprzestrzeń (subnet) wewnątrz VPC z określonym zakresem adresów IP i przypisuje ją do strefy
resource "aws_subnet" "main_subnet" {
    vpc_id     = aws_vpc.mainvpc.id
    cidr_block = "10.0.1.0/24"
    availability_zone = "us-east-1a"
}

//tworzy brame internetową aby instancje vpc mogły sie komunikować z internetem
resource "aws_internet_gateway" "maingateway" {
	vpc_id = aws_vpc.mainvpc.id
}

//Tworzy tabele routingu i dodaje trase domyślną, która kieruje ruch do Internet Gateway
resource "aws_route_table" "mainroutetable" {
	vpc_id = aws_vpc.mainvpc.id
	
	route {
		cidr_block = "0.0.0.0/0"
		gateway_id = aws_internet_gateway.maingateway.id
	}
}

//Przypisuje routing table do subnet
resource "aws_route_table_association" "main_subnet" {
	subnet_id = aws_subnet.main_subnet.id
	route_table_id = aws_route_table.mainroutetable.id
}

//Tworzy grupę zabezpieczeń, kontrola ruchu do i z instancji
resource "aws_security_group" "app_sg" {
    name        = "app-security-group"
    description = "Security group for the application"
	vpc_id = aws_vpc.mainvpc.id
	
	  egress {
		from_port   = 0
		to_port     = 0
		protocol    = "-1"
		cidr_blocks = ["0.0.0.0/0"]
	  }

	  ingress {
		from_port   = 22
		to_port     = 22
		protocol    = "tcp"
		description = "SSH"
		cidr_blocks = ["0.0.0.0/0"]
	  }

    ingress {
      from_port   = 3000
      to_port     = 3000
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }

    ingress {
      from_port   = 8080
      to_port     = 8080
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
}

//instancja EC2 
resource "aws_instance" "server" {
	ami = "ami-051f8a213df8bc089"
	instance_type = "t2.micro"
	associate_public_ip_address = true //publiczny adres ip
	key_name = "lab" //para kluczy użyta przy połączeniu SSH
	
	tags = {
		Name = "Server"	
	}
	
	user_data = "${file("install.sh")}" //skrypt uruchomiony przy pierwszym uruchomieniu instancji
	
	connection { //parametry ołączenia ssh z instancją
		type = "ssh"
		user = "ec2-user"
		private_key = file("C:/Users/filip/.awsLabKeyspem/lab.pem")
		host = aws_instance.server.public_ip
	}
		
	subnet_id = aws_subnet.main_subnet.id //subnet do której należy instancja
	vpc_security_group_ids = [aws_security_group.app_sg.id] //grupa zabezpieczen przypisana do instancji 
}