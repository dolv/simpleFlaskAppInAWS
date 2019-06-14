# models.py
from flask_sqlalchemy import SQLAlchemy
from sqlalchemy import MetaData, create_engine, UniqueConstraint, ForeignKeyConstraint, CheckConstraint
from config import Config
from app import app

eng = create_engine(Config.dbconnection_string)

meta = MetaData()
meta.reflect(bind=eng)

db = SQLAlchemy(app, meta)

class Brands(db.Model):
    __tablename__ = "brands"
    name = db.Column(db.String(50), primary_key=True)
    description = db.Column(db.Text, nullable=True)
    __table_args__ = (
        UniqueConstraint(name, name='brend_names_are_unique_constraint'),
    )

    products = db.relationship('Products', backref='producer')

    def __repr__(self):
        return '<Brand %r>' % self.name


class ProductCategories(db.Model):
    __tablename__ = "product_categories"
    category = db.Column(db.String(100), primary_key=True, nullable=False)
    products = db.relationship('Products', backref='category_name')

    def __repr__(self):
        return '<Product category %r>' % self.category


class Products(db.Model):
    __tablename__ = "products"
    id = db.Column(db.BIGINT, primary_key=True, nullable=False, autoincrement=True)
    name = db.Column(db.String(50), nullable=False)
    brand = db.Column(db.String(50), db.ForeignKey('brands.name'), nullable=False)
    category = db.Column(db.String(100), db.ForeignKey('product_categories.category'), nullable=False)
    description = db.Column(db.Text, nullable=True)

    __table_args__ = (
        UniqueConstraint(id, name, name='products_id_name_combination_unique_constraint'),
        ForeignKeyConstraint(['brand'], ['brands.name'],),
        ForeignKeyConstraint(['category'], ['product_categories.category'], ),
    )
    stocks = db.relationship('Stock', backref='product_stocks')
    prices = db.relationship('Prices', backref='product_prices')

    def __repr__(self):
        return '<Product %r>' % self.name


class Stores(db.Model):
    __tablename__ = "stores"
    id = db.Column(db.BIGINT, primary_key=True, autoincrement=True)
    code = db.Column(db.String(30), nullable=True, unique=True)
    name = db.Column(db.String(30), nullable=True)

    __table_args__ = (
        UniqueConstraint(id, code, name='store_id_code_unique_constraint'),
    )
    stock = db.relationship('Stock', backref='store')
    prices = db.relationship('Prices', backref='store')

    def __repr__(self):
        return '<Store %r>' % self.name


class Stock(db.Model):
    __tablename__ = "stock"
    id = db.Column(db.BIGINT, primary_key=True, autoincrement=True)
    store_id = db.Column(db.BIGINT, db.ForeignKey('stores.id'), nullable=False)
    product_id = db.Column(db.BIGINT, db.ForeignKey('products.id'), nullable=False)
    quantity = db.Column(db.Integer, nullable=False)

    __table_args__ = (
        ForeignKeyConstraint(['store_id'], ['stores.id'], ),
        ForeignKeyConstraint(['product_id'], ['products.id'], ),
    )

    def __repr__(self):
        return '<Stock %r>' % self.name


class Prices(db.Model):
    __tablename__ = "prices"
    id = db.Column(db.BIGINT, primary_key=True, autoincrement=True)
    store_id = db.Column(db.BIGINT, db.ForeignKey('stores.id'), nullable=False)
    product_id = db.Column(db.BIGINT, db.ForeignKey('products.id'), nullable=False)
    price = db.Column(db.Float(2), nullable=True)

    __table_args__ = (
        ForeignKeyConstraint(['store_id'], ['stores.id'], ),
        ForeignKeyConstraint(['product_id'], ['products.id'], ),
    )

    ordered = db.relationship('OrderItems', backref='price')

    def __repr__(self):
        return '<Prices %r>' % self.name


class OrderItems(db.Model):
    __tablename__ = "order_items"
    id = db.Column(db.BIGINT, primary_key=True, autoincrement=True)
    user_id = db.Column(db.BIGINT, db.ForeignKey('users.name'), nullable=False)
    price_id = db.Column(db.BIGINT, db.ForeignKey('prices.id'), nullable=False)
    quantity = db.Column(db.Integer, nullable=False)
    orders = db.relationship('Orders', backref='oreders_list')

    def __repr__(self):
        return '<OrderItems %r>' % self.name


