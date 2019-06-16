import java.util.Arrays
import java.util.logging.Logger
Logger logger = Logger.getLogger("ecs-cluster")

logger.info("Loading Jenkins")
import jenkins.model.*
instance = Jenkins.getInstance()

import com.cloudbees.jenkins.plugins.amazonecs.ECSTaskTemplate.MountPointEntry
def mounts = Arrays.asList(
  new MountPointEntry(
    name="docker",
    sourcePath="/var/run/docker.sock",
    containerPath="/var/run/docker.sock",
    readOnly=false),
  new MountPointEntry(
    name="jenkins",
    sourcePath="/home/jenkins",
    containerPath="/home/jenkins",
    readOnly=false),
)

logger.info("Creating template")
import com.cloudbees.jenkins.plugins.amazonecs.ECSTaskTemplate
def ecsTemplate = new ECSTaskTemplate(
  templateName="jnlp-slave-with-docker",
  label="ecs",
  image="jenkinsci/jnlp-slave",
  remoteFSRoot=null,
  memory=512,
  cpu=1024,
  privileged=false,
  logDriverOptions=null,
  environments=null,
  extraHosts=null,
  mountPoints=mounts
)

logger.info("Retrieving ecs cloud config by descriptor")
import com.cloudbees.jenkins.plugins.amazonecs.ECSCloud
ecsCloud = new ECSCloud(
  name="ecs-cloud",
  templates=Arrays.asList(ecsTemplate),
  credentialsId='ECR_SERVICE_USER',
  cluster="arn:aws:ecs:eu-central-1:126981522510:cluster/jslave",
  regionName="eu-central-1",
  jenkinsUrl="http://oleksandr.dudchenko.kiev.ua:8080",
  slaveTimoutInSeconds=30
)

logger.info("Gettings clouds")
def clouds = instance.clouds
clouds.add(ecsCloud)
logger.info("Saving jenkins")
instance.save()