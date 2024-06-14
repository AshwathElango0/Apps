from flask import Flask, jsonify, request
import json
from sqlalchemy import create_engine, text

app = Flask(__name__)

def get_news_from_db(category=None):
    engine = create_engine('sqlite:///news.db')
    with engine.connect() as connection:
        if category:
            result = connection.execute(text("SELECT * FROM news WHERE category = :category"), {'category': category})
        else:
            result = connection.execute(text("SELECT * FROM news"))
        news = []
        for row in result:
            news.append(dict(zip(result.keys(), row)))
    return news

def get_categories_from_db():
    engine = create_engine('sqlite:///news.db')
    with engine.connect() as connection:
        result = connection.execute(text("SELECT DISTINCT category FROM news"))
        categories = [row[0] for row in result]
    return categories

@app.route('/news', methods=['GET'])
def get_news():
    category = request.args.get('category')
    news = get_news_from_db(category)
    return jsonify(news)

@app.route('/categories', methods=['GET'])
def get_categories():
    categories = get_categories_from_db()
    return jsonify(categories)

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=True)
