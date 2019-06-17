
import java.util.logging.Logger
import jenkins.model.*

Logger logger = Logger.getLogger("ecs-cluster")
logger.info("Loading Jenkins")

instance = Jenkins.getInstance()

logger.info("Saving jenkins")
instance.save()