class Orders(db.Model):
    __tablename__ = "orders"
    id = db.Column(db.BIGINT, primary_key=True, autoincrement=True)
    user_id = db.Column(db.String(30), db.ForeignKey('users.name'), nullable=False)
    order_items = db.Column(db.ARRAY(db.BIGINT), db.ForeignKey('order_items.id'), nullable=False)

    __table_args__ = (
        ForeignKeyConstraint(['user_id'], ['users.name'], ),
    )

    def __repr__(self):
        return '<Orders %r>' % self.name

class Users(db.Model):
    __tablename__ = "users"
    name = db.Column(db.String(30), unique=True, primary_key=True)
    email = db.Column(db.String(120), unique=True, nullable=False)
    purchases = db.relationship('OrderItems', backref='customer')
    __table_args__ = (
        UniqueConstraint(name, email, name='name_email_combiantion_unique_constraint'),
    )

    def __repr__(self):
        return '<Users %r>' % self.name

queries = {
        'all': """
WITH stk as (SELECT stores.id as store_id,
		   stores.code,
		   sub.id as product_id,
		   sub.name,
		   sub.brand,
		   sub.category,
	       stock.quantity,
		   sub.quantity as total
	FROM (
		SELECT
		    products.id,
		    products.name,
		    products.brand,
		    products.category,
		    SUM(COALESCE(stock.quantity,0)) as quantity
		FROM products
		LEFT JOIN stock ON stock.product_id = products.id
		GROUP BY products.id) as sub
	LEFT JOIN stock ON sub.id = stock.product_id
	LEFT JOIN stores ON stock.store_id = stores.id)
SELECT name, brand, category, quantity,
       CASE WHEN total > 0 THEN 'in stock' ELSE 'out of stock' END as available
FROM stk
    WHERE code = '{store_code}'
UNION ALL
SELECT name, brand, category, 0,
CASE WHEN total > 0 THEN 'in stock' ELSE 'out of stock' END as available
FROM stk
    WHERE product_id not in (
            SELECT product_id FROM stk
            WHERE code = '{store_code}'
        )
""",
        'available_only': """
WITH sub as (	   
		SELECT
		    products.id,
		    products.name,
		    products.brand,
		    products.category,
		    SUM(CASE
		    	    WHEN stock.quantity IS NULL THEN 0
		    	    ELSE stock.quantity
		        END) as quantity
		FROM products
		LEFT JOIN stock ON stock.product_id = products.id
		GROUP BY products.id)
SELECT sub.name,
	   sub.brand,
	   sub.category,
	   stock.quantity,
	   CASE WHEN sub.quantity > 0 THEN 'in stock' ELSE 'out of stock' END as available
FROM sub
LEFT JOIN stock ON sub.id = stock.product_id
LEFT JOIN stores ON stock.store_id = stores.id
WHERE stores.code = '{store_code}' AND stock.quantity > 0
        """,
    'not_available_only': """
WITH stk as (SELECT stores.id as store_id,
		   stores.code,
		   sub.id as product_id,
		   sub.name,
		   sub.brand,
		   sub.category,
	       stock.quantity,
		   sub.quantity as total
	FROM (	   
		SELECT
		    products.id,
		    products.name,
		    products.brand,
		    products.category,
		    SUM(COALESCE(stock.quantity,0)) as quantity
		FROM products
		LEFT JOIN stock ON stock.product_id = products.id
		GROUP BY products.id) as sub
	LEFT JOIN stock ON sub.id = stock.product_id
	LEFT JOIN stores ON stock.store_id = stores.id)
SELECT name, brand, category, '0' as quantity, 
CASE WHEN total > 0 THEN 'in stock' ELSE 'out of stock' END as available
FROM stk
    WHERE product_id not in (SELECT product_id FROM stk
    WHERE code = '{store_code}')
    """}

def get_store_stock(store_code, availability_filter):
    if availability_filter in queries:
        return db.session.execute(queries[availability_filter]
                                  .format(store_code=store_code))
    else:
        return db.session.execute(queries['available_only']
                                  .format(store_code=store_code))
