resource "aws_security_group" "lb-sg" {
  provider    = aws.region-master
  name        = "lb-sg"
  description = "Allows 443 and traffic to Jenkins SG"
  vpc_id      = aws_vpc.vpc_master.id
  ingress {
    protocol    = "tcp"
    from_port   = 443
    to_port     = 443
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow 443 from anywhere"
  }
  ingress {
    protocol    = "tcp"
    from_port   = 80
    to_port     = 80
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow 80 from anywhere for redirection"
  }
  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# SG for Jenkins Master
resource "aws_security_group" "jenkins-master-sg" {
  provider    = aws.region-master
  name        = "jenkins-master-sg"
  description = "Allow TCP 8080&22"
  vpc_id      = aws_vpc.vpc_master.id
  ingress {
    protocol    = "tcp"
    from_port   = 22
    to_port     = 22
    cidr_blocks = [var.external_ip]
    description = "Allow 22 from our public IP"
  }
  ingress {
    protocol        = "tcp"
    from_port       = 8080
    to_port         = 8080
    security_groups = [aws_security_group.lb-sg.id]
    description     = "Allow anyone on port 8080"
  }
  ingress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["192.168.1.0/24"]
    description = "Allow all traffic from worker"
  }

  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
    description = "outbound traffic anywhere"
  }
}

# SG for Jenkins Worker
resource "aws_security_group" "jenkins-worker-sg" {
  provider = aws.region-worker

  name        = "jenkins-worker-sg"
  description = "Allows 8080&22"
  vpc_id      = aws_vpc.vpc_worker.id

  ingress {
    protocol    = "tcp"
    from_port   = 22
    to_port     = 22
    cidr_blocks = [var.external_ip]
    description = "Allow 22 from home"
  }
  ingress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["10.0.1.0/24"]
    description = "Allow all traffic from us-east subnet"
  }
  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
}