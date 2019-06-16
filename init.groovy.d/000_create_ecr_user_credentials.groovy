import com.cloudbees.jenkins.plugins.awscredentials.AWSCredentialsImpl
import com.cloudbees.plugins.credentials.Credentials
import com.cloudbees.plugins.credentials.CredentialsScope
import com.cloudbees.plugins.credentials.SystemCredentialsProvider
import com.cloudbees.plugins.credentials.domains.Domain
import jenkins.model.*

def ecr_user_credentials_file = "ecr_service_user_credentials.ini"

static boolean saveJenkinsCredentials(
            String id,
            String accessKey,
            String secretKey,
            String description
    ){
        boolean credentialsAdded
        boolean credentialsUpdated
        Credentials newCreds = new AWSCredentialsImpl(
                CredentialsScope.GLOBAL,
                id, accessKey, secretKey, description)
        SystemCredentialsProvider.StoreImpl credentialsStore = SystemCredentialsProvider
                .getInstance()
                .getStore()
        credentialsAdded = credentialsStore.addCredentials(Domain.global(), newCreds)

        if (! credentialsAdded){

            Credentials existingCreds = getJenkinsAWSCredentialsByID(id)
            credentialsUpdated = credentialsStore
                    .updateCredentials(Domain.global(), existingCreds, newCreds)
        }
        credentialsStore.save()
        return credentialsAdded || credentialsUpdated
    }


static Credentials getJenkinsAWSCredentialsByID(
            String credentialsID
    ) {
        Credentials credsInstance = SystemCredentialsProvider
                .getInstance()
                .getCredentials()
                .findAll{creds->
                    creds instanceof com.cloudbees.jenkins.plugins.awscredentials.AWSCredentialsImpl \
                    && creds.getId() == credentialsID
                }[0]
        return credsInstance
    }

static Tuple3 getCredentialsFromINIfile(String filename){
    def ini = new IniParser(filename)
    ini.dumpConfig()
    def secs = ini.getAllSections()
    username = secs[0]
    access_key_id = ini.getConfig(username, 'aws_access_key_id')
    secret_access_key =  ini.getConfig(username, 'aws_secret_access_key')
    return new Tuple3<String, String, String>(username, access_key_id, secret_access_key)
}

class IniParser {
    def src = null
    def sections = new ArrayList<String>();
    def config = [:]
    String section = ""
    boolean inSection = false
    def match = null
    IniParser(filename) {
        src = new File(filename)
        src.eachLine { line ->
            line.find(/\[(.*)\]/) {full, sec ->
                sections.add(sec)
                inSection = true;
                section = sec
                config[section] = [:]
            }
            line.find(/\s*(\S+)\s*=\s*(.*)?(?:#|$)/) {full, key, value ->
                if (config.get(section).containsKey(key)) {
                    def v = config.get(section).get(key)
                    if (v in Collection) {
                        def oldVal = config.get(section).get(key)
                        oldVal.add(value)
                        config[key] = oldVal
                        config.get(section).put(key, oldVal)
                    } else {
                        def values = new ArrayList<String>();
                        values.add(v)
                        values.add(value)
                        config.get(section).put(key, values)
                    }
                } else {
                    config.get(section).put(key, value)
                }
                // println "Match: $full, Key: $key, Value: $value"
                // config.get(section).put(key, value)
            }
        }
    }

    def dumpConfig() {
        config.each() {key, value ->
            println "$key: $value"
        }
    }

    ArrayList<String> getAllSections() {
        return sections
    }

    def getSection(s) {
        return config.get(s)
    }

    def getConfig() {
        return config
    }

    def getConfig(String section) {
        return config.get(section)
    }

    def getConfig(String section, String key) {
        return config.get(section).get(key)
    }
}

Tuple3 access_keys = getCredentialsFromINIfile(ecr_user_credentials_file)
result = saveJenkinsCredentials(
        'ECR_SERVICE_USER',
        (String) access_keys(1),
        (String) access_keys(2),
        'USER for interaction with ECR')