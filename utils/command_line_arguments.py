import argparse

parser = argparse.ArgumentParser(
    add_help=True,
    description='This script deploys the infrastructure in AWS based on terrafrom files in project folder.')

parser.add_argument('action', type=str,
                    choices=["configure", "init", "plan", "deploy", "destroy"],
                    help='an action to be performed by deployer script.')
parser.add_argument('-C', '--create_ecr_user_credentials',
                    action = 'store_true',
                    dest='create_ecr_user_credentials',
                    help='This will create new IAM credentials for ecr user and store that infor in the file user_name_credentials.ini.')
parser.add_argument('-F', '--from-scratch',
                    action = 'store_true',
                    dest='from_scratch',
                    help='This will delete resources if exists before creation.')


args = parser.parse_args()