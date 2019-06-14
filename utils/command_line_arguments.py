import argparse

parser = argparse.ArgumentParser(
    add_help=True,
    description='This script deploys the infrastructure in AWS based on terrafrom files in project folder.')

parser.add_argument('action', type=str,
                    help='an action to perform by deployer script. \n' +
                    'currently implemented actions are: ["configure", "init", "plan", "deploy", "destroy"]')

args = parser.parse_args()