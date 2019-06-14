class Config:
    dbconnection_string = 'postgresql://dbuser:22222@localhost:5432/grover'
    flask = {
        'host': '0.0.0.0',
        'debug': True,
        'use_debugger': False,
        'use_reloader': False,
        'passthrough_errors': True
    }
