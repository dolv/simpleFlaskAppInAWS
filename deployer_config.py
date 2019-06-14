class Config:
    terraform_state_bucket_name_prefix = 'terraform'
    salt_str_length = 6
    aws = {
        'shared_credentials_file': '~/.aws/credentials',
        'credentials_profile': 'grover-test-account',
        'region': 'eu-central-1',
        'aws_account_id': ''
    }
    ssh={
        'folder': 'ssh',
        'default_ssh_public_key_location': '~/.ssh/id_rsa.pub',
        'keys': {
            'grover_admin': {
                'private_key_file': 'grover_admin_id_rsa',
                'public_key_file': 'grover_admin_id_rsa.pub'
            }
        }
    }
