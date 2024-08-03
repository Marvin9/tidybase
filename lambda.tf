data "archive_file" "scale_up" {
  type        = "zip"
  source_dir  = "${path.root}/lambda/scale-up/"
  output_path = "${path.root}/assets/scale-up/lambda.zip"
}

resource "aws_lambda_function" "scale_up_lambda" {
  function_name    = "scale-up"
  role             = var.lambda_role
  handler          = "index.handler"
  runtime          = "nodejs18.x"
  filename         = data.archive_file.scale_up.output_path
  timeout          = 900
  source_code_hash = data.archive_file.scale_up.output_base64sha256

  environment {
    variables = {
      BIG_AUTO_SCALING_NAME : aws_autoscaling_group.tidybase_large_asg.name
      TINY_AUTO_SCALING_NAME : aws_autoscaling_group.tidybase_small_asg.name
      TARGET_GROUP_ARN : aws_lb_target_group.tidybase_target_group.arn
    }
  }
}

resource "aws_lambda_function_url" "scale_up_lambda" {
  function_name      = aws_lambda_function.scale_up_lambda.function_name
  authorization_type = "NONE"
  cors {
    allow_origins  = ["*"]
    allow_headers  = ["*"]
    allow_methods  = ["*"]
    expose_headers = ["*"]
  }
}

output "lambda_scale_up_function_url" {
  value = aws_lambda_function_url.scale_up_lambda.function_url
}

data "archive_file" "scale_down" {
  type        = "zip"
  source_dir  = "${path.root}/lambda/scale-down/"
  output_path = "${path.root}/assets/scale-down/lambda.zip"
}

resource "aws_lambda_function" "scale_down_lambda" {
  function_name    = "scale-down"
  role             = var.lambda_role
  handler          = "index.handler"
  runtime          = "nodejs18.x"
  filename         = data.archive_file.scale_down.output_path
  timeout          = 900
  source_code_hash = data.archive_file.scale_down.output_base64sha256

  environment {
    variables = {
      BIG_AUTO_SCALING_NAME : aws_autoscaling_group.tidybase_large_asg.name
      TINY_AUTO_SCALING_NAME : aws_autoscaling_group.tidybase_small_asg.name
      TARGET_GROUP_ARN : aws_lb_target_group.tidybase_target_group.arn
    }
  }
}

resource "aws_lambda_function_url" "scale_down_lambda" {
  function_name      = aws_lambda_function.scale_down_lambda.function_name
  authorization_type = "NONE"
  cors {
    allow_origins  = ["*"]
    allow_headers  = ["*"]
    allow_methods  = ["*"]
    expose_headers = ["*"]
  }
}

output "lambda_scale_down_function_url" {
  value = aws_lambda_function_url.scale_down_lambda.function_url
}
