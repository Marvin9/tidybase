resource "aws_sns_topic" "scale_up_topic" {
  name = "scale-up-topic"
}

resource "aws_sns_topic" "scale_down_topic" {
  name = "scale-down-topic"
}

resource "aws_lambda_permission" "allow_scale_up_invocation_from_sns" {
  statement_id  = "AllowExecutionFromSNS"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.scale_up_lambda.function_name
  principal     = "sns.amazonaws.com"
  source_arn    = aws_sns_topic.scale_up_topic.arn
}

resource "aws_lambda_permission" "allow_scale_down_invocation_from_sns" {
  statement_id  = "AllowExecutionFromSNS"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.scale_down_lambda.function_name
  principal     = "sns.amazonaws.com"
  source_arn    = aws_sns_topic.scale_down_topic.arn
}

resource "aws_sns_topic_subscription" "scale_up_subscription" {
  topic_arn = aws_sns_topic.scale_up_topic.arn
  protocol  = "lambda"
  endpoint  = aws_lambda_function.scale_up_lambda.arn
}

resource "aws_sns_topic_subscription" "scale_down_subscription" {
  topic_arn = aws_sns_topic.scale_down_topic.arn
  protocol  = "lambda"
  endpoint  = aws_lambda_function.scale_down_lambda.arn
}
