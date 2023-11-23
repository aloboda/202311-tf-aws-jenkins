

data "aws_ssm_parameter" "linuxAmiMaster" {
  provider = aws.region-master
  name     = "/aws/service/ami-amazon-linux-latest/amzn-ami-hvm-x86_64-gp2"
}

data "aws_ssm_parameter" "linuxAmiWorker" {
  provider = aws.region-worker
  name     = "/aws/service/ami-amazon-linux-latest/amzn-ami-hvm-x86_64-gp2"

}

resource "aws_key_pair" "master-key" {
  provider   = aws.region-master
  key_name   = "jenkins"
  public_key = file("ssh-keys/cg_tf_generated_key.pub")
}

resource "aws_instance" "jenkins-master" {
  provider                    = aws.region-master
  ami                         = data.aws_ssm_parameter.linuxAmiMaster.value
  instance_type               = var.instance_type
  key_name                    = aws_key_pair.master-key.key_name
  associate_public_ip_address = true
  vpc_security_group_ids      = [aws_security_group.jenkins-master-sg.id]
  subnet_id                   = aws_subnet.master_subnet_1.id

  tags = {
    Name = "jenkins-master-tf"
  }
  depends_on = [
    aws_main_route_table_association.set-master-default-rt-assoc
  ]

  provisioner "local-exec" {
    command = <<EOF
aws --profile ${var.profile} ec2 wait instance-status-ok --region ${var.region-master} --instance-ids ${self.id} \
&& ansible-playbook --private-key ./ssh-keys/cg_tf_generated_key --extra-vars 'passed_in_hosts=${aws_instance.jenkins-master.public_ip}' ansible_templates/jenkins-master-sample.yml
EOF
  }
}


resource "aws_key_pair" "worker-key" {
  provider   = aws.region-worker
  key_name   = "jenkins"
  public_key = file("ssh-keys/cg_tf_generated_key.pub")
}

resource "aws_instance" "jenkins-worker-oregon" {
  provider                    = aws.region-worker
  count                       = var.workers-count
  ami                         = data.aws_ssm_parameter.linuxAmiWorker.value
  instance_type               = "t3.micro"
  key_name                    = aws_key_pair.worker-key.key_name
  associate_public_ip_address = true
  vpc_security_group_ids      = [aws_security_group.jenkins-worker-sg.id]
  subnet_id                   = aws_subnet.worker_subnet_1.id

  tags = {
    Name = join("_", ["jenkings-worker-oregon-tf", count.index + 1])
  }
  depends_on = [aws_main_route_table_association.set-worker-rt-association, aws_instance.jenkins-master]


  provisioner "local-exec" {
    command = <<EOF
aws --profile ${var.profile} ec2 wait instance-status-ok --region ${var.region-worker} --instance-ids ${self.id} \
&& ansible-playbook --private-key ./ssh-keys/cg_tf_generated_key --extra-vars 'passed_in_hosts=${self.public_ip}' ansible_templates/jenkins-worker-sample.yml
EOF
  }
}