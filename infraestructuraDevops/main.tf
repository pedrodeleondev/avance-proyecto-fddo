#Proveedor de nube
provider "aws" {
  region = "us-west-2"
}

#VPC Oregon
resource "aws_vpc" "vpc_oregon" {
    cidr_block = "10.0.0.0/16"
    tags = {
      Name = "VPC Oregon - Proyecto"
    }
}

#Gateway
resource "aws_internet_gateway" "igw-oregon" {
    vpc_id = aws_vpc.vpc_oregon.id
    tags = {
      Name = "IGW Oregon - Proyecto"
    }
}

#Subred Publica Oregon Web
resource "aws_subnet" "subred_publica_oregon_Web" {
  vpc_id = aws_vpc.vpc_oregon.id
  cidr_block = "10.0.0.0/24"
  availability_zone = "us-west-2a"
  map_public_ip_on_launch = true

  tags = {
    Name = "Subred Publica Web Oregon - Proyect"
  }
}

#Subred Privada Oregon - Backend
resource "aws_subnet" "subred_privada_oregon_Back" {
  vpc_id = aws_vpc.vpc_oregon.id
  cidr_block = "10.1.2.0/24"
  availability_zone = "us-west-2b"

 tags = {
    Name = "Subred Privada Backend - Proyect"
  }
}

#Subred Privada Oregon - Base de datos
resource "aws_subnet" "subred_privada_oregon_BD" {
  vpc_id = aws_vpc.vpc_oregon.id
  cidr_block = "10.1.3.0/24"
  availability_zone = "us-west-2c"

 tags = {
    Name = "Subred Privada BD - Proyect"
  }
}

#Grupo de subred RDS
resource "aws_db_subnet_group" "db_subnet_group" {
  name = "db-subnet-group"
  subnet_ids = [
    aws_subnet.subred_privada_oregon_Back.id,
    aws_subnet.subred_privada_oregon_BD.id
  ]

  tags = {
    Name = "Grupo de subred BD - Proyect"
  }
}

#Tabla de rutas Oregon
resource "aws_route_table" "tabla_rutas_oregon" {
  vpc_id = aws_vpc.vpc_oregon.id

  route{
    cidr_block = "10.0.0.0/16"
    gateway_id = aws_internet_gateway.igw-oregon.id
  }

  tags = {
    Name = "Tabla Rutas Oregon"
  }
}
resource "aws_route_table_association" "privada_oregon_Backend" {
  subnet_id = aws_subnet.subred_privada_oregon_Back.id
  route_table_id = aws_route_table.tabla_rutas_oregon.id
}
resource "aws_route_table_association" "privada_oregon_BD" {
  subnet_id = aws_subnet.subred_privada_oregon_BD.id
  route_table_id = aws_route_table.tabla_rutas_oregon.id
}
resource "aws_route_table_association" "publica_oregon_Web" {
  subnet_id = aws_subnet.subred_publica_oregon_Web.id
  route_table_id = aws_route_table.tabla_rutas_oregon.id
} 

#Grupo de seguridad para Servidores Web Linux
resource "aws_security_group" "SG-WebOregon" {
  vpc_id = aws_vpc.vpc_oregon.id
  name = "SG-Proyect-WebOregon"
  description = "Conexión al servidor Windows Web Oregon por RDP desde IPs especificas y acceso a HTTP/HTTPS por internet"

  #Trafico RDP desde IP de integrantes
  ingress {
    from_port = 3389
    to_port = 3389
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"] #TU IP al final de ella poner un "/32"
  }

  #Trafico HTTP desde cualquier IP
  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = [ "0.0.0.0/0" ]
  }

  #Trafico HTTPS desde cualquier IP
  ingress {
    from_port = 443
    to_port = 443
    protocol = "tcp"
    cidr_blocks = [ "0.0.0.0/0" ]
  }

  #Salida a todo el trafico
  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = [ "0.0.0.0/0" ]
  }  
}

#Grupo de seguridad para Windows Backend
resource "aws_security_group" "SG-WindowsBackend" {
  vpc_id = aws_vpc.vpc_oregon.id
  name = "SG-WindowsBackend"
  description = "Acceso a Windows Backend desde instancias Web y acceso desde los servicios Web"

  #Trafico RDP mediante IP de Linux Web
  ingress {
    from_port = 3389
    to_port = 3389
    protocol = "tcp"
    cidr_blocks = [format("%s/32", aws_instance.instancia_WebVirginia.private_ip), format("%s/32", aws_instance.instancia_WebOregon.private_ip)]
  }

  #Trafico Web mediante grupo de seguridad de Servidores Web
  ingress {
    from_port = 5000
    to_port = 5000
    protocol = "tcp"
    security_groups = [aws_security_group.SG-WebVirginia.id, aws_security_group.SG-WebOregon.id]
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

#Grupo de seguridad para RDS MySQL
resource "aws_security_group" "SG-BD" {
  vpc_id = aws_vpc.vpc_oregon.id
  name = "SG-BaseDeDatos"
  description = "Acceso a MySQL RDS mediante Windows Backend"

  #Trafico MySQL mediante Windows Backend
  ingress {
    from_port = 3306
    to_port = 3306
    protocol = "tcp"
    cidr_blocks = [format("%s/32", aws_instance.instancia_WindowsBack.private_ip)]
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

#Instancia Windows Backend con su grupo de seguridad
resource "aws_instance" "instancia_WindowsBack" {
  ami = "ami-005148a6a3abb558a"
  instance_type = "t2.medium"
  subnet_id = aws_subnet.subred_privada_oregon_Back.id
  key_name = "vockey"
  
  vpc_security_group_ids = [aws_security_group.SG-WindowsBackend.id]
  associate_public_ip_address = false 

  tags = {
    Name = "Windows Backend - Proyect"
  }
}

#Instancia de Windows Web Oregon con su grupo de seguridad
resource "aws_instance" "instancia_WebOregon" {
  ami = "ami-005148a6a3abb558a"
  instance_type = "t2.medium"
  subnet_id = aws_subnet.subred_publica_oregon_Web.id
  key_name = "vockey"
  
  vpc_security_group_ids = [aws_security_group.SG-WebOregon.id]
  associate_public_ip_address = true

  tags = {
    Name = "Windows Web Oregon - Proyect"
  }
}

resource "aws_db_instance" "BD_MySQL" {
  identifier = "bd-proyect-mysql"
  engine = "mysql"
  engine_version = "8.0"
  instance_class = "db.t3.micro"
  allocated_storage = 20
  storage_type = "gp2"
  username = "admin"
  password = "proyecto98765"
  db_subnet_group_name = aws_db_subnet_group.db_subnet_group.name
  vpc_security_group_ids = [aws_security_group.SG-BD.id]
  multi_az = false
  publicly_accessible = false
  skip_final_snapshot = true

  tags = {
    Name = "RDS MySQL - Proyect"
  }
}