import logging
import boto3
from deployer_config import Config
from botocore.exceptions import ClientError
import random
import string
import os, sys, re
import fileinput
from Crypto.PublicKey import RSA
from utils.terraform_commands import *
from utils.command_line_arguments import args

logger = logging.getLogger()
logger.setLevel(logging.INFO)
log_handler = logging.StreamHandler(sys.stdout)
log_handler.setLevel(logging.INFO)
logger.addHandler(log_handler)

def set_environment_variables():
    os.environ['AWS_SHARED_CREDENTIALS_FILE'] = os.path.expanduser(
        Config.aws['shared_credentials_file'])
    os.environ['AWS_PROFILE'] = Config.aws['credentials_profile']

session = boto3.Session(
    region_name=Config.aws['region'],
    profile_name=Config.aws['credentials_profile'])

def create_s3_bucket(bucket_name):
    """ Create an Amazon S3 bucket
    :param bucket_name: Unique string name
    :return: bucket_name if bucket is created, else None
    """

    s3 = session.client('s3')

    letters = string.ascii_lowercase
    salt = ''.join(random.choice(letters) for i in range(Config.salt_str_length))
    bucket_name = '{bucket_name}-{salt}'.format(bucket_name=bucket_name,
                                                salt=salt)
    try:
        s3.create_bucket(Bucket=bucket_name,
                         CreateBucketConfiguration={
                             'LocationConstraint': Config.aws['region']
                         })
    except ClientError as e:
        logging.error(e)
        return None
    logging.info('"{}" AWS S3 bucket created'.format(bucket_name))
    return bucket_name

def get_tfstate_bucket_name():
    s3 = session.client('s3')
    response = s3.list_buckets()
    if len(response['Buckets']):
        logging.info('Iterating over existing buckets.')
        for bucket in response['Buckets']:
            regex_str = '^{prefix}-.{salt_len}$'.format(
                prefix=Config.terraform_state_bucket_name_prefix,
                salt_len='{' + str(Config.salt_str_length) + '}'
            )
            match = re.search(regex_str, bucket["Name"])
            if match:
                logging.info(f'   Found needed pattern for: {bucket["Name"]}, using it...')
                return bucket["Name"]
    return create_s3_bucket(Config.terraform_state_bucket_name_prefix)

def adjust_terraform_config(bucket, filepath='main.tf'):
    for line in fileinput.input(filepath,inplace=True):
        line = re.sub('^(.*bucket = ).*$',f'\\1"{bucket}"',line)
        region = Config.aws['region']
        line = re.sub('^(.*region = ).*$',f'\\1"{region}"', line)
        # shared_credentials_path = os.path.join(Path.home(),'.aws/credentials')
        # line = re.sub('^(.*shared_credentials_file = ).*$',
        #               f'\\1"{shared_credentials_path}"', line)
        profile = Config.aws['credentials_profile']
        line = re.sub('^(.*profile =).*$',
                      f'\\1"{profile}"', line)
        print(line.rstrip())

def adjust_ssh_public_key_reference(ssh_pub_key_path='~/.ssh/id_rsa.pub', filepath='variables.tf'):
    for line in fileinput.input(filepath,inplace=True):
        line = re.sub('^(.*)(default = "~/.ssh/id_rsa").*$',f'\\1default = "{ssh_pub_key_path}"',line)
        print(line.rstrip())

def print_current_user_access_keys():
    iam = session.resource('iam')
    current_user = iam.CurrentUser()
    for accessKey in current_user.access_keys.all():
        print(accessKey)

def generate_ssh_keys(
        output_folder=Config.ssh['folder'],
        private_key_file=os.path.join(
            Config.ssh['folder'],
            Config.ssh['keys']['grover_admin']['private_key_file']),
        public_key_file=os.path.join(
            Config.ssh['folder'],
            Config.ssh['keys']['grover_admin']['public_key_file'])):

    key = RSA.generate(2048)
    private_key = key.export_key()
    file_out = open(private_key_file, "wb")
    file_out.write(private_key)

    public_key = key.publickey().export_key()
    file_out = open(public_key_file, "wb")
    file_out.write(public_key)

    return public_key_file


def configure(*args, **kwargs):
    adjust_terraform_config(get_tfstate_bucket_name())
    default_ssh_public_key_location = os.path.expanduser(
        Config.ssh['default_ssh_public_key_location'])
    if os.path.isfile(default_ssh_public_key_location):
        adjust_ssh_public_key_reference(
            default_ssh_public_key_location)
    else:
        adjust_ssh_public_key_reference(generate_ssh_keys())
    logging.info(f'Configuration stage completed...')
    logging.info(f'Consider double-checking main.tf and variables.tf files for correctness before executing further stages like init, plan or deploy...')

def init(*args, **kwarg):
    set_environment_variables()
    call_terraform_init(*args, **kwarg)

def plan(*args, **kwarg):
    set_environment_variables()
    call_terraform_plan(*args, **kwarg)

def apply(*args, **kwarg):
    set_environment_variables()
    call_terraform_apply(*args, **kwarg)

def destroy(*args, **kwarg):
    set_environment_variables()
    call_terraform_destroy(*args, **kwarg)

def deploy(*args, **kwarg):
    set_environment_variables()
    configure(*args, **kwarg)
    init(*args, **kwarg)
    apply(skip_plan=True, *args, **kwarg)

def execute_action(action):
    actions_map = {
        'configure': configure,
        'deploy': deploy,
        'init': init,
        'plan': plan,
        'apply': apply,
        'destroy': destroy
    }
    actions_map[action]()

if __name__ == '__main__':
    execute_action(args.action)