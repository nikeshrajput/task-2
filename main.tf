provider "aws" {
    region = "${var.region}"
    access_key = "${var.access_key}"
    secret_key = "${var.secret_key}"
    version = "3.30.0"
}

resource "aws_sqs_queue" "queue" {
    name = "upload-queue"
    delay_seconds = 60
    max_message_size = 1024
    message_retention_seconds = 172800
    receive_wait_time_seconds = 30
    policy = <<POLICY
{
  "Policy_id": "iam_notif_policy_doc"
  "Version": "2012-10-17",
  "Statement"" [
      {
          "Sid": "1"
          "Effect": "Allow",
          "Principal": "*",
          "Action": "sqs:SendMessage",
          "Resource": "arn:aws:sqs:*:*:s3-event-notification-queue",
          "Condition": {
              "ArnEquals": { "aws:SourceArn": "${aws_s3_bucket.bucket.arn}"}
          }
      }
  ]
}
POLICY
}

resource "aws_s3_bucket" "bucket" {
    bucket = "upload-bucket"
}

resource "aws_s3_bucket_notification" "bucket_notification" {
    count = "${var.event ? 1 : 0 }"
    bucket = "${aws_s3_bucket.bucket.id}"

    queue {
        queue_arn = "${aws_sqs_queue.queue.arn}"
        events = ["s3:ObjectCreated:Put"]
    }
}