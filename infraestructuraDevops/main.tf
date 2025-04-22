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

#Subred Privada Oregon - Backend
resource "aws_subnet" "subred_privada_oregon_Back" {
  vpc_id = aws_vpc.vpc_proyect.id
  cidr_block = "10.10.0.0/24"
  availability_zone = "us-east-1c"

 tags = {
    Name = "Subred Privada Backend - Proyect"
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


#Tabla de rutas privadas
resource "aws_route_table" "tabla_rutas_privadas" {
  vpc_id = aws_vpc.vpc_proyect.id

  tags = {
    Name = "Tabla Rutas Privadas"
  }
}
resource "aws_route_table_association" "privada_oregon_Backend" {
  subnet_id = aws_subnet.subred_privada_oregon_Back.id
  route_table_id = aws_route_table.tabla_rutas_privadas.id
}

#Rutas de subredes privadas
resource "aws_route_table_association" "publica_oregon_BD" {
  subnet_id = aws_subnet.subred_privada_oregon_BD.id
  route_table_id = aws_route_table.tabla_rutas_privadas.id
}

#Grupo de seguridad para Servidores Web Linux
resource "aws_security_group" "SG-WebLinux" {
  vpc_id = aws_vpc.vpc_proyect.id
  name = "GrupoSeguridad-Proyect-WebLinux"
  description = "Conexión al servidor Linux Web por SSH desde IPs especificas y acceso a HTTP/HTTPS por internet"

  #Trafico SSH desde IP de Windows Backend
  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["",""] #IP de todos los integrantes
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
  vpc_id = aws_vpc.vpc_proyect.id
  name = "SG-WindowsBackend"
  description = "Acceso a Windows Backend desde instancias Web y acceso desde los servicios Web"

  #Trafico RDP mediante IP de Linux Web
  ingress {
    from_port = 3389
    to_port = 3389
    protocol = "tcp"
    cidr_blocks = [format("%s/32", aws_instance.LinuxWeb1.private_ip), format("%s/32", aws_instance.LinuxWeb2.private_ip)]
  }

  #Trafico Web mediante grupo de seguridad de Servidores Web
  ingress {
    from_port = 5000
    to_port = 5000
    protocol = "tcp"
    security_groups = [aws_security_group.SG-WebLinux.id]
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
  vpc_id = aws_vpc.vpc_proyect.id
  name = "SG-BaseDeDatos"
  description = "Acceso a MySQL RDS mediante Windows Backend"

  #Trafico 
  ingress {
    from_port = 3306
    to_port = 3306
    protocol = "tcp"
    cidr_blocks = [format("%s/32", aws_instance.WindowsBack.private_ip)]
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
