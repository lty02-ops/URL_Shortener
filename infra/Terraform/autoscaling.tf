resource "aws_autoscaling_group" "backend" {
  name = "url-shortener-backend-asg"

  min_size         = 2
  desired_capacity = 2
  max_size         = 4

  vpc_zone_identifier = [
    aws_subnet.private_app_1.id,
    aws_subnet.private_app_2.id
  ]

  target_group_arns = [
    aws_lb_target_group.url_shortener_tg.arn
  ]

  health_check_type         = "ELB"
  health_check_grace_period = 300
  default_instance_warmup   = 300

  launch_template {
    id      = aws_launch_template.backend.id
    version = "$Latest"
  }

  instance_refresh {
    strategy = "Rolling"

    preferences {
      min_healthy_percentage = 50
      instance_warmup        = 300
    }

  }

  tag {
    key                 = "Name"
    value               = "URL Shortener Backend"
    propagate_at_launch = true
  }
}

resource "aws_autoscaling_policy" "backend_cpu" {
  name                   = "url-shortener-backend-cpu-scaling"
  autoscaling_group_name = aws_autoscaling_group.backend.name
  policy_type            = "TargetTrackingScaling"

  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }

    target_value     = 60
    disable_scale_in = false
  }
}
