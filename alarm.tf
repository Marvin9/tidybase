resource "aws_cloudwatch_metric_alarm" "cpu_high_alarm" {
  alarm_name          = "HighCPUUsage"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 10
  metric_name         = "CPUActive"
  namespace           = "Compute/Tidybase"
  alarm_actions       = [aws_sns_topic.scale_up_topic.arn]
  period              = 30
  statistic           = "Average"
  threshold           = 70
  treat_missing_data  = "notBreaching"
  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.tidybase_small_asg.name
  }
}

resource "aws_cloudwatch_metric_alarm" "cpu_low_alarm" {
  alarm_name          = "LowCPUAlarm"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 10
  metric_name         = "CPUActive"
  namespace           = "Compute/Tidybase"
  alarm_actions       = [aws_sns_topic.scale_down_topic.arn]
  period              = 30
  statistic           = "Average"
  threshold           = 20
  treat_missing_data  = "notBreaching"
  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.tidybase_large_asg.name
  }
}
