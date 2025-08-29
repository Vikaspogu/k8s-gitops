# Minio

## Bucket Creation

```admonish info
This requires installing the Minio `mc` CLI tool
```

### Creating a Bucket

1. Create the Minio CLI configuration file (`~/.mc/config.json`)

    ```sh
    mc alias set minio "https://s3.<domain>.<tld>" "<access-key>" "<secret-key>"
    ```

2. Export settings

    ```sh
    export BUCKET_NAME="<bucket-name>" # also used for the bucket username
    export BUCKET_PASSWORD="$(openssl rand -hex 20)"
    echo $BUCKET_PASSWORD
    ```

3. Create the bucket username and password

    ```sh
    mc admin user add minio "${BUCKET_NAME}" "${BUCKET_PASSWORD}"
    ```

4. Create the bucket

    ```sh
    mc mb "minio/${BUCKET_NAME}"
    ```

5. Create the user policy document

    ```sh
    cat <<EOF > /tmp/user-policy.json
    {
        "Version": "2012-10-17",
        "Statement": [
            {
                "Action": [
                    "s3:ListBucket",
                    "s3:PutObject",
                    "s3:GetObject",
                    "s3:DeleteObject"
                ],
                "Effect": "Allow",
                "Resource": ["arn:aws:s3:::${BUCKET_NAME}/*", "arn:aws:s3:::${BUCKET_NAME}"],
                "Sid": ""
            }
        ]
    }
    EOF
    ```

6. Apply the bucket policies

    ```sh
    mc admin policy create minio "${BUCKET_NAME}-private" /tmp/user-policy.json
    ```

7. Associate private policy with the user

    ```sh
    mc admin policy attach minio "${BUCKET_NAME}-private" --user="${BUCKET_NAME}"
    ```

#### Allow public access to certain objects in the bucket

```admonish info
This step is optional and not needed unless you want to make certain objects public to the internet
```

1. Create the bucket policy document and update the folders that should be public

    ```sh
    cat <<EOF > /tmp/bucket-policy.json
    {
        "Version": "2012-10-17",
        "Statement": [
            {
                "Effect": "Allow",
                "Principal": {
                    "AWS": [
                        "*"
                    ]
                },
                "Action": [
                    "s3:GetBucketLocation"
                ],
                "Resource": [
                    "arn:aws:s3:::${BUCKET_NAME}"
                ]
            },
            {
                "Effect": "Allow",
                "Principal": {
                    "AWS": [
                        "*"
                    ]
                },
                "Action": [
                    "s3:ListBucket"
                ],
                "Resource": [
                    "arn:aws:s3:::${BUCKET_NAME}"
                ],
                "Condition": {
                    "StringEquals": {
                        "s3:prefix": [
                            "avatars",
                            "public"
                        ]
                    }
                }
            },
            {
                "Effect": "Allow",
                "Principal": {
                    "AWS": [
                        "*"
                    ]
                },
                "Action": [
                    "s3:GetObject"
                ],
                "Resource": [
                    "arn:aws:s3:::${BUCKET_NAME}/avatars*",
                    "arn:aws:s3:::${BUCKET_NAME}/public*"
                ]
            }
        ]
    }
    EOF
    ```

2. Associate public policy with the bucket

    ```sh
    mc anonymous set-json /tmp/bucket-policy.json "minio/${BUCKET_NAME}"
    ```

### Sharing an object in a bucket

```sh
mc share download --expire=7d "minio/<bucket-name>/<file>.<ext>" --json  | jq -r .share | pbcopy
```
