# Create VPC in us-east-1

resource "aws_vpc" "vpc_master" {
  provider             = aws.region-master
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name = "master-vpc-jenkins"
  }
}
resource "aws_internet_gateway" "igw_master" {
  provider = aws.region-master
  vpc_id   = aws_vpc.vpc_master.id
}

data "aws_availability_zones" "azs" {
  provider = aws.region-master
  state    = "available"
}

# Subnet
resource "aws_subnet" "master_subnet_1" {
  provider          = aws.region-master
  vpc_id            = aws_vpc.vpc_master.id
  availability_zone = element(data.aws_availability_zones.azs.names, 0)
  cidr_block        = "10.0.1.0/24"
}

resource "aws_subnet" "master_subnet_2" {
  provider          = aws.region-master
  vpc_id            = aws_vpc.vpc_master.id
  availability_zone = element(data.aws_availability_zones.azs.names, 1)
  cidr_block        = "10.0.2.0/24"
}

# Create VPC in us-west-2
resource "aws_vpc" "vpc_worker" {
  provider             = aws.region-worker
  cidr_block           = "192.168.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name = "worker-vpc-jenkins"
  }
}

resource "aws_internet_gateway" "igw_worker" {
  provider = aws.region-worker
  vpc_id   = aws_vpc.vpc_worker.id
}


resource "aws_subnet" "worker_subnet_1" {
  provider   = aws.region-worker
  vpc_id     = aws_vpc.vpc_worker.id
  cidr_block = "192.168.1.0/24"
}

### Peering
# Peering Request
resource "aws_vpc_peering_connection" "useast1-to-uswest2" {
  provider = aws.region-master
  vpc_id   = aws_vpc.vpc_master.id

  peer_vpc_id = aws_vpc.vpc_worker.id
  peer_region = var.region-worker

}

# Peering Accept
resource "aws_vpc_peering_connection_accepter" "accept_peering" {
  provider                  = aws.region-worker
  vpc_peering_connection_id = aws_vpc_peering_connection.useast1-to-uswest2.id
  auto_accept               = true
}


# Route table for master
resource "aws_route_table" "internet-route" {
  provider = aws.region-master
  vpc_id   = aws_vpc.vpc_master.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw_master.id
  }
  route {
    cidr_block                = "192.168.1.0/24" # worker vpn subnet
    vpc_peering_connection_id = aws_vpc_peering_connection.useast1-to-uswest2.id
  }

  lifecycle {
    ignore_changes = all

  }

  tags = {
    Name = "Master-Region-RT"
  }
}

resource "aws_main_route_table_association" "set-master-default-rt-assoc" {
  provider       = aws.region-master
  vpc_id         = aws_vpc.vpc_master.id
  route_table_id = aws_route_table.internet-route.id
}

# Route table for worker

resource "aws_route_table" "internet_route_worker" {
  provider = aws.region-worker
  vpc_id   = aws_vpc.vpc_worker.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw_worker.id
  }
  route {
    cidr_block                = "10.0.1.0/24"
    vpc_peering_connection_id = aws_vpc_peering_connection.useast1-to-uswest2.id
  }
  lifecycle {
    ignore_changes = all
  }
  tags = {
    Name = "Worker-Region-RT"
  }
}

resource "aws_main_route_table_association" "set-worker-rt-association" {
  provider       = aws.region-worker
  route_table_id = aws_route_table.internet_route_worker.id
  vpc_id         = aws_vpc.vpc_worker.id
}