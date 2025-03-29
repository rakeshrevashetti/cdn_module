resource "aws_s3_bucket" "my_bucket" {
  bucket = var.bucket_name
}

resource "aws_s3_object" "index_html" {
  bucket      = aws_s3_bucket.my_bucket.bucket
  key         = "index.html"
  source      = "index.html"  
  content_type = "text/html"
  acl         = "private"  
}

resource "aws_cloudfront_origin_access_identity" "oai" {
  comment = "OAI for CloudFront to access S3"
}

resource "aws_s3_bucket_policy" "s3_policy" {
  bucket = aws_s3_bucket.my_bucket.id
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          AWS = aws_cloudfront_origin_access_identity.oai.iam_arn
        }
        Action   = "s3:GetObject"
        Resource = "arn:aws:s3:::${aws_s3_bucket.my_bucket.id}/*"
      }
    ]
  })
}

resource "aws_cloudfront_distribution" "cdn" {
  origin {
    domain_name = aws_s3_bucket.my_bucket.bucket_regional_domain_name
    origin_id   = "S3-my-cloudfront-devops-acecloud-application"

    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.oai.cloudfront_access_identity_path
    }
  }

  enabled             = true
  default_root_object = "index.html"

  default_cache_behavior {
    target_origin_id       = "S3-my-cloudfront-devops-acecloud-application"
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]
    compress               = true
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }
  }

  price_class = "PriceClass_100"

  restrictions {
    geo_restriction {
      restriction_type = "none"  
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true  
  }
}



