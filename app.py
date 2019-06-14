from flask import Flask, jsonify, redirect, render_template, request
from config import Config
from models import *

app = Flask(__name__)
app.config['SQLALCHEMY_DATABASE_URI'] = Config.dbconnection_string
app.config['SQLALCHEMY_TRACK_MODIFICATIONS'] = False
eng = create_engine(Config.dbconnection_string)

meta = MetaData()
meta.reflect(bind=eng)

db = SQLAlchemy(app, meta)

@app.route('/REST')
def rest_root_path():
    return redirect("/REST/stock", code=301)

@app.route('/REST/stock', methods = ['GET'])
@app.route('/REST/stock/<store_code>', methods = ['GET'])
@app.route('/REST/stock/<store_code>/<availability_filter>', methods = ['GET'])
def get_stock(store_code='grover-de', availability_filter='available_only'):
    result = get_store_stock(store_code, availability_filter)
    return jsonify({'result': {
        'store_code': store_code,
        'stock': [dict(row) for row in result]}
    })

@app.route('/', methods = ['GET'])
@app.route('/<store_code>', methods = ['GET'])
@app.route('/<store_code>/<availability_filter>', methods = ['GET'])
def index(store_code='grover-de', availability_filter='available_only'):
   if request.method == 'GET':
       result = get_store_stock(store_code, availability_filter)
       store_codes = [row.code  for row in Stores.query.with_entities(Stores.code)\
           .order_by(Stores.code.asc())\
           .all()]
       return render_template('index.html',
                          store_code = store_code,
                          store_codes = store_codes,
                          filters_list = queries.keys(),
                          availability_filter = availability_filter,
                          stock = [dict(row) for row in result])

def main():
    db.init_app(app)
    app.run(debug=Config.flask['debug'],
        use_debugger=Config.flask['use_debugger'],
        use_reloader=Config.flask['use_reloader'],
        passthrough_errors=Config.flask['passthrough_errors'],
        host=Config.flask['host'])

if __name__ == '__main__':
    main()
