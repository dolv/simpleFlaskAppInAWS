import java.util.Arrays
import java.util.logging.Logger
import jenkins.model.*
import com.cloudbees.jenkins.plugins.amazonecs.ECSCloud
import com.cloudbees.jenkins.plugins.amazonecs.ECSTaskTemplate
import com.cloudbees.jenkins.plugins.amazonecs.ECSTaskTemplate.MountPointEntry
import com.cloudbees.jenkins.plugins.amazonecs.ECSTaskTemplate.LogDriverOption
import com.cloudbees.jenkins.plugins.amazonecs.ECSTaskTemplate.EnvironmentEntry
import com.cloudbees.jenkins.plugins.amazonecs.ECSTaskTemplate.ExtraHostEntry


Logger logger = Logger.getLogger("ecs-cluster")
logger.info("Loading Jenkins")

instance = Jenkins.getInstance()

List<MountPointEntry> mounts = new ArrayList<MountPointEntry>()
mounts.add( new MountPointEntry(
    name="docker",
    sourcePath="/var/run/docker.sock",
    containerPath="/var/run/docker.sock",
    readOnly=false)
)
mounts.add( new MountPointEntry(
    name="jenkins",
    sourcePath="/home/jenkins",
    containerPath="/home/jenkins",
    readOnly=false)
)

logger.info("Creating template")

def templateArgumentsMap = [
  label: "ecs",
  image: "jenkinsci/jnlp-slave",
  remoteFSRoot: null,
  memory: 512,
  cpu: 1024,
  privileged: false,
  logDriverOptions: new ArrayList<LogDriverOption>(),
  environments: new ArrayList<EnvironmentEntry>(),
  extraHosts: new ArrayList<ExtraHostEntry>(),
  mountPoints: mounts
]

def ecsTemplate = new ECSTaskTemplate(
        (String) templateArgumentsMap['label'],
        (String) templateArgumentsMap['image'],
        (String) templateArgumentsMap['remoteFSRoot'],
        (int) templateArgumentsMap['memory'],
        (int) templateArgumentsMap['cpu'],
        (boolean) templateArgumentsMap['privileged'].asBoolean(),
        (List<LogDriverOption>) templateArgumentsMap['logDriverOptions'],
        (List<EnvironmentEntry>) templateArgumentsMap['environments'],
        (List<ExtraHostEntry>) templateArgumentsMap['extraHosts'],
        (List<MountPointEntry>) templateArgumentsMap['mountPoints']
)

logger.info("Retrieving ecs cloud config by descriptor")
List<ECSTaskTemplate> templates = new ArrayList<ECSTaskTemplate>()
templates.add(ecsTemplate)
ecsCloud = new ECSCloud(
  name="ecs-cloud",
  templates=templates,
  credentialsId='ECR_SERVICE_USER',
  cluster="arn:aws:ecs:eu-central-1:126981522510:cluster/jslaves",
  regionName="eu-central-1",
  jenkinsUrl="http://oleksandr.dudchenko.kiev.ua:8080",
  slaveTimoutInSeconds=30
)

logger.info("Gettings clouds")
def clouds = instance.clouds
clouds.add(ecsCloud)
logger.info("Saving jenkins")
instance.save()