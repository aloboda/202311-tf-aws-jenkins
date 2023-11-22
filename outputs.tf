output "vpc-id-us-east-1" {
  value = aws_vpc.vpc_master.id
}
output "vpc-id-us-west-2" {
  value = aws_vpc.vpc_worker.id
}
output "peering-connection0id" {
  value = aws_vpc_peering_connection.useast1-to-uswest2.id
}

output "master-instance-ip" {
  value = aws_instance.jenkins-master.public_ip
}

output "worker-ips" {
  value = {
    for ins in aws_instance.jenkins-worker-oregon :
    ins.id => ins.public_ip
  }
}