from .terraform import *
from deployer import logger

terraform = Terraform()

def call_terraform_apply(*args, **kwarg):
    terraform.apply(capture_output=False,
                    raise_on_error=True,
                    lock=True,
                    *args, **kwarg)

def call_terraform_init(*args, **kwarg):
    terraform.init(capture_output=False,
                   *args, **kwarg)

def call_terraform_plan(*args, **kwarg):
    terraform.plan(capture_output=False, *args, **kwarg)

def call_terraform_destroy(*args, **kwarg):
    terraform.destroy(capture_output=False,
                      raise_on_error=True,
                      *args, **kwarg)