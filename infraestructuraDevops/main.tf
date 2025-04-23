#Proveedor de nube
provider "aws" {
  region = "us-east-1"
}

provider "aws" {
  alias  = "oregon"
  region = "us-west-2"
}

#VPC Virginia
resource "aws_vpc" "vpc_virginia" {
    cidr_block = "10.0.0.0/16"
    tags = {
      Name = "VPC Virginia - Proyecto"
    }
}

#VPC Oregon
resource "aws_vpc" "vpc_oregon" {
    cidr_block = "10.1.0.0/16"
    tags = {
      Name = "VPC Oregon - Proyecto"
    }
}

#VPC Peering entre Virginia y Oregon
resource "aws_vpc_peering_connection" "conexion_peering" {
  provider = aws
  vpc_id = aws_vpc.vpc_virginia.id
  peer_vpc_id = aws_vpc.vpc_oregon.id
  peer_region = "us-west-2"

  tags = {
    Name = "VPC Peering - Virginia&Oregon"
  }
}

#Gateway Virginia & Oregon
resource "aws_internet_gateway" "igw-virginia" {
    vpc_id = aws_vpc.vpc_virginia.id
    tags = {
      Name = "IGW Virginia - Proyect"
    }
}
resource "aws_internet_gateway" "igw-oregon" {
    vpc_id = aws_vpc.vpc_oregon.id
    tags = {
      Name = "IGW Oregon - Proyect"
    }
}

#Subred Publica Virginia Web
resource "aws_subnet" "subred_publica_virginia_Web" {
  vpc_id = aws_vpc.vpc_virginia.id
  cidr_block = "10.0.0.0/24"
  availability_zone = "us-east-1a"
  map_public_ip_on_launch = true

  tags = {
    Name = "Subred Publica Web Virginia - Proyect"
  }
}

#Subred Publica Oregon Web
resource "aws_subnet" "subred_publica_oregon_Web" {
  provider = aws.oregon
  vpc_id = aws_vpc.vpc_oregon.id
  cidr_block = "10.1.1.0/24"
  availability_zone = "us-west-2a"
  map_public_ip_on_launch = true

  tags = {
    Name = "Subred Publica Web Oregon - Proyect"
  }
}

#Subred Privada Oregon - Backend
resource "aws_subnet" "subred_privada_oregon_Back" {
  provider = aws.oregon
  vpc_id = aws_vpc.vpc_oregon.id
  cidr_block = "10.10.0.0/24"
  availability_zone = "us-west-2b"

 tags = {
    Name = "Subred Privada Backend - Proyect"
  }
}

#Subred Privada Oregon - Base de datos
resource "aws_subnet" "subred_privada_oregon_BD" {
  provider = aws.oregon
  vpc_id = aws_vpc.vpc_oregon.id
  cidr_block = "10.10.1.0/24"
  availability_zone = "us-west-2c"

 tags = {
    Name = "Subred Privada BD - Proyect"
  }
}

#Grupo de subred RDS
resource "aws_db_subnet_group" "db_subnet_group" {
  provider = aws.oregon
  name = "db-subnet-group"
  subnet_ids = [
    aws_subnet.subred_privada_oregon_Back.id,
    aws_subnet.subred_privada_oregon_BD.id
  ]

  tags = {
    Name = "Grupo de subred BD - Proyect"
  }
}

#Tabla de rutas Virginia
resource "aws_route_table" "tabla_rutas_virginia" {
  provider = aws
  vpc_id = aws_vpc.vpc_virginia.id

  route{
    cidr_block = "10.1.0.0/16"
    gateway_id = aws_vpc_peering_connection.conexion_peering.id
  }

  tags = {
    Name = "Tabla Rutas Virginia"
  }
}
resource "aws_route_table_association" "publica_virginia_Web" {
  subnet_id = aws_subnet.subred_publica_virginia_Web.id
  route_table_id = aws_route_table.tabla_rutas_virginia.id
}

#Tabla de rutas Oregon
resource "aws_route_table" "tabla_rutas_oregon" {
  provider = aws.oregon
  vpc_id = aws_vpc.vpc_oregon.id

  route{
    cidr_block = "10.0.0.0/16"
    gateway_id = aws_vpc_peering_connection.conexion_peering.id
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
resource "aws_security_group" "SG-WebLinuxVirginia" {
  vpc_id = aws_vpc.vpc_virginia.id
  name = "SG-Proyect-WebLinuxVirginia"
  description = "Conexión al servidor Linux Web Virginia por SSH desde IPs especificas y acceso a HTTP/HTTPS por internet"

  #Trafico SSH desde IP de integrantes
  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["187.138.109.214/32"] #IP de todos los integrantes
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

resource "aws_security_group" "SG-WebLinuxOregon" {
  vpc_id = aws_vpc.vpc_oregon.id
  name = "SG-Proyect-WebLinuxOregon"
  description = "Conexión al servidor Linux Web Oregon por SSH desde IPs especificas y acceso a HTTP/HTTPS por internet"

  #Trafico SSH desde IP de integrantes
  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"] #Agregar IP de todos los integrantes
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
    cidr_blocks = [format("%s/32", aws_instance.LinuxWebVirginia.private_ip), format("%s/32", aws_instance.LinuxWebOregon.private_ip)]
  }

  #Trafico Web mediante grupo de seguridad de Servidores Web
  ingress {
    from_port = 5000
    to_port = 5000
    protocol = "tcp"
    security_groups = [aws_security_group.SG-WebLinuxVirginia.id, aws_security_group.SG-WebLinuxOregon.id]
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
  provider = aws.oregon
  ami = "ami-0c765d44cf1f25d26"
  instance_type = "t2.medium"
  subnet_id = aws_subnet.subred_privada_oregon_Back.id
  key_name = "vockey"
  
  vpc_security_group_ids = [aws_security_group.SG-WindowsBackend.id]
  associate_public_ip_address = false 

  tags = {
    Name = "Windows Backend - Proyect"
  }
}

#Instancia de Linux Web Oregon con su grupo de seguridad
resource "aws_instance" "instancia_LinuxWebOregon" {
  provider = aws.oregon
  ami = "ami-084568db4383264d4"
  instance_type = "t2.micro"
  subnet_id = aws_subnet.subred_publica_oregon_Web.id
  key_name = "vockey"
  
  vpc_security_group_ids = [aws_security_group.SG-WebLinuxOregon.id]
  associate_public_ip_address = true

  tags = {
    Name = "Linux Web Oregon - Proyect"
  }
}

#Instancia de Linux Web Virginia con su grupo de seguridad
resource "aws_instance" "instancia_LinuxWebVirginia" {
  provider = aws
  ami = "ami-084568db4383264d4"
  instance_type = "t2.micro"
  subnet_id = aws_subnet.subred_publica_virginia_Web.id
  key_name = "vockey"
  
  vpc_security_group_ids = [aws_security_group.SG-WebLinuxVirginia.id]
  associate_public_ip_address = true

  tags = {
    Name = "Linux Web Virginia - Proyect"
  }
}

resource "aws_db_instance" "BD_MySQL" {
  provider = aws.oregon
  identifier = "BaseDeDatos-Proyect-MySQL"
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