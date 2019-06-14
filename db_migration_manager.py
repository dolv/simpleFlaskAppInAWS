from models import *
from flask_script import Manager
from flask_migrate import Migrate, MigrateCommand

def run_migration_manager():
    migrate = Migrate(app, db)
    manager = Manager(app)

    manager.add_command('db', MigrateCommand)
    manager.run()

if __name__ == '__main__':
    run_migration_manager()