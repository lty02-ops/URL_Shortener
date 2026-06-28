resource "aws_cloudwatch_metric_alarm" "high_cpu_alarm" {
  alarm_name          = "HighCPUUtilization"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 300
  statistic           = "Average"
  threshold           = 80

  dimensions = {
    InstanceId = aws_instance.url_shortener_instance.id
  }

  alarm_description = "This metric monitors EC2 instance CPU utilization"
}

resource "aws_cloudwatch_metric_alarm" "high_rds_cpu_alarm" {
  alarm_name          = "HighRDSCPUUtilization"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/RDS"
  period              = 300
  statistic           = "Average"
  threshold           = 80

  dimensions = {
    DBInstanceIdentifier = aws_db_instance.url_shortener_db.id
  }

  alarm_description = "This metric monitors RDS instance CPU utilization"
}


resource "aws_cloudwatch_metric_alarm" "alb_target_5xx" {
  alarm_name          = "url-shortener-alb-target-5xx"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = "HTTPCode_Target_5XX_Count"
  namespace           = "AWS/ApplicationELB"
  period              = 300
  statistic           = "Sum"
  threshold           = 1
  alarm_description   = "ALB target returned 5XX errors."

  dimensions = {
    LoadBalancer = aws_lb.url_shortener_lb.arn_suffix
  }
}