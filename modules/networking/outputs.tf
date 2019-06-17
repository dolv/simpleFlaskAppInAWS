output "alb_target_group_app_id" {
  value = "${aws_alb_target_group.app.id}"
}

output "public_subnet_ids" {
  value = [
    for subnet in aws_subnet.public:
          subnet.id
  ]
}

output "private_subnet_ids" {
  value = [
    for subnet in aws_subnet.private:
          subnet.id
  ]
}

output "region_availability_zones_names" {
  value = data.aws_availability_zones.available.names
}

output "esc_tasks_security_group_ids" {
  value = [aws_security_group.ecs_tasks.id]
}

output "app_lb_dns_name" {
  value = aws_lb.app.dns_name
}