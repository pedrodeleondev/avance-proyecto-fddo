#Proveedor de nube
provider "aws" {
  region = "us-east-1"
}

#VPC
resource "aws_vpc" "vpc_proyect" {
    cidr_block = "10.0.0.0/16"
    tags = {
      Name = "VPC - Proyecto"
    }
}

#Gateway
resource "aws_internet_gateway" "igw" {
    vpc_id = aws_vpc.vpc_proyect.id
    tags = {
      Name = "IGW - Proyect"
    }
}

#Subred Publica Virginia Web
resource "aws_subnet" "subred_publica_virginia_Web" {
  vpc_id = aws_vpc.vpc_proyect.id
  cidr_block = "10.0.0.0/24"
  availability_zone = "us-east-1a"
  map_public_ip_on_launch = true

  tags = {
    Name = "Subred Publica Web Virginia - Proyect"
  }
}

#Subred Publica Oregon Web
resource "aws_subnet" "subred_publica_oregon_Web" {
  vpc_id = aws_vpc.vpc_proyect.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "us-east-1b"
  map_public_ip_on_launch = true

  tags = {
    Name = "Subred Publica Web Oregon - Proyect"
  }
}

#Subred Publica Oregon - Backend
resource "aws_subnet" "subred_publica_oregon_Back" {
  vpc_id = aws_vpc.vpc_proyect.id
  cidr_block = "10.10.0.0/24"
  availability_zone = "us-east-1c"
  map_public_ip_on_launch = true

 tags = {
    Name = "Subred Publica Backend - Proyect"
  }
}

#Subred Privada Oregon - Base de datos
resource "aws_subnet" "subred_privada_oregon_BD" {
  vpc_id = aws_vpc.vpc_proyect.id
  cidr_block = "10.10.1.0/24"
  availability_zone = "us-east-1d"

 tags = {
    Name = "Subred Privada BD - Proyect"
  }
}

#Tabla de rutas publicas
resource "aws_route_table" "tabla_rutas_publicas" {
  vpc_id = aws_vpc.vpc_proyect.id

  route{
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "Tabla Rutas Publicas"
  }
}

#Rutas de subredes publicas Web
resource "aws_route_table_association" "publica_virginia_Web" {
  subnet_id = aws_subnet.subred_publica_virginia_Web.id
  route_table_id = aws_route_table.tabla_rutas_publicas.id
}
resource "aws_route_table_association" "publica_oregon_Web" {
  subnet_id = aws_subnet.subred_publica_oregon_Web.id
  route_table_id = aws_route_table.tabla_rutas_publicas.id
}
resource "aws_route_table_association" "publica_oregon_Backend" {
  subnet_id = aws_subnet.subred_publica_oregon_Back.id
  route_table_id = aws_route_table.tabla_rutas_publicas.id
}

#Tabla de rutas privadas
resource "aws_route_table" "tabla_rutas_privadas" {
  vpc_id = aws_vpc.vpc_proyect.id

  tags = {
    Name = "Tabla Rutas Privadas"
  }
}

#Rutas de subredes privadas
resource "aws_route_table_association" "publica_oregon_BD" {
  subnet_id = aws_subnet.subred_privada_oregon_BD.id
  route_table_id = aws_route_table.tabla_rutas_privadas.id
}